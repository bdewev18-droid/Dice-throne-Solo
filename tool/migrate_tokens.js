const fs = require('fs');
const path = require('path');

const enemyProfilesPath = path.join(__dirname, '..', 'docs', 'enemy_profiles.json');
const tokenCatalogPath = path.join(__dirname, '..', 'assets', 'data', 'token_catalog.json');

const enemyData = JSON.parse(fs.readFileSync(enemyProfilesPath, 'utf8'));
const tokenCatalogData = JSON.parse(fs.readFileSync(tokenCatalogPath, 'utf8'));
const tokenCatalog = Array.isArray(tokenCatalogData) ? tokenCatalogData : tokenCatalogData.tokens;

// Build replacement patterns for tokens
const tokenRules = [];
for (const token of tokenCatalog) {
  if (!token.imageAsset || token.editorVisible === false) continue;
  
  const aliases = [token.label, token.frLabel, ...(token.aliases || [])]
    .filter(Boolean)
    .filter(a => a.length >= 3)
    .sort((a, b) => b.length - a.length); // Longest first
    
  tokenRules.push({
    label: token.label,
    aliases: aliases,
  });
}

// Sort token rules globally by longest alias to prevent partial matches
tokenRules.sort((a, b) => b.aliases[0].length - a.aliases[0].length);

function replaceTokens(text) {
  if (typeof text !== 'string') return text;
  // If it already has an explicit token, we don't skip entirely in case there are multiple,
  // but we should be careful not to replace inside existing {token:XXX}
  let newText = text;
  
  for (const rule of tokenRules) {
    for (const alias of rule.aliases) {
      // Use regex with word boundaries to match aliases case-insensitively
      // Escaping special characters in alias just in case
      const escapedAlias = alias.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      // Lookbehind (?<!...) and Lookahead (?!...) to ensure we are not already inside {token:...}
      // and not matching part of a bigger word. JavaScript regex supports this.
      const regex = new RegExp(`(?<!\\{token:)\\b(${escapedAlias})\\b`, 'gi');
      
      if (regex.test(newText)) {
        newText = newText.replace(regex, `{token:${rule.label}}`);
      }
    }
  }
  return newText;
}

function processDisplayRows(rows) {
  if (!rows || !Array.isArray(rows)) return;
  for (const row of rows) {
    if (row.items && Array.isArray(row.items)) {
      row.items = row.items.map(replaceTokens);
    }
  }
}

for (const profile of enemyData.profiles || []) {
  if (profile.attackPlan) {
    processDisplayRows(profile.attackPlan.displayRows);
    if (profile.attackPlan.conditionalRules) {
      for (const rule of profile.attackPlan.conditionalRules) {
        processDisplayRows(rule.displayRows);
      }
    }
  }
  if (profile.defensePlan) {
    processDisplayRows(profile.defensePlan.displayRows);
    if (profile.defensePlan.effects) {
      for (const effect of profile.defensePlan.effects) {
        processDisplayRows(effect.displayRows);
      }
    }
  }
}

fs.writeFileSync(enemyProfilesPath, JSON.stringify(enemyData, null, 2) + '\n');
console.log('Migration complete.');
