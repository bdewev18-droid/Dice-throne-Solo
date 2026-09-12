const fs = require('fs');
const path = require('path');

const heroesFile = path.resolve(__dirname, '..', 'web', 'simulation', 'heroes.js');
const heroesCode = fs.readFileSync(heroesFile, 'utf8');

// Extract DTS_HEROES array
const heroes = [];
const heroRegex = /id:\s*'([^']+)',\s*name:\s*'([^']+)'/g;
let m;
while ((m = heroRegex.exec(heroesCode)) !== null) {
  heroes.push({ id: m[1], name: m[2] });
}

// Initial known sheet profiles
const sheetProfiles = {
  blackWidow: {
    active: true,
    selectedVariant: 'v2',
    variants: {
      'v2': { label: 'Black Widow (v2)', avgAtk: 6.29, avgUndef: 2.19, avgToken: 2.10, avgCounter: 1.57, avgDef: 2.21, avgHeal: 0.0 }
    }
  },
  loki: {
    active: true,
    selectedVariant: 'standard',
    variants: {
      'standard': { label: 'Loki Standard', avgAtk: 3.50, avgUndef: 4.50, avgToken: 1.00, avgCounter: 0.0, avgDef: 1.00, avgHeal: 1.33 }
    }
  },
  raveness: {
    active: true,
    selectedVariant: 'standard',
    variants: {
      'standard': { label: 'Raveness Standard', avgAtk: 3.10, avgUndef: 2.52, avgToken: 0.0, avgCounter: 2.43, avgDef: 1.48, avgHeal: 1.86 }
    }
  },
  cursedPirate: {
    active: true,
    selectedVariant: 'v2',
    variants: {
      'v2': { label: 'Pirate (v2)', avgAtk: 5.96, avgUndef: 2.46, avgToken: 1.63, avgCounter: 1.96, avgDef: 2.17, avgHeal: 0.0 },
      'v1': { label: 'Pirate (v1)', avgAtk: 12.77, avgUndef: 0.0, avgToken: 0.0, avgCounter: 0.0, avgDef: 4.54, avgHeal: 0.0 }
    }
  },
  druid: {
    active: true,
    selectedVariant: 'equilibre',
    variants: {
      'equilibre': { label: 'Druide Équilibré', avgAtk: 5.83, avgUndef: 0.58, avgToken: 2.75, avgCounter: 1.00, avgDef: 1.50, avgHeal: 0.0 },
      'agro': { label: 'Druide Agro', avgAtk: 5.74, avgUndef: 1.39, avgToken: 3.43, avgCounter: 1.74, avgDef: 1.91, avgHeal: 0.0 },
      'survie': { label: 'Druide Survie', avgAtk: 5.56, avgUndef: 2.34, avgToken: 0.91, avgCounter: 1.66, avgDef: 2.44, avgHeal: 0.0 }
    }
  },
  deadpool: {
    active: true,
    selectedVariant: 'standard',
    variants: {
      'standard': { label: 'Deadpool Standard', avgAtk: 3.14, avgUndef: 3.56, avgToken: 1.06, avgCounter: 1.06, avgDef: 0.50, avgHeal: 2.64 }
    }
  },
  pyromancer: {
    active: true,
    selectedVariant: 'standard',
    variants: {
      'standard': { label: 'Pyromancienne avec Défense', avgAtk: 3.44, avgUndef: 6.94, avgToken: 0.63, avgCounter: 2.38, avgDef: 1.31, avgHeal: 0.0 },
      'sans_def': { label: 'Pyromancienne sans Défense', avgAtk: 3.04, avgUndef: 6.44, avgToken: 1.52, avgCounter: 0.0, avgDef: 0.0, avgHeal: 0.0 }
    }
  },
  shadowThief: {
    active: true,
    selectedVariant: 'standard',
    variants: {
      'standard': { label: 'Voleur / Shadow Thief', avgAtk: 5.04, avgUndef: 1.68, avgToken: 1.52, avgCounter: 0.44, avgDef: 0.48, avgHeal: 0.0 }
    }
  }
};

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
    fullStats[hero.id] = {
      heroId: hero.id,
      heroName: hero.name,
      active: false,
      selectedVariant: 'standard',
      variants: {
        'standard': {
          label: `${hero.name} Standard`,
          avgAtk: 6.0,
          avgUndef: 1.5,
          avgToken: 1.0,
          avgCounter: 1.0,
          avgDef: 2.0,
          avgHeal: 0.0
        }
      }
    };
  }
}

const out1 = path.resolve(__dirname, '..', 'docs', 'hero_simulation_stats.json');
const out2 = path.resolve(__dirname, '..', 'web', 'simulation', 'hero_simulation_stats.json');

fs.writeFileSync(out1, JSON.stringify(fullStats, null, 2) + '\n');
fs.writeFileSync(out2, JSON.stringify(fullStats, null, 2) + '\n');

console.log(`Generated full stats for ${Object.keys(fullStats).length} heroes.`);
console.log(`Active heroes in simulator: ${Object.values(fullStats).filter(h => h.active).map(h => h.heroName).join(', ')}`);
