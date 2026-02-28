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

interface CacheRow {
  district_id: string;
  cached_at: string;
}

interface MockSupabaseOptions {
  /** Row returned by the district_zip_cache SELECT, or null for a miss. */
  cacheRow?: CacheRow | null;
  /** Error object returned by the cache SELECT (simulates a DB error). */
  cacheError?: { message: string; code?: string } | null;
  /** Error returned by the upsert, or null for success. */
  upsertError?: { message: string } | null;
  /** Spy called when upsert is invoked, receives the table name and upserted data. */
  onUpsert?: (table: string, data: Record<string, unknown>) => void;
  /**
   * Rows returned by the zip_cicero_officials join query on a cache hit.
   * Each element should be shaped { cicero_officials: { district_type, district_ocd_id,
   * first_name, last_name, addresses, email_addresses, party } }.
   */
  cachedOfficialRows?: Record<string, unknown>[];
}

/**
 * Builds a mock of the Supabase client that covers:
 *   district_zip_cache  → .select().eq().maybeSingle()  (cache read)
 *   zip_cicero_officials → .select().eq()               (join read on cache hit)
 *   any table           → .upsert(data)                  (cache / officials write)
 */
function makeSupabaseMock(opts: MockSupabaseOptions = {}) {
  const {
    cacheRow = null,
    cacheError = null,
    upsertError = null,
    onUpsert,
    cachedOfficialRows = [],
  } = opts;

  return () => ({
    from: (table: string) => ({
      select: (_cols: string) => ({
        eq: (_col: string, _val: string) => {
          // zip_cicero_officials join — awaitable list query
          if (table === "zip_cicero_officials") {
            return Promise.resolve({ data: cachedOfficialRows, error: null });
          }
          // district_zip_cache — .maybeSingle() needed
          return {
            maybeSingle: () => Promise.resolve({ data: cacheRow, error: cacheError }),
          };
        },
      }),
      upsert: (data: Record<string, unknown>) => {
        onUpsert?.(table, data);
        return Promise.resolve({ error: upsertError });
      },
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

function postRequest(zip_code: string): Request {
  return new Request("http://localhost/", {
    method: "POST",
    body: JSON.stringify({ zip_code }),
    headers: { "Content-Type": "application/json" },
  });
}

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

Deno.test("districtTypeToChamber: unknown types return null", () => {
  assertEquals(districtTypeToChamber("COUNTY"), null);
  assertEquals(districtTypeToChamber("state_lower"), null); // case sensitive
  assertEquals(districtTypeToChamber(""), null);
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

Deno.test("handler: missing zip_code → 400", async () => {
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
    assertEquals((await res.json()).error, "zip_code must be a 5-digit string");
  } finally {
    env.restore();
  }
});

Deno.test("handler: 4-digit zip → 400", async () => {
  const env = makeEnvStub();
  try {
    const res = await handler(postRequest("4620"));
    assertEquals(res.status, 400);
  } finally {
    env.restore();
  }
});

Deno.test("handler: 6-digit zip → 400", async () => {
  const env = makeEnvStub();
  try {
    const res = await handler(postRequest("462011"));
    assertEquals(res.status, 400);
  } finally {
    env.restore();
  }
});

Deno.test("handler: alpha zip → 400", async () => {
  const env = makeEnvStub();
  try {
    const res = await handler(postRequest("ABCDE"));
    assertEquals(res.status, 400);
  } finally {
    env.restore();
  }
});

// ===========================================================================
// Handler — cache hit (fresh) — Cicero API must NOT be called
// ===========================================================================

Deno.test("handler: fresh cache hit returns cached data without calling Cicero API", async () => {
  const env = makeEnvStub();
  let ciceroCalled = false;
  const restoreFetch = mockCiceroFetch((() => {
    ciceroCalled = true;
    return mockJson({});
  }) as unknown as Response);

  const supabase = makeSupabaseMock({
    cacheRow: {
      district_id: "ocd-division/country:us/state:in/sldl:92",
      cached_at: new Date(Date.now() - 1000 * 60 * 60).toISOString(), // 1 hour ago
    },
    cachedOfficialRows: [
      {
        cicero_officials: {
          first_name: "Jane", last_name: "Smith", party: "Democratic",
          district_type: "STATE_LOWER",
          district_ocd_id: "ocd-division/country:us/state:in/sldl:92",
          addresses: [{ phone_1: "317-555-0100" }],
          email_addresses: ["jane@in.gov"],
        },
      },
    ],
  });

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.district_id, "ocd-division/country:us/state:in/sldl:92");
    assertEquals(body.officials.length, 1);
    assertEquals(body.officials[0].first_name, "Jane");
    assertEquals(body.officials[0].last_name, "Smith");
    assertEquals(ciceroCalled, false);
  } finally {
    env.restore();
    restoreFetch();
  }
});

// ===========================================================================
// Handler — stale cache → falls through to Cicero API and upserts
// ===========================================================================

Deno.test("handler: stale cache (91 days) calls Cicero API and upserts new data", async () => {
  const env = makeEnvStub();
  const upserted: Array<{ table: string; data: Record<string, unknown> }> = [];

  const supabase = makeSupabaseMock({
    cacheRow: {
      district_id: "old-district",
      cached_at: new Date(Date.now() - 1000 * 60 * 60 * 24 * 91).toISOString(),
    },
    onUpsert: (table, data) => { upserted.push({ table, data }); },
  });

  const restoreFetch = mockCiceroFetch(mockJson(CICERO_IN));

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    assertEquals((await res.json()).district_id, "ocd-division/country:us/state:in/sldl:92");
    // Should have upserted: 1 district_zip_cache + 3 cicero_officials + 3 zip_cicero_officials
    const districtUpserts = upserted.filter((u) => u.table === "district_zip_cache");
    assertEquals(districtUpserts.length, 1);
    assertEquals(districtUpserts[0].data.zip_code, "46201");
  } finally {
    env.restore();
    restoreFetch();
  }
});

// ===========================================================================
// Handler — cache DB error → 500
// ===========================================================================

Deno.test("handler: cache lookup DB error → 500", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheError: { message: "DB error", code: "PGRST301" } });

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 500);
    assertEquals((await res.json()).error, "Failed to look up cached district data");
  } finally {
    env.restore();
  }
});

