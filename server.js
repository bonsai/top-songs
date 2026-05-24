const http = require('http');
const fs = require('fs');
const path = require('path');
const { URL } = require('url');

const ROOT = __dirname;
const MIME_TYPES = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.ico': 'image/x-icon',
};
const ALLOWED_HOSTS = new Set(['kworb.net', 'www.kworb.net']);

function send(res, status, body, headers = {}) {
  res.writeHead(status, headers);
  res.end(body);
}

function serveFile(req, res) {
  const requestPath = req.url === '/' ? '/index.html' : req.url.split('?')[0];
  const safePath = path.normalize(requestPath).replace(/^(\.\.[/\\])+/, '');
  const filePath = path.join(ROOT, safePath);

  if (!filePath.startsWith(ROOT)) {
    send(res, 403, 'Forbidden');
    return;
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      send(res, 404, 'Not Found');
      return;
    }

    const ext = path.extname(filePath).toLowerCase();
    send(res, 200, data, { 'Content-Type': MIME_TYPES[ext] || 'application/octet-stream' });
  });
}

async function handleProxy(req, res, port) {
  try {
    const reqUrl = new URL(req.url, `http://localhost:${port}`);
    const target = reqUrl.searchParams.get('url');

    if (!target) {
      send(res, 400, JSON.stringify({ error: 'Missing url parameter' }), {
        'Content-Type': 'application/json; charset=utf-8',
      });
      return;
    }

    const parsed = new URL(target);
    if (!ALLOWED_HOSTS.has(parsed.hostname)) {
      send(res, 403, JSON.stringify({ error: 'Host not allowed' }), {
        'Content-Type': 'application/json; charset=utf-8',
      });
      return;
    }

    const upstream = await fetch(parsed, {
      headers: {
        'User-Agent': 'top-songs-proxy/1.0',
        Accept: 'text/html,application/xhtml+xml',
      },
    });

    const body = await upstream.text();
    send(res, upstream.status, body, {
      'Content-Type': upstream.headers.get('content-type') || 'text/html; charset=utf-8',
      'Cache-Control': 'public, max-age=300',
    });
  } catch (error) {
    send(res, 502, JSON.stringify({ error: error.message }), {
      'Content-Type': 'application/json; charset=utf-8',
    });
  }
}

function createServer(port = process.env.PORT || 3000) {
  return http.createServer((req, res) => {
    if (!req.url) {
      send(res, 400, 'Bad Request');
      return;
    }

    if (req.url.startsWith('/api/proxy')) {
      handleProxy(req, res, port);
      return;
    }

    serveFile(req, res);
  });
}

if (require.main === module) {
  const port = process.env.PORT || 3000;
  createServer(port).listen(port, () => {
    console.log(`top-songs listening on http://localhost:${port}`);
  });
}

module.exports = { createServer };
