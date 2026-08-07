const fs = require('fs');
const path = require('path');
const cssPath = path.join(__dirname, '..', 'web', 'admin', 'admin.css');
let css = fs.readFileSync(cssPath, 'utf8');

css = css.replace('.editor-state.layout-full { grid-template-columns: minmax(200px, 25%) minmax(390px, auto) 1fr; }', '.editor-state.layout-full { grid-template-columns: 1fr minmax(260px, 312px) 50%; }');
css = css.replace('.editor-state.layout-no-card { grid-template-columns: 48px minmax(390px, auto) 1fr; }', '.editor-state.layout-no-card { grid-template-columns: 48px minmax(260px, 312px) 50%; }');
css = css.replace('.editor-state.layout-no-phone { grid-template-columns: minmax(200px, 30%) 48px 1fr; }', '.editor-state.layout-no-phone { grid-template-columns: 1fr 48px 50%; }');
css = css.replace('.editor-state.layout-minimal { grid-template-columns: 48px 48px 1fr; }', '.editor-state.layout-minimal { grid-template-columns: 48px 48px 50%; }');

fs.writeFileSync(cssPath, css);
console.log('admin.css layout updated.');
