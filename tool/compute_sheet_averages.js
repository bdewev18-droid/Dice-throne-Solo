const fs = require('fs');
const path = require('path');

const dir = 'd:/app/DTS/web/simulation/sheets';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.csv'));

function parseNumber(val) {
  if (!val) return 0;
  val = val.trim().replace(',', '.');
  if (val.includes('+')) {
    // e.g. 3+(1/2) or 6+parlay or 8+parlay
    const parts = val.split('+');
    let sum = 0;
    for (const p of parts) {
      if (p.includes('(1/2)')) sum += 0.5;
      else if (!isNaN(parseFloat(p))) sum += parseFloat(p);
    }
    return sum;
  }
  if (val.includes('(1/2)')) return 0.5;
  const num = parseFloat(val);
  return isNaN(num) ? 0 : num;
}

const heroProfiles = {};

for (const file of files) {
  const heroKey = file.replace('.csv', '');
  const content = fs.readFileSync(path.join(dir, file), 'utf8');
  const lines = content.split('\n').map(l => l.trim()).filter(l => l.length > 0);

  let totalAtk = 0, countAtk = 0;
  let totalUndef = 0, countUndef = 0;
  let totalDef = 0, countDef = 0;
  let totalCounter = 0, countCounter = 0;
  let totalToken = 0, countToken = 0;
  let totalHeal = 0, countHeal = 0;
  let totalTurns = 0;

  for (const line of lines) {
    const parts = line.split(',');
    const label = parts[0].trim().toLowerCase();
    const values = parts.slice(1).map(v => v.trim()).filter(v => v.length > 0);

    if (label.startsWith('atk') && !label.includes('imparable') && !label.includes('imp')) {
      for (const v of values) {
        const n = parseNumber(v);
        if (n > 0) { totalAtk += n; countAtk++; }
      }
    } else if (label.includes('imparable') || label === 'atk imp') {
      for (const v of values) {
        const n = parseNumber(v);
        if (n > 0) { totalUndef += n; countUndef++; }
      }
    } else if (label.startsWith('def') && !label.includes('atk')) {
      for (const v of values) {
        const n = parseNumber(v);
        if (n > 0) { totalDef += n; countDef++; }
      }
    } else if (label.includes('contre') || label.includes('def atk')) {
      for (const v of values) {
        const n = parseNumber(v);
        if (n > 0) { totalCounter += n; countCounter++; }
      }
    } else if (label.includes('token') || label.includes('brûlure') || label.includes('poison') || label.includes('bombe') || label.includes('forme') || label.includes('wound') || label.includes('sac degat') || label.includes('rps dégât') || label.includes('nevermore')) {
      for (const v of values) {
        const n = parseNumber(v);
        if (n > 0) { totalToken += n; countToken++; }
      }
    } else if (label.includes('heal') || label.includes('donuts') || label.includes('sac heal')) {
      for (const v of values) {
        const n = parseNumber(v);
        if (n > 0) { totalHeal += n; countHeal++; }
      }
    } else if (label.includes('vie ennemie')) {
      // number of turns in this run
      totalTurns += values.length;
    }
  }

  // Calculate per turn averages
  const turns = Math.max(1, totalTurns);
  heroProfiles[heroKey] = {
    totalTurns: turns,
    avgAtk: +(totalAtk / turns).toFixed(2),
    avgUndef: +(totalUndef / turns).toFixed(2),
    avgToken: +(totalToken / turns).toFixed(2),
    avgCounter: +(totalCounter / turns).toFixed(2),
    avgDef: +(totalDef / turns).toFixed(2),
    avgHeal: +(totalHeal / turns).toFixed(2),
  };
}

console.log('Hero Profiles from Sheet:');
console.log(JSON.stringify(heroProfiles, null, 2));
