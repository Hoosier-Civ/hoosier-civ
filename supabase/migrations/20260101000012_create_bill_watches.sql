-- Migration: create_bill_watches
-- Users subscribe to bills to receive push notification alerts on updates.

create table public.bill_watches (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  bill_id    text not null references public.bills(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, bill_id)
);

create index on public.bill_watches(user_id);
create index on public.bill_watches(bill_id);

-- RLS
alter table public.bill_watches enable row level security;

create policy "Users can view own bill watches"
  on public.bill_watches for select
  using (auth.uid() = user_id);

create policy "Users can insert own bill watches"
  on public.bill_watches for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own bill watches"
  on public.bill_watches for delete
  using (auth.uid() = user_id);
