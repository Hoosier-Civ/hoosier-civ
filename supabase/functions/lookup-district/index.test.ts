/**
 * Unit tests for the lookup-district edge function.
 *
 * Run from the supabase/functions directory:
 *   deno test --allow-env lookup-district/index.test.ts
 *
 * The Supabase client is fully mocked via dependency injection so no real
 * HTTP traffic is made and no interval timers are started.
 * The Cicero API is mocked via globalThis.fetch replacement.
 */

import { assertEquals } from "jsr:@std/assert";
import { stub } from "jsr:@std/testing/mock";
import { districtTypeToChamber, handler } from "./_handler.ts";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface MockSupabaseOptions {
  /** Error returned by any upsert, or null for success. */
  upsertError?: { message: string } | null;
  /** Spy called when upsert is invoked, receives the table name and upserted data. */
  onUpsert?: (table: string, data: Record<string, unknown>) => void;
  /** Row returned by district_zip_cache select, or null for a cache miss. */
  cacheRow?: { district_id: string; cached_at: string; match_city?: string | null } | null;
  /** Error returned by district_zip_cache select (causes CacheError → falls through). */
  cacheSelectError?: { message: string } | null;
  /** Rows returned by zip_cicero_officials select (join with cicero_officials). */
  zipOfficials?: Array<{ cicero_officials: Record<string, unknown> }> | null;
  /** Error returned by zip_cicero_officials select. */
  zipOfficialsError?: { message: string } | null;
}

/**
 * Builds a mock of the Supabase client that covers:
 *   district_zip_cache   → .select(...).eq(...).maybeSingle()  (cache read)
 *   district_zip_cache   → .upsert(data)                       (cache write)
 *   zip_cicero_officials → .select("cicero_officials(*)").eq() (join read)
 *   zip_cicero_officials → .upsert(data)                       (link write)
 *   cicero_officials     → .upsert(data)                       (official write)
 */
function makeSupabaseMock(opts: MockSupabaseOptions = {}) {
  const {
    upsertError = null,
    onUpsert,
    cacheRow = null,
    cacheSelectError = null,
    zipOfficials = null,
    zipOfficialsError = null,
  } = opts;

  return () => ({
    from: (table: string) => ({
      upsert: (data: Record<string, unknown>) => {
        onUpsert?.(table, data);
        return Promise.resolve({ error: upsertError });
      },
      select: (_fields: string) => ({
        eq: (_col: string, _val: unknown) => {
          // Decide what to return based on the table being queried
          const arrayResult = table === "zip_cicero_officials"
            ? { data: zipOfficials ?? [], error: zipOfficialsError ?? null }
            : { data: [], error: null };

          const singleResult = table === "district_zip_cache"
            ? { data: cacheRow, error: cacheSelectError ?? null }
            : { data: null, error: null };

          // Return a thenable (awaitable as array) that also exposes .maybeSingle()
          const p = Promise.resolve(arrayResult);
          // deno-lint-ignore no-explicit-any
          (p as any).maybeSingle = () => Promise.resolve(singleResult);
          return p;
        },
      }),
    }),
  });
}

// ---------------------------------------------------------------------------
// Env stub helper
// ---------------------------------------------------------------------------

function makeEnvStub(overrides: Record<string, string> = {}) {
  const defaults: Record<string, string> = {
    SUPABASE_URL: "http://localhost:54321",
    SUPABASE_SERVICE_ROLE_KEY: "test-key",
    CICERO_API_KEY: "test-cicero-key",
    DISTRICT_CACHE_TTL_DAYS: "90",
  };
  const env = { ...defaults, ...overrides };
  return stub(Deno.env, "get", (key: string) => env[key]);
}

// ---------------------------------------------------------------------------
// Cicero API fetch mock helper
// ---------------------------------------------------------------------------

