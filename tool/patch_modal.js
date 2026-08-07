const fs = require('fs');
const path = require('path');

const indexHtmlPath = path.join(__dirname, '..', 'web', 'admin', 'index.html');
let html = fs.readFileSync(indexHtmlPath, 'utf8');
if (!html.includes('imageModal')) {
    html = html.replace('</body>', `
  <div id="imageModal" style="display:none; position:fixed; inset:0; background:rgba(0,0,0,0.9); z-index:2000; place-items:center; cursor:zoom-out;">
    <img id="imageModalImg" src="" style="max-width:95vw; max-height:95vh; object-fit:contain;">
  </div>
</body>`);
    fs.writeFileSync(indexHtmlPath, html);
    console.log('index.html patched');
}

const adminCssPath = path.join(__dirname, '..', 'web', 'admin', 'admin.css');
let css = fs.readFileSync(adminCssPath, 'utf8');
if (!css.includes('.card-frame img { cursor: zoom-in; }')) {
    css += '\n.card-frame img { cursor: zoom-in; transition: transform 0.2s; }\n.card-frame img:hover { transform: scale(1.02); }\n';
    fs.writeFileSync(adminCssPath, css);
    console.log('admin.css patched');
}

const adminJsPath = path.join(__dirname, '..', 'web', 'admin', 'admin.js');
let js = fs.readFileSync(adminJsPath, 'utf8');
if (!js.includes('imageModal')) {
    js = js.replace('function setupUIEnhancements() {', `function setupUIEnhancements() {
  $('enemyAssetPreview')?.addEventListener('click', (e) => {
    if (!e.target.src) return;
    $('imageModalImg').src = e.target.src;
    $('imageModal').style.display = 'grid';
  });
  $('imageModal')?.addEventListener('click', () => {
    $('imageModal').style.display = 'none';
  });\n`);
    fs.writeFileSync(adminJsPath, js);
    console.log('admin.js patched');
}
