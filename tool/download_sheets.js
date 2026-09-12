const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const gids = {
  "black_widow_v2": "1473748382",
  "loki": "63048052",
  "raveness": "1530406691",
  "pirate": "1338236361",
  "pirates_v2": "1451827057",
  "druide_agro": "147267957",
  "druide_survie": "950560443",
  "deadpool": "1362741118",
  "pyro": "1075174033",
  "pyro_sans_def": "1753557223",
  "druide_equilibre": "1093084440",
  "voleur": "1815310751"
};

const outDir = 'd:/app/DTS/web/simulation/sheets';
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

for (const [name, gid] of Object.entries(gids)) {
  const url = `https://docs.google.com/spreadsheets/d/1mvQbg2AnvR6Y4O7W497N-XrhRCgqUfrKN1-1GT1Thtw/export?format=csv&gid=${gid}`;
  const outFile = path.join(outDir, `${name}.csv`);
  console.log(`Downloading ${name} (gid=${gid})...`);
  try {
    execSync(`curl.exe -s -L "${url}" -o "${outFile}"`);
    console.log(`Saved ${outFile}`);
  } catch (e) {
    console.error(`Error downloading ${name}:`, e.message);
  }
}
