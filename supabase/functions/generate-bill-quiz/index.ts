import Anthropic from "npm:@anthropic-ai/sdk";
import { createClient } from "npm:@supabase/supabase-js";

const anthropic = new Anthropic();

Deno.serve(async (req) => {
  const { record } = await req.json(); // Supabase database webhook payload

  const billId: string = record.id;
  const billTitle: string = record.title;
  const billSummary: string = record.summary ?? "No summary available.";

  // Generate quiz with Claude
  const message = await anthropic.messages.create({
    model: "claude-haiku-4-5-20251001",
    max_tokens: 1024,
    messages: [
      {
        role: "user",
        content: `You are a civic education assistant for HoosierCiv, an Indiana civic engagement app for Gen Z and Millennials.

Given this Indiana bill, generate a 3-question multiple-choice quiz. Return ONLY valid JSON — no explanation, no markdown.

Bill: ${billTitle}
Summary: ${billSummary}

Return this exact JSON structure:
[
  {
    "question": "...",
    "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
    "correct": "A",
    "explanation": "Brief explanation of the correct answer."
  }
]`,
      },
    ],
  });

  const questions = JSON.parse(message.content[0].type === "text" ? message.content[0].text : "[]");

  // Store in Supabase with service role (bypasses RLS)
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  const { error } = await supabase
    .from("quizzes")
    .upsert({ bill_id: billId, questions, generated_at: new Date().toISOString() });

  if (error) {
    console.error("Failed to store quiz:", error.message);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ success: true, bill_id: billId }), {
    headers: { "Content-Type": "application/json" },
  });
});