function mockCiceroFetch(response: Response | (() => never)): () => void {
  const original = globalThis.fetch;
  globalThis.fetch = ((_url: string | URL | Request) => {
    if (typeof response === "function") response();
    return Promise.resolve(response as Response);
  }) as typeof fetch;
  return () => {
    globalThis.fetch = original;
  };
}



function mockJson(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ---------------------------------------------------------------------------
// Shared test fixture: a valid Indiana Cicero API response
// Uses the candidates[0] structure; match_region drives the Indiana check.
// ---------------------------------------------------------------------------

function makeCiceroCandidate(matchRegion: string, officials: unknown[]) {
  return {
    response: {
      results: {
        candidates: [{
          match_region: matchRegion,
          match_addr: "46201",
          match_city: "Indianapolis",
          match_subregion: "Marion",
          match_postal: "46201",
          match_country: "US",
          match_streetaddr: "",
          x: -86.1581,
          y: 39.7684,
          wkid: 4326,
          locator: "ZIP",
          locator_type: "ZIP5",
          geoservice: "Esri",
          score: 100,
          count: { from: 0, to: officials.length - 1, total: officials.length },
          officials,
        }],
      },
    },
  };
}

function makeOfficial(overrides: Record<string, unknown>) {
  return {
    id: 1,
    sk: 1,
    valid_from: "2025-01-01 00:00:00",
    valid_to: null,
    last_update_date: "2025-01-01 00:00:00",
    salutation: "",
    first_name: "Jane",
    middle_initial: "",
    last_name: "Smith",
    nickname: "",
    preferred_name: "",
    name_suffix: "",
    party: "Democratic",
    photo_origin_url: null,
    photo_cropping: null,
    web_form_url: "",
    urls: [],
    initial_term_start_date: null,
    current_term_start_date: "2025-01-01 00:00:00",
    term_end_date: "2027-01-01 00:00:00",
    notes: ["Bio text.", null],
    titles: [],
    addresses: [{ address_1: "", address_2: "", address_3: "", city: "", county: "", state: "IN", postal_code: "", phone_1: "317-555-0100", fax_1: "", phone_2: "", fax_2: "" }],
    email_addresses: ["jane@in.gov"],
    committees: [],
    identifiers: [],
    office: {
      id: 1, sk: 1, valid_from: "2025-01-01 00:00:00", valid_to: null,
      last_update_date: "2025-01-01 00:00:00", notes: "", election_rules: "",
      representing_city: "", representing_state: "IN", representing_country: {},
      title: "Representative",
      district: {
        id: 1, sk: 1, valid_from: "2025-01-01 00:00:00", valid_to: null,
        last_update_date: "2025-01-01 00:00:00", subtype: "LOWER", country: "US",
        city: "", district_id: "92", label: "IN House District 92",
        num_officials: 1, data: {},
        district_type: "STATE_LOWER",
        state: "IN",
        ocd_id: "ocd-division/country:us/state:in/sldl:92",
      },
      chamber: {
        id: 1, official_count: 100, term_length: "2 years", term_limit: "",
        inauguration_rules: "", name_native_language: "", contact_phone: "",
        election_frequency: "2 years", redistricting_rules: "", vacancy_rules: "",
        is_chamber_complete: true, contact_email: "", last_update_date: "",
        remarks: "", notes: "", url: "", has_geographic_representation: true,
        is_appointed: false, election_rules: "", legislature_update_date: null,
        government: { name: "Indiana", type: "STATE", city: "", state: "IN", notes: "", country: {} },
        name: "House",
        name_formal: "Indiana House of Representatives",
        type: "LOWER",
      },
    },
    ...overrides,
  };
}

const OFFICIAL_STATE_REP = makeOfficial({});

const OFFICIAL_US_SENATOR_1 = makeOfficial({
  id: 2,
  first_name: "John",
  last_name: "Doe",
  party: "Republican",
  addresses: [{ address_1: "", address_2: "", address_3: "", city: "", county: "", state: "DC", postal_code: "", phone_1: "202-555-0200", fax_1: "", phone_2: "", fax_2: "" }],
  email_addresses: [],
  office: {
    ...makeOfficial({}).office,
    title: "Senator",
    district: {
      ...makeOfficial({}).office.district,
      district_type: "NATIONAL_UPPER",
      ocd_id: "ocd-division/country:us/state:in",
      label: "Indiana",
    },
    chamber: { ...makeOfficial({}).office.chamber, name: "Senate", name_formal: "United States Senate", type: "UPPER" },
  },
});

const OFFICIAL_US_SENATOR_2 = makeOfficial({
  id: 3,
  first_name: "Bob",
  last_name: "Jones",
  party: "Republican",
  addresses: [],
  email_addresses: [],
  office: OFFICIAL_US_SENATOR_1.office,
});

const CICERO_IN = makeCiceroCandidate("IN", [
  OFFICIAL_STATE_REP,
  OFFICIAL_US_SENATOR_1,
  OFFICIAL_US_SENATOR_2,
]);

const TEST_ADDRESS = "17941 Ambrosia Trail, Westfield, IN";
const TEST_ZIP = "46074";

function postRequest(zip: string, address?: string): Request {
  return new Request("http://localhost/", {
    method: "POST",
    body: JSON.stringify({ zip, ...(address ? { address } : {}) }),
    headers: { "Content-Type": "application/json" },
  });
}

// ---------------------------------------------------------------------------
// Cache fixtures
// ---------------------------------------------------------------------------

/** A fresh cache row (cached just now, TTL not expired). */
const FRESH_CACHE_ROW = {
  district_id: "ocd-division/country:us/state:in/sldl:92",
  cached_at: new Date().toISOString(),
  match_city: "Indianapolis",
};

/** A stale cache row (cached 91 days ago, beyond the 90-day TTL). */
const STALE_CACHE_ROW = {
  district_id: "ocd-division/country:us/state:in/sldl:92",
  cached_at: new Date(Date.now() - 91 * 24 * 60 * 60 * 1000).toISOString(),
  match_city: "Indianapolis",
};

/** A cached DB official whose term is still in the future. */
const DB_OFFICIAL_FRESH = {
  cicero_id: 1,
  first_name: "Jane",
  last_name: "Smith",
  middle_initial: null,
  salutation: null,
  nickname: null,
  preferred_name: null,
  name_suffix: null,
  office_title: "Representative",
  district_type: "STATE_LOWER",
  district_ocd_id: "ocd-division/country:us/state:in/sldl:92",
  district_state: "IN",
  district_city: null,
  district_label: "IN House District 92",
  chamber_name: "House",
  chamber_name_formal: "Indiana House of Representatives",
  chamber_type: "LOWER",
  party: "Democratic",
  photo_url: null,
  website_url: null,
  web_form_url: null,
  term_start_date: "2025-01-01",
  term_end_date: "2027-01-01",
  bio: null,
  birth_date: null,
  addresses: [],
  email_addresses: ["jane@in.gov"],
  committees: [],
  identifiers: [],
  cicero_valid_to: null,
  cached_at: new Date().toISOString(),
};

/** A cached DB official whose term has expired. */
const DB_OFFICIAL_EXPIRED = {
  ...DB_OFFICIAL_FRESH,
  term_end_date: "2020-01-01",
};

const ZIP_OFFICIALS_FRESH = [{ cicero_officials: DB_OFFICIAL_FRESH }];
const ZIP_OFFICIALS_EXPIRED = [{ cicero_officials: DB_OFFICIAL_EXPIRED }];

// ===========================================================================
// districtTypeToChamber — pure unit tests (no mocking needed)
// ===========================================================================

Deno.test("districtTypeToChamber: STATE_LOWER → house", () => {
  assertEquals(districtTypeToChamber("STATE_LOWER"), "house");
});

Deno.test("districtTypeToChamber: STATE_UPPER → senate", () => {
  assertEquals(districtTypeToChamber("STATE_UPPER"), "senate");
});

Deno.test("districtTypeToChamber: NATIONAL_LOWER → us_house", () => {
  assertEquals(districtTypeToChamber("NATIONAL_LOWER"), "us_house");
});

Deno.test("districtTypeToChamber: NATIONAL_UPPER → us_senate", () => {
  assertEquals(districtTypeToChamber("NATIONAL_UPPER"), "us_senate");
});

Deno.test("districtTypeToChamber: STATE_EXEC → state_exec", () => {
  assertEquals(districtTypeToChamber("STATE_EXEC"), "state_exec");
});

Deno.test("districtTypeToChamber: LOCAL → local", () => {
  assertEquals(districtTypeToChamber("LOCAL"), "local");
});

Deno.test("districtTypeToChamber: LOCAL_EXEC → local_exec", () => {
  assertEquals(districtTypeToChamber("LOCAL_EXEC"), "local_exec");
});

Deno.test("districtTypeToChamber: NATIONAL_EXEC → national_exec", () => {
  assertEquals(districtTypeToChamber("NATIONAL_EXEC"), "national_exec");
});

Deno.test("districtTypeToChamber: unknown types return lowercased fallback", () => {
  assertEquals(districtTypeToChamber("COUNTY"), "county");
  assertEquals(districtTypeToChamber("SCHOOL_BOARD"), "school_board");
  assertEquals(districtTypeToChamber("state_lower"), "state_lower"); // case sensitive — not a known type
  assertEquals(districtTypeToChamber(""), "unknown");
});

// ===========================================================================
// Handler — HTTP method validation (no DB/fetch needed)
// ===========================================================================

Deno.test("handler: GET → 405", async () => {
  const env = makeEnvStub();
  try {
    const res = await handler(new Request("http://localhost/", { method: "GET" }));
    assertEquals(res.status, 405);
    assertEquals((await res.json()).error, "Method not allowed");
  } finally {
    env.restore();
  }
});

Deno.test("handler: PUT → 405", async () => {
  const env = makeEnvStub();
  try {
    const res = await handler(new Request("http://localhost/", { method: "PUT" }));
    assertEquals(res.status, 405);
  } finally {
    env.restore();
  }
});

// ===========================================================================
// Handler — request body validation (no DB/fetch needed)
// ===========================================================================

Deno.test("handler: non-JSON body → 400", async () => {
  const env = makeEnvStub();
  try {
    const res = await handler(
      new Request("http://localhost/", {
        method: "POST",
        body: "not json",
        headers: { "Content-Type": "application/json" },
      }),
    );
    assertEquals(res.status, 400);
    assertEquals((await res.json()).error, "Invalid request body");
  } finally {
    env.restore();
  }
});

Deno.test("handler: missing zip → 400", async () => {
  const env = makeEnvStub();
  try {
    const res = await handler(
      new Request("http://localhost/", {
        method: "POST",
        body: JSON.stringify({}),
        headers: { "Content-Type": "application/json" },
      }),
    );
    assertEquals(res.status, 400);
    assertEquals((await res.json()).error, "zip must be a 5-digit string");
  } finally {
    env.restore();
  }
});

Deno.test("handler: empty zip → 400", async () => {
  const env = makeEnvStub();
  try {
    const res = await handler(postRequest(""));
    assertEquals(res.status, 400);
    assertEquals((await res.json()).error, "zip must be a 5-digit string");
  } finally {
    env.restore();
  }
});

Deno.test("handler: non-5-digit zip → 400", async () => {
  const env = makeEnvStub();
  try {
    const res = await handler(postRequest("1234"));
    assertEquals(res.status, 400);
    assertEquals((await res.json()).error, "zip must be a 5-digit string");
  } finally {
    env.restore();
  }
});

Deno.test("handler: address is optional — zip only is valid", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock();
  const restoreFetch = mockCiceroFetch(mockJson(CICERO_IN));
  try {
    const res = await handler(postRequest(TEST_ZIP), supabase);
    assertEquals(res.status, 200);
  } finally {
    env.restore();
    restoreFetch();
  }
});

