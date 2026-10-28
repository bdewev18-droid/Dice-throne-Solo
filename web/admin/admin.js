
const SUPABASE_URL = 'https://rqxfjffwzdfefinfcxjo.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_3EuoFYUzqUvNX7IPrhZKpQ_mkW-Gl97';
let supabaseClient = null;

// Global event listener for token inputs (Event Delegation)
document.addEventListener('click', (e) => {
  if (e.target && e.target.matches && e.target.matches('input.token-input')) {
    openTokenModal(e.target);
  }
});

async function initAuth() {
  if (!window.supabase) {
    $('authError').textContent = 'Supabase non chargé.';
    $('mainAppShell').style.display = 'grid';
    $('authOverlay').style.display = 'none';
    return;
  }
  supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  
  $('googleLoginBtn').onclick = async (e) => {
    e.preventDefault();
    try {
      $('authError').textContent = 'Connexion en cours...';
      const { error } = await supabaseClient.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: window.location.origin + window.location.pathname
        }
      });
      if (error) $('authError').textContent = error.message;
    } catch (err) {
      $('authError').textContent = 'Erreur JS: ' + err.message;
      console.error(err);
    }
  };
  
  $('logoutBtn').onclick = async () => {
    try {
      await supabaseClient.auth.signOut();
    } catch (e) {
      console.error(e);
    }
  };

  try {
    const { data: { session } } = await supabaseClient.auth.getSession();
    checkSession(session);
  } catch (err) {
    console.error("Auth init error:", err);
    // Clear corrupted token if present
    try {
      localStorage.removeItem('sb-rqxfjffwzdfefinfcxjo-auth-token');
    } catch(e) {}
    checkSession(null);
  }
  
  try {
    supabaseClient.auth.onAuthStateChange((event, session) => {
      checkSession(session);
    });
  } catch (err) {
    console.error("AuthStateChange error:", err);
  }
}

function checkSession(session) {
  if (!session) {
    $('mainAppShell').style.display = 'none';
    $('authOverlay').style.display = 'grid';
  } else {
    const email = session.user?.email;
    if (email !== 'bdewev18@gmail.com') {
      $('authError').textContent = 'Unauthorized email: ' + email;
      $('mainAppShell').style.display = 'none';
      $('authOverlay').style.display = 'grid';
    } else {
      $('mainAppShell').style.display = 'grid';
      $('authOverlay').style.display = 'none';
      if ($('userEmailDisplay')) $('userEmailDisplay').textContent = email;
    }
  }
}

const rankOrder = ['green', 'blue', 'violet', 'orange', 'viseer', 'naraxus'];
const rankLabels = {
  green: 'Green',
  blue: 'Blue',
  violet: 'Violet',
  orange: 'Orange',
  viseer: 'Viseer',
  naraxus: 'Boss',
};

let sourceData = null;
let selectedProfile = null;
let selectedIndex = -1;
let fileHandle = null;
let devBacklog = [];
let tokenCatalog = [];
let tokenSourceData = null;
let tokenDatalistReady = false;
let enemyDirty = false;
let tokenDirty = false;

const $ = (id) => document.getElementById(id);
const clone = (value) => JSON.parse(JSON.stringify(value));
const intVal = (value, fallback = 0) =>
  Number.isFinite(Number(value)) ? Number(value) : fallback;
const csv = (value) =>
  String(value || '')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
function setDirty(kind, value = true) {
  if (kind === 'token') tokenDirty = value;
  if (kind === 'enemy') enemyDirty = value;
  updateDownloadButtons();
}
function updateDownloadButtons() {
  const enemyButton = $('exportJsonBtn');
  const tokenButton = $('exportTokenJsonBtn');
  if (enemyButton) {
    enemyButton.textContent = enemyDirty ? 'Download enemy JSON *' : 'Download enemy JSON';
    enemyButton.classList.toggle('dirty', enemyDirty);
  }
  if (tokenButton) {
    tokenButton.textContent = tokenDirty ? 'Download token JSON *' : 'Download token JSON';
    tokenButton.classList.toggle('dirty', tokenDirty);
  }
}
function appBaseUrl() {
  return location.pathname.includes('/Dice-throne-Solo/')
    ? `${location.origin}/Dice-throne-Solo`
    : location.origin;
}
async function loadTokenCatalog() {
  const candidates = [
    appBaseUrl() + '/assets/assets/data/token_catalog.json',
    '../assets/data/token_catalog.json',
    '../../assets/data/token_catalog.json',
  ];
  for (const url of candidates) {
    try {
      const response = await fetch(url, { cache: 'no-store' });
      if (!response.ok) continue;
      const data = await response.json();
      tokenSourceData = data && !Array.isArray(data) ? data : { version: 1, tokens: Array.isArray(data) ? data : [], heroTokens: {} };
      tokenCatalog = Array.isArray(tokenSourceData.tokens) ? tokenSourceData.tokens : [];
      ensureTokenDatalist();
      renderTokenAdmin();
      return;
    } catch {}
  }
}

function ensureTokenDatalist() {
  tokenDatalistReady = true;
}

let activeTokenInput = null;



function openTokenModal(input) {
  activeTokenInput = input;
  const currentTokens = input.value.split(',').map(t => t.trim()).filter(Boolean);
  const container = $('tokenCheckboxes');
  container.innerHTML = '';

  const sortedTokens = [...tokenCatalog].sort((a, b) => {
    const la = (a.label || '').toLowerCase();
    const lb = (b.label || '').toLowerCase();
    return la.localeCompare(lb, 'fr');
  });

  sortedTokens.forEach(token => {
    const label = document.createElement('label');
    label.className = 'token-option';
    label.style.display = 'flex';
    label.style.alignItems = 'center';
    label.style.gap = '10px';
    label.style.padding = '6px 8px';
    label.style.borderRadius = '4px';
    label.style.cursor = 'pointer';
    label.style.transition = 'background 0.15s ease';

    label.onmouseenter = () => label.style.background = 'rgba(255,255,255,0.08)';
    label.onmouseleave = () => label.style.background = 'transparent';

    const cb = document.createElement('input');
    cb.type = 'checkbox';
    cb.value = token.label;
    cb.checked = currentTokens.includes(token.label);
    cb.style.margin = '0';
    cb.style.width = '16px';
    cb.style.height = '16px';
    cb.style.flexShrink = '0';
    cb.style.cursor = 'pointer';

    const textSpan = document.createElement('span');
    textSpan.style.fontSize = '14px';
    textSpan.style.color = '#e0e0e0';

    let displayTxt = token.label;
    if (token.frLabel) {
      displayTxt += ` (${token.frLabel})`;
    }
    textSpan.textContent = displayTxt;

    label.appendChild(cb);
    label.appendChild(textSpan);
    container.appendChild(label);
  });

  const searchInput = $('tokenSearchInput');
  if (searchInput) {
    searchInput.value = '';
    searchInput.oninput = () => {
      const q = searchInput.value.trim().toLowerCase();
      container.querySelectorAll('.token-option').forEach(opt => {
        const txt = opt.textContent.toLowerCase();
        opt.style.display = (!q || txt.includes(q)) ? 'flex' : 'none';
      });
    };
  }

  $('tokenModal').style.display = 'flex';
  if (searchInput) {
    setTimeout(() => searchInput.focus(), 60);
  }
}

function onTokenInputChanged(e) {
  validateTokenInput(e.target);
}

function validateTokenInput(inputEl) {
  const val = inputEl.value.trim();
  if (!val) {
    inputEl.style.backgroundColor = '';
    return;
  }
  const validTokens = tokenCatalog.map(t => t.label);
  const tokens = val.split(',').map(t => t.trim()).filter(Boolean);
  const allValid = tokens.length > 0 && tokens.every(t => validTokens.includes(t));
  if (allValid) {
    inputEl.style.backgroundColor = '#1e4620';
  } else {
    inputEl.style.backgroundColor = '#5c3a10';
  }
}

