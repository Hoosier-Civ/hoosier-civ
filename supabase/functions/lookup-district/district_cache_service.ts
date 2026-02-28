import { SupabaseClient } from "npm:@supabase/supabase-js";

export type CacheRow = {
  district_id: string;
  cached_at: string;
};

export class CacheError extends Error {
  constructor(message: string, public readonly httpStatus: number) {
    super(message);
    this.name = "CacheError";
  }
}

export class DistrictCacheService {
  // deno-lint-ignore no-explicit-any
  constructor(private readonly client: Pick<SupabaseClient, "from"> | any) {}

  async get(zipCode: string): Promise<CacheRow | null> {
    const { data, error } = await this.client
      .from("district_zip_cache")
      .select("district_id, cached_at")
      .eq("zip_code", zipCode)
      .maybeSingle();

    if (error) {
      console.error("Error looking up district cache", error);
      throw new CacheError("Failed to look up cached district data", 500);
    }

    return data ?? null;
  }

  isFresh(cachedAt: string, ttlDays: number): boolean {
    const ageMs = Date.now() - new Date(cachedAt).getTime();
    return ageMs / (1000 * 60 * 60 * 24) < ttlDays;
  }

  async upsert(zipCode: string, districtId: string): Promise<void> {
    const { error } = await this.client.from("district_zip_cache").upsert({
      zip_code: zipCode,
      district_id: districtId,
      cached_at: new Date().toISOString(),
    });

    if (error) {
      console.error("Cache upsert failed:", error.message);
      // Non-fatal — caller still returns the data
    }
  }
}