// ===========================================================================
// Handler — missing Cicero API key → 500
// ===========================================================================

Deno.test("handler: missing CICERO_API_KEY → 500", async () => {
  const env = makeEnvStub({ CICERO_API_KEY: "" });
  const supabase = makeSupabaseMock();

  try {
    const res = await handler(postRequest(TEST_ZIP, TEST_ADDRESS), supabase);
    assertEquals(res.status, 500);
    assertEquals((await res.json()).error, "Cicero API key not configured");
  } finally {
    env.restore();
  }
});

// ===========================================================================
// Handler — Cicero API error paths
// ===========================================================================

Deno.test("handler: Cicero API 404 → 404 with address-not-found message", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock();
  const restoreFetch = mockCiceroFetch(mockJson({ error: { code: 404 } }, 404));

  try {
    const res = await handler(postRequest("60601"), supabase);
    assertEquals(res.status, 404);
    assertEquals(
      (await res.json()).error,
      "Address not found — check that it is a valid US address",
    );
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: Cicero API 500 → 502", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock();
  const restoreFetch = mockCiceroFetch(new Response("Server Error", { status: 500 }));

  try {
    const res = await handler(postRequest(TEST_ZIP, TEST_ADDRESS), supabase);
    assertEquals(res.status, 502);
    assertEquals((await res.json()).error, "Failed to fetch district data");
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: Cicero API network failure → 502", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock();

  const original = globalThis.fetch;
  globalThis.fetch = (() => Promise.reject(new Error("Network failure"))) as typeof fetch;

  try {
    const res = await handler(postRequest(TEST_ZIP, TEST_ADDRESS), supabase);
    assertEquals(res.status, 502);
    assertEquals((await res.json()).error, "Failed to reach Cicero API");
  } finally {
    env.restore();
    globalThis.fetch = original;
  }
});

// ===========================================================================
// Handler — Indiana validation (now driven by candidate.match_region)
// ===========================================================================

Deno.test("handler: non-Indiana address (IL match_region) → 422", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock();
  const restoreFetch = mockCiceroFetch(
    mockJson(makeCiceroCandidate("IL", [
      makeOfficial({
        office: {
          ...makeOfficial({}).office,
          district: { ...makeOfficial({}).office.district, district_type: "STATE_LOWER", ocd_id: "ocd-division/country:us/state:il/sldl:1", state: "IL" },
        },
      }),
    ])),
  );

  try {
    const res = await handler(postRequest("60601"), supabase);
    assertEquals(res.status, 422);
    assertEquals((await res.json()).error, "Address is not in Indiana");
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: no candidate in Cicero response → 422", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock();
  const restoreFetch = mockCiceroFetch(
    mockJson({ response: { results: { candidates: [] } } }),
  );

  try {
    const res = await handler(postRequest(TEST_ZIP, TEST_ADDRESS), supabase);
    assertEquals(res.status, 422);
    assertEquals((await res.json()).error, "Address is not in Indiana");
  } finally {
    env.restore();
    restoreFetch();
  }
});

// ===========================================================================
// Handler — district ID extraction priority
// ===========================================================================

Deno.test("handler: prefers STATE_LOWER > STATE_UPPER > NATIONAL_LOWER > any state:in", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock();
  const restoreFetch = mockCiceroFetch(
    mockJson(makeCiceroCandidate("IN", [
      makeOfficial({ id: 1, office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "STATE_LOWER", ocd_id: "ocd-division/country:us/state:in/sldl:92" } } }),
      makeOfficial({ id: 2, office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "STATE_UPPER", ocd_id: "ocd-division/country:us/state:in/sldu:30" } } }),
      makeOfficial({ id: 3, office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "NATIONAL_LOWER", ocd_id: "ocd-division/country:us/state:in/cd:7" } } }),
      makeOfficial({ id: 4, office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "NATIONAL_UPPER", ocd_id: "ocd-division/country:us/state:in" } } }),
    ])),
  );

  try {
    const res = await handler(postRequest(TEST_ZIP, TEST_ADDRESS), supabase);
    assertEquals(res.status, 200);
    assertEquals((await res.json()).district_id, "ocd-division/country:us/state:in/sldl:92");
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: falls back to STATE_UPPER when STATE_LOWER is absent", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock();
  const restoreFetch = mockCiceroFetch(
    mockJson(makeCiceroCandidate("IN", [
      makeOfficial({ id: 2, office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "STATE_UPPER", ocd_id: "ocd-division/country:us/state:in/sldu:30" } } }),
      makeOfficial({ id: 3, office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "NATIONAL_LOWER", ocd_id: "ocd-division/country:us/state:in/cd:7" } } }),
    ])),
  );

  try {
    const res = await handler(postRequest(TEST_ZIP, TEST_ADDRESS), supabase);
    assertEquals(res.status, 200);
    assertEquals((await res.json()).district_id, "ocd-division/country:us/state:in/sldu:30");
  } finally {
    env.restore();
    restoreFetch();
  }
});

