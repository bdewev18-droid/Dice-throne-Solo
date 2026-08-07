const fs = require('fs');
const path = require('path');
const cssPath = path.join(__dirname, '..', 'web', 'admin', 'admin.css');
let css = fs.readFileSync(cssPath, 'utf8');

// Disable the syntax highlighting overlay trick for text areas, 
// because it causes unreadable text on some browsers (color transparent issues).
css = css.replace('.highlight-backdrop { color: #fff; }', '.highlight-backdrop { display: none; }');
css = css.replace('.highlight-textarea { color: transparent !important; caret-color: #fff; }', '.highlight-textarea { color: #fff !important; }');

fs.writeFileSync(cssPath, css);
console.log('admin.css syntax highlight fallback applied.');
