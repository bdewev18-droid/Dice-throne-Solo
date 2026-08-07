const fs = require('fs');
const path = require('path');
const adminJsPath = path.join(__dirname, '..', 'web', 'admin', 'admin.js');
let code = fs.readFileSync(adminJsPath, 'utf8');

// Patch updateDownloadButtons to also update saveFileBtn
code = code.replace(
  "tokenButton.classList.toggle('dirty', tokenDirty);\n    }",
  `tokenButton.classList.toggle('dirty', tokenDirty);\n    }\n    if (document.getElementById('saveFileBtn') && (location.hostname === '127.0.0.1' || location.hostname === 'localhost')) {\n      document.getElementById('saveFileBtn').disabled = !enemyDirty;\n      document.getElementById('saveFileBtn').classList.toggle('dirty', enemyDirty);\n    }`
);

fs.writeFileSync(adminJsPath, code);
console.log('admin.js patch 3 applied.');
