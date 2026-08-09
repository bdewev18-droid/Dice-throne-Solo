const fs = require('fs');
const http = require('http');
const path = require('path');

const root = path.resolve(__dirname, '..', 'build', 'web');
const port = Number(process.env.PORT || 8083);
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
      'Cache-Control': 'no-store, no-cache, must-revalidate, proxy-revalidate',
      Pragma: 'no-cache',
      Expires: '0',
    });
    response.end(data);
  });
}

http
  .createServer((request, response) => {
    let urlPath = decodeURI(request.url.split('?')[0]);
    if (request.method === 'POST' && urlPath === '/api/save-enemy') {
      let body = '';
      request.on('data', chunk => { body += chunk.toString(); });
      request.on('end', () => {
        try {
          const json = JSON.parse(body);
          const enemyProfilesPath = path.resolve(__dirname, '..', 'docs', 'enemy_profiles.json');
          fs.writeFileSync(enemyProfilesPath, JSON.stringify(json, null, 2) + '\n');
          
          response.writeHead(200, {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
          });
          response.end(JSON.stringify({ success: true }));
        } catch (e) {
          response.writeHead(500, { 'Content-Type': 'application/json' });
          response.end(JSON.stringify({ error: e.message }));
        }
      });
      return;
    }
    
    // Handle CORS preflight just in case
    if (request.method === 'OPTIONS') {
      response.writeHead(204, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type'
      });
      response.end();
      return;
    }

    if (urlPath === '/' || urlPath === basePath) {
      response.writeHead(302, { Location: `${basePath}/` });
      response.end();
      return;
    }
    if (urlPath.startsWith(`${basePath}/`)) {
      urlPath = urlPath.slice(basePath.length);
    }
    const relativePath = urlPath.replace(/^\/+/, '');
    if (relativePath === 'assets/docs/enemy_profiles.json') {
      const livePath = path.resolve(__dirname, '..', 'docs', 'enemy_profiles.json');
      if (fs.existsSync(livePath)) {
        sendFile(response, livePath);
        return;
      }
    }
    if (relativePath === 'assets/data/token_catalog.json') {
      const livePath = path.resolve(__dirname, '..', 'assets', 'data', 'token_catalog.json');
      if (fs.existsSync(livePath)) {
        sendFile(response, livePath);
        return;
      }
    }

    let filePath = path.join(root, relativePath);
    if (urlPath.endsWith('/')) {
      const directoryIndex = path.join(root, relativePath, 'index.html');
      filePath = fs.existsSync(directoryIndex)
        ? directoryIndex
        : path.join(root, 'index.html');
    }
    if (fs.existsSync(filePath) && fs.statSync(filePath).isDirectory()) {
      const normalizedPath = urlPath.endsWith('/') ? urlPath : `${urlPath}/`;
      response.writeHead(302, { Location: `${basePath}${normalizedPath}` });
      response.end();
      return;
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
