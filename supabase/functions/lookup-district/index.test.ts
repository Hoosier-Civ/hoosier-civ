/**
 * Unit tests for the lookup-district edge function.
 *
 * Run from the supabase/functions directory:
 *   deno test --allow-env lookup-district/index.test.ts
 *
 * The Supabase client is fully mocked via dependency injection so no real
 * HTTP traffic is made and no interval timers are started.
 * The Google Civic API is mocked via globalThis.fetch replacement.
 */

import { assertEquals } from "jsr:@std/assert";
import { stub } from "jsr:@std/testing/mock";
import { determineChamber, handler } from "./_handler.ts";

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface CacheRow {
  district_id: string;
  representatives: unknown[];
  cached_at: string;
}

interface MockSupabaseOptions {
  /** Row returned by the cache SELECT, or null for a miss. */
  cacheRow?: CacheRow | null;
  /** Error object returned by the cache SELECT (simulates a DB error). */
  cacheError?: { message: string; code?: string } | null;
  /** Error returned by the upsert, or null for success. */
  upsertError?: { message: string } | null;
  /** Spy called when upsert is invoked, receives the upserted data. */
  onUpsert?: (data: Record<string, unknown>) => void;
}

/**
 * Builds a minimal mock of the Supabase client covering only the operations
 * that the handler uses:
 *   supabase.from(t).select(c).eq(k,v).maybeSingle()  → cache read
 *   supabase.from(t).upsert(data)                      → cache write
 */
