import { createClient, SupabaseClient } from "npm:@supabase/supabase-js";
import { LookUpDistrictController } from "./controller.ts";
import { CiceroError, CiceroOfficial, CiceroService } from "./cicero_service.ts";
import { CiceroDistrictType } from "./cicero_types.ts";
import { CacheRow, DistrictCacheService } from "./district_cache_service.ts";

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

export function districtTypeToChamber(districtType: string): string {
  switch (districtType) {
    case "NATIONAL_UPPER":  return "us_senate";
    case "NATIONAL_LOWER":  return "us_house";
    case "NATIONAL_EXEC":   return "national_exec";
    case "STATE_UPPER":     return "senate";
    case "STATE_LOWER":     return "house";
    case "STATE_EXEC":      return "state_exec";
    case "LOCAL":           return "local";
    case "LOCAL_EXEC":      return "local_exec";
    default: return districtType ? districtType.toLowerCase() : "unknown";
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
function fromCiceroOfficial(o: CiceroOfficial): OfficialResponse {
  const chamber = districtTypeToChamber(o.office?.district?.district_type ?? "");
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

/** Maps a cicero_officials DB row to the OfficialResponse shape. */
// deno-lint-ignore no-explicit-any
function fromCacheRow(row: any): OfficialResponse {
  return {
    cicero_id: row.cicero_id,
    first_name: row.first_name,
    last_name: row.last_name,
    middle_initial: row.middle_initial ?? undefined,
    salutation: row.salutation ?? undefined,
    nickname: row.nickname ?? undefined,
    preferred_name: row.preferred_name ?? undefined,
    name_suffix: row.name_suffix ?? undefined,
    chamber: districtTypeToChamber(row.district_type ?? ""),
    office_title: row.office_title ?? undefined,
    party: row.party ?? undefined,
    district_type: row.district_type ?? undefined,
    district_ocd_id: row.district_ocd_id ?? undefined,
    district_state: row.district_state ?? undefined,
    district_city: row.district_city ?? undefined,
    district_label: row.district_label ?? undefined,
    chamber_name: row.chamber_name ?? undefined,
    chamber_name_formal: row.chamber_name_formal ?? undefined,
    photo_url: row.photo_url ?? undefined,
    website_url: row.website_url ?? undefined,
    web_form_url: row.web_form_url ?? undefined,
    addresses: row.addresses ?? [],
    email_addresses: row.email_addresses ?? [],
    identifiers: row.identifiers ?? [],
    committees: row.committees ?? [],
    term_start_date: row.term_start_date ?? undefined,
    term_end_date: row.term_end_date ?? undefined,
    bio: row.bio ?? undefined,
    birth_date: row.birth_date ?? undefined,
  };
}

/** Returns true if any official's term has already ended. */
// deno-lint-ignore no-explicit-any
function hasAnyExpiredOfficial(officials: any[]): boolean {
  const today = new Date().toISOString().split("T")[0];
  return officials.some(
    (o) => o.term_end_date != null && o.term_end_date < today,
  );
}

/** Upserts all officials into cicero_officials and links them to the ZIP. Non-fatal on error. */
// deno-lint-ignore no-explicit-any
async function upsertOfficials(supabase: any, zip: string, officials: CiceroOfficial[]): Promise<void> {
  for (const o of officials) {
    const birthDateRaw = o.notes?.[1];
    const birthDate = birthDateRaw && /^\d{4}-\d{2}-\d{2}$/.test(birthDateRaw) ? birthDateRaw : null;

    const { error } = await supabase.from("cicero_officials").upsert({
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

    if (error) {
      console.error("Failed to upsert official:", o.id, error.message);
    }

    // Link this official to the ZIP code
    const { error: linkError } = await supabase.from("zip_cicero_officials").upsert({
      zip_code: zip,
      cicero_id: o.id,
    });

    if (linkError) {
      console.error("Failed to upsert zip_cicero_officials:", o.id, linkError.message);
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
  const { zip, address } = controller;

  const supabase = makeSupabase();
  const ttlDays = Number(Deno.env.get("DISTRICT_CACHE_TTL_DAYS") ?? "90");
  const cache = new DistrictCacheService(supabase);

  // --- Cache check ---
  let cacheRow: CacheRow | null = null;
  try {
    cacheRow = await cache.get(zip);
  } catch (_err) {
    // Non-fatal: cache lookup failed, fall through to Cicero
  }

  if (cacheRow && cache.isFresh(cacheRow.cached_at, ttlDays)) {
    const { data: zipRows, error: joinError } = await supabase
      .from("zip_cicero_officials")
      .select("cicero_officials(*)")
      .eq("zip_code", zip);

    // deno-lint-ignore no-explicit-any
    if (!joinError && (zipRows as any[])?.length > 0) {
      // deno-lint-ignore no-explicit-any
      const officials = (zipRows as any[]).map((row: any) => row.cicero_officials);
      if (!hasAnyExpiredOfficial(officials)) {
        return new Response(
          JSON.stringify({
            city: cacheRow.match_city ?? "",
            zip_code: zip,
            district_id: cacheRow.district_id,
            officials: officials.map(fromCacheRow),
          }),
          { headers: { "Content-Type": "application/json" } },
        );
      }
    }
  }

  // --- Cicero API ---
  let city: string;
  let zipCode: string;
  let officials: CiceroOfficial[];
  try {
    const cicero = new CiceroService();
    ({ city, zipCode, officials } = await cicero.fetchOfficials(zip, address));
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

  if (!districtId) return errorResponse("Could not determine district for this address", 422);

  // --- Persist to cache and DB (non-fatal) ---
  await cache.upsert(zip, districtId, city);
  await upsertOfficials(supabase, zip, officials);

  const officialResponses = officials.map(fromCiceroOfficial);

  return new Response(
    JSON.stringify({ city, zip_code: zipCode, district_id: districtId, officials: officialResponses }),
    { headers: { "Content-Type": "application/json" } },
  );
}
