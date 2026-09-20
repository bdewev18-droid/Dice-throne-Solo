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

    if (request.method === 'POST' && urlPath === '/api/save-simulation-stats') {
      let body = '';
      request.on('data', chunk => { body += chunk.toString(); });
      request.on('end', () => {
        try {
          const json = JSON.parse(body);
          const statsPath1 = path.resolve(__dirname, '..', 'docs', 'hero_simulation_stats.json');
          const statsPath2 = path.resolve(__dirname, '..', 'web', 'simulation', 'hero_simulation_stats.json');
          fs.writeFileSync(statsPath1, JSON.stringify(json, null, 2) + '\n');
          fs.writeFileSync(statsPath2, JSON.stringify(json, null, 2) + '\n');
          
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

    // Serve web/recette directly so edits are immediate without rebuilding
    if (relativePath.startsWith('recette/assets/')) {
      const assetRel = relativePath.slice('recette/assets/'.length);
      const liveAssetPath = path.resolve(__dirname, '..', 'assets', assetRel);
      if (fs.existsSync(liveAssetPath) && !fs.statSync(liveAssetPath).isDirectory()) {
        sendFile(response, liveAssetPath);
        return;
      }
    }

    if (relativePath.startsWith('recette/') || relativePath === 'recette') {
      let recRel = relativePath === 'recette' ? 'index.html' : relativePath.slice('recette/'.length);
      if (!recRel || recRel.endsWith('/')) {
        recRel = path.join(recRel, 'index.html');
      }
      const liveRecPath = path.resolve(__dirname, '..', 'web', 'recette', recRel);
      if (fs.existsSync(liveRecPath) && !fs.statSync(liveRecPath).isDirectory()) {
        sendFile(response, liveRecPath);
        return;
      }
    }

    // Serve web/simulation directly so edits are immediate without rebuilding
    if (relativePath.startsWith('simulation/assets/')) {
      const assetRel = relativePath.slice('simulation/assets/'.length);
      const liveAssetPath = path.resolve(__dirname, '..', 'assets', assetRel);
      if (fs.existsSync(liveAssetPath) && !fs.statSync(liveAssetPath).isDirectory()) {
        sendFile(response, liveAssetPath);
        return;
      }
    }

    if (relativePath.startsWith('simulation/') || relativePath === 'simulation') {
      let simRel = relativePath === 'simulation' ? 'index.html' : relativePath.slice('simulation/'.length);
      if (!simRel || simRel.endsWith('/')) {
        simRel = path.join(simRel, 'index.html');
      }
      const liveSimPath = path.resolve(__dirname, '..', 'web', 'simulation', simRel);
      if (fs.existsSync(liveSimPath) && !fs.statSync(liveSimPath).isDirectory()) {
        sendFile(response, liveSimPath);
        return;
      }
    }

    // Serve assets directly from assets/ directory if not found in build/web
    if (relativePath.startsWith('assets/')) {
      const assetRel = relativePath.slice('assets/'.length);
      const liveAssetPath = path.resolve(__dirname, '..', 'assets', assetRel);
      if (fs.existsSync(liveAssetPath) && !fs.statSync(liveAssetPath).isDirectory()) {
        sendFile(response, liveAssetPath);
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
