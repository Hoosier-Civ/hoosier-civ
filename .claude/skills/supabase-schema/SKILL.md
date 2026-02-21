---
name: supabase-schema
description: Generate a Supabase PostgreSQL table schema, RLS policies, and matching Dart model for a HoosierCiv data entity. Use when adding a new table to the database.
argument-hint: "[entity-name]"
disable-model-invocation: true
---

# Generate Supabase Schema

Generate a Supabase PostgreSQL table schema, RLS policies, and matching Dart model for a HoosierCiv data entity.

## Instructions

The user will name a data entity (e.g. "bill_watch", "town_hall_event", "user_badge").

1. Read `HoosierCiv_Flutter_MVP_Architecture.txt` for existing model names to avoid conflicts.
2. Generate the following:

### SQL Migration
```sql
-- Migration: create_<table_name>
create table public.<table_name> (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  -- entity-specific columns
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Indexes
create index on public.<table_name>(user_id);

-- RLS
alter table public.<table_name> enable row level security;

-- Policies
create policy "Users can read own rows"
  on public.<table_name> for select
  using (auth.uid() = user_id);

create policy "Users can insert own rows"
  on public.<table_name> for insert
  with check (auth.uid() = user_id);

create policy "Users can update own rows"
  on public.<table_name> for update
  using (auth.uid() = user_id);
```

### Dart Model
Generate `lib/data/models/<entity>_model.dart` with:
- Named constructor
- `fromJson(Map<String, dynamic> json)` factory
- `toJson()` method
- All fields matching the SQL schema

### Repository Stub
Generate `lib/data/repositories/<entity>_repository.dart` with:
- `fetchAll()` — select with user_id filter
- `insert(Model m)` — insert row
- `delete(String id)` — delete by id
- Supabase client injected via constructor

## Notes
- Use `uuid` type for all IDs
- Always include `created_at` / `updated_at`
- RLS must always filter by `auth.uid() = user_id` for user-owned data
- Public/shared data (bills, representatives) should have read-only public policies

$ARGUMENTS
