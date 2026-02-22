# Supabase Edge Functions

This directory contains the Deno Edge Functions that power HoosierCiv's AI and data aggregation features.

| Function | Trigger | Description |
|---|---|---|
| [`generate-bill-quiz`](./generate-bill-quiz/index.ts) | Database webhook (on bill insert) | Calls Claude to generate a 3-question multiple-choice quiz for a bill and stores it in `quizzes` |
| [`aggregate-news`](./aggregate-news/index.ts) | Scheduled job | Fetches Google News RSS for each active bill and upserts results into `news_articles` |

Both functions use `verify_jwt = false` and are invoked server-side with the service role key.

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

### 2. Set environment variables

Create a `.env.local` file in the project root (do not commit this):

```bash
ANTHROPIC_API_KEY=your_key_here
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are injected automatically by the local runtime.

### 3. Serve the functions

```bash
supabase functions serve --env-file .env.local
```

Functions are available at:
- `http://localhost:54321/functions/v1/generate-bill-quiz`
- `http://localhost:54321/functions/v1/aggregate-news`

### 4. Invoke locally

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

## Deployment

Functions are deployed via CI using `supabase functions deploy`. See the GitHub Actions workflow for details.

To deploy manually:

```bash
supabase functions deploy generate-bill-quiz --project-ref <your-project-ref>
supabase functions deploy aggregate-news --project-ref <your-project-ref>
```

Set `ANTHROPIC_API_KEY` as a secret in your Supabase project dashboard under **Settings > Edge Functions**.