// ===========================================================================
// Handler — missing Cicero API key → 500
// ===========================================================================

Deno.test("handler: missing CICERO_API_KEY → 500", async () => {
  const env = makeEnvStub({ CICERO_API_KEY: "" });
  const supabase = makeSupabaseMock({ cacheRow: null });

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 500);
    assertEquals((await res.json()).error, "Cicero API key not configured");
  } finally {
    env.restore();
  }
});

// ===========================================================================
// Handler — Cicero API error paths
// ===========================================================================

Deno.test("handler: Cicero API 404 → 404 with human-readable message", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCiceroFetch(mockJson({ error: { code: 404 } }, 404));

  try {
    const res = await handler(postRequest("00000"), supabase);
    assertEquals(res.status, 404);
    assertEquals(
      (await res.json()).error,
      "ZIP code not found — check that it is a valid US ZIP code",
    );
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: Cicero API 500 → 502", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCiceroFetch(new Response("Server Error", { status: 500 }));

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 502);
    assertEquals((await res.json()).error, "Failed to fetch district data");
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: Cicero API network failure → 502", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });

  const original = globalThis.fetch;
  globalThis.fetch = (() => Promise.reject(new Error("Network failure"))) as typeof fetch;

  try {
    const res = await handler(postRequest("46201"), supabase);
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

Deno.test("handler: non-Indiana ZIP (IL match_region) → 422", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
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
    assertEquals((await res.json()).error, "ZIP code is not in Indiana");
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: no candidate in Cicero response → 422", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCiceroFetch(
    mockJson({ response: { results: { candidates: [] } } }),
  );

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 422);
    assertEquals((await res.json()).error, "ZIP code is not in Indiana");
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
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCiceroFetch(
    mockJson(makeCiceroCandidate("IN", [
      makeOfficial({ id: 1, office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "STATE_LOWER", ocd_id: "ocd-division/country:us/state:in/sldl:92" } } }),
      makeOfficial({ id: 2, office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "STATE_UPPER", ocd_id: "ocd-division/country:us/state:in/sldu:30" } } }),
      makeOfficial({ id: 3, office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "NATIONAL_LOWER", ocd_id: "ocd-division/country:us/state:in/cd:7" } } }),
      makeOfficial({ id: 4, office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "NATIONAL_UPPER", ocd_id: "ocd-division/country:us/state:in" } } }),
    ])),
  );

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    assertEquals((await res.json()).district_id, "ocd-division/country:us/state:in/sldl:92");
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: falls back to STATE_UPPER when STATE_LOWER is absent", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCiceroFetch(
    mockJson(makeCiceroCandidate("IN", [
      makeOfficial({ id: 2, office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "STATE_UPPER", ocd_id: "ocd-division/country:us/state:in/sldu:30" } } }),
      makeOfficial({ id: 3, office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "NATIONAL_LOWER", ocd_id: "ocd-division/country:us/state:in/cd:7" } } }),
    ])),
  );

  try {
    const res = await handler(postRequest("46201"), supabase);
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
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCiceroFetch(mockJson(CICERO_IN));

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    const body = await res.json();

    assertEquals(body.district_id, "ocd-division/country:us/state:in/sldl:92");
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
  const supabase = makeSupabaseMock({ cacheRow: null });
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
    const res = await handler(postRequest("46201"), supabase);
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

Deno.test("handler: officials with truly unknown district_type are excluded from response", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCiceroFetch(
    mockJson(makeCiceroCandidate("IN", [
      makeOfficial({
        id: 10, first_name: "Unknown", last_name: "Type",
        office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "SCHOOL_BOARD", ocd_id: "ocd-division/country:us/state:in/school:1" } },
      }),
      makeOfficial({
        id: 11, first_name: "Rep", last_name: "Alice", party: "Republican",
        office: { ...makeOfficial({}).office, district: { ...makeOfficial({}).office.district, district_type: "STATE_LOWER", ocd_id: "ocd-division/country:us/state:in/sldl:92" } },
      }),
    ])),
  );

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.officials.length, 1);
    assertEquals(body.officials[0].first_name, "Rep");
    assertEquals(body.officials[0].last_name, "Alice");
  } finally {
    env.restore();
    restoreFetch();
  }
});

