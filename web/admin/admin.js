
const SUPABASE_URL = 'https://rqxfjffwzdfefinfcxjo.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_3EuoFYUzqUvNX7IPrhZKpQ_mkW-Gl97';
let supabaseClient = null;

async function initAuth() {
  if (!window.supabase) {
    $('mainAppShell').style.display = 'grid';
    $('authOverlay').style.display = 'none';
    return;
  }
  supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
  
  $('googleLoginBtn').onclick = async (e) => {
    e.preventDefault();
    try {
      $('authError').textContent = 'Tentative de connexion...';
      const { error } = await supabaseClient.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: window.location.origin + window.location.pathname
        }
      });
      if (error) {
        $('authError').textContent = 'Erreur: ' + error.message;
      } else {
        $('authError').textContent = 'Redirection vers Google...';
      }
    } catch (err) {
      $('authError').textContent = 'Exception JS: ' + err.message;
      console.error(err);
    }
  };
  
  $('logoutBtn').onclick = async () => {
    await supabaseClient.auth.signOut();
  };

  try {
    const { data: { session } } = await supabaseClient.auth.getSession();
    checkSession(session);
  } catch (err) {
    console.error("Auth init error:", err);
    checkSession(null);
  }
  
  supabaseClient.auth.onAuthStateChange((event, session) => {
    checkSession(session);
  });
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
  naraxus: 'Naxarus',
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
  let list = document.getElementById('tokenOptions');
  if (!list) {
    list = document.createElement('datalist');
    list.id = 'tokenOptions';
    document.body.appendChild(list);
  }
  const options = tokenCatalog.map(t => {
      const fr = (t.frLabel && t.frLabel !== t.label) ? ` (${t.frLabel})` : '';
      return `<option value="${escapeAttr(t.label)}">${escapeAttr(t.label)}${fr}</option>`;
    }).sort();
    list.innerHTML = options.join('');
  tokenDatalistReady = true;
  document.querySelectorAll('input.token-input').forEach((input) => input.setAttribute('list', 'tokenOptions'));
}

function attachTokenList(root = document) {
  root.querySelectorAll('input.token-input').forEach((input) => {
    input.setAttribute('list', 'tokenOptions');
    input.placeholder ||= 'Poison, Blind, Bleed';
    
    validateTokenInput(input);
    input.removeEventListener('input', onTokenInputChanged);
    input.addEventListener('input', onTokenInputChanged);
  });
  if (!tokenDatalistReady) ensureTokenDatalist();
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
  const list = document.getElementById('tokenOptions');
  if (!list) return;
  const validTokens = Array.from(list.options).map(o => o.value);
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
    stealCp: 0,
    heal: 0,
    drawCards: 0,
    discardCards: 0,
    tokens: [],
    formulas: [],
  };
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
        setDirty('enemy', false);
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
  setDirty('enemy', false);
  $('saveFileBtn').disabled = false;
  renderLists();
  selectFirst();
}

async function saveLocalFile() {
  if (location.hostname === '127.0.0.1' || location.hostname === 'localhost') {
    collectCurrent();
    try {
      const response = await fetch('/api/save-enemy', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(sourceData)
      });
      if (!response.ok) throw new Error('Save failed');
      setDirty('enemy', false);
      $('saveFileBtn').disabled = true;
      flash('Saved locally via API!');
      return;
    } catch (e) {
      console.error('Direct save failed, falling back', e);
    }
  }

  if (!fileHandle || !sourceData) return;
  collectCurrent();
  const writable = await fileHandle.createWritable();
  await writable.write(JSON.stringify(sourceData, null, 2) + '\n');
  await writable.close();
  setDirty('enemy', false);
  flash('Saved local JSON file.');
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
  download('enemy_profiles.json', JSON.stringify(sourceData, null, 2) + '\n');
  setDirty('enemy', false);
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

