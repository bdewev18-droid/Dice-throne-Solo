const fs = require('fs');
const path = require('path');

const dir = 'd:/app/DTS/web/simulation/sheets';
const files = fs.readdirSync(dir).filter(f => f.endsWith('.csv'));

function parseNumber(val) {
  if (!val) return 0;
  val = val.trim().replace(',', '.');
  if (val.includes('+')) {
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

const perTurnProfiles = {};

for (const file of files) {
  const heroKey = file.replace('.csv', '');
  const content = fs.readFileSync(path.join(dir, file), 'utf8');
  const rawLines = content.split('\n').map(l => l.trim()).filter(l => l.length > 0);

  const runs = [];
  let currentRun = [];
  for (const line of rawLines) {
    const parts = line.split(',');
    const label = parts[0].trim().toLowerCase();
    const hasValues = parts.slice(1).some(v => v.trim().length > 0);

    if (label.startsWith('atk') && !label.includes('imparable') && !label.includes('imp') && currentRun.length > 0) {
      runs.push(currentRun);
      currentRun = [];
    }
    if (hasValues || label.length > 0) {
      currentRun.push({ label, values: parts.slice(1).map(v => v.trim()) });
    }
  }
  if (currentRun.length > 0) runs.push(currentRun);

  const turnData = [];
  for (let t = 0; t < 10; t++) {
    turnData.push({ atks: [], undefs: [], tokens: [], counters: [], defs: [], heals: [] });
  }

  for (const run of runs) {
    let maxT = 0;
    for (const row of run) {
      maxT = Math.max(maxT, row.values.length);
    }

    for (let t = 0; t < Math.min(10, maxT); t++) {
      let atkVal = 0, undefVal = 0, tokVal = 0, countVal = 0, defVal = 0, healVal = 0;
      let hasAtk = false, hasUndef = false, hasTok = false, hasCount = false, hasDef = false, hasHeal = false;

      for (const row of run) {
        const val = row.values[t];
        if (val === undefined || val === '') continue;
        const n = parseNumber(val);

        if (row.label.startsWith('atk') && !row.label.includes('imparable') && !row.label.includes('imp')) {
          atkVal += n;
          hasAtk = true;
        } else if (row.label.includes('imparable') || row.label === 'atk imp') {
          undefVal += n;
          hasUndef = true;
        } else if (row.label.startsWith('def') && !row.label.includes('atk')) {
          defVal += n;
          hasDef = true;
        } else if (row.label.includes('contre') || row.label.includes('def atk')) {
          countVal += n;
          hasCount = true;
        } else if (row.label.includes('token') || row.label.includes('brûlure') || row.label.includes('poison') || row.label.includes('bombe') || row.label.includes('forme') || row.label.includes('wound') || row.label.includes('sac degat') || row.label.includes('rps dégât') || row.label.includes('nevermore')) {
          tokVal += n;
          hasTok = true;
        } else if (row.label.includes('heal') || row.label.includes('donuts') || row.label.includes('sac heal')) {
          healVal += n;
          hasHeal = true;
        }
      }

      if (hasAtk || hasUndef || hasTok || hasCount || hasDef || hasHeal) {
        turnData[t].atks.push(atkVal);
        turnData[t].undefs.push(undefVal);
        turnData[t].tokens.push(tokVal);
        turnData[t].counters.push(countVal);
        turnData[t].defs.push(defVal);
        turnData[t].heals.push(healVal);
      }
    }
  }

  const perTurn = [];
  const avg = arr => arr.length === 0 ? 0 : +(arr.reduce((a, b) => a + b, 0) / arr.length).toFixed(1);

  for (let t = 0; t < 10; t++) {
    if (turnData[t].atks.length > 0 || turnData[t].undefs.length > 0) {
      perTurn.push({
        turn: t + 1,
        sampleCount: turnData[t].atks.length,
        avgAtk: avg(turnData[t].atks),
        avgUndef: avg(turnData[t].undefs),
        avgToken: avg(turnData[t].tokens),
        avgCounter: avg(turnData[t].counters),
        avgDef: avg(turnData[t].defs),
        avgHeal: avg(turnData[t].heals)
      });
    }
  }

  perTurnProfiles[heroKey] = perTurn;
}

// Map to hero IDs and variants
const sheetProfiles = {
  blackWidow: {
    active: true,
    selectedVariant: 'v2',
    variants: {
      'v2': { label: 'Black Widow (v2)', turns: perTurnProfiles['black_widow_v2'] }
    }
  },
  loki: {
    active: true,
    selectedVariant: 'standard',
    variants: {
      'standard': { label: 'Loki Standard', turns: perTurnProfiles['loki'] }
    }
  },
  raveness: {
    active: true,
    selectedVariant: 'standard',
    variants: {
      'standard': { label: 'Raveness Standard', turns: perTurnProfiles['raveness'] }
    }
  },
  cursedPirate: {
    active: true,
    selectedVariant: 'v2',
    variants: {
      'v2': { label: 'Pirate (v2)', turns: perTurnProfiles['pirates_v2'] },
      'v1': { label: 'Pirate (v1)', turns: perTurnProfiles['pirate'] }
    }
  },
  druid: {
    active: true,
    selectedVariant: 'equilibre',
    variants: {
      'equilibre': { label: 'Druide Équilibré', turns: perTurnProfiles['druide_equilibre'] },
      'agro': { label: 'Druide Agro', turns: perTurnProfiles['druide_agro'] },
      'survie': { label: 'Druide Survie', turns: perTurnProfiles['druide_survie'] }
    }
  },
  deadpool: {
    active: true,
    selectedVariant: 'standard',
    variants: {
      'standard': { label: 'Deadpool Standard', turns: perTurnProfiles['deadpool'] }
    }
  },
  pyromancer: {
    active: true,
    selectedVariant: 'standard',
    variants: {
      'standard': { label: 'Pyromancienne avec Défense', turns: perTurnProfiles['pyro'] },
      'sans_def': { label: 'Pyromancienne sans Défense', turns: perTurnProfiles['pyro_sans_def'] }
    }
  },
  shadowThief: {
    active: true,
    selectedVariant: 'standard',
    variants: {
      'standard': { label: 'Voleur / Shadow Thief', turns: perTurnProfiles['voleur'] }
    }
  }
};

const heroesFile = path.resolve(__dirname, '..', 'web', 'simulation', 'heroes.js');
const heroesCode = fs.readFileSync(heroesFile, 'utf8');

const heroes = [];
const heroRegex = /id:\s*'([^']+)',\s*name:\s*'([^']+)'/g;
let m;
while ((m = heroRegex.exec(heroesCode)) !== null) {
  heroes.push({ id: m[1], name: m[2] });
}

const fullStats = {};

for (const hero of heroes) {
  if (sheetProfiles[hero.id]) {
    fullStats[hero.id] = {
      heroId: hero.id,
      heroName: hero.name,
      active: true,
      selectedVariant: sheetProfiles[hero.id].selectedVariant,
      variants: sheetProfiles[hero.id].variants
    };
  } else {
    // Default 5 turns template for unconfigured heroes
    fullStats[hero.id] = {
      heroId: hero.id,
      heroName: hero.name,
      active: false,
      selectedVariant: 'standard',
      variants: {
        'standard': {
          label: `${hero.name} Standard`,
          turns: [
            { turn: 1, avgAtk: 5.0, avgUndef: 1.0, avgToken: 0.5, avgCounter: 1.0, avgDef: 1.5, avgHeal: 0.0 },
            { turn: 2, avgAtk: 6.0, avgUndef: 1.5, avgToken: 1.0, avgCounter: 1.0, avgDef: 2.0, avgHeal: 0.0 },
            { turn: 3, avgAtk: 7.0, avgUndef: 2.0, avgToken: 1.5, avgCounter: 1.5, avgDef: 2.0, avgHeal: 0.0 },
            { turn: 4, avgAtk: 7.5, avgUndef: 2.0, avgToken: 1.5, avgCounter: 1.5, avgDef: 2.5, avgHeal: 0.0 },
            { turn: 5, avgAtk: 8.0, avgUndef: 3.0, avgToken: 2.0, avgCounter: 2.0, avgDef: 2.5, avgHeal: 0.0 }
          ]
        }
      }
    };
  }
}

const out1 = path.resolve(__dirname, '..', 'docs', 'hero_simulation_stats.json');
const out2 = path.resolve(__dirname, '..', 'web', 'simulation', 'hero_simulation_stats.json');

fs.writeFileSync(out1, JSON.stringify(fullStats, null, 2) + '\n');
fs.writeFileSync(out2, JSON.stringify(fullStats, null, 2) + '\n');

console.log('Successfully generated per-turn stats for all heroes in docs/ and web/simulation/');
