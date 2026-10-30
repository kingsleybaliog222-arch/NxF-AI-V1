
const express = require("express");
const cors = require("cors");
const rateLimit = require("express-rate-limit");

const app = express();

app.use(cors());
app.use(express.json({ limit: "100kb" }));

app.use(rateLimit({
  windowMs: 60 * 1000,
  limit: 20
}));

app.get("/", (req, res) => {
  res.json({ status: "online", name: "NxF AI Backend" });
});

app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

app.post("/api/chat", async (req, res) => {
  try {
    const key = process.env.OPENROUTER_API_KEY;
    const model = process.env.OPENROUTER_MODEL || "openai/gpt-4o-mini";

    if (!key) {
      return res.status(500).json({
        error: "Backend API key is not configured."
      });
    }

    const messages = req.body.messages;

    if (!Array.isArray(messages) || messages.length === 0 ||
        messages.length > 30) {
      return res.status(400).json({
        error: "Invalid messages."
      });
    }

    const safeMessages = messages.map(m => {
      if (!["system", "user", "assistant"].includes(m.role) ||
          typeof m.content !== "string" ||
          m.content.length > 10000) {
        throw new Error("Invalid message format.");
      }

      return { role: m.role, content: m.content };
    });

    const response = await fetch(
      "https://openrouter.ai/api/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${key}`,
          "Content-Type": "application/json",
          "X-OpenRouter-Title": "NxF AI V1"
        },
        body: JSON.stringify({
          model,
          messages: safeMessages
        })
      }
    );

    const data = await response.json();

    if (!response.ok) {
      return res.status(502).json({
        error: "AI provider request failed."
      });
    }

    const reply = data.choices?.[0]?.message?.content;

    if (typeof reply !== "string") {
      return res.status(502).json({
        error: "No AI response received."
      });
    }

    res.json({ reply });

  } catch (error) {
    res.status(500).json({
      error: "Backend request failed."
    });
  }
});

const PORT = process.env.PORT || 10000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`NxF backend running on ${PORT}`);
});
