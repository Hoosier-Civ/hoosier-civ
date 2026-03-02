import { CiceroCandidate, CiceroOfficial, CiceroResponse } from "./cicero_types.ts";

export type { CiceroCandidate, CiceroOfficial };

const CICERO_API_BASE = "https://cicero.azavea.com/v3.1";

export class CiceroError extends Error {
  constructor(message: string, public readonly httpStatus: number) {
    super(message);
    this.name = "CiceroError";
  }
}

export class CiceroService {
  private readonly apiKey: string;

  constructor() {
    const key = Deno.env.get("CICERO_API_KEY");
    if (!key) throw new CiceroError("Cicero API key not configured", 500);
    this.apiKey = key;
  }

  async fetchOfficials(
    zip: string,
    address?: string,
  ): Promise<{ city: string; zipCode: string; officials: CiceroOfficial[] }> {
    const url = new URL(`${CICERO_API_BASE}/official`);
    if (address) url.searchParams.set("search_address", address);
    url.searchParams.set("search_state", "IN");
    url.searchParams.set("search_country", "US");
    url.searchParams.set("order", "district_type");
    url.searchParams.set("sort", "desc");
    url.searchParams.set("search_postal", zip);
    url.searchParams.set("max", "200");
    url.searchParams.set("key", this.apiKey);

    let res: Response;
    try {
      res = await fetch(url.toString());
    } catch (err) {
      console.error("Fetch error:", err);
      throw new CiceroError("Failed to reach Cicero API", 502);
    }

    if (res.status === 404) {
      throw new CiceroError(
        "Address not found — check that it is a valid US address",
        404,
      );
    }
    if (!res.ok) {
      console.error("Cicero API error:", res.status, await res.text());
      throw new CiceroError("Failed to fetch district data", 502);
    }

    const data = await res.json() as CiceroResponse;
    const candidate: CiceroCandidate | undefined = data?.response?.results?.candidates?.[0];

    if (candidate?.match_region !== "IN") throw new CiceroError("Address is not in Indiana", 422);

    return {
      city: candidate.match_city ?? "",
      zipCode: candidate.match_postal ?? "",
      officials: candidate?.officials ?? [],
    };
  }
}
