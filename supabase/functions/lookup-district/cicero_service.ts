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

  async fetchOfficials(zipCode: string): Promise<CiceroOfficial[]> {
    const url = new URL(`${CICERO_API_BASE}/official`);
    url.searchParams.set("search_postal", zipCode);
    url.searchParams.set("search_country", "US");
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
        "ZIP code not found — check that it is a valid US ZIP code",
        404,
      );
    }
    if (!res.ok) {
      console.error("Cicero API error:", res.status, await res.text());
      throw new CiceroError("Failed to fetch district data", 502);
    }

    const data = await res.json() as CiceroResponse;
    console.log(JSON.stringify(data, null, 2))
    const candidate: CiceroCandidate | undefined = data?.response?.results?.candidates?.[0];

    if (candidate?.match_region !== "IN") throw new CiceroError("ZIP code is not in Indiana", 422);

    return candidate?.officials ?? [];
  }
}
