import { handler } from "./_handler.ts";

Deno.serve((req) => handler(req));
