const SUPABASE_URL = process.env.SUPABASE_URL || "";
const SUPABASE_ANON_KEY = process.env.SUPABASE_ANON_KEY || "";

export default async function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");
  res.setHeader("Content-Type", "application/json");

  if (req.method === "OPTIONS") {
    res.status(200).end();
    return;
  }

  // POST: write message to Supabase → triggers Realtime push to local dev server
  if (req.method === "POST") {
    let text = "";

    const sp = new URL(req.url, "http://h").searchParams;
    if (sp.get("text")) {
      text = sp.get("text");
    } else {
      let body = "";
      await new Promise(resolve => {
        req.on("data", chunk => body += chunk);
        req.on("end", resolve);
      });
      try {
        const json = JSON.parse(body);
        if (json.text) text = json.text;
      } catch {
        const params = new URLSearchParams(body);
        if (params.get("text")) text = params.get("text");
      }
    }

    if (text && SUPABASE_URL && SUPABASE_ANON_KEY) {
      try {
        const { createClient } = await import("@supabase/supabase-js");
        const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        await supabase.from("messages").insert({ text });
      } catch (err) {
        console.error("Supabase insert failed:", err);
      }
    }

    return res.status(200).json({ message: text || "" });
  }

  // GET: read latest message from Supabase
  if (SUPABASE_URL && SUPABASE_ANON_KEY) {
    try {
      const { createClient } = await import("@supabase/supabase-js");
      const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
      const { data } = await supabase
        .from("messages")
        .select("text")
        .order("id", { ascending: false })
        .limit(1);
      return res.status(200).json({ message: data?.[0]?.text || "" });
    } catch {}
  }

  res.status(200).json({ message: "LED BOARD" });
}
