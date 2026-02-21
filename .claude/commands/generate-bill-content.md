# Generate Bill Content with Claude AI

Use the Claude API to generate civic engagement content for a specific Indiana bill.

## Instructions

The user will provide a bill number, title, or raw bill text.

Generate the following content using the Claude API (claude-sonnet-4-6 model):

---

### 1. Plain-Language Bill Summary
A 3–4 sentence summary written for a Gen Z / Millennial audience in Indiana.
- Avoid jargon
- Explain who it affects and how
- Neutral, factual tone

### 2. Bill Quiz (3 Questions)
Multiple-choice quiz to earn +15 XP in the app.
Format:
```json
[
  {
    "question": "...",
    "options": ["A. ...", "B. ...", "C. ...", "D. ..."],
    "correct": "A",
    "explanation": "Brief explanation of the correct answer."
  }
]
```

### 3. Legislator Call Talking Points
3–5 bullet points a user can reference when calling their Indiana legislator about this bill.
- Conversational, not scripted
- Cover: what the bill does, why it matters locally, one question to ask the staffer

### 4. "What's New" Digest Prompt
A Claude API prompt template that can be used at runtime to summarize recent news about this bill. Output the prompt string itself so it can be stored and reused.

---

## Claude API Implementation Notes

If the user wants to wire this to the app backend, scaffold a Supabase Edge Function:

```typescript
// supabase/functions/generate-bill-content/index.ts
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

Deno.serve(async (req) => {
  const { billText, billNumber } = await req.json();

  const message = await client.messages.create({
    model: "claude-sonnet-4-6",
    max_tokens: 1024,
    messages: [
      {
        role: "user",
        content: `You are a civic education assistant for HoosierCiv, an Indiana civic engagement app for Gen Z and Millennials. Given the following Indiana bill, generate: 1) a plain-language summary, 2) a 3-question quiz with answers, and 3) talking points for calling a legislator.\n\nBill ${billNumber}:\n${billText}`,
      },
    ],
  });

  return new Response(JSON.stringify(message.content[0]), {
    headers: { "Content-Type": "application/json" },
  });
});
```

Store the API key as a Supabase secret:
```bash
supabase secrets set ANTHROPIC_API_KEY=your_key_here
```

## Output
Produce all four content pieces. If bill text is not provided, ask for it before generating.

$ARGUMENTS
