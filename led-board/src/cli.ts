const url = process.argv[2] || "http://localhost:8080";
const text = process.argv[3] || process.argv[2];

if (!text || text === url) {
  console.error("Usage: npx tsx src/cli.ts [url] <message>");
  console.error("       npx tsx src/cli.ts http://192.168.1.100:8080 こんにちは");
  console.error("       npx tsx src/cli.ts こんにちは  (defaults to localhost:8080)");
  process.exit(1);
}

const endpoint = text === process.argv[2]
  ? `http://localhost:8080/api/message`
  : `${url.replace(/\/+$/, "")}/api/message`;

try {
  const res = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `text=${encodeURIComponent(text)}`,
  });
  const body = await res.json();
  console.log(`✓ ${body.message}`);
} catch (e) {
  console.error(`✗ ${(e as Error).message}`);
  process.exit(1);
}
