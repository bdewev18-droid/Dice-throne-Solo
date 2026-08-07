const fs = require('fs');
const path = require('path');

const jsPath = path.join(__dirname, '..', 'web', 'admin', 'admin.js');
let js = fs.readFileSync(jsPath, 'utf8');

// Fix image click listener
js = js.replace("$('enemyAssetPreview')?.addEventListener", "$('cardImage')?.addEventListener");

// Fix token Datalist to only show English value with French in label
js = js.replace(/function tokenNames\(\) \{[\s\S]*?function ensureTokenDatalist\(\) \{/, `function ensureTokenDatalist() {`);
js = js.replace(/list\.innerHTML = tokenNames.*?;/, `const options = tokenCatalog.map(t => {
      const fr = (t.frLabel && t.frLabel !== t.label) ? \` (\${t.frLabel})\` : '';
      return \`<option value="\${escapeAttr(t.label)}">\${escapeAttr(t.label)}\${fr}</option>\`;
    }).sort();
    list.innerHTML = options.join('');`);

fs.writeFileSync(jsPath, js);
console.log('admin.js updated.');
