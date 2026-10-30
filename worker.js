export default {
  async fetch(request, env) {
    const cors = {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "POST, GET, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type"
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers: cors });
    }

    const json = (data, status = 200) =>
      new Response(JSON.stringify(data), {
        status,
        headers: {
          ...cors,
          "Content-Type": "application/json"
        }
      });

    const url = new URL(request.url);

    if (url.pathname === "/" || url.pathname === "/health") {
      return json({ status: "online", name: "NxF AI Backend" });
    }

    if (url.pathname !== "/api/chat" || request.method !== "POST") {
      return json({ error: "Not found" }, 404);
    }

    if (!env.OPENROUTER_API_KEY) {
      return json({ error: "API key not configured" }, 500);
    }

    try {
      const body = await request.json();
      const messages = body.messages;

      if (!Array.isArray(messages) ||
          messages.length === 0 ||
          messages.length > 30) {
        return json({ error: "Invalid messages" }, 400);
      }

      for (const m of messages) {
        if (
          !["system", "user", "assistant"].includes(m.role) ||
          typeof m.content !== "string" ||
          m.content.length > 10000
        ) {
          return json({ error: "Invalid message" }, 400);
        }
      }

      const result = await fetch(
        "https://openrouter.ai/api/v1/chat/completions",
        {
          method: "POST",
          headers: {
            "Authorization": `Bearer ${env.OPENROUTER_API_KEY}`,
            "Content-Type": "application/json"
          },
          body: JSON.stringify({
            model: "openai/gpt-4o-mini",
            messages
          })
        }
      );

      const data = await result.json();

      if (!result.ok) {
        return json({ error: "AI provider request failed" }, 502);
      }

      return json({
        reply: data.choices?.[0]?.message?.content || "No response"
      });

    } catch (error) {
      return json({ error: "Invalid request or server error" }, 500);
    }
  }
};
