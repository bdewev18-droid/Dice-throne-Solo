const fs = require('fs');
const path = require('path');
const adminJsPath = path.join(__dirname, '..', 'web', 'admin', 'admin.js');
let code = fs.readFileSync(adminJsPath, 'utf8');

// Patch conditionalRuleCard
const oldCardHTML = `'<div class="display-row-head"><label class="wide-label">Display rows JSON<textarea class="cond-displayrows" \nrows="7" placeholder=\\'[{"align":"left","items":["If 3 identical values","=","{token:Silence}"]}]\\'>' + \nescapeText(JSON.stringify(data.displayRows || [], null, 2)) + '</textarea></label></div>',`;
// Wait, the regex replace might be safer since indentation or newlines can vary.
code = code.replace(
  /'<div class="display-row-head"><label class="wide-label">Display rows JSON<textarea class="cond-displayrows"[\s\S]*?<\/textarea><\/label><\/div>',/,
  `'<div class="display-row-head" style="margin-top: 10px;"><label class="wide-label">Display rows JSON' +
      '<div class="highlight-container"><div class="highlight-backdrop rule-backdrop"></div>' +
      '<textarea class="cond-displayrows rule-display-rows highlight-textarea" rows="5" placeholder=\\'[{"align":"left","items":["If 3 identical values","=","{token:Silence}"]}]\\'>' + escapeText(JSON.stringify(data.displayRows || [], null, 2)) + '</textarea></div></label>' +
      '<button class="ghost-btn generate-btn rule-generate-btn" type="button">Generate text</button></div>',`
);

// We also need to add the generate button logic to conditional rules.
// Let's find where they attach event listeners for `.cond-displayrows`.
code = code.replace(
  "node.querySelector('.remove-conditional').onclick = () => {",
  `node.querySelector('.rule-generate-btn').onclick = () => {
      // Basic translation logic from conditional rule to rows
      // We don't have full buildActionRows in admin.js easily for rules, but we can do a basic one
      const rows = [];
      const items = [];
      if (condition.type === 'sameValue') items.push('If ' + condition.count + ' identical values');
      if (condition.type === 'sameSymbol') items.push('If ' + condition.count + ' identical symbols');
      if (effect.heroTokens) effect.heroTokens.forEach(t => { items.push('Gain {token:' + t + '}'); });
      if (effect.minionTokens) effect.minionTokens.forEach(t => { items.push('Apply {token:' + t + '}'); });
      if (items.length > 0) rows.push({ align: 'left', items });
      
      data.displayRows = rows;
      setDirty('enemy');
      renderConditionalRules();
      renderPreview();
    };
    node.querySelector('.remove-conditional').onclick = () => {`
);

fs.writeFileSync(adminJsPath, code);
console.log('admin.js conditionalRuleCard patched.');
