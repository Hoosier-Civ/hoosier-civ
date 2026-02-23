import { createClient } from "npm:@supabase/supabase-js";

const GOOGLE_CIVIC_API_BASE = "https://civicinfo.googleapis.com/civicinfo/v2";

interface Representative {
  name: string;
  chamber: string;
  district: string;
  phone?: string;
  email?: string;
  party?: string;
}

function determineChamber(officeName: string): string | null {
  const name = officeName.toLowerCase();
  if (name.includes("u.s. representative") || name.includes("us representative")) return "us_house";
  if (name.includes("u.s. senator") || name.includes("us senator")) return "us_senate";
  if (name.includes("state representative") || name.includes("state house")) return "house";
  if (name.includes("state senator") || name.includes("state senate")) return "senate";
  return null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json" },
    });
  }

  let zip_code: string;
  try {
    const body = await req.json();
    zip_code = body.zip_code?.toString().trim();
    if (!zip_code || !/^\d{5}$/.test(zip_code)) {
      return new Response(JSON.stringify({ error: "zip_code must be a 5-digit string" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }
  } catch {
    return new Response(JSON.stringify({ error: "Invalid request body" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const cacheTtlDays = parseInt(Deno.env.get("DISTRICT_CACHE_TTL_DAYS") ?? "90", 10);

  // --- Cache check ---
  const { data: cached, error: cacheError } = await supabase
    .from("district_zip_cache")
    .select("district_id, representatives, cached_at")
    .eq("zip_code", zip_code)
    .maybeSingle();

  if (cacheError) {
    console.error("Error looking up district cache", cacheError);
    return new Response(JSON.stringify({ error: "Failed to look up cached district data" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
  if (cached) {
    const ageMs = Date.now() - new Date(cached.cached_at).getTime();
    const ageDays = ageMs / (1000 * 60 * 60 * 24);
    if (ageDays < cacheTtlDays) {
      return new Response(
        JSON.stringify({ district_id: cached.district_id, representatives: cached.representatives }),
        { headers: { "Content-Type": "application/json" } },
      );
    }
  }

  // --- Cache miss or stale: call Google Civic Info API ---
  const apiKey = Deno.env.get("GOOGLE_CIVIC_API_KEY");
  if (!apiKey) {
    return new Response(JSON.stringify({ error: "Google Civic API key not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const url = new URL(`${GOOGLE_CIVIC_API_BASE}/representatives`);
  url.searchParams.set("address", zip_code);
  url.searchParams.set("key", apiKey);

  let civicData: Record<string, unknown>;
  try {
    const civicRes = await fetch(url.toString(), { signal: AbortSignal.timeout(10_000) });
    if (civicRes.status === 404) {
      return new Response(
        JSON.stringify({ error: "ZIP code not found — check that it is a valid US ZIP code" }),
        { status: 404, headers: { "Content-Type": "application/json" } },
      );
    }
    if (!civicRes.ok) {
      console.error("Google Civic API error:", civicRes.status, await civicRes.text());
      return new Response(JSON.stringify({ error: "Failed to fetch district data" }), {
        status: 502,
        headers: { "Content-Type": "application/json" },
      });
    }
    civicData = await civicRes.json();
  } catch (err) {
    console.error("Fetch error:", err);
    return new Response(JSON.stringify({ error: "Failed to reach Google Civic API" }), {
      status: 502,
      headers: { "Content-Type": "application/json" },
    });
  }

  // --- Indiana validation ---
  const normalizedInput = civicData.normalizedInput as Record<string, string> | undefined;
  if (normalizedInput?.state !== "IN") {
    return new Response(
      JSON.stringify({ error: "ZIP code is not in Indiana" }),
      { status: 422, headers: { "Content-Type": "application/json" } },
    );
  }

  // --- Extract district_id from OCD division IDs ---
  const divisionIds = Object.keys((civicData.divisions as Record<string, unknown>) ?? {});

  // Prefer Indiana state house → state senate → US congressional → any Indiana division
  const districtId =
    divisionIds.find((id) => id.includes("state:in/sldl")) ??
    divisionIds.find((id) => id.includes("state:in/sldu")) ??
    divisionIds.find((id) => id.includes("state:in/cd")) ??
    divisionIds.find((id) => id.includes("state:in")) ??
    "";

  if (!districtId) {
    return new Response(
      JSON.stringify({ error: "Could not determine district for this ZIP code" }),
      { status: 422, headers: { "Content-Type": "application/json" } },
    );
  }

  // --- Map offices + officials to Representative records ---
  type CivicOffice = { name: string; divisionId: string; officialIndices: number[] };
  type CivicOfficial = { name: string; party?: string; phones?: string[]; emails?: string[] };

  const offices = (civicData.offices as CivicOffice[]) ?? [];
  const officials = (civicData.officials as CivicOfficial[]) ?? [];
  const representatives: Representative[] = [];

  for (const office of offices) {
    const chamber = determineChamber(office.name ?? "");
    if (!chamber) continue;

    for (const idx of office.officialIndices ?? []) {
      const official = officials[idx];
      if (!official) continue;
      representatives.push({
        name: official.name,
        chamber,
        district: office.divisionId,
        phone: official.phones?.[0],
        email: official.emails?.[0],
        party: official.party,
      });
    }
  }

  // --- Upsert cache row ---
  const { error: upsertError } = await supabase.from("district_zip_cache").upsert({
    zip_code,
    district_id: districtId,
    representatives,
    cached_at: new Date().toISOString(),
  });

  if (upsertError) {
    console.error("Cache upsert failed:", upsertError.message);
    // Non-fatal — still return the data
  }

  return new Response(
    JSON.stringify({ district_id: districtId, representatives }),
    { headers: { "Content-Type": "application/json" } },
  );
});
