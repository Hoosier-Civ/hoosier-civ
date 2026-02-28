import { createClient, SupabaseClient } from "npm:@supabase/supabase-js";
import { LookUpDistrictController } from "./controller.ts";
import { CiceroError, CiceroOfficial, CiceroService } from "./cicero_service.ts";
import { CacheError, DistrictCacheService } from "./district_cache_service.ts";
import { CiceroDistrictType } from "./cicero_types.ts";

export interface OfficialResponse {
  cicero_id: number;
  // Name
  first_name: string;
  last_name: string;
  middle_initial?: string;
  salutation?: string;
  nickname?: string;
  preferred_name?: string;
  name_suffix?: string;
  // Role
  chamber: string;          // computed from district_type via districtTypeToChamber
  office_title?: string;    // e.g. "Senator", "Governor", "Mayor"
  party?: string;
  // District
  district_type?: string;
  district_ocd_id?: string;
  district_state?: string;
  district_city?: string;
  district_label?: string;
  chamber_name?: string;
  chamber_name_formal?: string;
  // Contact & media
  photo_url?: string;
  website_url?: string;
  web_form_url?: string;
  addresses: { address_1: string; address_2: string; city: string; state: string; postal_code: string; phone_1: string; fax_1: string }[];
  email_addresses: string[];
  // Social / external IDs
  identifiers: { identifier_type: string; identifier_value: string }[];
  // Committees
  committees: { name: string; urls: string[]; position: string }[];
  // Term
  term_start_date?: string;
  term_end_date?: string;
  // Bio
  bio?: string;
  birth_date?: string;
}

export function districtTypeToChamber(districtType: string): string | null {
  switch (districtType) {
    case "NATIONAL_UPPER":  return "us_senate";
    case "NATIONAL_LOWER":  return "us_house";
    case "NATIONAL_EXEC":   return "national_exec";
    case "STATE_UPPER":     return "senate";
    case "STATE_LOWER":     return "house";
    case "STATE_EXEC":      return "state_exec";
    case "LOCAL":           return "local";
    case "LOCAL_EXEC":      return "local_exec";
    default: return null;
  }
}

// deno-lint-ignore no-explicit-any
export type SupabaseFactory = () => Pick<SupabaseClient, "from"> | any;

function defaultSupabaseFactory(): Pick<SupabaseClient, "from"> {
  return createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
}

function errorResponse(message: string, status: number): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** Maps a Cicero API official to the OfficialResponse shape. */
function fromCiceroOfficial(o: CiceroOfficial): OfficialResponse | null {
  const chamber = districtTypeToChamber(o.office?.district?.district_type ?? "");
  if (!chamber) return null;
  return {
    cicero_id: o.id,
    first_name: o.first_name,
    last_name: o.last_name,
    middle_initial: o.middle_initial || undefined,
    salutation: o.salutation || undefined,
    nickname: o.nickname || undefined,
    preferred_name: o.preferred_name || undefined,
    name_suffix: o.name_suffix || undefined,
    chamber,
    office_title: o.office?.title || undefined,
    party: o.party || undefined,
    district_type: o.office?.district?.district_type || undefined,
    district_ocd_id: o.office?.district?.ocd_id || undefined,
    district_state: o.office?.district?.state || undefined,
    district_city: o.office?.district?.city || undefined,
    district_label: o.office?.district?.label || undefined,
    chamber_name: o.office?.chamber?.name || undefined,
    chamber_name_formal: o.office?.chamber?.name_formal || undefined,
    photo_url: o.photo_origin_url || undefined,
    website_url: o.urls?.[0] || undefined,
    web_form_url: o.web_form_url || undefined,
    addresses: (o.addresses ?? []).map(({ address_1, address_2, city, state, postal_code, phone_1, fax_1 }) => ({ address_1, address_2, city, state, postal_code, phone_1, fax_1 })),
    email_addresses: o.email_addresses ?? [],
    identifiers: (o.identifiers ?? []).map(({ identifier_type, identifier_value }) => ({ identifier_type, identifier_value })),
    committees: (o.committees ?? []).map(({ name, urls, position }) => ({ name, urls, position })),
    term_start_date: o.current_term_start_date?.split(" ")[0] || undefined,
    term_end_date: o.term_end_date?.split(" ")[0] || undefined,
    bio: o.notes?.[0] || undefined,
    birth_date: (() => { const d = o.notes?.[1]; return d && /^\d{4}-\d{2}-\d{2}$/.test(d) ? d : undefined; })(),
  };
}