function assetUrl(asset) {
  if (!asset) return '';
  if (/^https?:\/\//i.test(asset)) return asset;
  const normalized = String(asset).replace(/^\/+/, '').replace(/^assets\//, '');
  return `${appBaseUrl()}/assets/assets/${normalized}`;
}

function getPreviewAssetUrl(profile) {
  if (!profile || !profile.cardAsset) return '';
  if (profile.key === 'naraxus') return assetUrl('assets/enemy_previews/naraxus.webp');
  if (profile.key === 'kaelen-voss') return assetUrl('assets/enemy_previews/kaelen-voss.webp');
  if (profile.key === 'viseer') return assetUrl('assets/enemy_previews/orange-viseer.webp');
  if (profile.key === 'rat-de-la-rue') return assetUrl('assets/enemy_previews/rat-de-la-rue.webp');
  
  const filename = profile.cardAsset.split('/').pop();
  const base = filename.split('.')[0].toLowerCase();
  
  const legacyMap = {
    'enemy_green_fairy': 'vert-001',
    'enemy_green_ronin': 'vert-002',
    'enemy_green_goblin_enchanter': 'vert-003',
    'enemy_green_shadow_archer': 'vert-004',
    'enemy_green_feline_shadow': 'vert-005',
    'enemy_green_lost_fencer': 'vert-006',
    'enemy_green_chaos_elf': 'vert-007',
    'enemy_green_raving_oni': 'vert-008'
  };
  
  if (legacyMap[base]) {
    return assetUrl('assets/enemy_previews/' + legacyMap[base] + '.webp');
  }
  
  return assetUrl('assets/enemy_previews/' + base + '.webp');
}

function defaultAction() {
  return {
    condition: { type: 'symbols', symbols: { white: 0, orange: 0, red: 0 } },
    label: '',
    damage: 0,
    undefendable: false,
    stealHp: 0,
    loseHp: 0,
    stealCp: 0,
    heal: 0,
    drawCards: 0,
    discardCards: 0,
    topDeckToDiscard: 0,
    tokens: [],
    formulas: [],
    extraRoll: null,
    notes: [],
  };
}

function defaultDefense() {
  return {
    condition: {
      type: 'symbols',
      symbols: { white: 0, orange: 0, red: 0 },
      repeat: false,
    },
    prevent: 0,
    returnDamage: 0,
    undefendable: false,
    stealHp: 0,
    loseHp: 0,
    stealCp: 0,
    heal: 0,
    drawCards: 0,
    discardCards: 0,
    tokens: [],
    formulas: [],
  };
}

function syncJsonVersionUI() {
  const input = $('jsonVersionInput');
  if (!input) return;
  const currentVersion = sourceData?.version || '1.0.0';
  input.value = currentVersion;
}

function incrementSemver(ver) {
  if (!ver || typeof ver !== 'string') return '1.0.1';
  const parts = ver.trim().split('.');
  if (parts.length === 3 && !isNaN(Number(parts[2]))) {
    return `${parts[0]}.${parts[1]}.${Number(parts[2]) + 1}`;
  }
  if (parts.length === 2 && !isNaN(Number(parts[1]))) {
    return `${parts[0]}.${Number(parts[1]) + 1}`;
  }
  const match = ver.match(/\d+$/);
  if (match) {
    const nextNum = Number(match[0]) + 1;
    return ver.slice(0, match.index) + nextNum;
  }
  return `${ver}.1`;
}

const IGNORED_MAP_KEYS = new Set(['green-fallback', 'blue-generic', 'violet-generic', 'orange-generic']);

function sanitizeLoadedProfiles() {
  if (sourceData?.profiles) {
    sourceData.profiles = sourceData.profiles.filter(p => !IGNORED_MAP_KEYS.has(p.key));
  }
}

async function loadDefault() {
  const candidates = [
    `${appBaseUrl()}/assets/docs/enemy_profiles.json`,
    '../assets/docs/enemy_profiles.json',
    '../../assets/docs/enemy_profiles.json',
    '../docs/enemy_profiles.json',
    '../../docs/enemy_profiles.json',
  ];
  let lastError = '';
  for (const url of candidates) {
    try {
      const response = await fetch(url, { cache: 'no-store' });
      if (response.ok) {
        sourceData = await response.json();
        sanitizeLoadedProfiles();
        setDirty('enemy', false);
        syncJsonVersionUI();
        if (location.hostname === '127.0.0.1' || location.hostname === 'localhost') {
          $('saveFileBtn').disabled = false;
        }
        renderLists();
        selectFirst();
        return;
      }
      lastError = `${response.status} ${url}`;
    } catch (error) {
      lastError = error.message;
    }
  }
  alert(`Unable to load enemy_profiles.json. Try Open local JSON. ${lastError}`);
}

async function openLocalJson() {
  if (!window.showOpenFilePicker) {
    alert('Your browser cannot save directly. Use Download JSON after edits.');
    return;
  }
  const [handle] = await showOpenFilePicker({
    types: [
      {
        description: 'Enemy profiles JSON',
        accept: { 'application/json': ['.json'] },
      },
    ],
  });
  fileHandle = handle;
  const file = await handle.getFile();
  sourceData = JSON.parse(await file.text());
  sanitizeLoadedProfiles();
  setDirty('enemy', false);
  syncJsonVersionUI();
  $('saveFileBtn').disabled = false;
  renderLists();
  selectFirst();
}

function ensureAllProfilesDisplayRows() {
  if (!sourceData?.profiles) return;
  for (const p of sourceData.profiles) {
    if (p.attackPlan?.style === 'symbols' && p.attackPlan.actions?.length) {
      p.attackPlan.goals ||= [];
      const existing = new Set(p.attackPlan.goals.map(g => `${g.white || 0},${g.orange || g.yellow || 0},${g.red || 0}`));
      for (const action of p.attackPlan.actions) {
        if (action.condition?.type === 'symbols' && action.condition.symbols) {
          const sym = action.condition.symbols;
          const key = `${sym.white || 0},${sym.orange || sym.yellow || 0},${sym.red || 0}`;
          if (!existing.has(key)) {
            existing.add(key);
            p.attackPlan.goals.push({
              white: sym.white || 0,
              orange: sym.orange || sym.yellow || 0,
              red: sym.red || 0
            });
          }
        }
      }
    }
  }
}

async function saveLocalFile() {
  if (location.hostname === '127.0.0.1' || location.hostname === 'localhost') {
    collectCurrent();
    ensureAllProfilesDisplayRows();
    if (originalSelectedProfile && selectedProfile) {
      computeDiffAndLog(originalSelectedProfile, selectedProfile);
      originalSelectedProfile = clone(selectedProfile);
    }
    const inputVal = $('jsonVersionInput')?.value.trim();
    const nextVer = inputVal || incrementSemver(sourceData.version);
    sourceData.version = nextVer;
    syncJsonVersionUI();
    try {
      const response = await fetch('/api/save-enemy', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(sourceData)
      });
      if (!response.ok) throw new Error('Save failed');
      setDirty('enemy', false);
      $('saveFileBtn').disabled = true;
      flash(`Saved locally via API! (JSON v${nextVer})`);
      return;
    } catch (e) {
      console.error('Direct save failed, falling back', e);
    }
  }

  if (!fileHandle || !sourceData) return;
  collectCurrent();
  ensureAllProfilesDisplayRows();
  if (originalSelectedProfile && selectedProfile) {
    computeDiffAndLog(originalSelectedProfile, selectedProfile);
    originalSelectedProfile = clone(selectedProfile);
  }
  const inputVal = $('jsonVersionInput')?.value.trim();
  const nextVer = inputVal || incrementSemver(sourceData.version);
  sourceData.version = nextVer;
  syncJsonVersionUI();
  const writable = await fileHandle.createWritable();
  await writable.write(JSON.stringify(sourceData, null, 2) + '\n');
  await writable.close();
  setDirty('enemy', false);
  flash(`Saved local JSON file. (JSON v${nextVer})`);
}

function download(name, text) {
  const blob = new Blob([text], { type: 'application/json' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = name;
  link.click();
  URL.revokeObjectURL(link.href);
}

function exportJson() {
  if (!sourceData) return;
  collectCurrent();
  ensureAllProfilesDisplayRows();
  if (originalSelectedProfile && selectedProfile) {
    computeDiffAndLog(originalSelectedProfile, selectedProfile);
    originalSelectedProfile = clone(selectedProfile);
  }
  // Auto-increment version on export
  const currentVer = $('jsonVersionInput')?.value.trim() || sourceData.version || '1.0.0';
  const nextVer = incrementSemver(currentVer);
  sourceData.version = nextVer;
  syncJsonVersionUI();
  download('enemy_profiles.json', JSON.stringify(sourceData, null, 2) + '\n');
  setDirty('enemy', false);
  flash(`Exported JSON v${nextVer}`);
}

function exportTokenJson() {
  if (!tokenSourceData) return;
  collectTokensFromAdmin();
  tokenSourceData.tokens = tokenCatalog;
  download('token_catalog.json', JSON.stringify(tokenSourceData, null, 2) + '\n');
  setDirty('token', false);
}

// exportDev removed
function flash(text) {
  $('enemyMeta').textContent = text;
  setTimeout(renderMeta, 1800);
}

function isAtkValid(p) {
  if (!p) return false;
  if (typeof p.validatedAtk === 'boolean') return p.validatedAtk;
  return !!p.validated;
}

function isDefValid(p) {
  if (!p) return false;
  if (typeof p.validatedDef === 'boolean') return p.validatedDef;
  return false;
}

function updateValidationButtons() {
  const atkBtn = $('validateAtkBtn');
  const defBtn = $('validateDefBtn');
  if (!atkBtn || !defBtn) return;
  if (!selectedProfile) {
    atkBtn.disabled = true;
    defBtn.disabled = true;
    atkBtn.className = 'ghost-btn validate-btn';
    defBtn.className = 'ghost-btn validate-btn';
    atkBtn.innerHTML = '⚔️ Atk validate';
    defBtn.innerHTML = '🛡️ Def validate';
    return;
  }
  atkBtn.disabled = false;
  defBtn.disabled = false;
  const atkValid = isAtkValid(selectedProfile);
  const defValid = isDefValid(selectedProfile);

  if (atkValid) {
    atkBtn.className = 'validate-btn valid';
    atkBtn.innerHTML = '✅ Atk validate';
  } else {
    atkBtn.className = 'ghost-btn validate-btn';
    atkBtn.innerHTML = '❌ Atk validate';
  }

  if (defValid) {
    defBtn.className = 'validate-btn valid';
    defBtn.innerHTML = '✅ Def validate';
  } else {
    defBtn.className = 'ghost-btn validate-btn';
    defBtn.innerHTML = '❌ Def validate';
  }
}

function toggleValidateAtk() {
  if (!selectedProfile || selectedIndex < 0) return;
  collectCurrent();
  const currentAtk = isAtkValid(selectedProfile);
  const currentDef = isDefValid(selectedProfile);
  selectedProfile.validatedAtk = !currentAtk;
  selectedProfile.validatedDef = currentDef;
  selectedProfile.validated = selectedProfile.validatedAtk && selectedProfile.validatedDef;
  sourceData.profiles[selectedIndex] = clone(selectedProfile);
  setDirty('enemy');
  updateValidationButtons();
  renderLists();
}

function toggleValidateDef() {
  if (!selectedProfile || selectedIndex < 0) return;
  collectCurrent();
  const currentAtk = isAtkValid(selectedProfile);
  const currentDef = isDefValid(selectedProfile);
  selectedProfile.validatedAtk = currentAtk;
  selectedProfile.validatedDef = !currentDef;
  selectedProfile.validated = selectedProfile.validatedAtk && selectedProfile.validatedDef;
  sourceData.profiles[selectedIndex] = clone(selectedProfile);
  setDirty('enemy');
  updateValidationButtons();
  renderLists();
}

function renderLists() {
  const root = $('enemyLists');
  root.innerHTML = '';
  const query = $('enemySearch').value.trim().toLowerCase();
  const allProfiles = sourceData?.profiles || [];
  
  let globalValidPoints = 0;
  for (const p of allProfiles) {
    if (isAtkValid(p)) globalValidPoints++;
    if (isDefValid(p)) globalValidPoints++;
  }
  const globalTotalPoints = allProfiles.length * 2;
  const globalPct = globalTotalPoints ? Math.round(globalValidPoints * 100 / globalTotalPoints) : 0;
  if ($('validationProgress')) {
    $('validationProgress').textContent = allProfiles.length ? `${globalPct}% validated` : '';
    $('validationProgress').title = `${globalValidPoints} / ${globalTotalPoints} validations (Atk + Def)`;
  }

  for (const rank of rankOrder) {
    const profiles = allProfiles
      .map((profile, index) => ({ profile, index }))
      .filter(({ profile }) => profile.rank === rank)
      .filter(
        ({ profile }) =>
          !query || `${profile.name} ${profile.key}`.toLowerCase().includes(query),
      );
    if (!profiles.length) continue;
    
    let groupValidPoints = 0;
    for (const { profile } of profiles) {
      if (isAtkValid(profile)) groupValidPoints++;
      if (isDefValid(profile)) groupValidPoints++;
    }
    const groupTotalPoints = profiles.length * 2;
    const groupPct = groupTotalPoints ? Math.round(groupValidPoints * 100 / groupTotalPoints) : 0;

    const group = document.createElement('section');
    group.className = 'rank-group';
    const head = document.createElement('button');
    head.className = `rank-head ${rank}`;
    head.innerHTML = `<span>${rankLabels[rank]} <span class="rank-head-percent">${groupPct}%</span></span><span>${profiles.length}</span>`;
    const items = document.createElement('div');
    items.className = 'rank-items';
    head.onclick = () => {
      items.classList.toggle('hidden');
    };
    for (const { profile, index } of profiles) {
      const button = document.createElement('button');
      button.className = 'enemy-btn';
      if (index === selectedIndex) button.classList.add('active');
      let prefix = '';
      if (profile.rank !== 'naraxus' && profile.cardAsset) {
        prefix = profile.cardAsset.split('/').pop().replace('.png', '').replace('.webp', '') + ' ';
      }
      const atk = isAtkValid(profile);
      const def = isDefValid(profile);
      let validIcon = '❌ ';
      if (atk && def) {
        validIcon = '🟩 ';
      } else if (atk || def) {
        validIcon = '🟠 ';
      }
      button.textContent = validIcon + prefix + (profile.name || profile.key);
      button.onclick = () => selectProfile(index);
      items.appendChild(button);
    }
    group.append(head, items);
    root.appendChild(group);
  }
}

function selectFirst() {
  const index = (sourceData?.profiles || []).findIndex((profile) =>
    rankOrder.includes(profile.rank),
  );
  if (index >= 0) selectProfile(index);
}

let originalSelectedProfile = null;

function selectProfile(index) {
  collectCurrent();
  if (originalSelectedProfile && selectedProfile) {
    computeDiffAndLog(originalSelectedProfile, selectedProfile);
  }
  selectedIndex = index;
  selectedProfile = clone(sourceData.profiles[index]);
  originalSelectedProfile = clone(selectedProfile);
  renderLists();
  renderEditor();
}

function computeDiffAndLog(original, current) {
  if (!original || !current) return;
  if (original.key !== current.key && !current.name) return; // safeguard

  const changes = [];
  const addChange = (field, oldVal, newVal) => {
    if (JSON.stringify(oldVal) !== JSON.stringify(newVal)) {
      changes.push(`${field} de ${JSON.stringify(oldVal)} vers ${JSON.stringify(newVal)}`);
    }
  };

  addChange('hp', original.maxHealth, current.maxHealth);
  addChange('cp', original.cp, current.cp);
  addChange('defenseDice', original.defenseDice, current.defenseDice);
  addChange('rewardChests', original.rewardChests, current.rewardChests);
  addChange('rewardRank', original.rewardRank, current.rewardRank);
  addChange('cardAsset', original.cardAsset, current.cardAsset);
  addChange('initialTokens', original.initialTokens, current.initialTokens);

  if (JSON.stringify(original.attackPlan) !== JSON.stringify(current.attackPlan)) {
    changes.push(`attaque modifiée`);
  }
  if (JSON.stringify(original.defensePlan) !== JSON.stringify(current.defensePlan)) {
    changes.push(`défense modifiée`);
  }
  if (JSON.stringify(original.passives) !== JSON.stringify(current.passives)) {
    changes.push(`passifs modifiés`);
  }
  if (JSON.stringify(original.attacks) !== JSON.stringify(current.attacks)) {
    changes.push(`titre d'attaque modifié`);
  }
  if (original.defense !== current.defense) {
    changes.push(`titre de défense modifié`);
  }
  if (original.name !== current.name) {
    changes.push(`name de "${original.name}" vers "${current.name}"`);
  }
  if (isAtkValid(original) !== isAtkValid(current)) {
    changes.push(`validation Atk: ${isAtkValid(current) ? 'validé' : 'non validé'}`);
  }
  if (isDefValid(original) !== isDefValid(current)) {
    changes.push(`validation Def: ${isDefValid(current) ? 'validé' : 'non validé'}`);
  }

  if (changes.length > 0) {
    const logEntry = {
      date: new Date().toISOString(),
      minion: current.name || current.key,
      changes: changes
    };
    saveLogEntry(logEntry);
  }
}

function saveLogEntry(entry) {
  let logs = [];
  try {
    logs = JSON.parse(localStorage.getItem('admin_logs') || '[]');
  } catch(e) {}
  logs.unshift(entry);
  if (logs.length > 500) logs = logs.slice(0, 500);
  localStorage.setItem('admin_logs', JSON.stringify(logs));
  renderLogs();
}

function renderLogs() {
  const container = $('adminLogList');
  if (!container) return;
  let logs = [];
  try {
    logs = JSON.parse(localStorage.getItem('admin_logs') || '[]');
  } catch(e) {}
  if (logs.length === 0) {
    container.innerHTML = '<p>Aucun log.</p>';
    return;
  }
  container.innerHTML = logs.map(l => {
    const d = new Date(l.date);
    const dateStr = d.toLocaleDateString() + ' ' + d.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'});
    const changesHtml = l.changes.map(c => `<li>${escapeAttr(c)}</li>`).join('');
    return `<div class="action-card" style="padding: 8px;">
      <div style="font-weight: bold; color: #888; font-size: 12px;">${dateStr} - Minion "${escapeAttr(l.minion)}"</div>
      <ul style="margin: 4px 0 0 20px; font-size: 13px;">${changesHtml}</ul>
    </div>`;
  }).join('');
}

$('clearLogsBtn')?.addEventListener('click', () => {
  if (confirm('Vider le journal de bord ?')) {
    localStorage.removeItem('admin_logs');
    renderLogs();
  }
});

function renderMeta() {
  if (!selectedProfile) return;
  $('enemyMeta').textContent = `${selectedProfile.rank} • ${selectedProfile.maxHealth} HP • ${selectedProfile.cp} CP • ${selectedProfile.key}`;
}

function setValue(id, value) {
  $(id).value = value ?? '';
}

function renderEditor() {
  if (!selectedProfile) {
    $('emptyState').classList.remove('hidden');
    $('editorState').classList.add('hidden');
    return;
  }
  $('emptyState').classList.add('hidden');
  $('editorState').classList.remove('hidden');
  $('enemyTitle').textContent = selectedProfile.name;
  renderMeta();
  const previewUrl = getPreviewAssetUrl(selectedProfile);
  if (selectedProfile.rank === 'naraxus' && previewUrl) {
    $('cardImage').src = previewUrl;
  } else {
    $('cardImage').src = assetUrl(selectedProfile.cardAsset);
  }
  
  if (previewUrl && $('previewImage')) {
    $('previewImage').src = previewUrl;
    $('previewImage').style.display = 'block';
  } else if ($('previewImage')) {
    $('previewImage').style.display = 'none';
  }

  $('previewName').textContent = selectedProfile.name;

  setValue('nameInput', selectedProfile.name);
  setValue('keyInput', selectedProfile.key);
  setValue('rankInput', selectedProfile.rank);
  setValue('hpInput', selectedProfile.maxHealth);
  setValue('cpInput', selectedProfile.cp);
  setValue(
    'defenseDiceInput',
    selectedProfile.defenseDice || selectedProfile.defensePlan?.dice || 0,
  );
  setValue('rewardChestsInput', selectedProfile.rewardChests || 0);
  setValue('rewardRankInput', selectedProfile.rewardRank || '');
  setValue('cardAssetInput', selectedProfile.cardAsset || '');
  const uniqueInitialTokens = [...new Set(selectedProfile.initialTokens || [])];
  setValue('initialTokensInput', uniqueInitialTokens.join(', '));
  setValue('initialTokensNbInput', resolveInitialTokensCountDisplay(selectedProfile));
  setValue('sourcePackInput', selectedProfile.sourcePack || 'dta');
  $('initialTokensInput').classList.add('token-input');
  
  selectedProfile.attackPlan ||= {
    style: 'symbols',
    goals: [],
    name: '',
    actions: [],
    conditionalRules: [],
    passives: [],
    notes: [],
  };
  setValue('attackStyleInput', selectedProfile.attackPlan.style || 'symbols');
  setValue(
    'attackNameInput',
    selectedProfile.attackPlan.name || selectedProfile.attacks?.[0] || '',
  );
  setValue('attacksTextInput', (selectedProfile.attacks || []).join('\n'));
  setValue('defenseTextInput', selectedProfile.defense || '');
  setValue('passivesTextInput', JSON.stringify(selectedProfile.passives || [], null, 2));
  setValue('attacksDisplayRowsInput', JSON.stringify(selectedProfile.attackPlan?.displayRows || [], null, 2));
  setValue('defenseDisplayRowsInput', JSON.stringify(selectedProfile.defensePlan?.displayRows || [], null, 2));
  setValue('passivesDisplayRowsInput', JSON.stringify(selectedProfile.passiveDisplayRows || [], null, 2));

  renderActions();
  renderDefense();
  renderConditionalRules();
  renderPassiveRules();
  renderPreview();
  renderDisplayRowsPreviews();
  renderFormulaList();
  renderTokenAdmin();
  updateTabDots();
  validateTokens();
  updateRewardWarnings();
  updateValidationButtons();
}

function collectCurrent() {
  if (!selectedProfile || selectedIndex < 0 || !sourceData) return;
  selectedProfile.name = $('nameInput').value.trim();
  selectedProfile.key = $('keyInput').value.trim();
  selectedProfile.rank = $('rankInput').value;
  selectedProfile.maxHealth = intVal($('hpInput').value);
  selectedProfile.cp = intVal($('cpInput').value);
  selectedProfile.defenseDice = intVal($('defenseDiceInput').value);
  selectedProfile.rewardChests = intVal($('rewardChestsInput').value);
  selectedProfile.rewardRank = $('rewardRankInput').value.trim() || null;
  selectedProfile.cardAsset = $('cardAssetInput').value.trim();
  const rawInitialTokens = csv($('initialTokensInput').value);
  const nbInitialVal = $('initialTokensNbInput')?.value?.trim();
  if (rawInitialTokens.length > 0) {
    const parsedNb = intVal(nbInitialVal, 1);
    const count = parsedNb > 0 ? parsedNb : 1;
    if (count > 1) {
      selectedProfile.initialTokenCount = count;
      if (rawInitialTokens.length === 1) {
        selectedProfile.initialTokens = Array(count).fill(rawInitialTokens[0]);
      } else {
        selectedProfile.initialTokens = rawInitialTokens;
      }
    } else {
      selectedProfile.initialTokenCount = 1;
      selectedProfile.initialTokens = rawInitialTokens;
    }
  } else {
    selectedProfile.initialTokens = [];
    delete selectedProfile.initialTokenCount;
  }
  selectedProfile.sourcePack = $('sourcePackInput').value || 'dta';
  selectedProfile.attacks = $('attacksTextInput').value
    .split('\n')
    .map((line) => line.trim())
    .filter(Boolean);
  selectedProfile.defense = $('defenseTextInput').value.trim();
  try {
    selectedProfile.passives = JSON.parse($('passivesTextInput').value || '[]');
  } catch {
    // Keep the previous passives when the editable JSON is temporarily invalid.
  }
  selectedProfile.attackPlan ||= {};
  selectedProfile.attackPlan.displayRows = parseDisplayRowsText($('attacksDisplayRowsInput')?.value || '');
  selectedProfile.defensePlan ||= { dice: selectedProfile.defenseDice, effects: [], notes: [] };
  selectedProfile.defensePlan.displayRows = parseDisplayRowsText($('defenseDisplayRowsInput')?.value || '');
  selectedProfile.passiveDisplayRows = parseDisplayRowsText($('passivesDisplayRowsInput')?.value || '');
  selectedProfile.attackPlan ||= {};
  selectedProfile.attackPlan.style = $('attackStyleInput').value;
  selectedProfile.attackPlan.name = $('attackNameInput').value.trim();
  selectedProfile.attackPlan.actions = [
    ...document.querySelectorAll('#attackActions .action-card'),
  ].map(readActionCard);
  selectedProfile.attackPlan.conditionalRules = [
    ...document.querySelectorAll('#conditionalRules .conditional-card'),
  ].map(readConditionalRuleCard);
  if (selectedProfile.attackPlan.style === 'symbols' && selectedProfile.attackPlan.actions?.length) {
    selectedProfile.attackPlan.goals ||= [];
    const existing = new Set(selectedProfile.attackPlan.goals.map(g => `${g.white || 0},${g.orange || g.yellow || 0},${g.red || 0}`));
    for (const action of selectedProfile.attackPlan.actions) {
      if (action.condition?.type === 'symbols' && action.condition.symbols) {
        const sym = action.condition.symbols;
        const key = `${sym.white || 0},${sym.orange || sym.yellow || 0},${sym.red || 0}`;
        if (!existing.has(key)) {
          existing.add(key);
          selectedProfile.attackPlan.goals.push({
            white: sym.white || 0,
            orange: sym.orange || sym.yellow || 0,
            red: sym.red || 0
          });
        }
      }
    }
  }
  selectedProfile.defensePlan ||= {
    dice: selectedProfile.defenseDice,
    effects: [],
    notes: [],
  };
  selectedProfile.defensePlan.dice = selectedProfile.defenseDice;
  selectedProfile.defensePlan.effects = [
    ...document.querySelectorAll('#defenseEffects .action-card'),
  ].map(readDefenseCard);
  sourceData.profiles[selectedIndex] = clone(selectedProfile);
}

function escapeAttr(value) {
  return String(value ?? '').replaceAll('&', '&amp;').replaceAll('"', '&quot;').replaceAll('<', '&lt;');
}
function escapeText(value) {
  return String(value ?? '').replaceAll('&', '&amp;').replaceAll('<', '&lt;');
}
function resolveTokenCountDisplay(data) {
  const tokens = data?.tokens || [];
  if (!tokens.length) return '';
  if (data.tokenCount && data.tokenCount > 0) return data.tokenCount;
  if (tokens.length > 1 && tokens.every(t => t === tokens[0])) return tokens.length;
  return 1;
}
function resolveInitialTokensCountDisplay(profile) {
  const tokens = profile?.initialTokens || [];
  if (!tokens.length) return '';
  if (profile.initialTokenCount && profile.initialTokenCount > 0) return profile.initialTokenCount;
  if (tokens.length > 1 && tokens.every(t => t === tokens[0])) return tokens.length;
  return 1;
}
function textarea(label, className, value = '', rows = 2) {
  return '<label class="wide-label formula-label">' + label + '<textarea class="' + className + '" rows="' + rows + '">' + escapeText(value) + '</textarea></label>';
}
function input(label, className, value = '', type = 'text') {
  const isToken = (className.includes('tokens') || className.includes('token')) && !className.includes('nb') && !className.includes('count');
  const tokenClass = isToken ? ' token-input' : '';
  const readOnlyAttr = isToken ? ' readonly style="cursor:pointer;" placeholder="Select tokens..."' : '';
  return `<label>${label}<input class="${className}${tokenClass}" type="${type}" value="${escapeAttr(value)}"${readOnlyAttr} /></label>`;
}
function select(label, className, value, options) {
  return `<label>${label}<select class="${className}">${options.map((option) => `<option value="${option}" ${option === value ? 'selected' : ''}>${option}</option>`).join('')}</select></label>`;
}
function check(label, className, checked) {
  return `<label class="checkline"><input class="${className}" type="checkbox" ${checked ? 'checked' : ''} />${label}</label>`;
}
function renderActions() {
  const root = $('attackActions');
  root.innerHTML = '';
  (selectedProfile.attackPlan?.actions || []).forEach((action, index) => root.appendChild(actionCard(action, index, false)));
}
function renderDefense() {
  const root = $('defenseEffects');
  root.innerHTML = '';
  (selectedProfile.defensePlan?.effects || []).forEach((effect, index) => root.appendChild(actionCard(effect, index, true)));
}
function defaultConditionalRule() {
  return {
    condition: { type: 'sameValue', count: 3 },
    effect: { heroTokens: [], minionTokens: [], damage: null, damageFormula: null, undefendable: false, lifeSteal: 0, loseHp: 0, cpSteal: 0, note: '' },
    displayRows: [],
    exclusive: true,
    minRollCount: 0,
  };
}
function renderConditionalRules() {
  if(window.bindHighlights) setTimeout(window.bindHighlights, 50);

  const root = $('conditionalRules');
  if (!root) return;
  root.innerHTML = '';
  (selectedProfile.attackPlan?.conditionalRules || []).forEach((rule, index) => root.appendChild(conditionalRuleCard(rule, index)));
}
function conditionalRuleCard(data, index) {
  const node = document.createElement('article');
  node.className = 'action-card conditional-card';
  const condition = data.condition || {};
  const effect = data.effect || {};
  node.innerHTML = [
    '<div class="action-head"><strong class="action-title">Conditional rule ' + (index + 1) + '</strong><button class="danger small remove-conditional">Remove</button></div>',
    '<div class="condition-grid">' +
      select('Condition type', 'cond-type', condition.type || 'sameValue', ['sameValue', 'sameSymbol', 'suite', 'symbols', 'attackSucceededAnd', 'alteration', 'text']) +
      input('Count', 'cond-count', condition.count ?? '', 'number') +
      input('Min length', 'cond-minlength', condition.minLength ?? condition.length ?? '', 'number') +
      input('White', 'cond-white', condition.white ?? 0, 'number') +
      input('Orange', 'cond-orange', condition.orange ?? condition.yellow ?? 0, 'number') +
      input('Red', 'cond-red', condition.red ?? 0, 'number') +
      input('Present tokens', 'cond-present-tokens', (condition.present || []).join(', ')) +
      input('Absent tokens', 'cond-absent-tokens', (condition.absent || []).join(', ')) +
      check('Negate', 'cond-negate', !!condition.negate) +
      '<label class="checkline">Inner (JSON)<textarea class="cond-inner" rows="3" placeholder=\'{ "type": "sameValue", "count": 3 }\'>' + escapeText(JSON.stringify(condition.inner ?? null, null, 2)) + '</textarea></label>' +
      '<label class="checkline">And (JSON array)<textarea class="cond-and" rows="3" placeholder=\'[]\'>' + escapeText(JSON.stringify(condition.and ?? [], null, 2)) + '</textarea></label>' +
      '</div>',
    '<div class="effect-grid">' +
      input('Hero tokens', 'eff-herotokens', (effect.heroTokens || []).join(', ')) +
      input('Minion tokens', 'eff-miniontokens', (effect.minionTokens || []).join(', ')) +
      input('Damage', 'eff-damage', effect.damage ?? '', 'number') +
      select('Damage formula', 'eff-damageformula', effect.damageFormula || '', ['', 'cp', 'cp+cpSteal']) +
      check('Undefendable', 'eff-undef', !!effect.undefendable) +
      input('Life steal', 'eff-lifesteal', effect.lifeSteal ?? 0, 'number') +
      input('Lose HP', 'eff-losehp', effect.loseHp ?? 0, 'number') +
      input('CP steal', 'eff-cpsteal', effect.cpSteal ?? 0, 'number') +
      textarea('Note', 'eff-note', effect.note || '', 2) +
      '</div>',
    '<div class="display-row-head" style="margin-top: 10px;"><label class="wide-label">Display rows JSON' +
      '<div class="highlight-container"><div class="highlight-backdrop rule-backdrop"></div>' +
      '<textarea class="cond-displayrows rule-display-rows highlight-textarea" rows="5" placeholder=\'[{"align":"left","items":["If 3 identical values","=","{token:Silence}"]}]\'>' + escapeText(JSON.stringify(data.displayRows || [], null, 2)) + '</textarea></div></label>' +
      '<button class="ghost-btn generate-btn rule-generate-btn" type="button">Generate text</button></div>',
    '<label class="checkline"><input class="cond-exclusive" type="checkbox" ' + (data.exclusive !== false ? 'checked' : '') + ' />Exclusive (first match wins, else-if cascade)</label>',
    input('Min roll count', 'cond-minroll', data.minRollCount ?? 0, 'number'),
  ].join('');
  node.querySelector('.rule-generate-btn').onclick = () => {
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
    node.querySelector('.remove-conditional').onclick = () => { node.remove(); collectCurrent(); setDirty('enemy'); renderPreview(); renderDisplayRowsPreviews(); };

  node.addEventListener('input', () => { collectCurrent(); setDirty('enemy'); renderPreview(); renderDisplayRowsPreviews(); });
  node.addEventListener('change', () => { collectCurrent(); setDirty('enemy'); renderPreview(); renderDisplayRowsPreviews(); });
  return node;
}
function readConditionalRuleCard(card) {
  const type = card.querySelector('.cond-type').value;
  const andRaw = card.querySelector('.cond-and').value.trim();
  let and = [];
  if (andRaw) { try { const parsed = JSON.parse(andRaw); if (Array.isArray(parsed)) and = parsed; } catch {} }
  const condition = { type, negate: card.querySelector('.cond-negate').checked, and };
  
  if (type === 'sameValue' || type === 'sameSymbol') condition.count = intVal(card.querySelector('.cond-count').value);
  if (type === 'suite') condition.minLength = intVal(card.querySelector('.cond-minlength').value);
  if (type === 'symbols' || type === 'attackSucceededAnd') {
    condition.white = intVal(card.querySelector('.cond-white').value);
    condition.orange = intVal(card.querySelector('.cond-orange').value);
    condition.red = intVal(card.querySelector('.cond-red').value);
  }
  if (type === 'alteration') {
    condition.present = csv(card.querySelector('.cond-present-tokens').value);
    condition.absent = csv(card.querySelector('.cond-absent-tokens').value);
  }
  const innerRaw = card.querySelector('.cond-inner').value.trim();
  if (innerRaw) { try { condition.inner = JSON.parse(innerRaw); } catch {} }
  
  const damageRaw = card.querySelector('.eff-damage').value.trim();
  const damageFormula = card.querySelector('.eff-damageformula').value;
  const effect = {
    heroTokens: csv(card.querySelector('.eff-herotokens').value),
    minionTokens: csv(card.querySelector('.eff-miniontokens').value),
    damage: damageRaw === '' ? null : intVal(damageRaw),
    damageFormula: damageFormula || null,
    undefendable: card.querySelector('.eff-undef').checked,
    lifeSteal: intVal(card.querySelector('.eff-lifesteal').value),
    loseHp: intVal(card.querySelector('.eff-losehp').value),
    cpSteal: intVal(card.querySelector('.eff-cpsteal').value),
    note: card.querySelector('.eff-note').value.trim(),
  };
  return {
    condition,
    effect,
    displayRows: parseDisplayRowsText(card.querySelector('.cond-displayrows')?.value || ''),
    exclusive: card.querySelector('.cond-exclusive').checked,
    minRollCount: intVal(card.querySelector('.cond-minroll').value),
  };
}
function actionCard(data, index, isDefense) {
  const node = $('actionTemplate').content.firstElementChild.cloneNode(true);
  node.dataset.kind = isDefense ? 'defense' : 'attack';
  node.querySelector('.action-title').textContent = `${isDefense ? 'Defense effect' : 'Attack action'} ${index + 1}`;
  node.querySelector('.remove-action').onclick = () => { node.remove(); collectCurrent(); setDirty('enemy'); renderPreview(); renderFormulaList(); };
  
  if (selectedProfile?.name === 'Rat de la Rue') {
    node.querySelector('.rat-labels').style.display = 'flex';
  }
  const label2Input = node.querySelector('.action-label2');
  if(label2Input) label2Input.value = data.label2 || '';
  const label3Input = node.querySelector('.action-label3');
  if(label3Input) label3Input.value = data.label3 || '';

  const condition = data.condition || {};
  const type = condition.type || 'symbols';
  const symbols = condition.symbols || {};
  const orWhiteOrange = condition.orWhiteOrange ?? symbols.orWhiteOrange ?? data.orWhiteOrange ?? false;
  const orOrangeRed = condition.orOrangeRed ?? symbols.orOrangeRed ?? data.orOrangeRed ?? false;
  node.querySelector('.condition-grid').innerHTML = [
    select('Condition type', 'cond-type', type, ['symbols', 'suite', 'number', 'range', 'any', 'text']),
    '<div class="dice-cond-group">' +
      input('White', 'cond-white', symbols.white ?? 0, 'number') +
      `<label class="check-or" title="White OR Orange"><input class="cond-or-white-orange" type="checkbox" ${orWhiteOrange ? 'checked' : ''} />or</label>` +
      input('Orange', 'cond-orange', symbols.orange ?? symbols.yellow ?? 0, 'number') +
      `<label class="check-or" title="Orange OR Red"><input class="cond-or-orange-red" type="checkbox" ${orOrangeRed ? 'checked' : ''} />or</label>` +
      input('Red', 'cond-red', symbols.red ?? 0, 'number') +
    '</div>',
    input('Suite', 'cond-suite', condition.suite || ''),
    input('Length', 'cond-length', condition.length ?? '', 'number'),
    input('Value', 'cond-value', condition.value ?? '', 'number'),
    check('Repeat per symbol', 'cond-repeat', !!condition.repeat),
    check('Exclusive (tier / highest match)', 'cond-exclusive', !!(condition.exclusive ?? data.exclusive)),
  ].join('');
  node.querySelector('.effect-grid').innerHTML = [
    select('Align', 'effect-align', data.align || 'left', ['left', 'center']),
    input('Label', 'effect-label', data.label || ''),
    input('Damage', 'effect-damage', data.damage ?? 0, 'number'),
    check('Undefendable', 'effect-undef', !!data.undefendable),
    input('Prevent', 'effect-prevent', data.prevent ?? 0, 'number'),
    input('Return dmg', 'effect-return', data.returnDamage ?? 0, 'number'),
    input('Steal HP', 'effect-stealhp', data.stealHp ?? 0, 'number'),
    input('Lose HP', 'effect-losehp', data.loseHp ?? 0, 'number'),
    input('Steal CP', 'effect-stealcp', data.stealCp ?? 0, 'number'),
    input('Heal', 'effect-heal', data.heal ?? 0, 'number'),
    input('Draw', 'effect-draw', data.drawCards ?? 0, 'number'),
    input('Discard', 'effect-discard', data.discardCards ?? 0, 'number'),
    input('Top deck discard', 'effect-topdeck', data.topDeckToDiscard ?? 0, 'number'),
    input('Nb', 'effect-nb', resolveTokenCountDisplay(data), 'number'),
    input('Tokens', 'effect-tokens', [...new Set(data.tokens || [])].join(', ')),
    textarea('Formulas', 'effect-formulas', (data.formulas || []).join('\n'), 3),
  ].join('');
  renderExtra(node.querySelector('.extra-roll-body'), data.extraRoll || null);
  node.querySelector('details').open = !!data.extraRoll;
  node.querySelector('.notes-field').value = (data.notes || []).join('\n');

  node.addEventListener('input', () => { collectCurrent(); setDirty('enemy'); renderPreview(); renderFormulaList(); });
  node.addEventListener('change', () => { collectCurrent(); setDirty('enemy'); renderPreview(); renderFormulaList(); });
  return node;
}
function renderExtra(root, extra) {
  root.innerHTML = [
    input('Dice', 'extra-dice', extra?.dice ?? 0, 'number'),
    select('Mode', 'extra-mode', extra?.mode || 'perFace', ['perFace', 'simple']),
    select('Align', 'extra-align', extra?.align || 'left', ['left', 'center']),
    `<label class="wide-label">Roll text<textarea class="extra-rolltext" rows="2">${escapeText(extra?.rollText || '')}</textarea></label>`,
    `<label class="wide-label">Final text<textarea class="extra-finaltext" rows="2">${escapeText(extra?.finalText || '')}</textarea></label>`,
    `<label class="wide-label">Display rows JSON<textarea class="extra-displayrows" rows="7" placeholder='[{"align":"center","items":["{die:orange}","{die:orange}","{die:red}"]},{"align":"right","items":["{damage:7}","+ nb","{token:Chaos}"]}]'>${escapeText(JSON.stringify(extra?.displayRows || [], null, 2))}</textarea></label>`,
    '<p class="hint mini-hint">Use align: left, center or right. Items accept {die:any}, {die:white}, {die:orange}, {die:red}, {hp:8}, {damage:7}, {undef:7}, {prevent:2}, {heal:4}, {token:Chaos}.</p>',
    '<div class="outcome-list"></div>',
    '<button type="button" class="ghost-btn add-outcome">Add outcome</button>',
  ].join('');
  const list = root.querySelector('.outcome-list');
  (extra?.outcomes || []).forEach((outcome) => list.appendChild(outcomeRow(outcome)));
  root.querySelector('.add-outcome').onclick = () => list.appendChild(outcomeRow({ face: 'white', label: '', damage: 0, tokens: [] }));
}
function outcomeRow(outcome) {
  const row = document.createElement('div');
  row.className = 'outcome-row';
  row.innerHTML = `
    <div class="outcome-row-grid">
      ${select('Align', 'out-align', outcome.align || '', ['', 'left', 'center', 'right'])}
      ${select('Face', 'out-face', outcome.face || 'white', ['white', 'orange', 'red', 'any'])}
      ${input('Dmg', 'out-damage', outcome.damage ?? 0, 'number')}
      ${input('Steal HP', 'out-stealhp', outcome.stealHp ?? 0, 'number')}
      ${input('Lose HP', 'out-losehp', outcome.loseHp ?? 0, 'number')}
      ${input('Steal CP', 'out-stealcp', outcome.stealCp ?? 0, 'number')}
      ${check('Undef', 'out-undef', !!outcome.undefendable)}
      ${input('Nb', 'out-nb', resolveTokenCountDisplay(outcome), 'number')}
      ${input('Tokens', 'out-tokens', [...new Set(outcome.tokens || [])].join(', '))}
      <button type="button" class="danger small">X</button>
    </div>
    <label class="wide-label">Label<input class="out-label" type="text" value="${escapeAttr(outcome.label || '')}" /></label>
  `;

  row.querySelector('button').onclick = () => { row.remove(); collectCurrent(); setDirty('enemy'); renderPreview(); };
  return row;
}

function readCondition(card) {
  const type = card.querySelector('.cond-type').value;
  const condition = { type };
  if (type === 'symbols') {
    condition.symbols = {
      white: intVal(card.querySelector('.cond-white')?.value),
      orange: intVal(card.querySelector('.cond-orange')?.value),
      red: intVal(card.querySelector('.cond-red')?.value),
    };
    if (card.querySelector('.cond-or-white-orange')?.checked) {
      condition.orWhiteOrange = true;
    }
    if (card.querySelector('.cond-or-orange-red')?.checked) {
      condition.orOrangeRed = true;
    }
  }
  if (type === 'suite') {
    condition.suite = card.querySelector('.cond-suite').value.trim();
    condition.length = intVal(card.querySelector('.cond-length').value);
  }
  if (type === 'number') condition.value = intVal(card.querySelector('.cond-value').value);
  if (card.querySelector('.cond-repeat')?.checked) condition.repeat = true;
  if (card.querySelector('.cond-exclusive')?.checked) condition.exclusive = true;
  return condition;
}
function readCommon(card) {
  const rawTokens = csv(card.querySelector('.effect-tokens')?.value);
  const nbVal = card.querySelector('.effect-nb')?.value?.trim();
  let tokenCount;
  let finalTokens = rawTokens;
  if (rawTokens.length > 0) {
    const parsedNb = intVal(nbVal, 1);
    const count = parsedNb > 0 ? parsedNb : 1;
    if (count > 1) {
      tokenCount = count;
      if (rawTokens.length === 1) {
        finalTokens = Array(count).fill(rawTokens[0]);
      }
    }
  } else {
    finalTokens = [];
    tokenCount = undefined;
  }
  const cond = readCondition(card);
  const res = {
    align: card.querySelector('.effect-align')?.value || 'left',
    condition: cond,
    label: card.querySelector('.effect-label').value.trim(),
    damage: intVal(card.querySelector('.effect-damage').value),
    undefendable: card.querySelector('.effect-undef').checked,
    prevent: intVal(card.querySelector('.effect-prevent')?.value),
    returnDamage: intVal(card.querySelector('.effect-return')?.value),
    stealHp: intVal(card.querySelector('.effect-stealhp').value),
    loseHp: intVal(card.querySelector('.effect-losehp').value),
    stealCp: intVal(card.querySelector('.effect-stealcp').value),
    heal: intVal(card.querySelector('.effect-heal').value),
    drawCards: intVal(card.querySelector('.effect-draw').value),
    discardCards: intVal(card.querySelector('.effect-discard').value),
    tokenCount: tokenCount,
    tokens: finalTokens,
    formulas: card.querySelector('.effect-formulas').value.split(/[,\n]/).map((line) => line.trim()).filter(Boolean),
    notes: card.querySelector('.notes-field').value.split('\n').map((line) => line.trim()).filter(Boolean),
  };
  if (cond.orWhiteOrange) res.orWhiteOrange = true;
  if (cond.orOrangeRed) res.orOrangeRed = true;
  if (cond.exclusive) res.exclusive = true;
  return res;
}
function readActionCard(card) {
  const data = readCommon(card);
  const label2 = card.querySelector('.action-label2')?.value?.trim();
  if (label2) data.label2 = label2;
  const label3 = card.querySelector('.action-label3')?.value?.trim();
  if (label3) data.label3 = label3;
  data.topDeckToDiscard = intVal(card.querySelector('.effect-topdeck').value);
  data.extraRoll = readExtra(card);
  return data;
}
function readDefenseCard(card) {
  const data = readCommon(card);
  data.prevent = intVal(card.querySelector('.effect-prevent').value);
  data.returnDamage = intVal(card.querySelector('.effect-return').value);
  delete data.damage;
  return data;
}
function readExtra(card) {
  const dice = intVal(card.querySelector('.extra-dice').value);
  if (dice <= 0) return null;
  return {
    dice,
    mode: card.querySelector('.extra-mode').value,
    align: card.querySelector('.extra-align').value,
    rollText: card.querySelector('.extra-rolltext').value.trim(),
    finalText: card.querySelector('.extra-finaltext').value.trim() || undefined,
    displayRows: readDisplayRows(card),
    outcomes: [...card.querySelectorAll('.outcome-row')].map((row) => {
      const rawTokens = csv(row.querySelector('.out-tokens')?.value);
      const nbVal = row.querySelector('.out-nb')?.value?.trim();
      let tokenCount;
      let tokens = rawTokens;
      if (rawTokens.length > 0) {
        const parsedNb = intVal(nbVal, 1);
        const count = parsedNb > 0 ? parsedNb : 1;
        if (count > 1) {
          tokenCount = count;
          if (rawTokens.length === 1) {
            tokens = Array(count).fill(rawTokens[0]);
          }
        }
      } else {
        tokens = [];
        tokenCount = undefined;
      }
      return {
        align: row.querySelector('.out-align').value || undefined,
        face: row.querySelector('.out-face').value,
        label: row.querySelector('.out-label').value.trim(),
        damage: intVal(row.querySelector('.out-damage').value),
        undefendable: row.querySelector('.out-undef').checked,
        stealHp: intVal(row.querySelector('.out-stealhp').value),
        loseHp: intVal(row.querySelector('.out-losehp').value),
        stealCp: intVal(row.querySelector('.out-stealcp').value),
        tokenCount: tokenCount > 1 ? tokenCount : undefined,
        tokens,
      };
    }),
  };
}
function conditionDisplayItems(condition = {}) {
  const items = [];
  const type = condition.type || 'symbols';
  if (type === 'suite') {
    const label = condition.suite ? String(condition.suite) : 'suite';
    items.push(condition.length ? `${label} ${condition.length}` : label);
    return items;
  }
  if (type === 'number') {
    items.push(`{die:${condition.value ?? '?'}}`);
    return items;
  }
  if (type === 'range') {
    if (condition.from != null) items.push(`{die:${condition.from}}`);
    items.push('-');
    if (condition.to != null) items.push(`{die:${condition.to}}`);
    return items;
  }
  if (type === 'any') return ['Any'];
  if (type === 'text') return [condition.text || condition.label || 'Text rule'];
  const symbols = condition.symbols || {};
  const add = (face, count) => {
    const total = intVal(count);
    for (let i = 0; i < total; i += 1) items.push(`{die:${face}}`);
  };
  add('white', symbols.white);
  add('orange', symbols.orange ?? symbols.yellow);
  add('red', symbols.red);
  return items;
}
function effectDisplayItems(effect = {}, { defense = false } = {}) {
  const items = [];
  if (effect.tokens) items.push(...effect.tokens.map((token) => `{token:${token}}`));
  if (!defense && effect.damage) items.push(`{${effect.undefendable ? 'undef' : 'damage'}:${effect.damage}}`);
  if (defense && effect.prevent) items.push(`{prevent:${effect.prevent}}`);
  if (defense && effect.returnDamage) items.push(`{${effect.undefendable ? 'undef' : 'damage'}:${effect.returnDamage}}`);
  if (effect.stealHp) items.push('Steal', `{heal:${effect.stealHp}}`);
  if (effect.loseHp) items.push('Lose', `{losehp:${effect.loseHp}}`);
  if (effect.stealCp) items.push(`Steal ${effect.stealCp} CP`);
  if (effect.heal) items.push(`{heal:${effect.heal}}`);
  if (effect.drawCards) items.push(`Draw ${effect.drawCards}`);
  if (effect.discardCards) items.push(`Discard ${effect.discardCards}`);
  if (effect.topDeckToDiscard) items.push(`Top ${effect.topDeckToDiscard} discard`);
  if (effect.extraRoll?.dice) items.push('Roll', `${effect.extraRoll.dice}x`, '{die:white}');
  if (effect.notes) items.push(...effect.notes);
  return items;
}
function actionToDisplayRows(action = {}) {
  const rows = [];
  const condition = conditionDisplayItems(action.condition);
  const effect = effectDisplayItems(action);
  const first = [...condition];
  if (action.label) first.push(action.label);
  if (effect.length) first.push('=', ...effect);
  if (action.label2) first.push(action.label2);
  if (action.label3) first.push(action.label3);
  if (first.length) rows.push({ align: 'left', items: first });
  if (action.extraRoll?.displayRows?.length) {
    rows.push(...action.extraRoll.displayRows);
  } else if (action.extraRoll?.dice) {
    rows.push({ align: 'center', items: ['Extra roll:', `${action.extraRoll.dice}x`, '{die:white}'] });
    const outcomes = action.extraRoll.outcomes || [];
    for (const outcome of outcomes) {
      const outcomeItems = [`{die:${outcome.face || 'white'}}`, '=', ...effectDisplayItems(outcome)];
      if (outcome.label) outcomeItems.splice(2, 0, outcome.label);
      if (outcomeItems.length > 2) rows.push({ align: 'left', items: outcomeItems });
    }
    if (action.extraRoll.finalText) rows.push({ align: 'left', items: [action.extraRoll.finalText] });
  }
  return rows;
}
function defenseToDisplayRows(effect = {}) {
  const condition = conditionDisplayItems(effect.condition);
  const result = effectDisplayItems(effect, { defense: true });
  const items = [...condition];
  if (result.length) items.push('=', ...result);
  return items.length ? [{ align: 'left', items }] : [];
}
function passiveToDisplayRows(passive = {}) {
  if (typeof passive === 'string') return passive.trim() ? [{ align: 'left', items: [passive.trim()] }] : [];
  const text = passive.customText || passive.text || buildPassiveSentence(passive) || passive.label || '';
  return text.trim() ? [{ align: 'left', items: [text.trim()] }] : [];
}
function writeGeneratedRows(inputId, rows, label) {
  const input = $(inputId);
  if (!input) return;
  input.value = JSON.stringify(rows, null, 2);
  collectCurrent();
  setDirty('enemy');
  renderDisplayRowsPreviews();
  flash(`${label} display rows generated.`);
}
function conditionalRuleToDisplayRows(rule = {}) {
  if (Array.isArray(rule.displayRows) && rule.displayRows.length) {
    return rule.displayRows;
  }
  const condition = rule.condition || {};
  const effect = rule.effect || {};
  const condItems = conditionalConditionDisplayItems(condition);
  const effItems = conditionalEffectDisplayItems(effect);
  const items = [...condItems];
  if (effItems.length) items.push('=', ...effItems);
  return items.length ? [{ align: 'left', items }] : [];
}
function conditionalConditionDisplayItems(condition = {}) {
  switch (condition.type) {
    case 'sameValue':
      return ['If ' + (condition.count || 3) + ' identical values'];
    case 'sameSymbol':
      return ['If ' + (condition.count || 4) + ' identical symbols'];
    case 'suite':
      return ['If suite ≥ ' + (condition.minLength || 5)];
    case 'symbols': {
      const symbols = { white: condition.white, orange: condition.orange, red: condition.red };
      return conditionDisplayItems({ type: 'symbols', symbols });
    }
    case 'attackSucceededAnd': {
      const inner = condition.inner ? conditionalConditionDisplayItems(condition.inner) : ['successful attack'];
      return ['If attack succeeded', ...inner];
    }
    case 'alteration': {
      const bits = [];
      if ((condition.present || []).length) bits.push('has ' + condition.present.join('/'));
      if ((condition.absent || []).length) bits.push('no ' + condition.absent.join('/'));
      return bits.length ? ['If ' + bits.join(' and ')] : ['Alteration rule'];
    }
    case 'text':
      return [condition.text || 'Text rule'];
    default:
      return ['Conditional rule'];
  }
}
function conditionalEffectDisplayItems(effect = {}) {
  const items = [];
  if (effect.heroTokens) items.push(...effect.heroTokens.map((token) => `{token:${token}}`));
  if (effect.minionTokens) items.push(...effect.minionTokens.map((token) => `{token:${token}}`));
  if (effect.damage != null) items.push(`{${effect.undefendable ? 'undef' : 'damage'}:${effect.damage}}`);
  if (effect.damageFormula) items.push('dmg:' + effect.damageFormula);
  if (effect.lifeSteal) items.push(`Steal ${effect.lifeSteal} HP`);
  if (effect.cpSteal) items.push(`Steal ${effect.cpSteal} CP`);
  if (effect.note) items.push(effect.note);
  return items;
}
function generateAttackRows() {
  collectCurrent();
  const rows = [];
  if (selectedProfile.attackPlan?.name) {
    rows.push({ align: 'center', items: [selectedProfile.attackPlan.name] });
  }
  (selectedProfile.attackPlan?.actions || []).forEach(a => rows.push(...actionToDisplayRows(a)));
  (selectedProfile.attackPlan?.conditionalRules || []).forEach(r => rows.push(...conditionalRuleToDisplayRows(r)));
  writeGeneratedRows('attacksDisplayRowsInput', rows, 'Attack');
}
function generateDefenseRows() {
  collectCurrent();
  const rows = (selectedProfile?.defensePlan?.effects || []).flatMap(defenseToDisplayRows);
  writeGeneratedRows('defenseDisplayRowsInput', rows, 'Defense');
}
function generatePassiveRows() {
  collectCurrent();
  const passives = (selectedProfile?.attackPlan?.passives?.length ? selectedProfile.attackPlan.passives : selectedProfile?.passives) || [];
  const rows = passives.flatMap(passiveToDisplayRows);
  writeGeneratedRows('passivesDisplayRowsInput', rows, 'Passive');
}
function parseDisplayRowsText(raw) {
  raw = String(raw || '').trim();
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (!Array.isArray(parsed)) return [];
    return parsed
      .map((row) => ({
        align: ['left', 'center', 'right'].includes(String(row.align || '').toLowerCase())
          ? String(row.align).toLowerCase()
          : 'left',
        items: Array.isArray(row.items) ? row.items.map(String).filter(Boolean) : [],
      }))
      .filter((row) => row.items.length);
  } catch {
    return [];
  }
}
function readDisplayRows(card) {
  const raw = card.querySelector('.extra-displayrows')?.value.trim() || '';
  return parseDisplayRowsText(raw);
}
function renderPreview() {
  if (!selectedProfile) return;
  $('previewName').textContent = selectedProfile.name;
  const actions = (selectedProfile.attackPlan?.actions || []).map(actionPreview);
  const rules = (selectedProfile.attackPlan?.conditionalRules || []).map(conditionalRulePreview);
  const attackHtml = [...actions, ...rules].join('');
  $('attackPreview').innerHTML = attackHtml || '<em>No attack actions.</em>';
  $('defensePreview').innerHTML = (selectedProfile.defensePlan?.effects || []).map(defensePreview).join('') || '<em>No defense effects.</em>';
}
function conditionalRulePreview(rule = {}) {
  const rows = conditionalRuleToDisplayRows(rule);
  const body = rows.length ? displayRowsHtml(rows) : '<span class="token-chip">Empty rule</span>';
  return '<div class="preview-row conditional-preview"><div>⚙ Conditional</div><div>' + body + '</div></div>';
}
function conditionHtml(condition = {}) {
  const prefix = condition.repeat ? '<span style="font-weight:900; font-size:16px; margin-right:4px;">x</span>' : '';
  if (condition.type === 'suite') return `${prefix}<span class="token-chip">${condition.suite || 'suite'} ${condition.length || ''}</span>`;
  if (condition.type === 'number') return `${prefix}<span class="die white">${condition.value ?? '?'}</span>`;
  if (condition.type === 'any') return `${prefix}<span class="token-chip">Any</span>`;
  if (condition.type === 'text') return `${prefix}<span class="token-chip">Text rule</span>`;
  const symbols = condition.symbols || {};
  const orWO = condition.orWhiteOrange || symbols.orWhiteOrange;
  const orOR = condition.orOrangeRed || symbols.orOrangeRed;
  const parts = [];
  const w = dice('white', symbols.white);
  const o = dice('orange', symbols.orange ?? symbols.yellow);
  const r = dice('red', symbols.red);
  if (w) parts.push(w);
  if (orWO && w && o) {
    parts.push('<span class="die-or">or</span>');
  }
  if (o) parts.push(o);
  if (orOR && o && r) {
    parts.push('<span class="die-or">or</span>');
  }
  if (r) parts.push(r);
  return `<div class="dice-line">${prefix}${parts.join('')}</div>`;
}
function dice(face, count = 0) {
  return Array.from({ length: intVal(count) }).map(() => `<span class="die ${face}">${face[0].toUpperCase()}</span>`).join('');
}
function tokenImageHtml(name) {
  const needle = String(name || '').toLowerCase();
  const token = tokenCatalog.find((item) => [item.label, item.frLabel, ...(item.aliases || [])]
    .filter(Boolean)
    .some((value) => String(value).toLowerCase() === needle));
  if (!token?.imageAsset) return '';
  return '<img class="token-inline-img" src="' + assetUrl(token.imageAsset) + '" alt="' + escapeAttr(token.label) + '" />';
}
function displayItemHtml(item) {
  const text = String(item || '');
  const match = text.match(/^\{([^:}]+)(?::([^}]+))?\}$/);
  if (!match) return '<span>' + escapeText(text) + '</span>';
  const kind = match[1].toLowerCase();
  const value = (match[2] ?? '').trim();
  if (kind === 'die') {
    if (['white', 'orange', 'red', 'yellow'].includes(value.toLowerCase())) {
      return dice(value.toLowerCase() === 'yellow' ? 'orange' : value.toLowerCase(), 1);
    }
    return dice('white', 1) || '<span class="die white">D</span>';
  }
  if (kind === 'damage' || kind === 'dmg') return '<span class="badge damage">' + escapeText(value) + '</span>';
  if (kind === 'undef' || kind === 'imparable') return '<span class="badge undef">' + escapeText(value) + '</span>';
  if (kind === 'prevent' || kind === 'block' || kind === 'shield' || kind === 'bouclier') {
    if (value === '1/2' || value === 'half') return '<span class="badge prevent" style="font-size:10px;">½</span>';
    return '<span class="badge prevent">' + escapeText(value || '0') + '</span>';
  }
  if (kind === 'half_prevent' || kind === 'half_shield' || kind === 'half_block') {
    return '<span class="badge prevent" style="font-size:10px;">½</span>';
  }
  if (kind === 'heal' || kind === 'life' || kind === 'vie' || kind === 'soin') return '<span class="badge heal">+' + escapeText(value) + '</span>';
  if (kind === 'losehp' || kind === 'lose_hp' || kind === 'losehealth' || kind === 'loselife' || kind === 'pertevie') return '<span class="badge losehp">-' + escapeText(value) + '</span>';
  if (kind === 'cp') return '<span class="token-chip">Steal ' + escapeText(value) + ' CP</span>';
  if (kind === 'token') return '<span class="token-chip">' + tokenImageHtml(value) + escapeText(value) + '</span>';
  return '<span>' + escapeText(text) + '</span>';
}
function renderFormattedInlineBadge(text = '') {
  const str = String(text || '').trim();
  if (!str) return '';
  const formatted = str.replaceAll(/\{([a-zA-Z0-9_-]+)(?::([^}]+))?\}/g, (match, tag, val) => {
    return displayItemHtml(`{${tag}:${val || ''}}`);
  });
  return `<span class="token-chip note-chip">${formatted}</span>`;
}
function displayRowsHtml(rows = []) {
  if (!rows.length) return '<em>No display rows.</em>';
  return rows.map((row) => '<div class="display-row ' + (row.align || 'left') + '">' + (row.items || []).map(displayItemHtml).join('') + '</div>').join('');
}
function renderDisplayRowsPreviews() {
  if(window.bindHighlights) window.bindHighlights();

  const pairs = [
    ['attacksDisplayRowsInput', 'attacksDisplayRowsPreview'],
    ['defenseDisplayRowsInput', 'defenseDisplayRowsPreview'],
    ['passivesDisplayRowsInput', 'passivesDisplayRowsPreview'],
  ];
  for (const [inputId, previewId] of pairs) {
    const input = $(inputId);
    const preview = $(previewId);
    if (input && preview) preview.innerHTML = displayRowsHtml(parseDisplayRowsText(input.value));
  }
}
function effectHtml(effect = {}) {
  const bits = [];
  if (effect.tokens && effect.tokens.length) {
    const counts = {};
    for (const token of effect.tokens) {
      counts[token] = (counts[token] || 0) + 1;
    }
    for (const [token, count] of Object.entries(counts)) {
      const prefix = count > 1 ? `${count} x ` : '';
      bits.push(`<span class="token-chip">${prefix}${tokenImageHtml(token)}${escapeText(token)}</span>`);
    }
  }
  if (effect.damage) bits.push(`<span class="badge ${effect.undefendable ? 'undef' : 'damage'}">${effect.damage}</span>`);
  if (effect.prevent) bits.push(`<span class="badge prevent">${effect.prevent}</span>`);
  if (effect.returnDamage) bits.push(`<span class="badge ${effect.undefendable ? 'undef' : 'damage'}">↩${effect.returnDamage}</span>`);
  if (effect.stealHp) bits.push(`<span class="badge heal">S${effect.stealHp}</span>`);
  if (effect.loseHp) bits.push(`<span class="badge losehp">-${effect.loseHp} HP</span>`);
  if (effect.stealCp && !effect.label2) bits.push(`<span class="token-chip">Steal ${effect.stealCp} CP</span>`);
  if (effect.heal) bits.push(`<span class="badge heal">+${effect.heal}</span>`);
  if (effect.drawCards) bits.push(`<span class="token-chip">Draw ${effect.drawCards}</span>`);
  if (effect.discardCards) bits.push(`<span class="token-chip">Discard ${effect.discardCards}</span>`);
  if (effect.topDeckToDiscard) bits.push(`<span class="token-chip">Top ${effect.topDeckToDiscard} discard</span>`);
  if (effect.notes && effect.notes.length) {
    bits.push(...effect.notes.map((note) => renderFormattedInlineBadge(note)));
  }
  if (effect.extraRoll?.dice) {
    bits.push(`<span class="token-chip">Roll ${effect.extraRoll.dice} die</span>`);
    if (effect.extraRoll.displayRows?.length) {
      bits.push(`<span class="token-chip">${effect.extraRoll.displayRows.length} display row${effect.extraRoll.displayRows.length > 1 ? 's' : ''}</span>`);
    }
  }
  return bits.join(' ') || '<span class="token-chip">No effect</span>';
}
function actionPreview(action) {
  let label2Html = action.label2 ? `<div class="token-chip" style="margin-left: 4px;">${action.label2}</div>` : '';
  let label3Html = action.label3 ? `<div class="token-chip" style="margin-left: 4px;">${action.label3}</div>` : '';
  return `<div class="preview-row"><div>${conditionHtml(action.condition)}<strong>${action.label || ''}</strong></div><div>${effectHtml(action)}${label2Html}${label3Html}</div></div>`;
}
function defensePreview(effect) {
  return `<div class="preview-row"><div>${conditionHtml(effect.condition)}</div><div>${effectHtml(effect)}</div></div>`;
}
function addAction() {
  collectCurrent();
  selectedProfile.attackPlan.actions.push(defaultAction());
  renderActions();
  renderPreview();
}
function addConditionalRule() {
  collectCurrent();
  selectedProfile.attackPlan ||= { style: 'symbols', goals: [], name: '', actions: [], conditionalRules: [], passives: [], notes: [] };
  selectedProfile.attackPlan.conditionalRules ||= [];
  selectedProfile.attackPlan.conditionalRules.push(defaultConditionalRule());
  renderConditionalRules();
  renderPreview();
}
function addDefense() {
  collectCurrent();
  selectedProfile.defensePlan ||= { dice: selectedProfile.defenseDice, effects: [], notes: [] };
  selectedProfile.defensePlan.effects.push(defaultDefense());
  renderDefense();
  renderPreview();
}
function updateTabDots() {
  if (!selectedProfile) return;
  const atkDot = $('attackDot');
  if (atkDot) {
    const hasRule = (selectedProfile.attackPlan?.conditionalRules?.length || 0) > 0;
    atkDot.classList.toggle('active', hasRule);
  }
  const txtDot = $('textDot');
  if (txtDot) {
    const atkR = (selectedProfile.attackPlan?.displayRows?.length || 0) > 0;
    const defR = (selectedProfile.defensePlan?.displayRows?.length || 0) > 0;
    const pasR = (selectedProfile.passiveDisplayRows?.length || 0) > 0;
    txtDot.classList.toggle('active', atkR || defR || pasR);
  }
  const pasDot = $('passiveDot');
  if (pasDot) {
    const hasPas = (selectedProfile.attackPlan?.passives?.length || 0) > 0 || (selectedProfile.passives?.length || 0) > 0;
    pasDot.classList.toggle('active', hasPas);
  }
}

