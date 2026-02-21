import { createClient } from "npm:@supabase/supabase-js";
import { DOMParser } from "npm:@xmldom/xmldom";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

interface Article {
  bill_id: string;
  headline: string;
  url: string;
  published_at: string | null;
  source: string;
}

async function fetchRssForBill(billId: string, billTitle: string): Promise<Article[]> {
  const query = encodeURIComponent(`Indiana ${billTitle}`);
  const url = `https://news.google.com/rss/search?q=${query}&hl=en-US&gl=US&ceid=US:en`;

  const res = await fetch(url, { signal: AbortSignal.timeout(10_000) });
  if (!res.ok) return [];

  const xml = await res.text();
  const parser = new DOMParser();
  const doc = parser.parseFromString(xml, "text/xml");
  const items = doc.getElementsByTagName("item");

  const articles: Article[] = [];
  for (let i = 0; i < Math.min(items.length, 10); i++) {
    const item = items[i];
    const headline = item.getElementsByTagName("title")[0]?.textContent ?? "";
    const link = item.getElementsByTagName("link")[0]?.textContent ?? "";
    const pubDate = item.getElementsByTagName("pubDate")[0]?.textContent ?? null;
    const source = item.getElementsByTagName("source")[0]?.textContent ?? "Unknown";

    if (link && headline) {
      articles.push({
        bill_id: billId,
        headline,
        url: link,
        published_at: pubDate ? new Date(pubDate).toISOString() : null,
        source,
      });
    }
  }
  return articles;
}

Deno.serve(async () => {
  // Only aggregate news for bills with active status
  const { data: bills, error: billsError } = await supabase
    .from("bills")
    .select("id, title")
    .neq("status", "signed")
    .neq("status", "vetoed");

  if (billsError) {
    return new Response(JSON.stringify({ error: billsError.message }), { status: 500 });
  }

  let totalInserted = 0;

  for (const bill of bills ?? []) {
    const articles = await fetchRssForBill(bill.id, bill.title);

    if (articles.length > 0) {
      const { error, count } = await supabase
        .from("news_articles")
        .upsert(articles, { onConflict: "url", ignoreDuplicates: true })
        .select("id");

      if (!error) totalInserted += count ?? 0;
    }
  }

  return new Response(
    JSON.stringify({ success: true, bills_processed: bills?.length ?? 0, articles_inserted: totalInserted }),
    { headers: { "Content-Type": "application/json" } },
  );
});