function renderLists() {
  const root = $('enemyLists');
  root.innerHTML = '';
  const query = $('enemySearch').value.trim().toLowerCase();
  const allProfiles = sourceData?.profiles || [];
  const globalValid = allProfiles.filter(p => p.validated).length;
  const globalPct = allProfiles.length ? Math.round(globalValid * 100 / allProfiles.length) : 0;
  if ($('validationProgress')) {
    $('validationProgress').textContent = allProfiles.length ? `${globalPct}% validated` : '';
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
    
    const groupTotal = profiles.length;
    const groupValid = profiles.filter(p => p.profile.validated).length;
    const groupPct = Math.round(groupValid * 100 / groupTotal);

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
      if (profile.cardAsset) {
        prefix = profile.cardAsset.split('/').pop().replace('.png', '') + ' ';
      }
      const validIcon = profile.validated ? '✅ ' : '❌ ';
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

function selectProfile(index) {
  collectCurrent();
  selectedIndex = index;
  selectedProfile = clone(sourceData.profiles[index]);
  renderLists();
  renderEditor();
}

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
  $('cardImage').src = assetUrl(selectedProfile.cardAsset);
  
  const previewUrl = getPreviewAssetUrl(selectedProfile);
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
  setValue('initialTokensInput', (selectedProfile.initialTokens || []).join(', '));
  $('initialTokensInput').classList.add('token-input');
  $('initialTokensInput').setAttribute('list', 'tokenOptions');
  attachTokenList(document);

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
  selectedProfile.initialTokens = csv($('initialTokensInput').value);
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
function textarea(label, className, value = '', rows = 2) {
  return '<label class="wide-label formula-label">' + label + '<textarea class="' + className + '" rows="' + rows + '">' + escapeText(value) + '</textarea></label>';
}
function input(label, className, value = '', type = 'text') {
  const isToken = className.includes('tokens') || className.includes('token');
  const tokenClass = isToken ? ' token-input' : '';
  const tokenList = isToken ? ' list="tokenOptions" placeholder="Poison, Blind, Bleed"' : '';
  return `<label>${label}<input class="${className}${tokenClass}" type="${type}" value="${escapeAttr(value)}"${tokenList} /></label>`;
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
    effect: { heroTokens: [], minionTokens: [], damage: null, damageFormula: null, undefendable: false, lifeSteal: 0, cpSteal: 0, note: '' },
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
      input('Present tokens', 'cond-present', (condition.present || []).join(', ')) +
      input('Absent tokens', 'cond-absent', (condition.absent || []).join(', ')) +
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
  attachTokenList(node);
  node.addEventListener('input', () => { collectCurrent(); setDirty('enemy'); renderPreview(); renderDisplayRowsPreviews(); });
  node.addEventListener('change', () => { collectCurrent(); setDirty('enemy'); renderPreview(); renderDisplayRowsPreviews(); });
  return node;
}
function readConditionalRuleCard(card) {
  const type = card.querySelector('.cond-type').value;
  const innerRaw = card.querySelector('.cond-inner').value.trim();
  let inner = null;
  if (innerRaw) { try { inner = JSON.parse(innerRaw); } catch {} }
  const andRaw = card.querySelector('.cond-and').value.trim();
  let and = [];
  if (andRaw) { try { const parsed = JSON.parse(andRaw); if (Array.isArray(parsed)) and = parsed; } catch {} }
  const condition = { type, negate: card.querySelector('.cond-negate').checked, and };
  if (inner) condition.inner = inner;
  if (type === 'sameValue' || type === 'sameSymbol') condition.count = intVal(card.querySelector('.cond-count').value);
  if (type === 'suite') condition.minLength = intVal(card.querySelector('.cond-minlength').value);
  if (type === 'symbols' || type === 'attackSucceededAnd') {
    condition.white = intVal(card.querySelector('.cond-white').value);
    condition.orange = intVal(card.querySelector('.cond-orange').value);
    condition.red = intVal(card.querySelector('.cond-red').value);
  }
  if (type === 'alteration') {
    condition.present = csv(card.querySelector('.cond-present').value);
    condition.absent = csv(card.querySelector('.cond-absent').value);
  }
  const damageRaw = card.querySelector('.eff-damage').value.trim();
  const damageFormula = card.querySelector('.eff-damageformula').value;
  const effect = {
    heroTokens: csv(card.querySelector('.eff-herotokens').value),
    minionTokens: csv(card.querySelector('.eff-miniontokens').value),
    damage: damageRaw === '' ? null : intVal(damageRaw),
    damageFormula: damageFormula || null,
    undefendable: card.querySelector('.eff-undef').checked,
    lifeSteal: intVal(card.querySelector('.eff-lifesteal').value),
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
  node.querySelector('.condition-grid').innerHTML = [
    select('Condition type', 'cond-type', type, ['symbols', 'suite', 'number', 'range', 'any', 'text']),
    input('White', 'cond-white', symbols.white ?? 0, 'number'),
    input('Orange', 'cond-orange', symbols.orange ?? symbols.yellow ?? 0, 'number'),
    input('Red', 'cond-red', symbols.red ?? 0, 'number'),
    input('Suite', 'cond-suite', condition.suite || ''),
    input('Length', 'cond-length', condition.length ?? '', 'number'),
    input('Value', 'cond-value', condition.value ?? '', 'number'),
    check('Repeat per symbol', 'cond-repeat', !!condition.repeat),
  ].join('');
  node.querySelector('.effect-grid').innerHTML = [
    select('Align', 'effect-align', data.align || 'left', ['left', 'center']),
    input('Label', 'effect-label', data.label || ''),
    input('Damage', 'effect-damage', data.damage ?? 0, 'number'),
    check('Undefendable', 'effect-undef', !!data.undefendable),
    input('Prevent', 'effect-prevent', data.prevent ?? 0, 'number'),
    input('Return dmg', 'effect-return', data.returnDamage ?? 0, 'number'),
    input('Steal HP', 'effect-stealhp', data.stealHp ?? 0, 'number'),
    input('Steal CP', 'effect-stealcp', data.stealCp ?? 0, 'number'),
    input('Heal', 'effect-heal', data.heal ?? 0, 'number'),
    input('Draw', 'effect-draw', data.drawCards ?? 0, 'number'),
    input('Discard', 'effect-discard', data.discardCards ?? 0, 'number'),
    input('Top deck discard', 'effect-topdeck', data.topDeckToDiscard ?? 0, 'number'),
    input('Tokens', 'effect-tokens', (data.tokens || []).join(', ')),
    textarea('Formulas', 'effect-formulas', (data.formulas || []).join('\n'), 3),
  ].join('');
  renderExtra(node.querySelector('.extra-roll-body'), data.extraRoll || null);
  node.querySelector('details').open = !!data.extraRoll;
  node.querySelector('.notes-field').value = (data.notes || []).join('\n');
  attachTokenList(node);
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
    '<p class="hint mini-hint">Use align: left, center or right. Items accept {die:any}, {die:white}, {die:orange}, {die:red}, {damage:7}, {undef:7}, {prevent:2}, {heal:4}, {token:Chaos}.</p>',
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
      ${input('Steal CP', 'out-stealcp', outcome.stealCp ?? 0, 'number')}
      ${check('Undef', 'out-undef', !!outcome.undefendable)}
      ${input('Tokens', 'out-tokens', (outcome.tokens || []).join(', '))}
      <button type="button" class="danger small">X</button>
    </div>
    <label class="wide-label">Label<input class="out-label" type="text" value="${escapeAttr(outcome.label || '')}" /></label>
  `;
  attachTokenList(row);
  row.querySelector('button').onclick = () => { row.remove(); collectCurrent(); setDirty('enemy'); renderPreview(); };
  return row;
}

function readCondition(card) {
  const type = card.querySelector('.cond-type').value;
  const condition = { type };
  if (type === 'symbols') {
    condition.symbols = {
      white: intVal(card.querySelector('.cond-white').value),
      orange: intVal(card.querySelector('.cond-orange').value),
      red: intVal(card.querySelector('.cond-red').value),
    };
  }
  if (type === 'suite') {
    condition.suite = card.querySelector('.cond-suite').value.trim();
    condition.length = intVal(card.querySelector('.cond-length').value);
  }
  if (type === 'number') condition.value = intVal(card.querySelector('.cond-value').value);
  if (card.querySelector('.cond-repeat').checked) condition.repeat = true;
  return condition;
}
function readCommon(card) {
  return {
    align: card.querySelector('.effect-align')?.value || 'left',
    condition: readCondition(card),
    label: card.querySelector('.effect-label').value.trim(),
    damage: intVal(card.querySelector('.effect-damage').value),
    undefendable: card.querySelector('.effect-undef').checked,
    stealHp: intVal(card.querySelector('.effect-stealhp').value),
    stealCp: intVal(card.querySelector('.effect-stealcp').value),
    heal: intVal(card.querySelector('.effect-heal').value),
    drawCards: intVal(card.querySelector('.effect-draw').value),
    discardCards: intVal(card.querySelector('.effect-discard').value),
    tokens: csv(card.querySelector('.effect-tokens').value),
    formulas: card.querySelector('.effect-formulas').value.split(/[,\n]/).map((line) => line.trim()).filter(Boolean),
    notes: card.querySelector('.notes-field').value.split('\n').map((line) => line.trim()).filter(Boolean),
  };
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
    outcomes: [...card.querySelectorAll('.outcome-row')].map((row) => ({
      align: row.querySelector('.out-align').value || undefined,
      face: row.querySelector('.out-face').value,
      label: row.querySelector('.out-label').value.trim(),
      damage: intVal(row.querySelector('.out-damage').value),
      undefendable: row.querySelector('.out-undef').checked,
      stealHp: intVal(row.querySelector('.out-stealhp').value),
      stealCp: intVal(row.querySelector('.out-stealcp').value),
      tokens: csv(row.querySelector('.out-tokens').value),
    })),
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
  if (effect.stealCp) items.push(`Steal ${effect.stealCp} CP`);
  if (effect.heal) items.push(`{heal:${effect.heal}}`);
  if (effect.drawCards) items.push(`Draw ${effect.drawCards}`);
  if (effect.discardCards) items.push(`Discard ${effect.discardCards}`);
  if (effect.topDeckToDiscard) items.push(`Top ${effect.topDeckToDiscard} discard`);
  if (effect.formulas) items.push(...effect.formulas);
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
  const text = passive.text || passive.label || passive.name || '';
  return text ? [{ align: 'left', items: [text] }] : [];
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
  const rootPassives = selectedProfile?.passives || [];
  const attackPassives = selectedProfile?.attackPlan?.passives || [];
  const rows = [...rootPassives, ...attackPassives].flatMap(passiveToDisplayRows);
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
  if (condition.type === 'suite') return `<span class="token-chip">${condition.suite || 'suite'} ${condition.length || ''}</span>`;
  if (condition.type === 'number') return `<span class="die white">${condition.value ?? '?'}</span>`;
  if (condition.type === 'any') return '<span class="token-chip">Any</span>';
  if (condition.type === 'text') return '<span class="token-chip">Text rule</span>';
  const symbols = condition.symbols || {};
  return `<div class="dice-line">${dice('white', symbols.white)}${dice('orange', symbols.orange)}${dice('red', symbols.red)}</div>`;
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
  const match = text.match(/^\{([^:}]+):([^}]+)\}$/);
  if (!match) return '<span>' + escapeText(text) + '</span>';
  const kind = match[1].toLowerCase();
  const value = match[2];
  if (kind === 'die') return dice(value, 1) || '<span class="die white">D</span>';
  if (kind === 'damage') return '<span class="badge damage">' + escapeText(value) + '</span>';
  if (kind === 'undef') return '<span class="badge undef">' + escapeText(value) + '</span>';
  if (kind === 'prevent') return '<span class="badge prevent">' + escapeText(value) + '</span>';
  if (kind === 'heal') return '<span class="badge heal">' + escapeText(value) + '</span>';
  if (kind === 'token') return '<span class="token-chip">' + tokenImageHtml(value) + escapeText(value) + '</span>';
  return '<span>' + escapeText(text) + '</span>';
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
  if (effect.tokens) bits.push(...effect.tokens.map((token) => `<span class="token-chip">${tokenImageHtml(token)}${token}</span>`));
  if (effect.damage) bits.push(`<span class="badge ${effect.undefendable ? 'undef' : 'damage'}">${effect.damage}</span>`);
  if (effect.prevent) bits.push(`<span class="badge prevent">${effect.prevent}</span>`);
  if (effect.returnDamage) bits.push(`<span class="badge ${effect.undefendable ? 'undef' : 'damage'}">↩${effect.returnDamage}</span>`);
  if (effect.stealHp) bits.push(`<span class="badge heal">S${effect.stealHp}</span>`);
  if (effect.stealCp && !effect.label2) bits.push(`<span class="token-chip">Steal ${effect.stealCp} CP</span>`);
  if (effect.heal) bits.push(`<span class="badge heal">+${effect.heal}</span>`);
  if (effect.drawCards) bits.push(`<span class="token-chip">Draw ${effect.drawCards}</span>`);
  if (effect.discardCards) bits.push(`<span class="token-chip">Discard ${effect.discardCards}</span>`);
  if (effect.topDeckToDiscard) bits.push(`<span class="token-chip">Top ${effect.topDeckToDiscard} discard</span>`);
  if (effect.formulas) bits.push(...effect.formulas.map((formula) => `<span class="token-chip">${formula}</span>`));
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
    const hasPas = (selectedProfile.attackPlan?.passives?.length || 0) > 0;
    pasDot.classList.toggle('active', hasPas);
  }
}

function renderPassiveRules() {
  const root = $('passiveRules');
  if (!root) return;
  root.innerHTML = '';
  (selectedProfile.attackPlan?.passives || []).forEach((text, index) => {
    const row = document.createElement('div');
    row.style.display = 'flex';
    row.style.gap = '8px';
    const input = document.createElement('textarea');
    input.value = text;
    input.rows = 2;
    input.style.flex = '1';
    input.className = 'notes-field';
    input.oninput = () => {
      selectedProfile.attackPlan.passives[index] = input.value;
      setDirty('enemy');
      updateTabDots();
    };
    const rm = document.createElement('button');
    rm.className = 'danger small';
    rm.textContent = 'Remove';
    rm.style.height = 'fit-content';
    rm.onclick = () => {
      selectedProfile.attackPlan.passives.splice(index, 1);
      setDirty('enemy');
      renderPassiveRules();
      updateTabDots();
    };
    row.append(input, rm);
    root.appendChild(row);
  });
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
function formulaRefs() {
  const refs = new Map();
  for (const profile of sourceData?.profiles || []) {
    const scan = (items = [], kind) => {
      for (const item of items) {
        for (const formula of item.formulas || []) {
          const key = String(formula || '').trim();
          if (!key) continue;
          if (!refs.has(key)) refs.set(key, []);
          refs.get(key).push(profile.name + ' (' + kind + ')');
        }
      }
    };
    scan(profile.attackPlan?.actions || [], 'attack');
    scan(profile.defensePlan?.effects || [], 'defense');
  }
  return refs;
}
function renderFormulaList() {
  const root = $('formulaList');
  if (!root) return;
  const refs = formulaRefs();
  if (!refs.size) { root.innerHTML = '<em>No formulas found.</em>'; return; }
  root.innerHTML = [...refs.entries()]
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([formula, profiles]) => '<div class="formula-card"><code>' + escapeText(formula) + '</code><span>' + profiles.map(escapeText).join(', ') + '</span></div>')
    .join('');
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
    return '<article class="token-admin-card" data-token-index="' + index + '">' +
      '<div class="token-admin-head"><img src="' + assetUrl(token.imageAsset) + '" alt="' + escapeAttr(token.label) + '" /><div><strong>' + escapeText(token.label || 'Token') + '</strong><div class="hint">' + escapeText(token.kind || '') + '<div class="token-highlight" style="font-size:12px; margin-top:4px;">{token:' + escapeText(token.label) + '}</div>' + '</div></div></div>' +
      '<div class="token-admin-grid">' +
      '<label>UK title<input class="tok-label" value="' + escapeAttr(token.label || '') + '" /></label>' +
      '<label>FR title<input class="tok-fr" value="' + escapeAttr(token.frLabel || '') + '" /></label>' +
      '<label>Kind<select class="tok-kind"><option value="positive" ' + (token.kind === 'positive' ? 'selected' : '') + '>positive</option><option value="negative" ' + (token.kind === 'negative' ? 'selected' : '') + '>negative</option><option value="unique" ' + (token.kind === 'unique' ? 'selected' : '') + '>unique</option></select></label>' +
      '<label>Max stack<input class="tok-max" type="number" value="' + escapeAttr(token.maxStack ?? 1) + '" /></label>' +
      '<label>Image asset<input class="tok-asset" value="' + escapeAttr(token.imageAsset || '') + '" /></label>' +
      '<label>Aliases<input class="tok-aliases" value="' + escapeAttr((token.aliases || []).join(', ')) + '" /></label>' +
      '<label class="checkline"><input class="tok-supported" type="checkbox" ' + (token.appSupported ? 'checked' : '') + ' />App enabled</label>' +
      '<label class="checkline"><input class="tok-removable" type="checkbox" ' + (token.removable !== false ? 'checked' : '') + ' />Removable</label>' +
      '<label class="checkline"><input class="tok-minion" type="checkbox" ' + (token.minionAllowed !== false ? 'checked' : '') + ' />Can affect enemies</label>' +
      '<label class="checkline"><input class="tok-visible" type="checkbox" ' + (token.editorVisible !== false ? 'checked' : '') + ' />Visible in token list</label>' +
      '</div>' +
      '<label class="wide-label">Description<textarea class="tok-desc" rows="4">' + escapeText(token.description || '') + '</textarea></label>' +
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
    token.maxStack = intVal(card.querySelector('.tok-max').value, 1);
    token.imageAsset = card.querySelector('.tok-asset').value.trim() || null;
    token.aliases = csv(card.querySelector('.tok-aliases').value);
    token.appSupported = card.querySelector('.tok-supported').checked;
    token.removable = card.querySelector('.tok-removable').checked;
    token.minionAllowed = card.querySelector('.tok-minion').checked;
    token.editorVisible = card.querySelector('.tok-visible').checked;
    token.description = card.querySelector('.tok-desc').value.trim();
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
  ['nameInput','keyInput','rankInput','hpInput','cpInput','defenseDiceInput','rewardChestsInput','rewardRankInput','cardAssetInput','initialTokensInput','attackStyleInput','attackNameInput','attacksTextInput','defenseTextInput','passivesTextInput','attacksDisplayRowsInput','defenseDisplayRowsInput','passivesDisplayRowsInput'].forEach((id) => {
    $(id).addEventListener('input', () => { collectCurrent(); setDirty('enemy'); renderLists(); renderPreview(); renderDisplayRowsPreviews(); renderMeta(); updateRewardWarnings(); });
  });
}
document.addEventListener('DOMContentLoaded', () => {
  initAuth();
  setupUIEnhancements();

  loadTokenCatalog();
  $('loadDefaultBtn').onclick = loadDefault;
  $('openFileBtn').onclick = openLocalJson;
  $('saveFileBtn').onclick = saveLocalFile;
  $('exportJsonBtn').onclick = exportJson;
  $('exportTokenJsonBtn').onclick = exportTokenJson;
  $('validateBtn').onclick = () => {
    if (!selectedProfile) return;
    selectedProfile.validated = !selectedProfile.validated;
    setDirty('enemy');
    renderLists();
  };
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
  
  $('addPassiveRuleBtn').onclick = () => {
    if (!selectedProfile) return;
    selectedProfile.attackPlan.passives ||= [];
    selectedProfile.attackPlan.passives.push("");
    renderPassiveRules();
    setDirty('enemy');
  };

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