function ensureProfilePassivesList() {
  if (!selectedProfile) return [];
  if (!selectedProfile.attackPlan) selectedProfile.attackPlan = {};
  if (!Array.isArray(selectedProfile.attackPlan.passives)) {
    selectedProfile.attackPlan.passives = [];
  }
  if (selectedProfile.attackPlan.passives.length === 0 && Array.isArray(selectedProfile.passives) && selectedProfile.passives.length > 0) {
    selectedProfile.attackPlan.passives = selectedProfile.passives.map((p) => {
      if (p && typeof p === 'object') return JSON.parse(JSON.stringify(p));
      return {
        type: 'custom',
        text: String(p || ''),
        tokens: [],
        effects: {
          damage: 0,
          undefendable: false,
          stealHp: 0,
          stealCp: 0,
          heal: 0,
          drawCards: 0,
          discardCards: 0,
          topDeckToDiscard: 0,
          tokens: [],
          formulas: []
        }
      };
    });
  }

  // Normalize each item with 3-zone fields
  selectedProfile.attackPlan.passives.forEach((p) => {
    if (typeof p === 'object' && p !== null) {
      if (!p.type) {
        const txt = (p.text || '').toLowerCase();
        if (txt.includes('offensive roll fail') || txt.includes('offensive failure') || txt.includes('rolls offensif fail')) {
          p.type = 'offensive_failure';
          p.timing ||= 'offensiveRollFailed';
        } else if (txt.includes('start of') || txt.includes('debut de son tour') || txt.includes('upkeep')) {
          p.type = 'start_of_turn';
          p.timing ||= 'minionUpkeep';
        } else {
          p.type = 'custom';
        }
      }
      p.target ||= (p.type === 'offensive_failure' ? 'opponent' : 'minion');
      if (p.impact === undefined) {
        p.impact = p.type === 'custom' ? (p.text || '') : extractPassiveImpact(p.text, p.type);
      }
      p.customText ||= '';
      p.tokens ||= [];
      p.effects ||= {};
    }
  });

  selectedProfile.passives = selectedProfile.attackPlan.passives;
  return selectedProfile.attackPlan.passives;
}