/** Maps a cicero_officials DB row (flat columns) to the OfficialResponse shape. */
// deno-lint-ignore no-explicit-any
function fromCacheRow(o: any): OfficialResponse | null {
  const chamber = districtTypeToChamber(o.district_type ?? "");
  if (!chamber) return null;
  return {
    cicero_id: o.cicero_id,
    first_name: o.first_name,
    last_name: o.last_name,
    middle_initial: o.middle_initial || undefined,
    salutation: o.salutation || undefined,
    nickname: o.nickname || undefined,
    preferred_name: o.preferred_name || undefined,
    name_suffix: o.name_suffix || undefined,
    chamber,
    office_title: o.office_title || undefined,
    party: o.party || undefined,
    district_type: o.district_type || undefined,
    district_ocd_id: o.district_ocd_id || undefined,
    district_state: o.district_state || undefined,
    district_city: o.district_city || undefined,
    district_label: o.district_label || undefined,
    chamber_name: o.chamber_name || undefined,
    chamber_name_formal: o.chamber_name_formal || undefined,
    photo_url: o.photo_url || undefined,
    website_url: o.website_url || undefined,
    web_form_url: o.web_form_url || undefined,
    addresses: o.addresses ?? [],
    email_addresses: o.email_addresses ?? [],
    identifiers: o.identifiers ?? [],
    committees: o.committees ?? [],
    term_start_date: o.term_start_date || undefined,
    term_end_date: o.term_end_date || undefined,
    bio: o.bio || undefined,
    birth_date: o.birth_date || undefined,
  };
}

/** Upserts all officials into cicero_officials and zip_cicero_officials. Non-fatal on error. */
// deno-lint-ignore no-explicit-any
async function upsertOfficials(supabase: any, zipCode: string, officials: CiceroOfficial[]): Promise<void> {
  for (const o of officials) {
    const birthDateRaw = o.notes?.[1];
    const birthDate = birthDateRaw && /^\d{4}-\d{2}-\d{2}$/.test(birthDateRaw) ? birthDateRaw : null;

    const { error: officialError } = await supabase.from("cicero_officials").upsert({
      cicero_id: o.id,
      first_name: o.first_name,
      last_name: o.last_name,
      middle_initial: o.middle_initial || null,
      salutation: o.salutation || null,
      nickname: o.nickname || null,
      preferred_name: o.preferred_name || null,
      name_suffix: o.name_suffix || null,
      party: o.party || null,
      photo_url: o.photo_origin_url || null,
      website_url: o.urls?.[0] || null,
      web_form_url: o.web_form_url || null,
      office_title: o.office?.title || null,
      district_type: o.office?.district?.district_type || null,
      district_ocd_id: o.office?.district?.ocd_id || null,
      district_state: o.office?.district?.state || null,
      district_city: o.office?.district?.city || null,
      district_label: o.office?.district?.label || null,
      chamber_name: o.office?.chamber?.name || null,
      chamber_name_formal: o.office?.chamber?.name_formal || null,
      chamber_type: o.office?.chamber?.type || null,
      term_start_date: o.current_term_start_date?.split(" ")[0] || null,
      term_end_date: o.term_end_date?.split(" ")[0] || null,
      bio: o.notes?.[0] || null,
      birth_date: birthDate,
      addresses: o.addresses ?? [],
      email_addresses: o.email_addresses ?? [],
      committees: o.committees ?? [],
      identifiers: (o.identifiers ?? []).map(({ identifier_type, identifier_value }) => ({ identifier_type, identifier_value })),
      cicero_valid_to: o.valid_to || null,
      cached_at: new Date().toISOString(),
    });

    if (officialError) {
      console.error("Failed to upsert official:", o.id, officialError.message);
    }

    const { error: joinError } = await supabase.from("zip_cicero_officials").upsert({
      zip_code: zipCode,
      cicero_id: o.id,
    });

    if (joinError) {
      console.error("Failed to upsert zip_cicero_officials:", o.id, joinError.message);
    }
  }
}