// ===========================================================================
// Handler — upsert failure is non-fatal
// ===========================================================================

Deno.test("handler: upsert failure does not affect 200 response", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({
    cacheRow: null,
    upsertError: { message: "write failed" },
  });
  const restoreFetch = mockCiceroFetch(mockJson(CICERO_IN));

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    assertEquals((await res.json()).district_id, "ocd-division/country:us/state:in/sldl:92");
  } finally {
    env.restore();
    restoreFetch();
  }
});

// ===========================================================================
// Handler — TTL edge cases
// ===========================================================================

Deno.test("handler: custom DISTRICT_CACHE_TTL_DAYS=30 treats 31-day-old cache as stale", async () => {
  const env = makeEnvStub({ DISTRICT_CACHE_TTL_DAYS: "30" });
  let ciceroCalled = false;

  const supabase = makeSupabaseMock({
    cacheRow: {
      district_id: "old-district",
      cached_at: new Date(Date.now() - 1000 * 60 * 60 * 24 * 31).toISOString(),
    },
  });

  const original = globalThis.fetch;
  globalThis.fetch = ((() => {
    ciceroCalled = true;
    return Promise.resolve(mockJson(CICERO_IN));
  }) as unknown) as typeof fetch;

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    assertEquals(ciceroCalled, true);
  } finally {
    env.restore();
    globalThis.fetch = original;
  }
});

Deno.test("handler: invalid DISTRICT_CACHE_TTL_DAYS defaults to 90 — 89-day cache is still fresh", async () => {
  const env = makeEnvStub({ DISTRICT_CACHE_TTL_DAYS: "not-a-number" });
  let ciceroCalled = false;

  const supabase = makeSupabaseMock({
    cacheRow: {
      district_id: "ocd-division/country:us/state:in/sldl:92",
      cached_at: new Date(Date.now() - 1000 * 60 * 60 * 24 * 89).toISOString(),
    },
    cachedOfficialRows: [],
  });

  const original = globalThis.fetch;
  globalThis.fetch = ((() => {
    ciceroCalled = true;
    return Promise.resolve(mockJson({}));
  }) as unknown) as typeof fetch;

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    assertEquals(ciceroCalled, false); // served from cache, Cicero API not hit
  } finally {
    env.restore();
    globalThis.fetch = original;
  }
});
