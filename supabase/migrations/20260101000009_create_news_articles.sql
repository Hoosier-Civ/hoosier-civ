-- Migration: create_news_articles
-- Aggregated by the aggregate-news Edge Function. Unique on URL to deduplicate.

create table public.news_articles (
  id           uuid primary key default gen_random_uuid(),
  bill_id      text not null references public.bills(id) on delete cascade,
  headline     text not null,
  summary      text,
  url          text not null unique,
  published_at timestamptz,
  source       text not null,
  created_at   timestamptz not null default now()
);

create index on public.news_articles(bill_id);
create index on public.news_articles(bill_id, published_at desc);

-- RLS
alter table public.news_articles enable row level security;

create policy "News articles are publicly readable"
  on public.news_articles for select
  using (true);