// ===========================================================================
// Handler — happy path (full response shape)
// ===========================================================================

Deno.test("handler: happy path returns correct district_id and all representative fields", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock();
  const restoreFetch = mockCiceroFetch(mockJson(CICERO_IN));

  try {
    const res = await handler(postRequest(TEST_ZIP, TEST_ADDRESS), supabase);
    assertEquals(res.status, 200);
    const body = await res.json();

    assertEquals(body.district_id, "ocd-division/country:us/state:in/sldl:92");
    assertEquals(body.city, "Indianapolis");
    assertEquals(body.officials.length, 3);

    // State representative
    assertEquals(body.officials[0].first_name, "Jane");
    assertEquals(body.officials[0].last_name, "Smith");
    assertEquals(body.officials[0].chamber, "house");
    assertEquals(body.officials[0].office_title, "Representative");
    assertEquals(body.officials[0].district_ocd_id, "ocd-division/country:us/state:in/sldl:92");
    assertEquals(body.officials[0].addresses[0].phone_1, "317-555-0100");
    assertEquals(body.officials[0].email_addresses[0], "jane@in.gov");
    assertEquals(body.officials[0].party, "Democratic");

    // Two US senators
    assertEquals(body.officials[1].first_name, "John");
    assertEquals(body.officials[1].last_name, "Doe");
    assertEquals(body.officials[1].chamber, "us_senate");
    assertEquals(body.officials[1].addresses[0].phone_1, "202-555-0200");
    assertEquals(body.officials[1].email_addresses.length, 0);

    assertEquals(body.officials[2].first_name, "Bob");
    assertEquals(body.officials[2].last_name, "Jones");
    assertEquals(body.officials[2].chamber, "us_senate");
    assertEquals(body.officials[2].addresses.length, 0);
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: LOCAL and LOCAL_EXEC officials are included in response", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock();
  const restoreFetch = mockCiceroFetch(
    mockJson(makeCiceroCandidate("IN", [
      makeOfficial({
        id: 10, first_name: "Mayor", last_name: "Bob",
        office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "LOCAL_EXEC", ocd_id: "ocd-division/country:us/state:in/place:indianapolis" } },
      }),
      makeOfficial({
        id: 11, first_name: "Rep", last_name: "Alice", party: "Republican",
        office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "STATE_LOWER", ocd_id: "ocd-division/country:us/state:in/sldl:92" } },
      }),
    ])),
  );

  try {
    const res = await handler(postRequest(TEST_ZIP, TEST_ADDRESS), supabase);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.officials.length, 2);
    assertEquals(body.officials[0].first_name, "Mayor");
    assertEquals(body.officials[0].last_name, "Bob");
    assertEquals(body.officials[0].chamber, "local_exec");
    assertEquals(body.officials[1].first_name, "Rep");
    assertEquals(body.officials[1].last_name, "Alice");
    assertEquals(body.officials[1].chamber, "house");
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: officials with unknown district_type are included with lowercased chamber", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock();
  const restoreFetch = mockCiceroFetch(
    mockJson(makeCiceroCandidate("IN", [
      makeOfficial({
        id: 10, first_name: "Board", last_name: "Member",
        office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "SCHOOL_BOARD", ocd_id: "ocd-division/country:us/state:in/school:1" } },
      }),
      makeOfficial({
        id: 11, first_name: "Rep", last_name: "Alice", party: "Republican",
        office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "STATE_LOWER", ocd_id: "ocd-division/country:us/state:in/sldl:92" } },
      }),
    ])),
  );

  try {
    const res = await handler(postRequest(TEST_ZIP, TEST_ADDRESS), supabase);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.officials.length, 2);
    assertEquals(body.officials[0].first_name, "Board");
    assertEquals(body.officials[0].chamber, "school_board");
    assertEquals(body.officials[1].first_name, "Rep");
    assertEquals(body.officials[1].chamber, "house");
  } finally {
    env.restore();
    restoreFetch();
  }
});

