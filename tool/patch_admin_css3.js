const fs = require('fs');
const path = require('path');
const cssPath = path.join(__dirname, '..', 'web', 'admin', 'admin.css');
let css = fs.readFileSync(cssPath, 'utf8');

css = css.replace('.editor-state{display:grid;grid-template-columns:40% minmax(260px,28%) 1fr;gap:14px;align-items:start}', '.editor-state{display:grid;grid-template-columns:1fr minmax(260px,312px) 50%;gap:14px;align-items:start}');

fs.writeFileSync(cssPath, css);
console.log('admin.css base layout updated.');
