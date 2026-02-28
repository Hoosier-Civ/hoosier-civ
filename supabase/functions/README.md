# Supabase Edge Functions

This directory contains the Deno Edge Functions that power HoosierCiv's AI and data aggregation features.

| Function | Trigger | Description |
|---|---|---|
| [`lookup-district`](./lookup-district/index.ts) | HTTP POST | Accepts an Indiana ZIP code, returns the user's district ID and all elected/appointed officials via the Cicero API. Results are cached in `district_zip_cache`, `cicero_officials`, and `zip_cicero_officials`. |
| [`generate-bill-quiz`](./generate-bill-quiz/index.ts) | Database webhook (on bill insert) | Calls Claude to generate a 3-question multiple-choice quiz for a bill and stores it in `quizzes`. |
| [`aggregate-news`](./aggregate-news/index.ts) | Scheduled job | Fetches Google News RSS for each active bill and upserts results into `news_articles`. |

All functions use `verify_jwt = false` and are invoked server-side with the service role key.

---

## Quickstart (local development)

### Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) (`brew install supabase/tap/supabase`)
- Docker Desktop (must be running)

### 1. Start the local Supabase stack

```bash
supabase start
```

This brings up Postgres, Auth, Storage, Studio (at `localhost:54323`), and the Edge Functions runtime.

### 2. Apply migrations

```bash
supabase migration up
```

### 3. Set environment variables

Create a `.env.local` file in the project root (do not commit this):

```bash
ANTHROPIC_API_KEY=your_key_here
CICERO_API_KEY=your_key_here
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically by the local runtime.

### 4. Serve the functions

```bash
supabase functions serve --env-file .env.local
```

Functions are available at `http://localhost:54321/functions/v1/<function-name>`.

### 5. Invoke locally

**`lookup-district`** — look up officials for an Indiana ZIP code:

```bash
curl -X POST http://localhost:54321/functions/v1/lookup-district \
  -H "Content-Type: application/json" \
  -d '{"zip_code": "46201"}'
```

Response shape:
```json
{
  "district_id": "ocd-division/country:us/state:in/sldl:92",
  "officials": [
    {
      "cicero_id": 12345,
      "first_name": "Jane",
      "last_name": "Smith",
      "chamber": "house",
      "office_title": "Representative",
      "party": "Democratic",
      "district_type": "STATE_LOWER",
      "district_ocd_id": "ocd-division/country:us/state:in/sldl:92",
      "district_state": "IN",
      "district_label": "IN House District 92",
      "chamber_name": "House",
      "chamber_name_formal": "Indiana House of Representatives",
      "photo_url": "https://...",
      "website_url": "https://...",
      "web_form_url": "https://...",
      "addresses": [{ "address_1": "...", "city": "Indianapolis", "state": "IN", "phone_1": "..." }],
      "email_addresses": ["rep@in.gov"],
      "identifiers": [{ "identifier_type": "TWITTER", "identifier_value": "RepJaneSmith" }],
      "committees": [{ "name": "Ways and Means", "urls": ["..."], "position": "" }],
      "term_start_date": "2025-01-08",
      "term_end_date": "2027-01-13",
      "bio": "...",
      "birth_date": "1980-03-15"
    }
  ]
}
```

The `chamber` field maps Cicero district types to readable values:

| `district_type` | `chamber` |
|---|---|
| `NATIONAL_UPPER` | `us_senate` |
| `NATIONAL_LOWER` | `us_house` |
| `NATIONAL_EXEC` | `national_exec` |
| `STATE_UPPER` | `senate` |
| `STATE_LOWER` | `house` |
| `STATE_EXEC` | `state_exec` |
| `LOCAL` | `local` |
| `LOCAL_EXEC` | `local_exec` |

Results are cached for 90 days (configurable via `DISTRICT_CACHE_TTL_DAYS`). On a cache hit, officials are served from the `cicero_officials` table. On a cache miss, all officials are fetched from Cicero and upserted into the normalized cache tables.

**`aggregate-news`** — fetches news for all active bills (no body required):

```bash
curl -X POST http://localhost:54321/functions/v1/aggregate-news
```

**`generate-bill-quiz`** — pass a mock database webhook payload:

```bash
curl -X POST http://localhost:54321/functions/v1/generate-bill-quiz \
  -H "Content-Type: application/json" \
  -d '{"record": {"id": "some-bill-id", "title": "HB 1234", "summary": "A bill about..."}}'
```

---

## Database tables (civic data cache)

| Table | Description |
|---|---|
| `district_zip_cache` | One row per ZIP code: maps ZIP → `district_id`, geocoding metadata, and `cached_at` TTL timestamp. |
| `cicero_officials` | One row per Cicero official ID. Stores all fields returned by the Cicero API including addresses, social media identifiers, committees, bio, and term dates. Shared across ZIP codes — a US Senator is stored once. |
| `zip_cicero_officials` | Join table linking each ZIP code to the officials that represent it. |

---

## Running tests

```bash
cd supabase/functions
deno test --allow-env lookup-district/index.test.ts
```

---

## Deployment

Functions are deployed via CI using `supabase functions deploy`. See the GitHub Actions workflow for details.

To deploy manually:

```bash
supabase functions deploy lookup-district --project-ref <your-project-ref>
supabase functions deploy generate-bill-quiz --project-ref <your-project-ref>
supabase functions deploy aggregate-news --project-ref <your-project-ref>
```

Set secrets in your Supabase project dashboard under **Settings > Edge Functions**:

| Secret | Used by |
|---|---|
| `ANTHROPIC_API_KEY` | `generate-bill-quiz` |
| `CICERO_API_KEY` | `lookup-district` |
| `DISTRICT_CACHE_TTL_DAYS` | `lookup-district` (optional, defaults to `90`) |