// ===========================================================================
// Handler — officials are persisted to cicero_officials after each lookup
// ===========================================================================

Deno.test("handler: upserts each official to cicero_officials", async () => {
  const env = makeEnvStub();
  const upserted: Array<{ table: string; data: Record<string, unknown> }> = [];

  const supabase = makeSupabaseMock({
    onUpsert: (table, data) => { upserted.push({ table, data }); },
  });
  const restoreFetch = mockCiceroFetch(mockJson(CICERO_IN));

  try {
    const res = await handler(postRequest(TEST_ZIP, TEST_ADDRESS), supabase);
    assertEquals(res.status, 200);
    const officialUpserts = upserted.filter((u) => u.table === "cicero_officials");
    assertEquals(officialUpserts.length, 3); // one per official in CICERO_IN
    assertEquals(officialUpserts[0].data.first_name, "Jane");
    assertEquals(officialUpserts[1].data.first_name, "John");
    assertEquals(officialUpserts[2].data.first_name, "Bob");
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: writes district_zip_cache and zip_cicero_officials after Cicero call", async () => {
  const env = makeEnvStub();
  const upserted: Array<{ table: string; data: Record<string, unknown> }> = [];

  const supabase = makeSupabaseMock({
    onUpsert: (table, data) => { upserted.push({ table, data }); },
  });
  const restoreFetch = mockCiceroFetch(mockJson(CICERO_IN));

  try {
    const res = await handler(postRequest(TEST_ZIP, TEST_ADDRESS), supabase);
    assertEquals(res.status, 200);

    // district_zip_cache written once with correct zip, district_id, and city
    const cacheWrites = upserted.filter((u) => u.table === "district_zip_cache");
    assertEquals(cacheWrites.length, 1);
    assertEquals(cacheWrites[0].data.zip_code, TEST_ZIP);
    assertEquals(cacheWrites[0].data.district_id, "ocd-division/country:us/state:in/sldl:92");
    assertEquals(cacheWrites[0].data.match_city, "Indianapolis");

    // zip_cicero_officials written once per official
    const linkWrites = upserted.filter((u) => u.table === "zip_cicero_officials");
    assertEquals(linkWrites.length, 3);
    assertEquals(linkWrites[0].data.zip_code, TEST_ZIP);
    assertEquals(linkWrites[0].data.cicero_id, 1); // OFFICIAL_STATE_REP
    assertEquals(linkWrites[1].data.cicero_id, 2); // OFFICIAL_US_SENATOR_1
    assertEquals(linkWrites[2].data.cicero_id, 3); // OFFICIAL_US_SENATOR_2
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: upsert failure does not affect 200 response", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({
    upsertError: { message: "write failed" },
  });
  const restoreFetch = mockCiceroFetch(mockJson(CICERO_IN));

  try {
    const res = await handler(postRequest(TEST_ZIP, TEST_ADDRESS), supabase);
    assertEquals(res.status, 200);
    assertEquals((await res.json()).district_id, "ocd-division/country:us/state:in/sldl:92");
  } finally {
    env.restore();
    restoreFetch();
  }
});

