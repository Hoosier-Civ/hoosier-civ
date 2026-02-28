export class LookUpDistrictController {
  zipCode!: string;

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
      const zip = body.zip_code?.toString().trim();
      if (!zip || !/^\d{5}$/.test(zip)) {
        return new Response(JSON.stringify({ error: "zip_code must be a 5-digit string" }), {
          status: 400,
          headers: { "Content-Type": "application/json" },
        });
      }
      this.zipCode = zip;
    } catch {
      return new Response(JSON.stringify({ error: "Invalid request body" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    return null;
  }
}