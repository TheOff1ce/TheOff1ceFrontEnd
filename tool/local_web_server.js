// Serves Flutter's web build locally and falls back to index.html for routes.
const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.resolve(process.cwd(), 'build', 'web');
const port = Number(process.env.PORT || 5173);
const mime = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.webmanifest': 'application/manifest+json',
};

http
  .createServer((request, response) => {
    const pathname = decodeURIComponent(
      new URL(request.url, 'http://localhost').pathname,
    );
    const candidate = path.resolve(root, `.${pathname}`);
    const isAsset =
      candidate.startsWith(root) &&
      fs.existsSync(candidate) &&
      fs.statSync(candidate).isFile();
    const file = isAsset ? candidate : path.join(root, 'index.html');

    fs.readFile(file, (error, content) => {
      if (error) {
        response.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
        response.end('No se pudo cargar la aplicación. Ejecuta flutter build web.');
        return;
      }
      response.writeHead(200, {
        'Cache-Control': 'no-cache',
        'Content-Type': mime[path.extname(file)] || 'application/octet-stream',
      });
      response.end(content);
    });
  })
  .listen(port, '127.0.0.1', () => {
    console.log(`FARMA GO disponible en http://localhost:${port}`);
  });