// ===========================================================================
// Handler — caching: fresh cache hit skips Cicero
// ===========================================================================

Deno.test("handler: fresh cache hit returns cached officials without calling Cicero", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({
    cacheRow: FRESH_CACHE_ROW,
    zipOfficials: ZIP_OFFICIALS_FRESH,
  });

  // If Cicero is accidentally called the test will throw
  const original = globalThis.fetch;
  globalThis.fetch = (() => {
    throw new Error("Cicero should not be called on cache hit");
  }) as typeof fetch;

  try {
    const res = await handler(postRequest(TEST_ZIP), supabase);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.city, "Indianapolis");
    assertEquals(body.zip_code, TEST_ZIP);
    assertEquals(body.district_id, FRESH_CACHE_ROW.district_id);
    assertEquals(body.officials.length, 1);
    assertEquals(body.officials[0].first_name, "Jane");
    assertEquals(body.officials[0].chamber, "house");
    assertEquals(body.officials[0].email_addresses[0], "jane@in.gov");
  } finally {
    env.restore();
    globalThis.fetch = original;
  }
});

// ===========================================================================
// Handler — caching: invalidation conditions fall through to Cicero
// ===========================================================================

Deno.test("handler: expired official busts cache and falls through to Cicero", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({
    cacheRow: FRESH_CACHE_ROW,
    zipOfficials: ZIP_OFFICIALS_EXPIRED, // term_end_date in the past
  });
  const restoreFetch = mockCiceroFetch(mockJson(CICERO_IN));

  try {
    const res = await handler(postRequest(TEST_ZIP), supabase);
    assertEquals(res.status, 200);
    // Should return fresh Cicero data (3 officials), not the 1 stale cached one
    assertEquals((await res.json()).officials.length, 3);
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: stale TTL busts cache and falls through to Cicero", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({
    cacheRow: STALE_CACHE_ROW,
    zipOfficials: ZIP_OFFICIALS_FRESH,
  });
  const restoreFetch = mockCiceroFetch(mockJson(CICERO_IN));

  try {
    const res = await handler(postRequest(TEST_ZIP), supabase);
    assertEquals(res.status, 200);
    assertEquals((await res.json()).officials.length, 3);
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: cache DB error is non-fatal and falls through to Cicero", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({
    cacheSelectError: { message: "DB connection error" },
  });
  const restoreFetch = mockCiceroFetch(mockJson(CICERO_IN));

  try {
    const res = await handler(postRequest(TEST_ZIP), supabase);
    assertEquals(res.status, 200);
    assertEquals((await res.json()).officials.length, 3);
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: empty zip_cicero_officials falls through to Cicero", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({
    cacheRow: FRESH_CACHE_ROW,
    zipOfficials: [], // no linked officials in DB
  });
  const restoreFetch = mockCiceroFetch(mockJson(CICERO_IN));

  try {
    const res = await handler(postRequest(TEST_ZIP), supabase);
    assertEquals(res.status, 200);
    assertEquals((await res.json()).officials.length, 3);
  } finally {
    env.restore();
    restoreFetch();
  }
});