function makeSupabaseMock(opts: MockSupabaseOptions = {}) {
  const { cacheRow = null, cacheError = null, upsertError = null, onUpsert } = opts;

  return () => ({
    from: (_table: string) => ({
      // Cache read chain: .select().eq().maybeSingle()
      select: (_cols: string) => ({
        eq: (_col: string, _val: string) => ({
          maybeSingle: () =>
            Promise.resolve({ data: cacheRow, error: cacheError }),
        }),
      }),
      // Cache write: .upsert(data)
      upsert: (data: Record<string, unknown>) => {
        onUpsert?.(data);
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
    GOOGLE_CIVIC_API_KEY: "test-civic-key",
    DISTRICT_CACHE_TTL_DAYS: "90",
  };
  const env = { ...defaults, ...overrides };
  return stub(Deno.env, "get", (key: string) => env[key]);
}

// ---------------------------------------------------------------------------
// Civic API fetch mock helper
// ---------------------------------------------------------------------------

function mockCivicFetch(response: Response | (() => never)): () => void {
  const original = globalThis.fetch;
  globalThis.fetch = ((_url: string | URL | Request) => {
    if (typeof response === "function") response();
    return Promise.resolve(response as Response);
  }) as typeof fetch;
  return () => {
    globalThis.fetch = original;
  };
}

function civicJson(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

// ---------------------------------------------------------------------------
// Shared test fixture: a valid Indiana civic API response
// ---------------------------------------------------------------------------

const CIVIC_IN = {
  normalizedInput: { city: "Indianapolis", state: "IN", zip: "46201" },
  divisions: {
    "ocd-division/country:us/state:in/sldl:92": { name: "Indiana 92nd House" },
    "ocd-division/country:us/state:in": { name: "Indiana" },
  },
  offices: [
    {
      name: "State Representative",
      divisionId: "ocd-division/country:us/state:in/sldl:92",
      officialIndices: [0],
    },
    {
      name: "U.S. Senator",
      divisionId: "ocd-division/country:us/state:in",
      officialIndices: [1, 2],
    },
  ],
  officials: [
    { name: "Jane Smith", party: "Democratic", phones: ["317-555-0100"], emails: ["jane@in.gov"] },
    { name: "John Doe", party: "Republican", phones: ["202-555-0200"] },
    { name: "Bob Jones", party: "Republican" },
  ],
};

function postRequest(zip_code: string): Request {
  return new Request("http://localhost/", {
    method: "POST",
    body: JSON.stringify({ zip_code }),
    headers: { "Content-Type": "application/json" },
  });
}

// ===========================================================================
// determineChamber — pure unit tests (no mocking needed)
// ===========================================================================

Deno.test("determineChamber: us_house — all label variants", () => {
  assertEquals(determineChamber("U.S. Representative"), "us_house");
  assertEquals(determineChamber("US Representative, District 5"), "us_house");
  assertEquals(determineChamber("United States Representative"), "us_house");
  assertEquals(determineChamber("U.S. House"), "us_house");
  assertEquals(determineChamber("US House of Representatives"), "us_house");
  assertEquals(determineChamber("United States House"), "us_house");
});

Deno.test("determineChamber: us_senate — all label variants", () => {
  assertEquals(determineChamber("U.S. Senator"), "us_senate");
  assertEquals(determineChamber("US Senator"), "us_senate");
  assertEquals(determineChamber("United States Senator"), "us_senate");
  assertEquals(determineChamber("U.S. Senate"), "us_senate");
  assertEquals(determineChamber("US Senate"), "us_senate");
  assertEquals(determineChamber("United States Senate"), "us_senate");
});

Deno.test("determineChamber: state house — all label variants", () => {
  assertEquals(determineChamber("State Representative"), "house");
  assertEquals(determineChamber("Indiana State Representative"), "house");
  assertEquals(determineChamber("State House Member"), "house");
});

Deno.test("determineChamber: state senate — all label variants", () => {
  assertEquals(determineChamber("State Senator"), "senate");
  assertEquals(determineChamber("Indiana State Senator"), "senate");
  assertEquals(determineChamber("State Senate"), "senate");
});

Deno.test("determineChamber: case insensitive", () => {
  assertEquals(determineChamber("u.s. representative"), "us_house");
  assertEquals(determineChamber("STATE REPRESENTATIVE"), "house");
  assertEquals(determineChamber("U.S. SENATOR"), "us_senate");
  assertEquals(determineChamber("state senate"), "senate");
});

Deno.test("determineChamber: unknown offices return null", () => {
  assertEquals(determineChamber("Mayor"), null);
  assertEquals(determineChamber("Governor"), null);
  assertEquals(determineChamber("City Council Member"), null);
  assertEquals(determineChamber(""), null);
  assertEquals(determineChamber("School Board"), null);
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
// Handler — cache hit (fresh) — Civic API must NOT be called
// ===========================================================================

Deno.test("handler: fresh cache hit returns cached data without calling Civic API", async () => {
  const env = makeEnvStub();
  let civicCalled = false;
  const restoreFetch = mockCivicFetch((() => {
    civicCalled = true;
    return civicJson({});
  }) as unknown as Response);

  const supabase = makeSupabaseMock({
    cacheRow: {
      district_id: "ocd-division/country:us/state:in/sldl:92",
      representatives: [{ name: "Jane Smith", chamber: "house", district: "..." }],
      cached_at: new Date(Date.now() - 1000 * 60 * 60).toISOString(), // 1 hour ago
    },
  });

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    const body = await res.json();
    assertEquals(body.district_id, "ocd-division/country:us/state:in/sldl:92");
    assertEquals(civicCalled, false);
  } finally {
    env.restore();
    restoreFetch();
  }
});

// ===========================================================================
// Handler — stale cache → falls through to Civic API and upserts
// ===========================================================================

Deno.test("handler: stale cache (91 days) calls Civic API and upserts new data", async () => {
  const env = makeEnvStub();
  let upsertData: Record<string, unknown> | null = null;

  const supabase = makeSupabaseMock({
    cacheRow: {
      district_id: "old-district",
      representatives: [],
      cached_at: new Date(Date.now() - 1000 * 60 * 60 * 24 * 91).toISOString(),
    },
    onUpsert: (data) => { upsertData = data; },
  });

  const restoreFetch = mockCivicFetch(civicJson(CIVIC_IN));

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    assertEquals((await res.json()).district_id, "ocd-division/country:us/state:in/sldl:92");
    assertEquals(upsertData !== null, true);
    assertEquals((upsertData as unknown as Record<string, unknown>).zip_code, "46201");
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
// Handler — missing Civic API key → 500
// ===========================================================================

Deno.test("handler: missing GOOGLE_CIVIC_API_KEY → 500", async () => {
  const env = makeEnvStub({ GOOGLE_CIVIC_API_KEY: "" });
  const supabase = makeSupabaseMock({ cacheRow: null });

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 500);
    assertEquals((await res.json()).error, "Google Civic API key not configured");
  } finally {
    env.restore();
  }
});

// ===========================================================================
// Handler — Civic API error paths
// ===========================================================================

Deno.test("handler: Civic API 404 → 404 with human-readable message", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCivicFetch(civicJson({ error: { code: 404 } }, 404));

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

Deno.test("handler: Civic API 500 → 502", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCivicFetch(new Response("Server Error", { status: 500 }));

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 502);
    assertEquals((await res.json()).error, "Failed to fetch district data");
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: Civic API network failure → 502", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });

  const original = globalThis.fetch;
  globalThis.fetch = (() => Promise.reject(new Error("Network failure"))) as typeof fetch;

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 502);
    assertEquals((await res.json()).error, "Failed to reach Google Civic API");
  } finally {
    env.restore();
    globalThis.fetch = original;
  }
});

// ===========================================================================
// Handler — Indiana validation
// ===========================================================================

Deno.test("handler: non-Indiana ZIP (IL) → 422", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCivicFetch(
    civicJson({
      normalizedInput: { city: "Chicago", state: "IL", zip: "60601" },
      divisions: {},
      offices: [],
      officials: [],
    }),
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

// ===========================================================================
// Handler — district ID extraction priority
// ===========================================================================

Deno.test("handler: prefers sldl > sldu > cd > state:in when all divisions present", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCivicFetch(
    civicJson({
      normalizedInput: { state: "IN", zip: "46201" },
      divisions: {
        "ocd-division/country:us/state:in/sldl:92": {},
        "ocd-division/country:us/state:in/sldu:30": {},
        "ocd-division/country:us/state:in/cd:7": {},
        "ocd-division/country:us/state:in": {},
      },
      offices: [],
      officials: [],
    }),
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

Deno.test("handler: falls back to sldu when sldl is absent", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCivicFetch(
    civicJson({
      normalizedInput: { state: "IN", zip: "46201" },
      divisions: {
        "ocd-division/country:us/state:in/sldu:30": {},
        "ocd-division/country:us/state:in/cd:7": {},
      },
      offices: [],
      officials: [],
    }),
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

Deno.test("handler: no Indiana divisions → 422", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCivicFetch(
    civicJson({
      normalizedInput: { state: "IN", zip: "46201" },
      divisions: {},
      offices: [],
      officials: [],
    }),
  );

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 422);
    assertEquals((await res.json()).error, "Could not determine district for this ZIP code");
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
  const restoreFetch = mockCivicFetch(civicJson(CIVIC_IN));

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    const body = await res.json();

    assertEquals(body.district_id, "ocd-division/country:us/state:in/sldl:92");
    assertEquals(body.representatives.length, 3);

    // State representative
    assertEquals(body.representatives[0].name, "Jane Smith");
    assertEquals(body.representatives[0].chamber, "house");
    assertEquals(body.representatives[0].district, "ocd-division/country:us/state:in/sldl:92");
    assertEquals(body.representatives[0].phone, "317-555-0100");
    assertEquals(body.representatives[0].email, "jane@in.gov");
    assertEquals(body.representatives[0].party, "Democratic");

    // Two US senators
    assertEquals(body.representatives[1].name, "John Doe");
    assertEquals(body.representatives[1].chamber, "us_senate");
    assertEquals(body.representatives[1].phone, "202-555-0200");
    assertEquals(body.representatives[1].email, undefined);

    assertEquals(body.representatives[2].name, "Bob Jones");
    assertEquals(body.representatives[2].chamber, "us_senate");
    assertEquals(body.representatives[2].phone, undefined);
  } finally {
    env.restore();
    restoreFetch();
  }
});

Deno.test("handler: offices with unknown chamber are excluded from response", async () => {
  const env = makeEnvStub();
  const supabase = makeSupabaseMock({ cacheRow: null });
  const restoreFetch = mockCivicFetch(
    civicJson({
      normalizedInput: { state: "IN", zip: "46201" },
      divisions: { "ocd-division/country:us/state:in/sldl:92": {} },
      offices: [
        {
          name: "Mayor",
          divisionId: "ocd-division/country:us/state:in/sldl:92",
          officialIndices: [0],
        },
        {
          name: "State Representative",
          divisionId: "ocd-division/country:us/state:in/sldl:92",
          officialIndices: [1],
        },
      ],
      officials: [
        { name: "Mayor Bob" },
        { name: "Rep Alice", party: "Republican" },
      ],
    }),
  );

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    const body = await res.json();
    // Mayor is filtered out — only the State Representative remains
    assertEquals(body.representatives.length, 1);
    assertEquals(body.representatives[0].name, "Rep Alice");
    assertEquals(body.representatives[0].chamber, "house");
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
  const restoreFetch = mockCivicFetch(civicJson(CIVIC_IN));

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
  let civicCalled = false;

  const supabase = makeSupabaseMock({
    cacheRow: {
      district_id: "old-district",
      representatives: [],
      cached_at: new Date(Date.now() - 1000 * 60 * 60 * 24 * 31).toISOString(),
    },
  });

  const original = globalThis.fetch;
  globalThis.fetch = ((() => {
    civicCalled = true;
    return Promise.resolve(civicJson(CIVIC_IN));
  }) as unknown) as typeof fetch;

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    assertEquals(civicCalled, true);
  } finally {
    env.restore();
    globalThis.fetch = original;
  }
});

Deno.test("handler: invalid DISTRICT_CACHE_TTL_DAYS defaults to 90 — 89-day cache is still fresh", async () => {
  const env = makeEnvStub({ DISTRICT_CACHE_TTL_DAYS: "not-a-number" });
  let civicCalled = false;

  const supabase = makeSupabaseMock({
    cacheRow: {
      district_id: "ocd-division/country:us/state:in/sldl:92",
      representatives: [],
      cached_at: new Date(Date.now() - 1000 * 60 * 60 * 24 * 89).toISOString(),
    },
  });

  const original = globalThis.fetch;
  globalThis.fetch = ((() => {
    civicCalled = true;
    return Promise.resolve(civicJson({}));
  }) as unknown) as typeof fetch;

  try {
    const res = await handler(postRequest("46201"), supabase);
    assertEquals(res.status, 200);
    assertEquals(civicCalled, false); // served from cache, Civic API not hit
  } finally {
    env.restore();
    globalThis.fetch = original;
  }
});