export async function handler(
  req: Request,
  makeSupabase: SupabaseFactory = defaultSupabaseFactory,
): Promise<Response> {
  // --- Request validation ---
  const controller = new LookUpDistrictController(req);
  const validationError = await controller.validateRequest();
  if (validationError) return validationError;
  const { zipCode } = controller;

  // --- TTL config ---
  const rawCacheTtl = Deno.env.get("DISTRICT_CACHE_TTL_DAYS");
  let cacheTtlDays = parseInt(rawCacheTtl ?? "", 10);
  if (!Number.isFinite(cacheTtlDays) || cacheTtlDays <= 0) cacheTtlDays = 90;

  const supabase = makeSupabase();

  // --- Cache check ---
  const cache = new DistrictCacheService(supabase);
  let cached;
  try {
    cached = await cache.get(zipCode);
  } catch (err) {
    const status = err instanceof CacheError ? err.httpStatus : 500;
    const message = err instanceof Error ? err.message : "Failed to look up cached district data";
    return errorResponse(message, status);
  }

  if (cached && cache.isFresh(cached.cached_at, cacheTtlDays)) {
    const { data: joinRows } = await supabase
      .from("zip_cicero_officials")
      .select("cicero_officials(*)")
      .eq("zip_code", zipCode);

    const officials = (joinRows ?? [])
      .map((r: { cicero_officials: unknown }) => fromCacheRow(r.cicero_officials))
      .filter((o): o is OfficialResponse => o !== null);

    return new Response(
      JSON.stringify({ district_id: cached.district_id, officials }),
      { headers: { "Content-Type": "application/json" } },
    );
  }

  // --- Cicero API ---
  let officials: CiceroOfficial[];
  try {
    const cicero = new CiceroService();
    officials = await cicero.fetchOfficials(zipCode);
  } catch (err) {
    const status = err instanceof CiceroError ? err.httpStatus : 502;
    const message = err instanceof Error ? err.message : "Failed to reach Cicero API";
    return errorResponse(message, status);
  }

  // --- Extract district_id (STATE_LOWER → STATE_UPPER → NATIONAL_LOWER → any state:in) ---
  const findOcdId = (type: CiceroDistrictType): string | null =>
    officials.find((o) => o.office?.district?.district_type === type && o.office?.district?.ocd_id)
      ?.office?.district?.ocd_id ?? null;

  const districtId =
    findOcdId("STATE_LOWER") ??
    findOcdId("STATE_UPPER") ??
    findOcdId("NATIONAL_LOWER") ??
    officials.find((o) => o.office?.district?.ocd_id?.includes("state:in"))?.office?.district?.ocd_id ??
    "";

  if (!districtId) return errorResponse("Could not determine district for this ZIP code", 422);

  // --- Cache writes (non-fatal) ---
  await cache.upsert(zipCode, districtId);
  await upsertOfficials(supabase, zipCode, officials);

  const officialResponses = officials
    .map(fromCiceroOfficial)
    .filter((o): o is OfficialResponse => o !== null);

  return new Response(
    JSON.stringify({ district_id: districtId, officials: officialResponses }),
    { headers: { "Content-Type": "application/json" } },
  );
}
