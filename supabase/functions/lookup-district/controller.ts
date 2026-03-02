export class LookUpDistrictController {
  zip!: string;
  address?: string;

  constructor(private readonly req: Request) {}

  async validateRequest(): Promise<Response | null> {
    if (this.req.method !== "POST") {
      return new Response(JSON.stringify({ error: "Method not allowed" }), {
        status: 405,
        headers: { "Content-Type": "application/json" },
      });
    }

    try {
      const body = await this.req.json();
      const zip = body.zip?.toString().trim();
      if (!zip || !/^\d{5}$/.test(zip)) {
        return new Response(JSON.stringify({ error: "zip must be a 5-digit string" }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        });
      }
      this.zip = zip;
      const address = body.address?.toString().trim();
      if (address) this.address = address;
    } catch {
      return new Response(JSON.stringify({ error: "Invalid request body" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    return null;
  }
}