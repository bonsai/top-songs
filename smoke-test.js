const assert = require('node:assert/strict');

const { createServer } = require('./server');

async function startServer() {
  const server = createServer(0);
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const address = server.address();
  return {
    server,
    baseUrl: `http://127.0.0.1:${address.port}`,
  };
}

async function main() {
  const { server, baseUrl } = await startServer();

  try {
    const homeRes = await fetch(`${baseUrl}/`);
    const homeBody = await homeRes.text();
    assert.equal(homeRes.status, 200);
    assert.match(homeBody, /Kworb Spotify Global Daily Chart/);

    const proxyRes = await fetch(`${baseUrl}/api/proxy?url=${encodeURIComponent('https://example.com')}`);
    const proxyBody = await proxyRes.json();
    assert.equal(proxyRes.status, 403);
    assert.equal(proxyBody.error, 'Host not allowed');

    console.log('smoke test passed');
  } finally {
    await new Promise((resolve) => server.close(resolve));
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