function extractPassiveImpact(text = '', type = 'custom') {
  let str = String(text || '').trim();
  if (type === 'offensive_failure') {
    str = str.replace(/^(passive:\s*)?(if\s+(the\s+)?offensive\s+roll(\s+phase)?\s+fails?:?\s*,?\s*)/i, '');
    str = str.replace(/^(passive:\s*)?(si\s+(le\s+)?rolls?(\s+offensif)?\s+fails?:?\s*,?\s*)/i, '');
    str = str.replace(/^(passif\s+failure:\s*)/i, '');
  } else if (type === 'start_of_turn') {
    str = str.replace(/^(passive:\s*)?(at\s+the\s+start\s+of\s+(its|the(\s+minion'?s)?)\s+turn:?\s*,?\s*)/i, '');
    str = str.replace(/^(passive:\s*)?(au\s+debut\s+de\s+son\s+tour:?\s*,?\s*)/i, '');
    str = str.replace(/^(passive:\s*)?(start\s+of\s+turn:?\s*,?\s*)/i, '');
    str = str.replace(/^(passif\s+upkeep:\s*)/i, '');
  }
  return str.replace(/\.$/, '').trim();
}

function buildPassiveSentence(passive) {
  if (passive.customText && passive.customText.trim()) {
    return passive.customText.trim();
  }
  const impact = (passive.impact || '').trim();
  if (passive.type === 'offensive_failure') {
    if (!impact) return 'If the Offensive Roll Phase fails: no effect.';
    return `If the Offensive Roll Phase fails: ${impact}${impact.endsWith('.') ? '' : '.'}`;
  }
  if (passive.type === 'start_of_turn') {
    if (!impact) return 'At the start of its turn: no effect.';
    return `At the start of its turn: ${impact}${impact.endsWith('.') ? '' : '.'}`;
  }
  return passive.text || impact;
}

function formatInlineHtml(text = '') {
  const str = String(text || '').trim();
  if (!str) return '';
  return str.replaceAll(/\{([a-zA-Z0-9_-]+)(?::([^}]+))?\}/g, (match, tag, val) => {
    return displayItemHtml(`{${tag}:${val || ''}}`);
  });
}

function syncPassiveEffects(passive) {
  const textToScan = `${passive.impact || ''} ${passive.text || ''} ${passive.customText || ''}`;
  
  // Extract tokens from {token:Name}
  const tokenMatches = textToScan.matchAll(/\{token:([^}]+)\}/gi);
  const foundTokens = [];
  for (const m of tokenMatches) {
    if (m[1] && !foundTokens.includes(m[1].trim())) {
      foundTokens.push(m[1].trim());
    }
  }
  if (foundTokens.length > 0) {
    passive.tokens = foundTokens;
  }

  passive.effects ||= {};
  // Extract damage / undef
  const dmgMatch = textToScan.match(/\{(damage|dmg|undef|imparable):(\d+)\}/i);
  if (dmgMatch) {
    passive.effects.damage = parseInt(dmgMatch[2], 10) || 0;
    passive.effects.undefendable = ['undef', 'imparable'].includes(dmgMatch[1].toLowerCase());
  }
  // Extract heal
  const healMatch = textToScan.match(/\{(heal|life|vie|soin):(\d+)\}/i);
  if (healMatch) {
    passive.effects.heal = parseInt(healMatch[2], 10) || 0;
  }
  // Extract stealHp
  const stealHpMatch = textToScan.match(/\{(stealhp|steal_hp):(\d+)\}/i);
  if (stealHpMatch) {
    passive.effects.stealHp = parseInt(stealHpMatch[2], 10) || 0;
  }
  passive.effects.tokens = passive.tokens;
}

function createPassiveQuickChipsRow(input, onUpdate) {
  const row = document.createElement('div');
  row.className = 'passive-quick-chips';
  const chips = [
    { label: '+ {undef:1}', code: '{undef:1}' },
    { label: '+ {undef:2}', code: '{undef:2}' },
    { label: '+ {damage:2}', code: '{damage:2}' },
    { label: '+ {heal:2}', code: '{heal:2}' },
    { label: '+ {heal:3}', code: '{heal:3}' },
    { label: '+ {cp:1}', code: '{cp:1}' },
    { label: '+ {die:white}', code: '{die:white}' },
    { label: '+ {die:orange}', code: '{die:orange}' },
    { label: '+ {die:red}', code: '{die:red}' },
  ];
  chips.forEach((c) => {
    const btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'passive-chip-btn';
    btn.textContent = c.label;
    btn.onclick = () => {
      const pos = input.selectionStart || input.value.length;
      const text = input.value;
      const prefix = (pos > 0 && text[pos - 1] !== ' ') ? ' ' : '';
      const suffix = (pos < text.length && text[pos] !== ' ') ? ' ' : '';
      input.value = text.slice(0, pos) + prefix + c.code + suffix + text.slice(pos);
      input.focus();
      onUpdate();
    };
    row.appendChild(btn);
  });
  return row;
}

function openTokenPickerForPassive(input, onUpdate) {
  input._onTokenInsert = (selectedTokens) => {
    if (selectedTokens.length > 0) {
      const shortcodes = selectedTokens.map(s => `{token:${s}}`).join(' ');
      const pos = input.selectionStart || input.value.length;
      const text = input.value;
      const prefix = (pos > 0 && text[pos - 1] !== ' ') ? ' ' : '';
      const suffix = (pos < text.length && text[pos] !== ' ') ? ' ' : '';
      input.value = text.slice(0, pos) + prefix + shortcodes + suffix + text.slice(pos);
      input.focus();
      onUpdate();
    }
  };
  openTokenModal(input);
}

function renderPassiveItemCard(item, origIndex, zoneType) {
  const card = document.createElement('div');
  card.className = 'passive-item-card';

  // Card Top
  const top = document.createElement('div');
  top.className = 'passive-card-top';

  const badge = document.createElement('span');
  badge.className = `passive-type-badge ${zoneType === 'offensive_failure' ? 'badge-failure' : (zoneType === 'start_of_turn' ? 'badge-start' : 'badge-custom')}`;
  badge.textContent = zoneType === 'offensive_failure' ? 'Offensive Roll Failure' : (zoneType === 'start_of_turn' ? 'Start of Turn' : 'Custom');

  const rm = document.createElement('button');
  rm.className = 'danger small';
  rm.type = 'button';
  rm.textContent = 'Remove';
  rm.onclick = () => {
    selectedProfile.attackPlan.passives.splice(origIndex, 1);
    selectedProfile.passives = selectedProfile.attackPlan.passives;
    setDirty('enemy');
    renderPassiveRules();
    updateTabDots();
  };
  top.append(badge, rm);
  card.appendChild(top);

  if (zoneType === 'custom') {
    // Custom passive layout
    const textGroup = document.createElement('div');
    textGroup.className = 'passive-impact-group';

    const lbl = document.createElement('label');
    lbl.textContent = 'Passive rule (text & tags)';

    const textarea = document.createElement('textarea');
    textarea.rows = 3;
    textarea.className = 'passive-impact-input';
    textarea.value = item.text || item.impact || '';
    textarea.placeholder = 'e.g. Roll 1 {die:white}: on 6 ({die:red}), gains 1 new Head ({token:Chaos}).';

    const tokenBtn = document.createElement('button');
    tokenBtn.type = 'button';
    tokenBtn.className = 'ghost-btn small';
    tokenBtn.textContent = '🪙 Token';
    tokenBtn.style.alignSelf = 'flex-start';
    tokenBtn.title = 'Insert token shortcode';

    const previewBox = document.createElement('div');
    previewBox.className = 'passive-preview-box';

    const updatePreview = () => {
      item.text = textarea.value;
      item.impact = textarea.value;
      syncPassiveEffects(item);
      previewBox.innerHTML = `<span class="passive-preview-label">In-Game Render</span> <div>${formatInlineHtml(item.text) || '<em>Empty passive</em>'}</div>`;
      setDirty('enemy');
      updateTabDots();
    };

    textarea.oninput = updatePreview;
    tokenBtn.onclick = () => openTokenPickerForPassive(textarea, updatePreview);

    const chipsRow = createPassiveQuickChipsRow(textarea, updatePreview);
    chipsRow.prepend(tokenBtn);

    textGroup.append(lbl, textarea, chipsRow, previewBox);
    card.appendChild(textGroup);
    updatePreview();
    return card;
  }

  // Zone 1 & 2 Layout (Offensive Failure & Start of Turn)
  const fieldsRow = document.createElement('div');
  fieldsRow.className = 'passive-fields-row';

  // Target group
  const targetGroup = document.createElement('div');
  targetGroup.className = 'passive-target-group';
  const targetLbl = document.createElement('label');
  targetLbl.textContent = 'Target (receives / applies)';
  const targetSelect = document.createElement('select');
  targetSelect.className = 'passive-target-select';
  [
    { val: 'opponent', label: 'Opponent (Hero)' },
    { val: 'minion', label: 'Minion (Self)' },
    { val: 'both', label: 'Both' },
    { val: 'custom', label: 'Other / Custom' }
  ].forEach((opt) => {
    const el = document.createElement('option');
    el.value = opt.val;
    el.textContent = opt.label;
    if ((item.target || (zoneType === 'offensive_failure' ? 'opponent' : 'minion')) === opt.val) el.selected = true;
    targetSelect.appendChild(el);
  });
  targetGroup.append(targetLbl, targetSelect);

  // Impact group
  const impactGroup = document.createElement('div');
  impactGroup.className = 'passive-impact-group';
  const impactLbl = document.createElement('label');
  impactLbl.textContent = 'Consequence (Impact with tags)';

  const impactWrap = document.createElement('div');
  impactWrap.className = 'passive-impact-wrap';

  const impactInput = document.createElement('input');
  impactInput.type = 'text';
  impactInput.className = 'passive-impact-input';
  impactInput.value = item.impact || '';
  impactInput.placeholder = zoneType === 'offensive_failure'
    ? 'e.g. deals 2 {undef:2} damage or gains {token:Shadows}'
    : 'e.g. gains 1 {token:Chaos} or heals 3 {heal:3}';

  const tokenBtn = document.createElement('button');
  tokenBtn.type = 'button';
  tokenBtn.className = 'ghost-btn small';
  tokenBtn.textContent = '🪙 Token';
  tokenBtn.title = 'Insert token shortcode';

  impactWrap.append(impactInput, tokenBtn);

  // Preview Box
  const previewBox = document.createElement('div');
  previewBox.className = 'passive-preview-box';

  // Override details
  const overrideDetails = document.createElement('details');
  overrideDetails.className = 'passive-override-details';
  if (item.customText) overrideDetails.open = true;
  const summary = document.createElement('summary');
  summary.textContent = 'Render override (custom English text)';
  const overrideInput = document.createElement('input');
  overrideInput.type = 'text';
  overrideInput.value = item.customText || '';
  overrideInput.placeholder = 'Optional: Override the generated English phrase';
  overrideDetails.append(summary, overrideInput);

  const updateAll = () => {
    item.target = targetSelect.value;
    item.impact = impactInput.value;
    item.customText = overrideInput.value;
    item.text = buildPassiveSentence(item);
    syncPassiveEffects(item);
    previewBox.innerHTML = `<span class="passive-preview-label">Preview</span> <div>${formatInlineHtml(item.text)}</div>`;
    setDirty('enemy');
    updateTabDots();
  };

  tokenBtn.onclick = () => openTokenPickerForPassive(impactInput, updateAll);

  targetSelect.onchange = updateAll;
  impactInput.oninput = updateAll;
  overrideInput.oninput = updateAll;

  // Quick chips
  const chipsRow = createPassiveQuickChipsRow(impactInput, updateAll);

  impactGroup.append(impactLbl, impactWrap, chipsRow);
  fieldsRow.append(targetGroup, impactGroup);
  card.append(fieldsRow, previewBox, overrideDetails);

  updateAll();
  return card;
}

function renderPassiveRules() {
  const failureRoot = $('passiveFailureRules');
  const startRoot = $('passiveStartOfTurnRules');
  const customRoot = $('passiveCustomRules');
  if (!failureRoot || !startRoot || !customRoot) return;

  failureRoot.innerHTML = '';
  startRoot.innerHTML = '';
  customRoot.innerHTML = '';

  const passivesList = ensureProfilePassivesList();

  let failureCount = 0;
  let startCount = 0;
  let customCount = 0;

  passivesList.forEach((item, index) => {
    const type = item.type || 'custom';
    if (type === 'offensive_failure') {
      failureRoot.appendChild(renderPassiveItemCard(item, index, 'offensive_failure'));
      failureCount++;
    } else if (type === 'start_of_turn') {
      startRoot.appendChild(renderPassiveItemCard(item, index, 'start_of_turn'));
      startCount++;
    } else {
      customRoot.appendChild(renderPassiveItemCard(item, index, 'custom'));
      customCount++;
    }
  });

  if (failureCount === 0) {
    failureRoot.innerHTML = '<div class="passive-empty-hint">No offensive roll failure passive. Click "+ Add failure passive" to create one.</div>';
  }
  if (startCount === 0) {
    startRoot.innerHTML = '<div class="passive-empty-hint">No start-of-turn passive. Click "+ Add start-of-turn passive" to create one.</div>';
  }
  if (customCount === 0) {
    customRoot.innerHTML = '<div class="passive-empty-hint">No custom passive. Click "+ Add custom passive" to create one.</div>';
  }
}

function addPassiveItem(type) {
  if (!selectedProfile) return;
  ensureProfilePassivesList();
  const newPassive = {
    type: type,
    timing: type === 'offensive_failure' ? 'offensiveRollFailed' : (type === 'start_of_turn' ? 'minionUpkeep' : 'custom'),
    target: type === 'offensive_failure' ? 'opponent' : 'minion',
    impact: '',
    customText: '',
    text: '',
    tokens: [],
    effects: {
      damage: 0,
      undefendable: false,
      stealHp: 0,
      stealCp: 0,
      heal: 0,
      drawCards: 0,
      discardCards: 0,
      topDeckToDiscard: 0,
      tokens: [],
      formulas: []
    }
  };
  selectedProfile.attackPlan.passives.push(newPassive);
  selectedProfile.passives = selectedProfile.attackPlan.passives;
  renderPassiveRules();
  setDirty('enemy');
  updateTabDots();
}

function validateTokens() {
  const tokenLabels = (tokenCatalog || []).map(t => t.label);
  document.querySelectorAll('.token-input').forEach(input => {
    const vals = csv(input.value);
    if (vals.length === 0) {
      input.classList.remove('valid', 'invalid');
      return;
    }
    const allValid = vals.every(v => tokenLabels.includes(v));
    input.classList.toggle('valid', allValid);
    input.classList.toggle('invalid', !allValid);
  });
}
const SUPPORTED_FORMULAS = [
  // --- DEFENSE : PRÉVENTION ---
  {
    category: 'Défense - Prévention',
    name: 'Ignorer tous les dégâts entrants',
    syntax: 'ignoreAllIncomingDamage = true',
    aliases: ['ignoreAllIncomingDamage=true'],
    description: 'Annule l\'intégralité des dégâts entrants infligés par l\'attaque adverse, même si celle-ci est indéfendable.',
    example: 'Attaque entrante: 12 dégâts ➔ Dégâts subis: 0 (totalement ignoré).'
  },
  {
    category: 'Défense - Prévention',
    name: 'Prévenir la moitié des dégâts entrants',
    syntax: 'prevent = ceil(incomingDamage / 2)',
    aliases: ['prevent = ceil(incomingDamage/2)'],
    description: 'Prévient la moitié des dégâts entrants de l\'attaque du héros (arrondi supérieur).',
    example: 'Attaque entrante: 5 dégâts ➔ Prévenu: 3 dégâts (2 subis).'
  },
  {
    category: 'Défense - Prévention',
    name: 'Prévenir la valeur faciale du jet défensif',
    syntax: 'prevent = defenseDieValue',
    aliases: ['prevent = defensedie', 'prevent = jetdefensif', 'prevent = d6value'],
    description: 'Prévient un montant de dégâts égal à la valeur faciale du dé de défense lancé dans l\'arène.',
    example: 'Dé de défense: 4 ➔ Prévenu: 4 dégâts.'
  },
  {
    category: 'Défense - Prévention',
    name: 'Prévenir la moitié d\'un dé additionnel D6',
    syntax: 'prevent = ceil(rollD6() / 2)',
    aliases: ['prevent = ceil(d6 / 2)', 'prevent = rollD6() / 2', 'prevent = ceil(rolld6()/2)'],
    description: 'Lance un dé D6 additionnel lors de la défense et prévient la moitié du résultat (arrondi supérieur).',
    example: 'Dé D6: 5 ➔ Prévenu: 3 dégâts.'
  },
  {
    category: 'Défense - Prévention',
    name: 'Prévenir le total d\'un dé additionnel D6',
    syntax: 'prevent = rollD6()',
    aliases: ['prevent = d6', 'prevent = rollAdditionalDie()'],
    description: 'Lance un dé D6 additionnel lors de la défense et prévient la valeur totale obtenue.',
    example: 'Dé D6: 6 ➔ Prévenu: 6 dégâts.'
  },

  // --- DEFENSE : RIPOSTES (DÉGÂTS EN RETOUR) ---
  {
    category: 'Défense - Riposte (Dégâts en retour)',
    name: 'Riposte de la moitié des dégâts entrants',
    syntax: 'returnDamage = ceil(incomingDamage / 2)',
    aliases: ['returnDamage = ceil(incomingDamage/2)'],
    description: 'Renvoie au héros attaquant la moitié des dégâts entrants reçus (arrondi supérieur).',
    example: 'Attaque entrante: 6 dégâts ➔ Renvoie: 3 dégâts au héros.'
  },
  {
    category: 'Défense - Riposte (Dégâts en retour)',
    name: 'Riposte de la moitié du jet défensif',
    syntax: 'returnDamage = ceil(defenseDieValue / 2)',
    aliases: ['returnDamage = ceil(defensedie / 2)', 'returnDamage = ceil(defenseDieValue/2)'],
    description: 'Renvoie au héros la moitié de la valeur du dé de défense lancé (arrondi supérieur) en dégâts directs indéfendables.',
    example: 'Dé de défense: 5 ➔ Renvoie 3 dégâts indéfendables au héros.'
  },
  {
    category: 'Défense - Riposte (Dégâts en retour)',
    name: 'Riposte de la moitié d\'un dé additionnel D6',
    syntax: 'returnDamage = ceil(rollD6() / 2)',
    aliases: ['returnDamage = ceil(d6 / 2)', 'returnDamage = rollD6() / 2', 'returnDamage = ceil(rolld6()/2)'],
    description: 'Lance un dé D6 additionnel lors de la défense et inflige la moitié du résultat en dégâts directs indéfendables au héros.',
    example: 'Dé D6: 5 ➔ Renvoie 3 dégâts indéfendables au héros.'
  },

  // --- DEFENSE : COMBINÉE ---
  {
    category: 'Défense - Formule Combinée',
    name: 'Dé additionnel D6 : Riposte 1/2 & Prévention 1/2',
    syntax: 'returnDamage = ceil(rollD6() / 2) & prevent = ceil(rollD6() / 2)',
    aliases: ['prevent = ceil(rollD6() / 2); returnDamage = ceil(rollD6() / 2)'],
    description: 'Lance un dé D6 additionnel unique partagé : prévient la moitié du dé ET inflige la moitié du dé en riposte directe indéfendable.',
    example: 'Dé D6: 5 ➔ Prévenu: 3 dégâts & Riposte: 3 dégâts au héros.'
  },

  // --- DEFENSE : SOIN ---
  {
    category: 'Défense - Soin',
    name: 'Soin au dé additionnel D6 (Partage 50/50 à 2 sbires)',
    syntax: 'heal = rollD6()',
    aliases: ['heal = d6', 'minionHeal = rollD6()', 'soin = rollD6()'],
    description: 'Lance un dé D6 additionnel : le sbire gagne la valeur en PV. En mode difficile si 2 sbires sont encore en vie, le dé est divisé par 2 (arrondi sup.) et chaque sbire gagne cette moitié en PV.',
    example: 'Dé D6: 5 ➔ 1 sbire: +5 PV / 2 sbires en vie: +3 PV chacun.'
  },

  // --- DEFENSE : CAPACITÉ ---
  {
    category: 'Défense - Capacité Passive',
    name: 'Déclencher la capacité passive en défense',
    syntax: 'activatePassiveAbility = true',
    aliases: ['activatePassiveAbility = true'],
    description: 'Active la règle passive défensive spéciale du monstre (ex. Viseer).',
    example: 'Déclenche la règle passive après la résolution défensive.'
  },

  // --- DEFENSE : PLAFOND DE DÉGÂTS ---
  {
    category: 'Défense - Plafond de Dégâts',
    name: 'Plafond de dégâts subis par attaque',
    syntax: 'damageCap = 6',
    aliases: ['damageCap = 6', 'maxIncomingDamage = 6'],
    description: 'Plafonne les dégâts subis par le monstre à un maximum de X par attaque (ex. Horde de Gobelins). Bloque également le compteur ATK du héros à X et prévient tout surplus.',
    example: 'damageCap = 6 ➔ Une attaque de 10 dégâts est ramenée à 6 dégâts subis au maximum.'
  },

  // --- DEFENSE : ALTÉRATION & DÉGÂTS CONDITIONNELS ---
  {
    category: 'Défense - Altération Conditionnelle',
    name: 'Inflige Brûlure ou dégâts directs si stack max atteint',
    syntax: 'burnOrDamageIfMax = 2',
    aliases: ['burnOrDamageIfMax = 2', 'tokenOrDamageIfMax = 2'],
    description: 'Inflige le statut Brûlure au joueur. Si le joueur possède déjà le maximum de stacks de Brûlure (1), lui inflige 2 dégâts indéfendables directs à la place (ex. The Ashen King).',
    example: 'Héros sans Brûlure ➔ Reçoit Brûlure. Héros avec 1 Brûlure ➔ Reçoit 2 dégâts indéfendables.'
  },

  // --- DEFENSE : ESQUIVE TOTALE ---
  {
    category: 'Défense - Esquive Totale',
    name: 'Attaque échoue complètement sur seuil de dé',
    syntax: 'attackFailsIfD6 >= 5',
    aliases: ['attackFailsIfD6 >= 5', 'evadeAllOnD6 >= 5'],
    description: 'Si le dé de défense (ou dé additionnel) est supérieur ou égal au seuil X (ex: 5 ou 6 pour Wyverne), l\'attaque du héros échoue complètement : 0 dégât subi et aucun jeton/altération appliqué.',
    example: 'Dé de défense: 5 ou 6 ➔ L\'attaque du héros échoue (0 dégât, aucun token appliqué).'
  },

  // --- DEFENSE : RIXE & FUITE ---
  {
    category: 'Défense - Fuite & Rixe',
    name: 'Rixe (1-5) ou Fuite (6)',
    syntax: 'if D6 <= 5: stealCp = 1 & returnDamage = 1 (undef); fleeIfD6 == 6',
    aliases: ['fleeIfD6 == 6', 'stealCp = 1 & returnDamage = 1 (undef) if D6 <= 5', 'fleeOnD6 == 6'],
    description: 'Sur 1 à 5 au dé défensif, le monstre vole 1 CP et inflige 1 dégât imparable au héros. Sur un 6, il prend la fuite : esquive tous les dégâts, aucun loot et arrêt immédiat du combat sans points de victoire (ex. Pillard Gobelin).',
    example: 'Dé de défense: 3 ➔ Vole 1 CP & 1 dégât imparable. Dé de défense: 6 ➔ Fuite immédiate du combat.'
  },

  // --- ATTAQUE : FORMULES DE DÉGÂTS ---
  {
    category: 'Attaque - Formules de Dégâts',
    name: 'Dégâts basés sur les CP actuels du sbire',
    syntax: 'cp',
    aliases: ['cp'],
    description: 'Inflige un montant de dégâts égal au nombre de CP actuels du sbire au moment de l\'attaque (ex. Rat de la Rue).',
    example: 'Sbire avec 4 CP ➔ Inflige 4 dégâts.'
  },
  {
    category: 'Attaque - Formules de Dégâts',
    name: 'Dégâts basés sur les CP après vol de CP',
    syntax: 'cp+cpSteal',
    aliases: ['cp+cpSteal'],
    description: 'Inflige un montant de dégâts égal aux CP du sbire calculés après avoir volé les CP du héros (ex. Rat de la Rue).',
    example: 'Sbire à 2 CP volant 2 CP ➔ Total: 4 CP ➔ Inflige 4 dégâts.'
  },
  {
    category: 'Attaque - Formules de Dégâts',
    name: 'Hydre Féroce - Dégâts par Tête (Chaos)',
    syntax: 'damage = 6 + 3 * tokens(Chaos)',
    aliases: ['damage = 6 + 3 * chaos', '6 + 3 * tokens(Chaos)'],
    description: 'Inflige 6 dégâts de base + 3 dégâts supplémentaires par Tête / jeton Chaos en possession de l\'Hydre au moment de l\'attaque (ex. Hydre Féroce).',
    example: 'Hydre avec 3 jetons Chaos ➔ 6 + (3 * 3) = 15 dégâts.'
  },
  {
    category: 'Défense - Mécaniques Uniques',
    name: 'Hydre Féroce - Défense Unique & Régénération (Chaos)',
    syntax: 'reviveOnZeroHpWithChaos(8)',
    aliases: ['hydraRevival', 'reviveWithChaos'],
    description: 'Défense Unique : Si la Santé de l\'Hydre est réduite à 0 alors qu\'il reste des Têtes (jetons Chaos), retire 1 Tête et réinitialise sa Santé à 8 PV (s\'applique même contre une Capacité Ultime).',
    example: 'Hydre à 0 PV avec 2 Chaos ➔ Consomme 1 Chaos (reste 1) et régénère 8 PV.'
  },
  {
    category: 'Défense - Altération Conditionnelle',
    name: 'Gain de jeton si au moins 1 dégât subi',
    syntax: 'gainTokenIfDamaged = Chaos',
    aliases: ['gainTokenIfDamaged = Chaos', 'gainTokenIfDamage = Chaos', 'gainTokenOnDamage = Chaos'],
    description: 'Le sbire gagne 1 jeton (ex. Chaos) sans lancer de dé, si et seulement si l\'attaquant lui inflige au moins 1 dégât (ex. Berserker Enragé).',
    example: 'Dégâts infligés >= 1 ➔ Le sbire gagne 1 jeton Chaos. Dégâts = 0 ➔ Aucun jeton gagné.'
  }
];

window.copyFormulaText = function(btn, text) {
  if (navigator?.clipboard?.writeText) {
    navigator.clipboard.writeText(text).then(() => {
      const old = btn.textContent;
      btn.textContent = '✓ Copié !';
      btn.style.borderColor = '#6ed188';
      btn.style.color = '#6ed188';
      setTimeout(() => {
        btn.textContent = old;
        btn.style.borderColor = '';
        btn.style.color = '';
      }, 1500);
    });
  }
};

function formulaRefs() {
  const refs = new Map();
  for (const profile of sourceData?.profiles || []) {
    const scan = (items = [], kind) => {
      for (const item of items) {
        for (const formula of item.formulas || []) {
          const key = String(formula || '').trim();
          if (!key) continue;
          const cleanKey = key.replaceAll(' ', '').toLowerCase();
          if (!refs.has(cleanKey)) refs.set(cleanKey, { original: key, profiles: [] });
          const entry = profile.name + ' (' + kind + ')';
          if (!refs.get(cleanKey).profiles.includes(entry)) {
            refs.get(cleanKey).profiles.push(entry);
          }
        }
        if (item.damageFormula) {
          const key = String(item.damageFormula).trim();
          const cleanKey = key.replaceAll(' ', '').toLowerCase();
          if (!refs.has(cleanKey)) refs.set(cleanKey, { original: key, profiles: [] });
          const entry = profile.name + ' (' + kind + ')';
          if (!refs.get(cleanKey).profiles.includes(entry)) {
            refs.get(cleanKey).profiles.push(entry);
          }
        }
      }
    };
    scan(profile.attackPlan?.actions || [], 'attack');
    scan(profile.defensePlan?.effects || [], 'defense');
    for (const rule of profile.attackPlan?.conditionalRules || []) {
      if (rule.effect?.damageFormula) {
        const key = String(rule.effect.damageFormula).trim();
        const cleanKey = key.replaceAll(' ', '').toLowerCase();
        if (!refs.has(cleanKey)) refs.set(cleanKey, { original: key, profiles: [] });
        const entry = profile.name + ' (attack)';
        if (!refs.get(cleanKey).profiles.includes(entry)) {
          refs.get(cleanKey).profiles.push(entry);
        }
      }
    }
  }
  return refs;
}

function renderFormulaList() {
  const root = $('formulaList');
  if (!root) return;
  const refs = formulaRefs();
  const search = String($('formulaSearch')?.value || '').trim().toLowerCase();

  // Find matching profiles for each supported formula
  const supportedWithMatches = SUPPORTED_FORMULAS.map((item) => {
    const matches = new Set();
    const candidates = [item.syntax, ...(item.aliases || [])];
    for (const cand of candidates) {
      const cleanCand = cand.replaceAll(' ', '').toLowerCase();
      for (const [cleanKey, data] of refs.entries()) {
        if (cleanKey === cleanCand || cleanKey.includes(cleanCand) || cleanCand.includes(cleanKey)) {
          for (const p of data.profiles) matches.add(p);
        }
      }
    }
    return { ...item, profiles: [...matches] };
  });

  // Track which database keys were matched
  const matchedCleanKeys = new Set();
  supportedWithMatches.forEach((item) => {
    const candidates = [item.syntax, ...(item.aliases || [])];
    for (const cand of candidates) {
      const cleanCand = cand.replaceAll(' ', '').toLowerCase();
      for (const [cleanKey] of refs.entries()) {
        if (cleanKey === cleanCand || cleanKey.includes(cleanCand) || cleanCand.includes(cleanKey)) {
          matchedCleanKeys.add(cleanKey);
        }
      }
    }
  });

  // Filter by search query
  const filteredSupported = supportedWithMatches.filter((item) => {
    if (!search) return true;
    const hay = [
      item.name,
      item.syntax,
      item.category,
      item.description,
      ...(item.aliases || []),
      ...(item.profiles || [])
    ].join(' ').toLowerCase();
    return hay.includes(search);
  });

  // Group by category
  const categories = [];
  filteredSupported.forEach((item) => {
    let cat = categories.find((c) => c.title === item.category);
    if (!cat) {
      cat = { title: item.category, items: [] };
      categories.push(cat);
    }
    cat.items.push(item);
  });

  const cardsHtml = categories.map((cat) => {
    const itemsHtml = cat.items.map((item) => {
      const escapedSyntax = escapeText(item.syntax);
      const profilesText = item.profiles.length
        ? '<span style="color:#7ee787;">✓ Utilisé par : ' + item.profiles.map(escapeText).join(', ') + '</span>'
        : '<span style="color:#667366;font-style:italic;">○ Non utilisé actuellement (disponible)</span>';
      const aliasesHtml = item.aliases && item.aliases.length
        ? '<div class="formula-aliases"><span>Variantes :</span> ' + item.aliases.map((a) => '<code>' + escapeText(a) + '</code>').join(' ') + '</div>'
        : '';

      return `
        <div class="formula-card">
          <div class="formula-head">
            <span class="formula-name">${escapeText(item.name)}</span>
            <span class="formula-badge">${escapeText(cat.title.split(' - ')[0])}</span>
          </div>
          <div class="formula-code-row">
            <code title="Cliquer pour copier" onclick="copyFormulaText(this, '${escapedSyntax}')">${escapedSyntax}</code>
            <button type="button" class="formula-copy-btn" onclick="copyFormulaText(this, '${escapedSyntax}')">Copier</button>
          </div>
          <div class="formula-desc">${escapeText(item.description)}</div>
          <div class="formula-example">Exemple : ${escapeText(item.example)}</div>
          ${aliasesHtml}
          <div class="formula-profiles"><strong>Sbires :</strong> ${profilesText}</div>
        </div>
      `;
    }).join('');

    return `
      <div class="formula-category-section">
        <div class="formula-category-title">${escapeText(cat.title)}</div>
        <div style="display:grid;gap:10px;">${itemsHtml}</div>
      </div>
    `;
  }).join('');

  // Unlisted formulas found in profiles
  const customEntries = [...refs.entries()].filter(([cleanKey]) => !matchedCleanKeys.has(cleanKey));
  let customHtml = '';
  if (customEntries.length) {
    const customCards = customEntries
      .filter(([cleanKey, data]) => {
        if (!search) return true;
        const hay = (data.original + ' ' + data.profiles.join(' ')).toLowerCase();
        return hay.includes(search);
      })
      .map(([cleanKey, data]) => `
        <div class="formula-card" style="border-style:dashed;">
          <div class="formula-head">
            <span class="formula-name">Formule personnalisée / locale</span>
            <span class="formula-badge" style="background:#2a1e11;color:#ffb340;border-color:#5c3e1e;">JSON Custom</span>
          </div>
          <div class="formula-code-row">
            <code>${escapeText(data.original)}</code>
            <button type="button" class="formula-copy-btn" onclick="copyFormulaText(this, '${escapeText(data.original)}')">Copier</button>
          </div>
          <div class="formula-profiles"><strong>Utilisé par :</strong> <span style="color:#7ee787;">${data.profiles.map(escapeText).join(', ')}</span></div>
        </div>
      `).join('');

    if (customCards) {
      customHtml = `
        <div class="formula-category-section" style="margin-top:16px;">
          <div class="formula-category-title" style="color:#79c0ff;border-color:#2a4060;">Autres formules détectées dans le fichier JSON</div>
          <div style="display:grid;gap:10px;">${customCards}</div>
        </div>
      `;
    }
  }

  if (!cardsHtml && !customHtml) {
    root.innerHTML = '<em style="color:#728074;padding:12px;display:block;">Aucune formule ne correspond à votre recherche.</em>';
    return;
  }

  root.innerHTML = cardsHtml + customHtml;
}
function tokenRefs(name) {
  const needle = String(name || '').toLowerCase();
  const minions = [];
  const heroes = [];
  for (const profile of sourceData?.profiles || []) {
    const values = [
      ...(profile.initialTokens || []),
      ...((profile.attackPlan?.actions || []).flatMap((action) => action.tokens || [])),
      ...((profile.defensePlan?.effects || []).flatMap((effect) => effect.tokens || [])),
    ];
    if (values.some((token) => String(token).toLowerCase() === needle)) minions.push(profile.name);
  }
  const heroTokens = tokenSourceData?.heroTokens || {};
  for (const [hero, tokens] of Object.entries(heroTokens)) {
    if ((tokens || []).some((token) => String(token).toLowerCase() === needle)) heroes.push(hero);
  }
  return { heroes, minions };
}
function renderTokenAdmin() {
  const root = $('tokenList');
  if (!root) return;
  const query = ($('tokenSearch')?.value || '').trim().toLowerCase();
  const rows = tokenCatalog
    .map((token, index) => ({ token, index }))
    .filter(({ token }) => {
      const hay = [token.label, token.frLabel, token.kind, ...(token.aliases || [])].join(' ').toLowerCase();
      return !query || hay.includes(query);
    });
  root.innerHTML = rows.map(({ token, index }) => {
    const refs = tokenRefs(token.label);
    const persistence = token.persistence || (token.persistent === false ? 'non_persistent' : 'persistent');
    return '<article class="token-admin-card" data-token-index="' + index + '">' +
      '<div class="token-admin-head"><img src="' + assetUrl(token.imageAsset) + '" alt="' + escapeAttr(token.label) + '" /><div><strong>' + escapeText(token.label || 'Token') + '</strong><div class="hint">' + escapeText(token.kind || '') + '<div class="token-highlight" style="font-size:12px; margin-top:4px;">{token:' + escapeText(token.label) + '}</div>' + '</div></div></div>' +
      '<div class="token-admin-grid">' +
      '<label>UK title<input class="tok-label" value="' + escapeAttr(token.label || '') + '" /></label>' +
      '<label>FR title<input class="tok-fr" value="' + escapeAttr(token.frLabel || '') + '" /></label>' +
      '<label>Kind<select class="tok-kind"><option value="positive" ' + (token.kind === 'positive' ? 'selected' : '') + '>positive</option><option value="negative" ' + (token.kind === 'negative' ? 'selected' : '') + '>negative</option><option value="unique" ' + (token.kind === 'unique' ? 'selected' : '') + '>unique</option></select></label>' +
      '<label>Persistence<select class="tok-persistence"><option value="persistent" ' + (persistence === 'persistent' ? 'selected' : '') + '>Persistent</option><option value="semi_persistent" ' + (persistence === 'semi_persistent' ? 'selected' : '') + '>Semi-persistent</option><option value="non_persistent" ' + (persistence === 'non_persistent' ? 'selected' : '') + '>Non-persistent</option></select></label>' +
      '<label>Max stack<input class="tok-max" type="number" value="' + escapeAttr(token.maxStack ?? 1) + '" /></label>' +
      '<label>Image asset<input class="tok-asset" value="' + escapeAttr(token.imageAsset || '') + '" /></label>' +
      '<label>Aliases<input class="tok-aliases" value="' + escapeAttr((token.aliases || []).join(', ')) + '" /></label>' +
      '<label class="checkline"><input class="tok-supported" type="checkbox" ' + (token.appSupported ? 'checked' : '') + ' />App enabled</label>' +
      '<label class="checkline"><input class="tok-animation" type="checkbox" ' + (token.appAnimation ? 'checked' : '') + ' />App animation</label>' +
      '<label class="checkline"><input class="tok-removable" type="checkbox" ' + (token.removable !== false ? 'checked' : '') + ' />Removable</label>' +
      '<label class="checkline"><input class="tok-minion" type="checkbox" ' + (token.minionAllowed !== false ? 'checked' : '') + ' />Can affect enemies</label>' +
      '<label class="checkline"><input class="tok-visible" type="checkbox" ' + (token.editorVisible !== false ? 'checked' : '') + ' />Visible in token list</label>' +
      '</div>' +
      '<label class="wide-label">Description<textarea class="tok-desc" rows="3">' + escapeText(token.description || '') + '</textarea></label>' +
      '<label class="wide-label">Code / App Details (Ce qui a été codé dans l\'application)<textarea class="tok-app-details" rows="2" placeholder="Ex: Géré automatiquement lors de la phase d\'upkeep...">' + escapeText(token.appDetails || '') + '</textarea></label>' +
      '<div class="token-refs"><span><strong>Heroes:</strong> ' + escapeText(refs.heroes.join(', ') || '-') + '</span><span><strong>Minions:</strong> ' + escapeText(refs.minions.join(', ') || '-') + '</span></div>' +
      '</article>';
  }).join('') || '<em>No token found.</em>';
  root.querySelectorAll('.token-admin-card').forEach((card) => {
    card.addEventListener('input', () => { collectTokensFromAdmin(); setDirty('token'); ensureTokenDatalist(); });
    card.addEventListener('change', () => { collectTokensFromAdmin(); setDirty('token'); ensureTokenDatalist(); });
  });
}
function collectTokensFromAdmin() {
  const root = $('tokenList');
  if (!root) return;
  root.querySelectorAll('.token-admin-card').forEach((card) => {
    const token = tokenCatalog[Number(card.dataset.tokenIndex)];
    if (!token) return;
    token.label = card.querySelector('.tok-label').value.trim();
    token.frLabel = card.querySelector('.tok-fr').value.trim();
    token.kind = card.querySelector('.tok-kind').value;
    const persVal = card.querySelector('.tok-persistence').value;
    token.persistence = persVal;
    token.persistent = persVal !== 'non_persistent';
    token.maxStack = intVal(card.querySelector('.tok-max').value, 1);
    token.imageAsset = card.querySelector('.tok-asset').value.trim() || null;
    token.aliases = csv(card.querySelector('.tok-aliases').value);
    token.appSupported = card.querySelector('.tok-supported').checked;
    token.appAnimation = card.querySelector('.tok-animation').checked;
    token.removable = card.querySelector('.tok-removable').checked;
    token.minionAllowed = card.querySelector('.tok-minion').checked;
    token.editorVisible = card.querySelector('.tok-visible').checked;
    token.description = card.querySelector('.tok-desc').value.trim();
    token.appDetails = card.querySelector('.tok-app-details').value.trim();
  });
}
function updateRewardWarnings() {
  const chests = parseInt($('rewardChestsInput').value, 10);
  const rank = $('rewardRankInput').value.trim();
  if (!chests || chests === 0) {
    $('rewardChestsInput').classList.add('invalid-warning');
  } else {
    $('rewardChestsInput').classList.remove('invalid-warning');
  }
  if (!rank) {
    $('rewardRankInput').classList.add('invalid-warning');
  } else {
    $('rewardRankInput').classList.remove('invalid-warning');
  }
}

function bindBasics() {
  ['nameInput','keyInput','rankInput','hpInput','cpInput','defenseDiceInput','rewardChestsInput','rewardRankInput','cardAssetInput','initialTokensNbInput','initialTokensInput','sourcePackInput','attackStyleInput','attackNameInput','attacksTextInput','defenseTextInput','passivesTextInput','attacksDisplayRowsInput','defenseDisplayRowsInput','passivesDisplayRowsInput'].forEach((id) => {
    $(id).addEventListener('input', () => { collectCurrent(); setDirty('enemy'); renderLists(); renderPreview(); renderDisplayRowsPreviews(); renderMeta(); updateRewardWarnings(); });
    $(id).addEventListener('change', () => { collectCurrent(); setDirty('enemy'); renderLists(); renderPreview(); renderDisplayRowsPreviews(); renderMeta(); updateRewardWarnings(); });
  });
}
document.addEventListener('DOMContentLoaded', () => {
  initAuth();
  setupUIEnhancements();
  renderLogs();

  $('cancelTokenModalBtn')?.addEventListener('click', () => {
    $('tokenModal').style.display = 'none';
    activeTokenInput = null;
  });

  $('confirmTokenModalBtn')?.addEventListener('click', () => {
    if (activeTokenInput) {
      const checkboxes = $('tokenCheckboxes').querySelectorAll('input[type="checkbox"]:checked');
      const selected = Array.from(checkboxes).map(cb => cb.value);

      if (typeof activeTokenInput._onTokenInsert === 'function') {
        activeTokenInput._onTokenInsert(selected);
        activeTokenInput._onTokenInsert = null;
      } else {
        activeTokenInput.value = selected.join(', ');

        if (activeTokenInput.id === 'initialTokensInput') {
          const nbInput = $('initialTokensNbInput');
          if (nbInput) {
            if (selected.length > 0 && !nbInput.value.trim()) {
              nbInput.value = '1';
            } else if (selected.length === 0) {
              nbInput.value = '';
            }
            nbInput.dispatchEvent(new Event('input', { bubbles: true }));
          }
        }

        const parentCard = activeTokenInput.closest('.action-card, .outcome-row');
        if (parentCard) {
          const nbInput = parentCard.querySelector('.effect-nb, .out-nb');
          if (nbInput) {
            if (selected.length > 0 && !nbInput.value.trim()) {
              nbInput.value = '1';
            } else if (selected.length === 0) {
              nbInput.value = '';
            }
            nbInput.dispatchEvent(new Event('input', { bubbles: true }));
          }
        }

        activeTokenInput.dispatchEvent(new Event('change', { bubbles: true }));
        activeTokenInput.dispatchEvent(new Event('input', { bubbles: true }));
      }
    }
    $('tokenModal').style.display = 'none';
    activeTokenInput = null;
  });

  loadTokenCatalog();
  $('loadDefaultBtn').onclick = loadDefault;
  $('openFileBtn').onclick = openLocalJson;
  $('saveFileBtn').onclick = saveLocalFile;
  $('exportJsonBtn').onclick = exportJson;
  $('exportTokenJsonBtn').onclick = exportTokenJson;
  $('jsonVersionInput')?.addEventListener('input', (e) => {
    if (sourceData) {
      sourceData.version = e.target.value.trim();
      setDirty('enemy');
    }
  });
  if ($('validateAtkBtn')) $('validateAtkBtn').onclick = toggleValidateAtk;
  if ($('validateDefBtn')) $('validateDefBtn').onclick = toggleValidateDef;
  if ($('validateBtn')) {
    $('validateBtn').onclick = () => {
      toggleValidateAtk();
      toggleValidateDef();
    };
  }
  if ($('cleanLegacyTextBtn')) {
    $('cleanLegacyTextBtn').onclick = () => {
      if (!selectedProfile) return;
      selectedProfile.attacks = [];
      selectedProfile.defense = '';
      selectedProfile.passives = [];
      $('attacksTextInput').value = '';
      $('defenseTextInput').value = '';
      $('passivesTextInput').value = '';
      setDirty('enemy');
      renderEditor();
    };
  }
  
  $('addPassiveFailureBtn')?.addEventListener('click', () => addPassiveItem('offensive_failure'));
  $('addPassiveStartBtn')?.addEventListener('click', () => addPassiveItem('start_of_turn'));
  $('addPassiveCustomBtn')?.addEventListener('click', () => addPassiveItem('custom'));
  if ($('addPassiveRuleBtn')) {
    $('addPassiveRuleBtn').onclick = () => addPassiveItem('custom');
  }

  $('enemySearch').oninput = renderLists;
  $('tokenSearch').oninput = renderTokenAdmin;
  $('addAttackActionBtn').onclick = addAction;
  $('addConditionalRuleBtn').onclick = addConditionalRule;
  $('addDefenseEffectBtn').onclick = addDefense;
  $('syncDefenseDiceBtn').onclick = () => { selectedProfile.defensePlan ||= {}; selectedProfile.defensePlan.dice = intVal($('defenseDiceInput').value); setDirty('enemy'); flash('Defense dice synced.'); };
  $('generateAttackRowsBtn').onclick = generateAttackRows;
  $('generateDefenseRowsBtn').onclick = generateDefenseRows;
  $('generatePassiveRowsBtn').onclick = generatePassiveRows;

  document.querySelectorAll('.tab').forEach((tab) => {
    tab.onclick = () => {
      document.querySelectorAll('.tab').forEach((item) => item.classList.remove('active'));
      document.querySelectorAll('.tab-panel').forEach((panel) => panel.classList.remove('active'));
      tab.classList.add('active');
      $(`tab-${tab.dataset.tab}`).classList.add('active');
      if (tab.dataset.tab === 'formulas') renderFormulaList();
      if (tab.dataset.tab === 'tokens') renderTokenAdmin();
    };
  });
  $('formulaSearch')?.addEventListener('input', renderFormulaList);
  bindBasics();
  updateDownloadButtons();
  loadDefault();
});


function setupUIEnhancements() {
  $('cardImage')?.addEventListener('click', (e) => {
    if (!e.target.src) return;
    $('imageModalImg').src = e.target.src;
    $('imageModal').style.display = 'grid';
  });
  $('previewImage')?.addEventListener('click', (e) => {
    if (!e.target.src) return;
    $('imageModalImg').src = e.target.src;
    $('imageModal').style.display = 'grid';
  });
  $('imageModal')?.addEventListener('click', () => {
    $('imageModal').style.display = 'none';
  });
  
  document.addEventListener('input', (e) => {
    if (e.target.classList.contains('token-input')) {
      validateTokens();
    }
  });

  // Collapsible Panes
  $('toggleSidebarBtn')?.addEventListener('click', () => {
    $('mainAppShell').classList.add('sidebar-collapsed');
    $('collapsedSidebarStrip').classList.remove('hidden');
  });
  $('expandSidebarBtn')?.addEventListener('click', () => {
    $('mainAppShell').classList.remove('sidebar-collapsed');
    $('collapsedSidebarStrip').classList.add('hidden');
  });
  
  $('toggleCardPaneBtn')?.addEventListener('click', () => {
    $('cardPane').classList.add('hidden');
    $('collapsedCardStrip').classList.remove('hidden');
    updateLayoutClass();
  });
  $('expandCardPaneBtn')?.addEventListener('click', () => {
    $('cardPane').classList.remove('hidden');
    $('collapsedCardStrip').classList.add('hidden');
    updateLayoutClass();
  });
  
  $('togglePhonePaneBtn')?.addEventListener('click', () => {
    $('phonePane').classList.add('hidden');
    $('collapsedPhoneStrip').classList.remove('hidden');
    updateLayoutClass();
  });
  $('expandPhonePaneBtn')?.addEventListener('click', () => {
    $('phonePane').classList.remove('hidden');
    $('collapsedPhoneStrip').classList.add('hidden');
    updateLayoutClass();
  });
  
  function updateLayoutClass() {
    const cardHidden = $('cardPane').classList.contains('hidden');
    const phoneHidden = $('phonePane').classList.contains('hidden');
    const es = $('editorState');
    es.className = 'editor-state'; // Reset
    if (cardHidden && phoneHidden) es.classList.add('layout-minimal');
    else if (cardHidden) es.classList.add('layout-no-card');
    else if (phoneHidden) es.classList.add('layout-no-phone');
    else es.classList.add('layout-full');
  }
  updateLayoutClass();

  // Highlighting synchronization
  function bindHighlight(textareaId, backdropId) {
    const textarea = $(textareaId);
    const backdrop = $(backdropId);
    if (!textarea || !backdrop) return;
    
    function applyHighlights() {
      let text = textarea.value;
      // Encode html
      text = text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
      // Highlight token tags
      text = text.replace(/(\{token:[^}]+\})/g, '<span class="token-highlight">$1</span>');
      // Ensure trailing newlines render correctly in div
      if (text.endsWith('\n')) text += ' ';
      backdrop.innerHTML = text;
    }
    textarea.addEventListener('input', applyHighlights);
    textarea.addEventListener('scroll', () => {
      backdrop.scrollTop = textarea.scrollTop;
      backdrop.scrollLeft = textarea.scrollLeft;
    });
    // Trigger initially
    textarea.dataset.highlightBound = "true";
  }
  
  // Need to bind on render, so we patch render function
  window.bindHighlights = () => {
    bindHighlight('attacksDisplayRowsInput', 'attackRowsBackdrop');
    bindHighlight('defenseDisplayRowsInput', 'defenseRowsBackdrop');
    bindHighlight('passivesDisplayRowsInput', 'passiveRowsBackdrop');
    document.querySelectorAll('.rule-display-rows').forEach(ta => {
      if (!ta.dataset.highlightBound) {
        const bd = ta.previousElementSibling;
        if(bd) {
           bd.id = 'bd_' + Math.random();
           ta.id = 'ta_' + Math.random();
           bindHighlight(ta.id, bd.id);
        }
      }
    });
  };
}
