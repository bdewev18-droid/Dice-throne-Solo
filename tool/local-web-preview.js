const fs = require('fs');
const http = require('http');
const path = require('path');

const root = path.resolve(__dirname, '..', 'build', 'web');
const port = Number(process.env.PORT || 8082);
const basePath = '/Dice-throne-Solo';
const types = {
  '.css': 'text/css',
  '.html': 'text/html',
  '.jpeg': 'image/jpeg',
  '.jpg': 'image/jpeg',
  '.js': 'text/javascript',
  '.json': 'application/json',
  '.png': 'image/png',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.webp': 'image/webp',
};

function sendFile(response, filePath) {
  fs.readFile(filePath, (error, data) => {
    if (error) {
      response.writeHead(404);
      response.end('Not found');
      return;
    }
    response.writeHead(200, {
      'Content-Type': types[path.extname(filePath)] || 'application/octet-stream',
    });
    response.end(data);
  });
}

http
  .createServer((request, response) => {
    let urlPath = decodeURI(request.url.split('?')[0]);
    if (urlPath === '/' || urlPath === basePath) {
      response.writeHead(302, { Location: `${basePath}/` });
      response.end();
      return;
    }
    if (urlPath.startsWith(`${basePath}/`)) {
      urlPath = urlPath.slice(basePath.length);
    }
    let filePath = path.join(root, urlPath);
    if (urlPath.endsWith('/')) {
      filePath = path.join(root, 'index.html');
    }
    if (!filePath.startsWith(root)) {
      response.writeHead(403);
      response.end('Forbidden');
      return;
    }
    if (!fs.existsSync(filePath)) {
      sendFile(response, path.join(root, 'index.html'));
      return;
    }
    sendFile(response, filePath);
  })
  .listen(port, '127.0.0.1', () => {
    console.log(`Preview: http://127.0.0.1:${port}${basePath}/`);
  });
