export async function onRequestPost({ request, env }) {
  const cors = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Content-Type": "application/json; charset=utf-8",
  };
  try {
    const body = await request.json();
    const language = String(body.language || "English").slice(0, 40);
    const level = String(body.level || "Beginner").slice(0, 30);
    const incoming = Array.isArray(body.messages) ? body.messages.slice(-10) : [];
    const messages = incoming
      .filter(m => m && ["user", "assistant"].includes(m.role) && typeof m.content === "string")
      .map(m => ({ role: m.role, content: m.content.slice(0, 1500) }));
    if (!messages.length) {
      return new Response(JSON.stringify({ error: "Kirim pesan terlebih dahulu." }), { status: 400, headers: cors });
    }
    if (!env.AI) {
      return new Response(JSON.stringify({ error: "AI binding belum dikonfigurasi." }), { status: 503, headers: cors });
    }
    const system = `You are LinguaGo, a patient language tutor. Practice language: ${language}. Learner level: ${level}. Reply in the target language at the learner's level, then briefly explain important corrections in Indonesian. Encourage the learner, keep replies concise, and ask one useful follow-up question. Never claim the learner is fluent based on one message.`;
    const response = await env.AI.run("@cf/meta/llama-3.1-8b-instruct", {
      messages: [{ role: "system", content: system }, ...messages],
      max_tokens: 450,
    });
    const reply = response?.response || response?.output_text || "Maaf, tutor belum dapat menjawab. Coba lagi.";
    return new Response(JSON.stringify({ reply }), { headers: cors });
  } catch (e) {
    return new Response(JSON.stringify({ error: "Permintaan tidak dapat diproses." }), { status: 500, headers: cors });
  }
}
export async function onRequestOptions() {
  return new Response(null, { status: 204, headers: {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
  }});
}
