// Dice Throne Combat Simulator, Profiles & Statistics Engine
document.addEventListener('DOMContentLoaded', async () => {
  // Global Data
  let statsData = {};
  let heroBoardsData = {};
  try {
    const res = await fetch('./hero_simulation_stats.json?t=' + Date.now());
    if (res.ok) {
      statsData = await res.json();
    }
    const bRes = await fetch('./hero_boards.json?t=' + Date.now());
    if (bRes.ok) {
      heroBoardsData = await bRes.json();
    }
  } catch (e) {
    console.warn('Could not load simulation data, using defaults', e);
  }

  // Combat State
  let hero1 = null;
  let hero2 = null;

  let p1Hp = 50, p1Cp = 2, p1Tokens = [];
  let p2Hp = 50, p2Cp = 2, p2Tokens = [];

  let firstPlayerStarter = 1; // 1: Player 1 starts; 2: Player 2 starts
  let p1TurnCount = 1; // Number of turns played by Player 1
  let p2TurnCount = 1; // Number of turns played by Player 2

  let turnNumber = 1; // Overall round number
  let activeAttacker = 1; // 1: Hero1 attacks Hero2; 2: Hero2 attacks Hero1
  let currentPhase = 0; // 0: Upkeep, 1: Main 1, 2: Offensive, 3: Defense & Counter, 4: Resolution
  let isAutoFighting = false;
  let autoFightTimer = null;

  // HP Combat History (for the graph)
  let pvHistory = [{ step: 'Début', round: 0, p1: 50, p2: 50 }];

  // Editor State
  let selectedEditorHero = null;
  let currentEditorFilter = 'active'; // 'active' by default as requested
  const expandedTurns = new Set(); // All runs collapsed by default

  // Stats Tab State
  let statsMode = 'single'; // 'single' | 'compare'
  let statsHero1 = null;
  let statsHero2 = null;

  // Initialize selected heroes from active pool
  const activeHeroes = DTS_HEROES.filter(h => statsData[h.id]?.active);
  hero1 = activeHeroes.find(h => h.id === 'blackWidow') || activeHeroes[0] || DTS_HEROES[0];
  hero2 = activeHeroes.find(h => h.id === 'loki') || activeHeroes[1] || DTS_HEROES[1];
  statsHero1 = hero1;
  statsHero2 = hero2;

  // Predefined Special Defensive Tokens
  const SPECIAL_DEFENSIVE_TOKENS = [
    { name: 'Parlay', desc: 'Annule totalement l\'attaque' },
    { name: 'Ombre', desc: 'Immunité totale (100% esquive)' },
    { name: 'Agilité', desc: '50% chance d\'esquiver tous les dégâts' },
    { name: 'Illusion', desc: '50% chance d\'annuler l\'attaque' }
  ];

  // DOM Elements - Tabs
  const tabBtns = document.querySelectorAll('.tab-btn');
  const tabViews = document.querySelectorAll('.tab-view');

  // DOM Elements - Simulator
  const heroCard1 = document.getElementById('heroCard1');
  const heroCard2 = document.getElementById('heroCard2');
  const p1Block = document.getElementById('p1Block');
  const p2Block = document.getElementById('p2Block');
  const p1NameEl = document.getElementById('p1Name');
  const p2NameEl = document.getElementById('p2Name');
  const p1VariantSelect = document.getElementById('p1VariantSelect');
  const p2VariantSelect = document.getElementById('p2VariantSelect');
  let p1SelectedVariant = null;
  let p2SelectedVariant = null;
  const p1HpEl = document.getElementById('p1Hp');
  const p1CpEl = document.getElementById('p1Cp');
  const p2HpEl = document.getElementById('p2Hp');
  const p2CpEl = document.getElementById('p2Cp');
  const p1HpBar = document.getElementById('p1HpBar');
  const p2HpBar = document.getElementById('p2HpBar');
  const p1StatsPill = document.getElementById('p1StatsPill');
  const p2StatsPill = document.getElementById('p2StatsPill');
  const p1TokensEl = document.getElementById('p1Tokens');
  const p2TokensEl = document.getElementById('p2Tokens');
  const p1QuickTokens = document.getElementById('p1QuickTokens');
  const p2QuickTokens = document.getElementById('p2QuickTokens');

  const btnStartP1 = document.getElementById('btnStartP1');
  const btnStartP2 = document.getElementById('btnStartP2');

  const currentTurnBadge = document.getElementById('currentTurnBadge');
  const activeAttackerLabel = document.getElementById('activeAttackerLabel');
  const phaseSteps = document.querySelectorAll('.phase-step');
  const phaseDetailsBox = document.getElementById('phaseDetailsBox');
  const phaseStateBadge = document.getElementById('phaseStateBadge');
  const combatLog = document.getElementById('combatLog');

  const btnNextPhase = document.getElementById('btnNextPhase');
  const btnNextTurn = document.getElementById('btnNextTurn');
  const btnAutoFight = document.getElementById('btnAutoFight');
  const btnMonteCarlo = document.getElementById('btnMonteCarlo');
  const resetCombatBtn = document.getElementById('resetCombatBtn');
  const btnClearLog = document.getElementById('btnClearLog');
  const swapHeroesBtn = document.getElementById('swapHeroesBtn');

  // DOM Elements - HP Graph
  const hpCombatSvg = document.getElementById('hpCombatSvg');
  const hpGraphLegend = document.getElementById('hpGraphLegend');

  // DOM Elements - Modal
  const modal = document.getElementById('heroPickerModal');
  const closeModalBtn = document.getElementById('closeModalBtn');
  const heroSearchInput = document.getElementById('heroSearchInput');
  const randomPickBtn = document.getElementById('randomPickBtn');
  const modalHeroGrid = document.getElementById('modalHeroGrid');
  let pickingSlot = 1;

  // DOM Elements - Editor
  const editorSearch = document.getElementById('editorSearch');
  const editorHeroesList = document.getElementById('editorHeroesList');
  const activeCountBadge = document.getElementById('activeCountBadge');
  const filterTabPills = document.querySelectorAll('.filter-tab-pill');
  const edHeroImg = document.getElementById('edHeroImg');
  const edHeroName = document.getElementById('edHeroName');
  const edHeroMeta = document.getElementById('edHeroMeta');
  const edActiveToggle = document.getElementById('edActiveToggle');
  const styleTabsRow = document.getElementById('styleTabsRow');
  const btnAddVariantBtn = document.getElementById('btnAddVariantBtn');
  const btnCombinedAverageBtn = document.getElementById('btnCombinedAverageBtn');
  const edTurnsContainer = document.getElementById('edTurnsContainer');
  const btnAddTurnRowBtn = document.getElementById('btnAddTurnRowBtn');
  const btnSaveStatsBtn = document.getElementById('btnSaveStatsBtn');
  const btnReloadFileBtn = document.getElementById('btnReloadFileBtn');
  const saveStatusIndicator = document.getElementById('saveStatusIndicator');

  // DOM Elements - Stats Tab
  const statsModeBtns = document.querySelectorAll('.stats-mode-btn');
  const statsHero1Select = document.getElementById('statsHero1Select');
  const statsHero2Select = document.getElementById('statsHero2Select');
  const statsVariantSelectA = document.getElementById('statsVariantSelectA');
  const statsVariantSelectB = document.getElementById('statsVariantSelectB');
  const statsCardA = document.getElementById('statsCardA');
  const statsCardB = document.getElementById('statsCardB');
  const statsColB = document.getElementById('statsColB');
  const statsVsDivider = document.getElementById('statsVsDivider');
  const statsKpisGrid = document.getElementById('statsKpisGrid');
  const statsComponentsSvg = document.getElementById('statsComponentsSvg');
  const statsComponentsLegend = document.getElementById('statsComponentsLegend');
  const statsBenchmarkSvg = document.getElementById('statsBenchmarkSvg');
  const statsBenchmarkLegend = document.getElementById('statsBenchmarkLegend');
  const statsPlusValueSvg = document.getElementById('statsPlusValueSvg');
  const statsPlusValueLegend = document.getElementById('statsPlusValueLegend');
  const chart1Title = document.getElementById('chart1Title');
  const chart2Title = document.getElementById('chart2Title');
  const chart3Title = document.getElementById('chart3Title');
  const chartBenchmarkCard = document.getElementById('chartBenchmarkCard');
  const filterRowLabel = document.getElementById('filterRowLabel');
  const chart1Sublabel = document.getElementById('chart1Sublabel');

  // Token Image Catalog for Graph & Simulation
  const TOKEN_ICONS = {
    'parlay': 'assets/token/Parlay.png',
    'ombre': 'assets/token/Shadows.png',
    'shadows': 'assets/token/Shadows.png',
    'agilité': 'assets/token/Agility.webp',
    'agilite': 'assets/token/Agility.webp',
    'agility': 'assets/token/Agility.webp',
    'illusion': 'assets/token/Sac_a_malice.webp',
    'poison': 'assets/token/poison.png',
    'brûlure': 'assets/token/burn.png',
    'brulure': 'assets/token/burn.png',
    'burn': 'assets/token/burn.png',
    'bombe': 'assets/token/time-bomb-2.webp',
    'bomb': 'assets/token/time-bomb-2.webp',
    'nevermore': 'assets/token/Feather.png',
    'plume': 'assets/token/Feather.png',
    'feather': 'assets/token/Feather.png',
    'hex': 'assets/token/hex.png'
  };

  // =========================================================================
  // TAB NAVIGATION
  // =========================================================================
  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      const targetId = btn.dataset.tab;
      tabBtns.forEach(b => b.classList.remove('active'));
      tabViews.forEach(v => v.classList.remove('active'));

      btn.classList.add('active');
      document.getElementById(targetId).classList.add('active');

      if (targetId === 'tabProfiles') {
        renderEditor();
      } else if (targetId === 'tabStats') {
        renderStatsTab();
      } else if (targetId === 'tabBoards') {
        renderBoardsTab();
      } else {
        updateSimulatorDisplay();
      }
    });
  });

  // =========================================================================
  // STATS & PER-TURN HELPERS WITH MULTI-STYLE / COMBINED AVERAGE
  // =========================================================================
  function getHeroProfile(heroId) {
    return statsData[heroId] || {
      heroId: heroId,
      heroName: heroId,
      active: false,
      selectedVariant: 'standard',
      variants: {
        'standard': {
          label: 'Standard',
          turns: [
            { turn: 1, avgAtk: 6, avgUndef: 1, avgToken: 1, avgCounter: 1, avgDef: 2, avgHeal: 0, runs: [{ runId: 1, atk: 6, undef: 1, token: 1, counter: 1, def: 2, heal: 0 }] }
          ]
        }
      }
    };
  }

  // Compute a combined virtual variant that averages all variants of a hero
  function getCombinedVariant(profile) {
    const variantsList = Object.values(profile.variants || {}).filter(v => v.turns && v.turns.length > 0);
    if (variantsList.length === 0) {
      return { label: 'Moyenne Combinée', turns: [] };
    }
    if (variantsList.length === 1) {
      return { label: `Moyenne Combinée (${variantsList[0].label})`, turns: variantsList[0].turns };
    }

    let maxTurns = 0;
    variantsList.forEach(v => maxTurns = Math.max(maxTurns, v.turns.length));

    const combinedTurns = [];
    for (let t = 0; t < maxTurns; t++) {
      const turnNumber = t + 1;
      let atks = [], undefs = [], tokens = [], counters = [], defs = [], heals = [];

      variantsList.forEach(v => {
        const turnData = v.turns[t] || v.turns[v.turns.length - 1];
        if (turnData) {
          atks.push(turnData.avgAtk ?? 0);
          undefs.push(turnData.avgUndef ?? 0);
          tokens.push(turnData.avgToken ?? 0);
          counters.push(turnData.avgCounter ?? 0);
          defs.push(turnData.avgDef ?? 0);
          heals.push(turnData.avgHeal ?? 0);
        }
      });

      const avg = arr => +(arr.reduce((a, b) => a + b, 0) / arr.length).toFixed(1);
      combinedTurns.push({
        turn: turnNumber,
        avgAtk: avg(atks),
        avgUndef: avg(undefs),
        avgToken: avg(tokens),
        avgCounter: avg(counters),
        avgDef: avg(defs),
        avgHeal: avg(heals),
        runs: []
      });
    }

    return {
      label: `Moyenne Combinée (${variantsList.length} styles)`,
      turns: combinedTurns
    };
  }

  function getHeroVariant(heroId, slot = null) {
    const profile = getHeroProfile(heroId);
    let selectedKey = profile.selectedVariant;
    if (slot === 1 && p1SelectedVariant) selectedKey = p1SelectedVariant;
    else if (slot === 2 && p2SelectedVariant) selectedKey = p2SelectedVariant;

    if (selectedKey === '__combined__') {
      return getCombinedVariant(profile);
    }
    const variantKey = selectedKey || Object.keys(profile.variants)[0];
    return profile.variants[variantKey] || { label: 'Standard', turns: [] };
  }

  function getHeroTurnStats(heroId, turnIndex, slot = null) {
    const variant = getHeroVariant(heroId, slot);
    const turns = variant.turns || [];

    if (turns.length === 0) {
      return { turn: turnIndex, avgAtk: 6, avgUndef: 1, avgToken: 1, avgCounter: 1, avgDef: 2, avgHeal: 0, isExtrapolated: true };
    }

    const exact = turns.find(t => t.turn === turnIndex);
    if (exact) return exact;

    // Extrapolation statistique au-delà des données du fichier (ex: Pyromancienne au Tour 10)
    // Calcule la moyenne globale du héros sur l'ensemble de ses tours réels enregistrés
    if (turnIndex > turns.length) {
      let sumAtk = 0, sumUndef = 0, sumToken = 0, sumCounter = 0, sumDef = 0, sumHeal = 0;
      turns.forEach(t => {
        sumAtk += (t.avgAtk || 0);
        sumUndef += (t.avgUndef || 0);
        sumToken += (t.avgToken || 0);
        sumCounter += (t.avgCounter || 0);
        sumDef += (t.avgDef || 0);
        sumHeal += (t.avgHeal || 0);
      });

      const n = turns.length;
      return {
        turn: turnIndex,
        avgAtk: +(sumAtk / n).toFixed(1),
        avgUndef: +(sumUndef / n).toFixed(1),
        avgToken: +(sumToken / n).toFixed(1),
        avgCounter: +(sumCounter / n).toFixed(1),
        avgDef: +(sumDef / n).toFixed(1),
        avgHeal: +(sumHeal / n).toFixed(1),
        isExtrapolated: true,
        runs: []
      };
    }

    return turns[0];
  }

  // Populate hero style selectors in the Simulator
  function populateSimHeroStyles(slot) {
    if (slot === 1 && p1VariantSelect) {
      const curVal = p1SelectedVariant;
      p1VariantSelect.innerHTML = '';
      const profile = getHeroProfile(hero1.id);
      const variants = profile.variants || {};
      const vKeys = Object.keys(variants);

      vKeys.forEach(k => {
        const opt = document.createElement('option');
        opt.value = k;
        opt.textContent = variants[k].label || k;
        if ((curVal && curVal === k) || (!curVal && k === profile.selectedVariant)) {
          opt.selected = true;
          p1SelectedVariant = k;
        }
        p1VariantSelect.appendChild(opt);
      });

      if (vKeys.length > 1) {
        const optComb = document.createElement('option');
        optComb.value = '__combined__';
        optComb.textContent = '🔀 Moyenne Tous Styles';
        if (curVal === '__combined__') optComb.selected = true;
        p1VariantSelect.appendChild(optComb);
      }

      if (!p1SelectedVariant && p1VariantSelect.options.length > 0) {
        p1SelectedVariant = p1VariantSelect.value;
      }
    }

    if (slot === 2 && p2VariantSelect) {
      const curVal = p2SelectedVariant;
      p2VariantSelect.innerHTML = '';
      const profile = getHeroProfile(hero2.id);
      const variants = profile.variants || {};
      const vKeys = Object.keys(variants);

      vKeys.forEach(k => {
        const opt = document.createElement('option');
        opt.value = k;
        opt.textContent = variants[k].label || k;
        if ((curVal && curVal === k) || (!curVal && k === profile.selectedVariant)) {
          opt.selected = true;
          p2SelectedVariant = k;
        }
        p2VariantSelect.appendChild(opt);
      });

      if (vKeys.length > 1) {
        const optComb = document.createElement('option');
        optComb.value = '__combined__';
        optComb.textContent = '🔀 Moyenne Tous Styles';
        if (curVal === '__combined__') optComb.selected = true;
        p2VariantSelect.appendChild(optComb);
      }

      if (!p2SelectedVariant && p2VariantSelect.options.length > 0) {
        p2SelectedVariant = p2VariantSelect.value;
      }
    }
  }

  p1VariantSelect?.addEventListener('change', () => {
    p1SelectedVariant = p1VariantSelect.value;
    const label = p1VariantSelect.options[p1VariantSelect.selectedIndex]?.text || p1SelectedVariant;
    updateSimulatorDisplay();
    log(`🎭 [Style J1] ${hero1.name} utilise désormais : ${label}`, 'info');
  });

  p2VariantSelect?.addEventListener('change', () => {
    p2SelectedVariant = p2VariantSelect.value;
    const label = p2VariantSelect.options[p2VariantSelect.selectedIndex]?.text || p2SelectedVariant;
    updateSimulatorDisplay();
    log(`🎭 [Style J2] ${hero2.name} utilise désormais : ${label}`, 'info');
  });

  // =========================================================================
  // SIMULATOR LOGIC & DISPLAY
  // =========================================================================
  function updateSimulatorDisplay() {
    p1Block.style.setProperty('--p1-color', hero1.color);
    p2Block.style.setProperty('--p2-color', hero2.color);

    p1Block.classList.toggle('active-turn', activeAttacker === 1);
    p2Block.classList.toggle('active-turn', activeAttacker === 2);

    populateSimHeroStyles(1);
    populateSimHeroStyles(2);

    renderCardContent(heroCard1, hero1, activeAttacker === 1 ? `ATTAQUANT (T${p1TurnCount})` : `DÉFENSEUR (T${p1TurnCount})`);
    renderCardContent(heroCard2, hero2, activeAttacker === 2 ? `ATTAQUANT (T${p2TurnCount})` : `DÉFENSEUR (T${p2TurnCount})`);

    p1NameEl.textContent = hero1.name;
    p2NameEl.textContent = hero2.name;

    btnStartP1.textContent = `🟢 ${hero1.name} (J1)`;
    btnStartP2.textContent = `🔵 ${hero2.name} (J2)`;
    btnStartP1.classList.toggle('active', firstPlayerStarter === 1);
    btnStartP2.classList.toggle('active', firstPlayerStarter === 2);

    p1HpEl.textContent = p1Hp;
    p1CpEl.textContent = p1Cp;
    p2HpEl.textContent = p2Hp;
    p2CpEl.textContent = p2Cp;

    p1HpBar.style.width = `${Math.max(0, Math.min(100, (p1Hp / 50) * 100))}%`;
    p2HpBar.style.width = `${Math.max(0, Math.min(100, (p2Hp / 50) * 100))}%`;

    const p1CurrentStats = getHeroTurnStats(hero1.id, p1TurnCount, 1);
    const p2CurrentStats = getHeroTurnStats(hero2.id, p2TurnCount, 2);

    p1StatsPill.innerHTML = `
      <span style="color: var(--accent-gold); font-weight: 800;">Tour ${p1TurnCount}${p1CurrentStats.isExtrapolated ? ' <span style="font-size: 10px; color: #38bdf8; font-weight: 700;">(Extrapolé)</span>' : ''} :</span>
      <span>⚔️ Atk: <strong>${p1CurrentStats.avgAtk}</strong></span>
      <span>💥 Imp: <strong>${p1CurrentStats.avgUndef}</strong></span>
      <span>🛡️ Def: <strong>${p1CurrentStats.avgDef}</strong></span>
      <span>🔄 Contre: <strong>${p1CurrentStats.avgCounter}</strong></span>
      <span>💣 Tok: <strong>${p1CurrentStats.avgToken}</strong></span>
    `;

    p2StatsPill.innerHTML = `
      <span style="color: var(--accent-gold); font-weight: 800;">Tour ${p2TurnCount}${p2CurrentStats.isExtrapolated ? ' <span style="font-size: 10px; color: #38bdf8; font-weight: 700;">(Extrapolé)</span>' : ''} :</span>
      <span>⚔️ Atk: <strong>${p2CurrentStats.avgAtk}</strong></span>
      <span>💥 Imp: <strong>${p2CurrentStats.avgUndef}</strong></span>
      <span>🛡️ Def: <strong>${p2CurrentStats.avgDef}</strong></span>
      <span>🔄 Contre: <strong>${p2CurrentStats.avgCounter}</strong></span>
      <span>💣 Tok: <strong>${p2CurrentStats.avgToken}</strong></span>
    `;

    renderQuickDefTokens(p1QuickTokens, p1Tokens, 1);
    renderQuickDefTokens(p2QuickTokens, p2Tokens, 2);

    renderTokens(p1TokensEl, p1Tokens, 1);
    renderTokens(p2TokensEl, p2Tokens, 2);

    currentTurnBadge.textContent = `Round ${turnNumber}`;
    activeAttackerLabel.textContent = activeAttacker === 1 ? `${hero1.name} (Tour ${p1TurnCount})` : `${hero2.name} (Tour ${p2TurnCount})`;
    activeAttackerLabel.style.color = activeAttacker === 1 ? hero1.color : hero2.color;

    phaseSteps.forEach((step, idx) => {
      step.classList.toggle('active', idx === currentPhase);
      step.classList.toggle('passed', idx < currentPhase);
    });

    phaseStateBadge.textContent = `Phase ${currentPhase + 1} / 5`;
    renderPhaseDetails();
    renderHpCombatGraph();
  }

  function renderCardContent(cardEl, hero, roleBadge) {
    cardEl.style.setProperty('--hero-color', hero.color);
    cardEl.style.setProperty('--hero-glow', hero.color + '66');

    cardEl.innerHTML = `
      <img class="hero-card-img" src="${hero.asset}" alt="${hero.name}" onerror="this.src='assets/heroes.jpg'" />
      <div class="hero-card-overlay"></div>
      <div class="hero-card-top">
        <div class="hero-complexity-die" title="Complexité ${hero.complexity}">
          <img src="assets/complexity/${hero.complexity}-niv.webp" onerror="this.src='assets/complexity/complexity-${hero.complexity}.png'" alt="Niv ${hero.complexity}" />
        </div>
        <span class="hero-role-badge">${roleBadge}</span>
      </div>
      <div class="hero-card-bottom">
        <div class="hero-card-name">${hero.name}</div>
        <div class="hero-change-hint">Cliquer pour changer</div>
      </div>
    `;
  }

  // Render quick defensive token adders
  function renderQuickDefTokens(container, tokens, playerNum) {
    container.innerHTML = '';
    SPECIAL_DEFENSIVE_TOKENS.forEach(tok => {
      const btn = document.createElement('button');
      btn.className = 'btn-quick-def';
      btn.textContent = `+ ${tok.name}`;
      btn.title = tok.desc;
      btn.addEventListener('click', () => {
        addToken(tokens, tok.name, playerNum);
      });
      container.appendChild(btn);
    });
  }

  function addToken(tokens, tokenName, playerNum) {
    const clean = tokenName.trim();
    const existing = tokens.find(t => t.name.toLowerCase() === clean.toLowerCase());
    if (existing) existing.count++;
    else tokens.push({ name: clean, count: 1 });
    updateSimulatorDisplay();
    log(`🛡️ ${playerNum === 1 ? hero1.name : hero2.name} s'équipe du token [${clean}]`, 'info');
  }

  function renderTokens(container, tokens, playerNum) {
    container.innerHTML = '';
    tokens.forEach((t, index) => {
      const chip = document.createElement('span');
      chip.className = 'token-chip';
      chip.title = 'Cliquer pour retirer';
      chip.innerHTML = `${t.name} <span class="token-count">${t.count}</span>`;
      chip.addEventListener('click', () => {
        if (t.count > 1) t.count--;
        else tokens.splice(index, 1);
        updateSimulatorDisplay();
        log(`${playerNum === 1 ? hero1.name : hero2.name} perd un token [${t.name}]`, 'info');
      });
      container.appendChild(chip);
    });

    const addBtn = document.createElement('button');
    addBtn.className = 'btn-add-token';
    addBtn.textContent = '+ Token';
    addBtn.addEventListener('click', () => {
      const tokenName = prompt(`Nom du token pour ${playerNum === 1 ? hero1.name : hero2.name} :`);
      if (tokenName && tokenName.trim()) {
        addToken(tokens, tokenName, playerNum);
      }
    });
    container.appendChild(addBtn);
  }

  // Starter Selector Handlers
  btnStartP1.addEventListener('click', () => {
    firstPlayerStarter = 1;
    resetCombatState();
  });
  btnStartP2.addEventListener('click', () => {
    firstPlayerStarter = 2;
    resetCombatState();
  });

  function resetCombatState() {
    stopAutoFight();
    p1Hp = 50; p1Cp = 2; p1Tokens = [];
    p2Hp = 50; p2Cp = 2; p2Tokens = [];
    p1TurnCount = 1; p2TurnCount = 1;
    turnNumber = 1;
    activeAttacker = firstPlayerStarter;
    currentPhase = 0;
    pvHistory = [{ step: 'Début', round: 0, p1: 50, p2: 50, tokensTriggered: [] }];
    updateSimulatorDisplay();
    log(`🔄 Combat réinitialisé. Premier attaquant : ${activeAttacker === 1 ? hero1.name : hero2.name}`, 'info');
  }

  // =========================================================================
  // PHASE ENGINE WITH DEFENSIVE TOKENS RESOLUTION
  // =========================================================================
  function renderPhaseDetails() {
    const attacker = activeAttacker === 1 ? hero1 : hero2;
    const defender = activeAttacker === 1 ? hero2 : hero1;
    const attackerTurn = activeAttacker === 1 ? p1TurnCount : p2TurnCount;
    const defenderTurn = activeAttacker === 1 ? p2TurnCount : p1TurnCount;
    const defTokens = activeAttacker === 1 ? p2Tokens : p1Tokens;

    const atkStats = getHeroTurnStats(attacker.id, attackerTurn, activeAttacker);
    const defStats = getHeroTurnStats(defender.id, defenderTurn, activeAttacker === 1 ? 2 : 1);

    let html = '';
    switch (currentPhase) {
      case 0: // Upkeep
        html = `
          <div class="phase-description-text">
            <strong>1. Phase d'Entretien (Upkeep) :</strong><br />
            - <strong>${attacker.name}</strong> (Tour ${attackerTurn}) gagne <strong>+1 PC</strong>.<br />
            - Résolution des tokens / effets d'état (moyenne : <strong>${atkStats.avgToken}</strong> dégâts).
          </div>
          <div class="stats-breakdown-grid">
            <div class="breakdown-item">
              <span class="breakdown-label">Gain PC</span>
              <span class="breakdown-val" style="color: #3b82f6;">+1 PC</span>
            </div>
            <div class="breakdown-item">
              <span class="breakdown-label">Dégâts Tokens</span>
              <span class="breakdown-val" style="color: #f59e0b;">${atkStats.avgToken} PV</span>
            </div>
          </div>
        `;
        break;

      case 1: // Main 1
        html = `
          <div class="phase-description-text">
            <strong>2. Phase Principale 1 :</strong><br />
            <strong>${attacker.name}</strong> prépare son assaut du <strong>Tour ${attackerTurn}</strong>.
          </div>
          <div class="stats-breakdown-grid">
            <div class="breakdown-item">
              <span class="breakdown-label">PC Disponibles</span>
              <span class="breakdown-val" style="color: #3b82f6;">${activeAttacker === 1 ? p1Cp : p2Cp} PC</span>
            </div>
          </div>
        `;
        break;

      case 2: // Offensive Roll
        html = `
          <div class="phase-description-text">
            <strong>3. Phase de Lancer Offensif :</strong><br />
            <strong>${attacker.name}</strong> déclenche son attaque :<br />
            - Dégâts parables : <strong>${atkStats.avgAtk}</strong> | Imparables : <strong>${atkStats.avgUndef}</strong>.
          </div>
          <div class="stats-breakdown-grid">
            <div class="breakdown-item">
              <span class="breakdown-label">Dégâts Parables</span>
              <span class="breakdown-val" style="color: #ff9944;">${atkStats.avgAtk}</span>
            </div>
            <div class="breakdown-item">
              <span class="breakdown-label">Dégâts Imparables</span>
              <span class="breakdown-val" style="color: #ff4757;">${atkStats.avgUndef}</span>
            </div>
            <div class="breakdown-item">
              <span class="breakdown-label">Soin Prévu</span>
              <span class="breakdown-val" style="color: #2ed573;">+${atkStats.avgHeal}</span>
            </div>
          </div>
        `;
        break;

      case 3: // Defense & Counter
        const isNoDef = (atkStats.avgAtk === 0);
        if (isNoDef) {
          html = `
            <div class="phase-description-text">
              <strong>4. Phase de Défense :</strong><br />
              <strong style="color: #ffe22d;">🪶 Aucune attaque directe parable</strong> (${attacker.name} inflige ${atkStats.avgUndef} imparable + ${atkStats.avgToken} Nevermore/token).<br />
              <strong>${defender.name} ne déclenche aucun jet de défense</strong> (0 dégât bloqué, 0 riposte, aucun gain d'avantage de défense) !
            </div>
            <div class="stats-breakdown-grid">
              <div class="breakdown-item">
                <span class="breakdown-label">Prévention (Def)</span>
                <span class="breakdown-val" style="color: #94a3b8;">0 (Aucune défense)</span>
              </div>
              <div class="breakdown-item">
                <span class="breakdown-label">Riposte</span>
                <span class="breakdown-val" style="color: #94a3b8;">0</span>
              </div>
            </div>
          `;
        } else {
          const hasDefToken = defTokens.some(t => ['parlay', 'ombre', 'agilité', 'agilite', 'illusion'].includes(t.name.toLowerCase()));
          html = `
            <div class="phase-description-text">
              <strong>4. Phase de Défense & Riposte :</strong><br />
              <strong>${defender.name}</strong> défend (Tour ${defenderTurn}) :<br />
              - Prévention : <strong>${defStats.avgDef}</strong> bloqués | Riposte : <strong>${defStats.avgCounter}</strong> en retour.
              ${hasDefToken ? `<br /><span style="color: #38bdf8; font-weight: bold;">🛡️ Token défensif actif détecté sur ${defender.name} ! Il sera activé lors de la résolution.</span>` : ''}
            </div>
            <div class="stats-breakdown-grid">
              <div class="breakdown-item">
                <span class="breakdown-label">Prévention (Def)</span>
                <span class="breakdown-val" style="color: #38bdf8;">-${defStats.avgDef}</span>
              </div>
              <div class="breakdown-item">
                <span class="breakdown-label">Riposte / Contre</span>
                <span class="breakdown-val" style="color: #c084fc;">${defStats.avgCounter} dégâts</span>
              </div>
            </div>
          `;
        }
        break;

      case 4: // Resolution
        html = `
          <div class="phase-description-text">
            <strong>5. Résolution & Décompte des Dégâts :</strong><br />
            Prise en compte de la défense et des tokens d'annulation/esquive (Parlay, Ombre, Agilité, Illusion).
          </div>
        `;
        break;
    }

    phaseDetailsBox.innerHTML = html;
  }

  function advancePhase() {
    const attacker = activeAttacker === 1 ? hero1 : hero2;
    const defender = activeAttacker === 1 ? hero2 : hero1;
    const attackerTurn = activeAttacker === 1 ? p1TurnCount : p2TurnCount;
    const defenderTurn = activeAttacker === 1 ? p2TurnCount : p1TurnCount;
    const defTokens = activeAttacker === 1 ? p2Tokens : p1Tokens;

    const atkStats = getHeroTurnStats(attacker.id, attackerTurn, activeAttacker);
    const defStats = getHeroTurnStats(defender.id, defenderTurn, activeAttacker === 1 ? 2 : 1);

    if (currentPhase === 0) {
      if (activeAttacker === 1) {
        p1Cp = Math.min(15, p1Cp + 1);
        if (atkStats.avgToken > 0) {
          p2Hp = Math.max(0, +(p2Hp - atkStats.avgToken).toFixed(1));
          log(`💣 [Upkeep T${attackerTurn}] Tokens infligent ${atkStats.avgToken} dégâts à ${defender.name}. (PV: ${p2Hp})`, 'damage');
        }
      } else {
        p2Cp = Math.min(15, p2Cp + 1);
        if (atkStats.avgToken > 0) {
          p1Hp = Math.max(0, +(p1Hp - atkStats.avgToken).toFixed(1));
          log(`💣 [Upkeep T${attackerTurn}] Tokens infligent ${atkStats.avgToken} dégâts à ${defender.name}. (PV: ${p1Hp})`, 'damage');
        }
      }
      const extMsg = atkStats.isExtrapolated ? ' [📊 Moyenne Extrapolée]' : '';
      log(`⚡ [Round ${turnNumber} - Tour ${attackerTurn} de ${attacker.name}]${extMsg} Début de tour (+1 PC)`, 'turn');
      currentPhase = 1;
    } else if (currentPhase === 1) {
      log(`🃏 [Main 1] ${attacker.name} prépare son offensive du Tour ${attackerTurn}`, 'info');
      currentPhase = 2;
    } else if (currentPhase === 2) {
      log(`🎯 [Lancer Offensif T${attackerTurn}] ${attacker.name} frappe : ${atkStats.avgAtk} parables + ${atkStats.avgUndef} imparables`, 'damage');
      currentPhase = 3;
    } else if (currentPhase === 3) {
      log(`🛡️ [Défense T${defenderTurn}] ${defender.name} prépare ${defStats.avgDef} de prévention et ${defStats.avgCounter} de riposte`, 'defense');
      currentPhase = 4;
    } else if (currentPhase === 4) {
      // Check Special Defensive Tokens
      let damageCancelled = false;
      let damageHalved = false;
      let cancelReason = '';
      const triggeredTokens = [];

      // 1. Ombre (Voleur / Shadow Thief) - 100% immunity
      const ombreToken = defTokens.find(t => t.name.toLowerCase() === 'ombre');
      if (defStats.hasShadow || ombreToken) {
        if (ombreToken) {
          if (ombreToken.count > 1) ombreToken.count--;
          else defTokens.splice(defTokens.indexOf(ombreToken), 1);
        }
        damageCancelled = true;
        triggeredTokens.push('ombre');
        cancelReason = `🛡️ [Token Ombre] ${defender.name} se dissimule dans l'Ombre : TOUS LES DÉGÂTS D'ATTAQUE DU TOUR SONT ANNULÉS (0 PV) !`;
      }

      // 2. Parlay (Pirate V2) - Attack damage cancellation (tokens & counter still apply)
      if (!damageCancelled) {
        const parlayToken = defTokens.find(t => t.name.toLowerCase() === 'parlay');
        if (defStats.hasParlay || parlayToken) {
          if (parlayToken) {
            if (parlayToken.count > 1) parlayToken.count--;
            else defTokens.splice(defTokens.indexOf(parlayToken), 1);
          }
          damageCancelled = true;
          triggeredTokens.push('parlay');
          cancelReason = `🏴‍☠️ [Token Parlay] Accord de Parlement invoqué : L'attaque de ${attacker.name} est annulée (0 PV) ! (Dégâts de tokens et contre-attaques restent actifs)`;
        }
      }

      // 3. Loki Illusion Active Turn (Tours 4 et 7 issus du fichier Google Sheets)
      if (!damageCancelled && defender.id === 'loki' && defStats.hasIllusion) {
        damageCancelled = true;
        triggeredTokens.push('illusion');
        cancelReason = `🎭 [Illusion de Loki - Tour ${defenderTurn}] L'illusion de Loki est active (comme en E7/H7 de votre fichier) : tous les dégâts d'attaque sont annulés (0 PV) !`;
      }

      // 4. Illusion Token (Loki / Autres) - 50% chance
      if (!damageCancelled) {
        const illusionToken = defTokens.find(t => t.name.toLowerCase() === 'illusion');
        if (illusionToken) {
          const success = Math.random() < 0.5;
          if (illusionToken.count > 1) illusionToken.count--;
          else defTokens.splice(defTokens.indexOf(illusionToken), 1);
          if (success) {
            damageCancelled = true;
            triggeredTokens.push('illusion');
            cancelReason = `🎭 [Token Illusion] Réussite ! L'attaque de ${attacker.name} passe à travers un leurre (0 dégât) !`;
          } else {
            log(`🎭 [Token Illusion] Échec de l'illusion de ${defender.name}.`, 'defense');
          }
        }
      }

      // 5. Agilité (Black Widow & Autres) - Réduit de 50% l'attaque adverse !
      if (!damageCancelled) {
        const agiliteToken = defTokens.find(t => ['agilité', 'agilite', 'agility'].includes(t.name.toLowerCase()));
        if (defStats.hasAgility || agiliteToken) {
          if (agiliteToken) {
            if (agiliteToken.count > 1) agiliteToken.count--;
            else defTokens.splice(defTokens.indexOf(agiliteToken), 1);
          }
          damageHalved = true;
          triggeredTokens.push('agilité');
          log(`⚡ [Token Agilité] ${defender.name} déclenche son Agilité : l'attaque adverse de ${attacker.name} est réduite de 50% !`, 'defense');
        }
      }

      // CORE RULE DICE THRONE & RAVENESS / NEVERMORE:
      // Quand l'attaque directe parable est égale à 0 (imparable pur, ou plumes Nevermore traitées comme des tokens),
      // la défense adverse NE SE DÉCLENCHE PAS !
      // (Aucun dégât bloqué, aucune riposte de défense, et pas d'avantages/tokens gagnés sur jet de défense).
      const isNoDefAtk = (atkStats.avgAtk === 0);
      let effectiveDef = defStats.avgDef || 0;
      let effectiveCounter = defStats.avgCounter || 0;

      if (attacker.id === 'raveness' && atkStats.avgToken > 0 && !triggeredTokens.includes('nevermore')) {
        triggeredTokens.push('nevermore');
      }

      if (isNoDefAtk) {
        effectiveDef = 0;
        effectiveCounter = 0;
        if (attacker.id === 'raveness') {
          log(`🪶 [Nevermore / Imparable] ${attacker.name} ne déclenche pas de défense (${atkStats.avgToken > 0 ? `🪶 Plumes Nevermore: ${atkStats.avgToken} dégâts directs` : ''}${atkStats.avgUndef > 0 ? `, 💥 Imparable: ${atkStats.avgUndef}` : ''}) : ${defender.name} ne peut pas lancer de défense (0 bloqué, 0 riposte) !`, 'attack');
        } else if (atkStats.avgUndef > 0) {
          log(`⚡ [Attaque Imparable] L'attaque de ${attacker.name} est totalement imparable : ${defender.name} ne peut pas lancer de défense (0 dégât bloqué, 0 riposte, aucun gain d'avantage de défense) !`, 'attack');
        } else {
          log(`💨 [Attaque Pure Token] ${attacker.name} n'inflige que des dégâts directs de tokens (${atkStats.avgToken} PV) sans attaque directe : aucune défense déclenchée.`, 'attack');
        }
      }

      let atkVal = atkStats.avgAtk || 0;
      let undefVal = atkStats.avgUndef || 0;

      if (damageHalved) {
        atkVal = +(atkVal * 0.5).toFixed(1);
        undefVal = +(undefVal * 0.5).toFixed(1);
      }

      let totalToDefender = 0;
      if (damageCancelled) {
        log(cancelReason, 'defense');
      } else {
        const netDefendable = Math.max(0, atkVal - effectiveDef);
        totalToDefender = +(netDefendable + undefVal).toFixed(1);
      }

      if (activeAttacker === 1) {
        p2Hp = Math.max(0, +(p2Hp - totalToDefender).toFixed(1));
        if (effectiveCounter > 0) p1Hp = Math.max(0, +(p1Hp - effectiveCounter).toFixed(1));
        if (atkStats.avgHeal > 0) p1Hp = Math.min(99, +(p1Hp + atkStats.avgHeal).toFixed(1));
      } else {
        p1Hp = Math.max(0, +(p1Hp - totalToDefender).toFixed(1));
        if (effectiveCounter > 0) p2Hp = Math.max(0, +(p2Hp - effectiveCounter).toFixed(1));
        if (atkStats.avgHeal > 0) p2Hp = Math.min(99, +(p2Hp + atkStats.avgHeal).toFixed(1));
      }

      log(`💥 [Résolution] ${defender.name} subit ${totalToDefender} dégâts (PV: ${activeAttacker === 1 ? p2Hp : p1Hp}) | Riposte: ${effectiveCounter} (PV: ${activeAttacker === 1 ? p1Hp : p2Hp})`, 'damage');

      // Record HP history: FUSION DES TOURS (Un seul cran par tour des 2 joueurs)
      const roundIndex = turnNumber;
      const existingEntry = pvHistory.find(e => e.round === roundIndex);
      if (existingEntry) {
        existingEntry.p1 = p1Hp;
        existingEntry.p2 = p2Hp;
        if (triggeredTokens.length > 0) {
          existingEntry.tokensTriggered = Array.from(new Set([...(existingEntry.tokensTriggered || []), ...triggeredTokens]));
        }
      } else {
        pvHistory.push({
          step: `Tour ${roundIndex}`,
          round: roundIndex,
          p1: p1Hp,
          p2: p2Hp,
          tokensTriggered: [...triggeredTokens]
        });
      }

      // Check KO
      if (p1Hp <= 0 || p2Hp <= 0) {
        const winner = p1Hp > 0 ? hero1 : hero2;
        log(`🏆 COMBAT TERMINÉ ! ${winner.name} l'emporte !`, 'turn');
        stopAutoFight();
        updateSimulatorDisplay();
        return;
      }

      // Next turn
      if (activeAttacker === 1) {
        p1TurnCount++;
        activeAttacker = 2;
      } else {
        p2TurnCount++;
        activeAttacker = 1;
        turnNumber++;
      }
      currentPhase = 0;
    }

    updateSimulatorDisplay();
  }

  function advanceFullTurn() {
    if (p1Hp <= 0 || p2Hp <= 0) return;
    do {
      advancePhase();
    } while (currentPhase !== 0 && p1Hp > 0 && p2Hp > 0);
  }

  function startAutoFight() {
    if (isAutoFighting) {
      stopAutoFight();
      return;
    }
    isAutoFighting = true;
    btnAutoFight.textContent = '⏸️ Pause';
    btnAutoFight.style.background = 'rgba(239, 68, 68, 0.3)';

    autoFightTimer = setInterval(() => {
      if (p1Hp <= 0 || p2Hp <= 0) {
        stopAutoFight();
        return;
      }
      advancePhase();
    }, 450);
  }

  function stopAutoFight() {
    isAutoFighting = false;
    if (autoFightTimer) clearInterval(autoFightTimer);
    btnAutoFight.textContent = '⚡ Combat Auto';
    btnAutoFight.style.background = '';
  }

  // Helper: Pick a random individual run from a hero's real data for a given turn
  function getRandomRunData(heroId, turnIndex, slot = null) {
    const variant = getHeroVariant(heroId, slot);
    const turns = variant.turns || [];
    if (turns.length === 0) {
      return { atk: 6, undef: 1, token: 1, counter: 1, def: 2, heal: 0 };
    }

    let turnObj = turns.find(t => t.turn === turnIndex);
    if (!turnObj || !turnObj.runs || turnObj.runs.length === 0) {
      // If turnIndex is beyond recorded data, pick a random recorded turn
      turnObj = turns[Math.floor(Math.random() * turns.length)];
    }

    if (turnObj && turnObj.runs && turnObj.runs.length > 0) {
      const r = turnObj.runs[Math.floor(Math.random() * turnObj.runs.length)];
      return {
        atk: r.atk ?? 0,
        undef: r.undef ?? 0,
        token: r.token ?? 0,
        counter: r.counter ?? 0,
        def: r.def ?? 0,
        heal: r.heal ?? 0,
        hasAgility: !!turnObj.hasAgility,
        hasParlay: !!turnObj.hasParlay,
        hasShadow: !!turnObj.hasShadow,
        hasIllusion: !!turnObj.hasIllusion
      };
    }

    return {
      atk: turnObj.avgAtk ?? 6,
      undef: turnObj.avgUndef ?? 1,
      token: turnObj.avgToken ?? 1,
      counter: turnObj.avgCounter ?? 1,
      def: turnObj.avgDef ?? 2,
      heal: turnObj.avgHeal ?? 0,
      hasAgility: !!turnObj.hasAgility,
      hasParlay: !!turnObj.hasParlay,
      hasShadow: !!turnObj.hasShadow,
      hasIllusion: !!turnObj.hasIllusion
    };
  }

  function runMonteCarlo() {
    let p1Wins = 0, p2Wins = 0, totalRounds = 0;
    let p1WinsWhenP1Starts = 0, p2WinsWhenP2Starts = 0;
    const runs = 100;

    for (let i = 0; i < runs; i++) {
      let hp1 = 50, hp2 = 50;
      let t1Count = 1, t2Count = 1, round = 0;
      // Exactement 50% J1 commence (combats 0 à 49) et 50% J2 commence (combats 50 à 99)
      const starter = (i < 50) ? 1 : 2;
      let attacker = starter;

      while (hp1 > 0 && hp2 > 0 && round < 40) {
        round++;

        const atkId = attacker === 1 ? hero1.id : hero2.id;
        const defId = attacker === 1 ? hero2.id : hero1.id;
        const atkTurn = attacker === 1 ? t1Count : t2Count;
        const defTurn = attacker === 1 ? t2Count : t1Count;

        // Tirage aléatoire indépendant d'un run réel pour ce tour
        const rAtk = getRandomRunData(atkId, atkTurn, attacker);
        const rDef = getRandomRunData(defId, defTurn, attacker === 1 ? 2 : 1);

        // Tokens défensifs
        let dmgCancelled = false;
        let dmgHalved = false;

        if (rDef.hasShadow) {
          dmgCancelled = true;
        } else if (rDef.hasParlay) {
          dmgCancelled = true;
        } else if (defId === 'loki' && rDef.hasIllusion) {
          dmgCancelled = true;
        } else if (rDef.hasAgility) {
          dmgHalved = true;
        }

        // Règle spéciale Raveness / Nevermore / Imparable : si atk direct = 0, aucune défense
        const isNoDef = (rAtk.atk === 0);
        let effDef = isNoDef ? 0 : rDef.def;
        let effCounter = isNoDef ? 0 : rDef.counter;

        let atkVal = rAtk.atk;
        let undefVal = rAtk.undef;
        if (dmgHalved) {
          atkVal = Math.ceil(atkVal * 0.5);
          undefVal = Math.ceil(undefVal * 0.5);
        }

        let totalDmgToDefender = 0;
        if (!dmgCancelled) {
          totalDmgToDefender = Math.max(0, atkVal - effDef) + undefVal;
        }

        if (attacker === 1) {
          hp2 = Math.max(0, +(hp2 - totalDmgToDefender - rAtk.token).toFixed(1));
          hp1 = Math.max(0, +(hp1 - effCounter).toFixed(1));
          hp1 = Math.min(99, +(hp1 + rAtk.heal).toFixed(1));
          hp2 = Math.min(99, +(hp2 + rDef.heal).toFixed(1));
          t1Count++;
          attacker = 2;
        } else {
          hp1 = Math.max(0, +(hp1 - totalDmgToDefender - rAtk.token).toFixed(1));
          hp2 = Math.max(0, +(hp2 - effCounter).toFixed(1));
          hp2 = Math.min(99, +(hp2 + rAtk.heal).toFixed(1));
          hp1 = Math.min(99, +(hp1 + rDef.heal).toFixed(1));
          t2Count++;
          attacker = 1;
        }
      }

      totalRounds += round;
      if (hp1 > hp2) {
        p1Wins++;
        if (starter === 1) p1WinsWhenP1Starts++;
      } else {
        p2Wins++;
        if (starter === 2) p2WinsWhenP2Starts++;
      }
    }

    const avgR = (totalRounds / runs).toFixed(1);
    const msg = `📊 SIMULATION DE 100 COMBATS (Mix de Runs Réels & Alternance 50/50) :\n\n` +
      `• ${hero1.name} (J1) : ${p1Wins} victoires (${p1Wins}%)\n` +
      `   └ ${p1WinsWhenP1Starts}/50 victoires quand J1 commence\n\n` +
      `• ${hero2.name} (J2) : ${p2Wins} victoires (${p2Wins}%)\n` +
      `   └ ${p2WinsWhenP2Starts}/50 victoires quand J2 commence\n\n` +
      `• Durée moyenne des combats : ${avgR} tours\n\n` +
      `(Note : Chaque tour a pioché indépendamment un run réel aléatoire parmi vos données).`;

    alert(msg);
    log(`📊 100 Combats (Runs réels mixés, 50% J1 / 50% J2 starter) : ${hero1.name} ${p1Wins}% - ${hero2.name} ${p2Wins}% (${avgR} tours)`, 'turn');
  }

  // Button Listeners
  btnNextPhase.addEventListener('click', advancePhase);
  btnNextTurn.addEventListener('click', advanceFullTurn);
  btnAutoFight.addEventListener('click', startAutoFight);
  btnMonteCarlo.addEventListener('click', runMonteCarlo);
  resetCombatBtn.addEventListener('click', resetCombatState);
  btnClearLog.addEventListener('click', () => combatLog.innerHTML = '');

  swapHeroesBtn.addEventListener('click', () => {
    stopAutoFight();
    const tmpH = hero1; hero1 = hero2; hero2 = tmpH;
    const tmpHp = p1Hp; p1Hp = p2Hp; p2Hp = tmpHp;
    const tmpCp = p1Cp; p1Cp = p2Cp; p2Cp = tmpCp;
    const tmpTok = p1Tokens; p1Tokens = p2Tokens; p2Tokens = tmpTok;
    const tmpVar = p1SelectedVariant; p1SelectedVariant = p2SelectedVariant; p2SelectedVariant = tmpVar;
    populateSimHeroStyles(1);
    populateSimHeroStyles(2);
    updateSimulatorDisplay();
    log(`⇄ Inversion des deux héros : ${hero1.name} (J1) vs ${hero2.name} (J2)`, 'info');
  });

  // Manual Adjusters
  document.querySelectorAll('[data-action]').forEach(btn => {
    btn.addEventListener('click', () => {
      const action = btn.dataset.action;
      const target = btn.dataset.target;
      const delta = action === 'inc' ? 1 : -1;
      if (target === 'p1Hp') p1Hp = Math.max(0, p1Hp + delta);
      else if (target === 'p1Cp') p1Cp = Math.max(0, Math.min(15, p1Cp + delta));
      else if (target === 'p2Hp') p2Hp = Math.max(0, p2Hp + delta);
      else if (target === 'p2Cp') p2Cp = Math.max(0, Math.min(15, p2Cp + delta));
      updateSimulatorDisplay();
    });
  });

  // =========================================================================
  // HP COMBAT GRAPH (Interactive SVG Line Chart)
  // =========================================================================
  function renderHpCombatGraph() {
    if (!hpCombatSvg) return;
    hpCombatSvg.innerHTML = '';

    const width = hpCombatSvg.clientWidth || 600;
    const height = hpCombatSvg.clientHeight || 220;
    const padL = 40, padR = 25, padT = 20, padB = 30;

    const chartW = width - padL - padR;
    const chartH = height - padT - padB;

    // Grid lines (0, 10, 20, 30, 40, 50 PV)
    for (let hp = 0; hp <= 50; hp += 10) {
      const y = padT + chartH - (hp / 50) * chartH;
      const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
      line.setAttribute('x1', padL);
      line.setAttribute('y1', y);
      line.setAttribute('x2', width - padR);
      line.setAttribute('y2', y);
      line.setAttribute('stroke', 'rgba(255, 255, 255, 0.08)');
      line.setAttribute('stroke-dasharray', '3 3');
      hpCombatSvg.appendChild(line);

      const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      text.setAttribute('x', padL - 8);
      text.setAttribute('y', y + 3);
      text.setAttribute('text-anchor', 'end');
      text.setAttribute('fill', 'rgba(255, 255, 255, 0.4)');
      text.setAttribute('font-size', '10');
      text.setAttribute('font-weight', '700');
      text.textContent = hp;
      hpCombatSvg.appendChild(text);
    }

    if (pvHistory.length === 0) return;

    const count = pvHistory.length;
    const stepX = count > 1 ? chartW / (count - 1) : chartW;

    let dP1 = '', dP2 = '';
    const pointsP1 = [], pointsP2 = [];

    pvHistory.forEach((pt, i) => {
      const x = padL + i * stepX;
      const y1 = padT + chartH - (Math.max(0, pt.p1) / 50) * chartH;
      const y2 = padT + chartH - (Math.max(0, pt.p2) / 50) * chartH;

      pointsP1.push({ x, y: y1, val: pt.p1, step: pt.step });
      pointsP2.push({ x, y: y2, val: pt.p2, step: pt.step });

      if (i === 0) {
        dP1 += `M ${x} ${y1}`;
        dP2 += `M ${x} ${y2}`;
      } else {
        dP1 += ` L ${x} ${y1}`;
        dP2 += ` L ${x} ${y2}`;
      }

      // X Axis Label
      const xText = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      xText.setAttribute('x', x);
      xText.setAttribute('y', height - 10);
      xText.setAttribute('text-anchor', 'middle');
      xText.setAttribute('fill', 'rgba(255, 255, 255, 0.5)');
      xText.setAttribute('font-size', '10');
      xText.setAttribute('font-weight', 'bold');
      xText.textContent = pt.step;
      hpCombatSvg.appendChild(xText);
    });

    // Draw Line 1
    const path1 = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path1.setAttribute('d', dP1);
    path1.setAttribute('fill', 'none');
    path1.setAttribute('stroke', hero1.color || '#ff9944');
    path1.setAttribute('stroke-width', '3');
    path1.setAttribute('stroke-linecap', 'round');
    path1.setAttribute('stroke-linejoin', 'round');
    hpCombatSvg.appendChild(path1);

    // Draw Line 2
    const path2 = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path2.setAttribute('d', dP2);
    path2.setAttribute('fill', 'none');
    path2.setAttribute('stroke', hero2.color || '#38bdf8');
    path2.setAttribute('stroke-width', '3');
    path2.setAttribute('stroke-linecap', 'round');
    path2.setAttribute('stroke-linejoin', 'round');
    hpCombatSvg.appendChild(path2);

    // Draw Dots
    pointsP1.forEach(pt => {
      const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      circle.setAttribute('cx', pt.x);
      circle.setAttribute('cy', pt.y);
      circle.setAttribute('r', '5');
      circle.setAttribute('fill', '#000');
      circle.setAttribute('stroke', hero1.color || '#ff9944');
      circle.setAttribute('stroke-width', '2.5');
      const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
      title.textContent = `${hero1.name} : ${pt.val} PV (${pt.step})`;
      circle.appendChild(title);
      hpCombatSvg.appendChild(circle);
    });

    pointsP2.forEach(pt => {
      const circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      circle.setAttribute('cx', pt.x);
      circle.setAttribute('cy', pt.y);
      circle.setAttribute('r', '5');
      circle.setAttribute('fill', '#000');
      circle.setAttribute('stroke', hero2.color || '#38bdf8');
      circle.setAttribute('stroke-width', '2.5');
      const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
      title.textContent = `${hero2.name} : ${pt.val} PV (${pt.step})`;
      circle.appendChild(title);
      hpCombatSvg.appendChild(circle);
    });

    // Draw Triggered Token Icons above points
    pvHistory.forEach((pt, i) => {
      if (pt.tokensTriggered && pt.tokensTriggered.length > 0) {
        const x = padL + i * stepX;
        const yTop = Math.min(pointsP1[i].y, pointsP2[i].y);
        pt.tokensTriggered.forEach((tok, tokIdx) => {
          const iconSrc = TOKEN_ICONS[tok.toLowerCase()];
          if (iconSrc) {
            const img = document.createElementNS('http://www.w3.org/2000/svg', 'image');
            img.setAttribute('href', iconSrc);
            img.setAttribute('x', x - 9 + (tokIdx * 20));
            img.setAttribute('y', Math.max(2, yTop - 26));
            img.setAttribute('width', '18');
            img.setAttribute('height', '18');
            img.style.filter = 'drop-shadow(0 2px 4px rgba(0,0,0,0.8))';
            const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
            title.textContent = `Token déclenché (${pt.step}) : ${tok}`;
            img.appendChild(title);
            hpCombatSvg.appendChild(img);
          }
        });
      }
    });

    // Update Legend
    hpGraphLegend.innerHTML = `
      <div class="legend-item">
        <span class="legend-color-dot" style="background: ${hero1.color};"></span>
        <span>${hero1.name} (J1) : <strong style="color: ${hero1.color};">${p1Hp} PV</strong></span>
      </div>
      <div class="legend-item">
        <span class="legend-color-dot" style="background: ${hero2.color};"></span>
        <span>${hero2.name} (J2) : <strong style="color: ${hero2.color};">${p2Hp} PV</strong></span>
      </div>
    `;
  }

  // =========================================================================
  // HERO PICKER MODAL (Filtered to Active Heroes Only)
  // =========================================================================
  heroCard1.addEventListener('click', () => openHeroModal(1));
  document.getElementById('changeH1Btn').addEventListener('click', () => openHeroModal(1));
  heroCard2.addEventListener('click', () => openHeroModal(2));
  document.getElementById('changeH2Btn').addEventListener('click', () => openHeroModal(2));

  function openHeroModal(slot) {
    pickingSlot = slot;
    modal.classList.add('active');
    heroSearchInput.value = '';
    renderModalHeroes();
    heroSearchInput.focus();
  }

  function closeModal() { modal.classList.remove('active'); }
  closeModalBtn.addEventListener('click', closeModal);
  modal.addEventListener('click', e => { if (e.target === modal) closeModal(); });
  heroSearchInput.addEventListener('input', renderModalHeroes);

  randomPickBtn.addEventListener('click', () => {
    const list = getActiveHeroesList();
    if (list.length > 0) {
      const chosen = list[Math.floor(Math.random() * list.length)];
      selectHeroInSlot(chosen);
    }
  });

  function getActiveHeroesList() {
    const q = heroSearchInput.value.toLowerCase().trim();
    return DTS_HEROES.filter(h => {
      const isActive = statsData[h.id]?.active;
      if (!isActive) return false;
      if (q && !h.name.toLowerCase().includes(q)) return false;
      return true;
    });
  }

  function renderModalHeroes() {
    const list = getActiveHeroesList();
    modalHeroGrid.innerHTML = '';

    if (list.length === 0) {
      modalHeroGrid.innerHTML = `
        <div style="grid-column: 1/-1; text-align: center; padding: 40px; color: var(--text-muted);">
          Aucun héros actif correspondant.<br />
          <button id="btnGoToProfiles" class="btn-ghost" style="margin-top: 14px;">Activer d'autres héros dans l'onglet Profils</button>
        </div>
      `;
      const btnGo = document.getElementById('btnGoToProfiles');
      if (btnGo) {
        btnGo.addEventListener('click', () => {
          closeModal();
          document.querySelector('[data-tab="tabProfiles"]').click();
        });
      }
      return;
    }

    list.forEach(hero => {
      const card = document.createElement('div');
      card.className = 'hero-card';
      renderCardContent(card, hero, `NIV ${hero.complexity}`);

      const isCurrent = (pickingSlot === 1 && hero.id === hero1.id) || (pickingSlot === 2 && hero.id === hero2.id);
      if (isCurrent) {
        card.style.borderColor = '#ffe22d';
        card.style.boxShadow = '0 0 16px rgba(255, 226, 45, 0.7)';
      }

      card.addEventListener('click', () => selectHeroInSlot(hero));
      modalHeroGrid.appendChild(card);
    });
  }

  function selectHeroInSlot(hero) {
    if (pickingSlot === 1) {
      hero1 = hero;
      p1TurnCount = 1;
      p1SelectedVariant = null;
      populateSimHeroStyles(1);
    } else {
      hero2 = hero;
      p2TurnCount = 1;
      p2SelectedVariant = null;
      populateSimHeroStyles(2);
    }
    updateSimulatorDisplay();
    closeModal();
    log(`Héros ${pickingSlot} sélectionné : ${hero.name}`, 'info');
  }

  // =========================================================================
  // TAB 2: PROFILES, ACTIVE FILTERS & STYLES MANAGER
  // =========================================================================
  filterTabPills.forEach(pill => {
    pill.addEventListener('click', () => {
      filterTabPills.forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      currentEditorFilter = pill.dataset.filter;
      renderEditor();
    });
  });

  function renderEditor() {
    const q = editorSearch.value.toLowerCase().trim();
    editorHeroesList.innerHTML = '';

    const allHeroes = DTS_HEROES.filter(h => {
      const isHeroActive = !!statsData[h.id]?.active;
      if (currentEditorFilter === 'active' && !isHeroActive) return false;
      if (currentEditorFilter === 'inactive' && isHeroActive) return false;
      if (q && !h.name.toLowerCase().includes(q)) return false;
      return true;
    });

    const activeCount = DTS_HEROES.filter(h => statsData[h.id]?.active).length;
    activeCountBadge.textContent = `${activeCount} actifs`;

    if (!selectedEditorHero || !DTS_HEROES.find(h => h.id === selectedEditorHero.id)) {
      selectedEditorHero = DTS_HEROES.find(h => statsData[h.id]?.active) || DTS_HEROES[0];
    }

    allHeroes.forEach(hero => {
      const isHeroActive = !!statsData[hero.id]?.active;
      const isSelected = selectedEditorHero && selectedEditorHero.id === hero.id;

      const item = document.createElement('div');
      item.className = `editor-hero-item ${isSelected ? 'selected' : ''}`;
      item.innerHTML = `
        <div class="editor-hero-item-left">
          <img class="editor-hero-avatar" src="${hero.asset}" alt="" onerror="this.src='assets/heroes.jpg'" />
          <div>
            <div style="font-size: 13px; font-weight: 800; color: ${hero.color};">${hero.name}</div>
            <div style="font-size: 10px; color: var(--text-muted);">Complexité ${hero.complexity}</div>
          </div>
        </div>
        <span class="${isHeroActive ? 'active-tag' : 'inactive-tag'}">${isHeroActive ? 'Actif' : 'Inactif'}</span>
      `;

      item.addEventListener('click', () => {
        selectedEditorHero = hero;
        renderEditor();
      });

      editorHeroesList.appendChild(item);
    });

    // Populate Editor Main Form
    if (selectedEditorHero) {
      const hero = selectedEditorHero;
      const profile = getHeroProfile(hero.id);

      edHeroImg.src = hero.asset;
      edHeroName.textContent = hero.name;
      edHeroName.style.color = hero.color;
      edHeroMeta.textContent = `Complexité ${hero.complexity} • ${hero.segments.join(', ')}`;
      edActiveToggle.checked = !!profile.active;

      // Render Style Tabs
      renderStyleTabs(profile);

      // Render Turns for current style
      const currentVarKey = profile.selectedVariant || Object.keys(profile.variants || {})[0] || 'standard';
      renderTurnsCards(profile, currentVarKey);
    }
  }

  function renderStyleTabs(profile) {
    styleTabsRow.innerHTML = '';
    const variants = profile.variants || {};
    const curVar = profile.selectedVariant || Object.keys(variants)[0];

    Object.entries(variants).forEach(([k, v]) => {
      const pill = document.createElement('button');
      pill.className = `style-tab-pill ${k === curVar ? 'active' : ''}`;
      pill.textContent = v.label || k;
      pill.addEventListener('click', () => {
        profile.selectedVariant = k;
        statsData[profile.heroId] = profile;
        renderEditor();
      });
      styleTabsRow.appendChild(pill);
    });

    // Combined Average Pill
    const combinedPill = document.createElement('button');
    combinedPill.className = `style-tab-pill combined ${curVar === '__combined__' ? 'active' : ''}`;
    combinedPill.textContent = '🔀 Moyenne Combinée';
    combinedPill.title = 'Moyenne de tous les styles du héros';
    combinedPill.addEventListener('click', () => {
      profile.selectedVariant = '__combined__';
      statsData[profile.heroId] = profile;
      renderEditor();
    });
    styleTabsRow.appendChild(combinedPill);
  }

  function renderTurnsCards(profile, varKey) {
    if (!edTurnsContainer) return;
    edTurnsContainer.innerHTML = '';

    let variant;
    let isCombined = varKey === '__combined__';

    if (isCombined) {
      variant = getCombinedVariant(profile);
    } else {
      variant = profile.variants[varKey] || { label: 'Standard', turns: [] };
    }

    const turns = variant.turns || [];

    if (turns.length === 0) {
      edTurnsContainer.innerHTML = `
        <div style="text-align: center; color: var(--text-muted); padding: 40px; background: rgba(0,0,0,0.3); border-radius: 10px; border: 1px dashed var(--border-color);">
          Aucun tour renseigné pour ce style.<br />
          <button id="btnEmptyAddTurn" class="btn-add-turn" style="margin-top: 10px;">+ Ajouter le Tour 1</button>
        </div>
      `;
      const btnEmpty = document.getElementById('btnEmptyAddTurn');
      if (btnEmpty) btnEmpty.addEventListener('click', () => addTurnRow(profile, varKey));
      return;
    }

    turns.forEach((t, tIdx) => {
      if (!isCombined && (!t.runs || t.runs.length === 0)) {
        t.runs = [{ runId: 1, atk: t.avgAtk ?? 6, undef: t.avgUndef ?? 1, token: t.avgToken ?? 0, counter: t.avgCounter ?? 1, def: t.avgDef ?? 1.5, heal: t.avgHeal ?? 0 }];
      }

      if (!isCombined) recalculateTurn(t);

      const turnNum = t.turn || tIdx + 1;
      const isExpanded = expandedTurns.has(turnNum);
      const card = document.createElement('div');
      card.className = `turn-card ${isExpanded ? 'runs-expanded' : ''}`;

      const header = document.createElement('div');
      header.className = 'turn-header';
      header.innerHTML = `
        <div class="turn-title-group">
          <span class="turn-badge-label">Tour ${turnNum}</span>
          <span class="runs-count-pill">${isCombined ? 'Synthèse Styles' : `${t.runs.length} run${t.runs.length > 1 ? 's' : ''}`}</span>
        </div>

        <div class="turn-actions-group">
          ${!isCombined ? `
            <button class="btn-ghost btn-toggle-expand" style="padding: 4px 10px; font-size: 11px;">
              ${isExpanded ? '▲ Masquer les runs' : `📋 Déplier les runs (${t.runs.length}) ▼`}
            </button>
            <button class="btn-ghost btn-add-run-inline" style="padding: 4px 10px; font-size: 11px;">+ Run</button>
            <button class="btn-del-turn btn-del-turn-card" title="Supprimer ce tour">×</button>
          ` : '<span style="font-size: 11px; color: var(--text-muted); font-weight: bold;">(Moyenne Calculée)</span>'}
        </div>
      `;

      // Top Average Banner (La moyenne du tour en haut, toujours visible par défaut)
      const avgBanner = document.createElement('div');
      avgBanner.className = 'turn-top-average-bar';
      avgBanner.id = `avgBar_${tIdx}`;
      avgBanner.innerHTML = `
        <div class="average-bar-title">
          <span>📊 MOYENNE DU TOUR ${turnNum} (${isCombined ? 'Moyenne tous styles' : `Sur ${t.runs.length} run${t.runs.length > 1 ? 's' : ''}`}) :</span>
          <span style="color: var(--accent-gold); font-size: 11px;">Dégâts nets projetés : <strong>${((t.avgAtk || 0) + (t.avgUndef || 0) + (t.avgToken || 0)).toFixed(1)} PV</strong></span>
        </div>
        <div class="average-metrics-grid">
          <div class="metric-box atk">
            <span class="metric-lbl">⚔️ Atk (Parable)</span>
            <span class="metric-num" id="avgAtkVal_${tIdx}">${t.avgAtk}</span>
          </div>
          <div class="metric-box undef">
            <span class="metric-lbl">💥 Imparable</span>
            <span class="metric-num" id="avgUndefVal_${tIdx}">${t.avgUndef}</span>
          </div>
          <div class="metric-box token">
            <span class="metric-lbl">💣 Tokens / Effets</span>
            <span class="metric-num" id="avgTokVal_${tIdx}">${t.avgToken}</span>
          </div>
          <div class="metric-box counter">
            <span class="metric-lbl">🔄 Contre-attaque</span>
            <span class="metric-num" id="avgCountVal_${tIdx}">${t.avgCounter}</span>
          </div>
          <div class="metric-box def">
            <span class="metric-lbl">🛡️ Défense</span>
            <span class="metric-num" id="avgDefVal_${tIdx}">${t.avgDef}</span>
          </div>
          <div class="metric-box heal">
            <span class="metric-lbl">💚 Soin</span>
            <span class="metric-num" id="avgHealVal_${tIdx}">${t.avgHeal}</span>
          </div>
        </div>
      `;

      if (!isCombined) {
        header.querySelector('.btn-toggle-expand').addEventListener('click', (e) => {
          e.stopPropagation();
          if (expandedTurns.has(turnNum)) {
            expandedTurns.delete(turnNum);
          } else {
            expandedTurns.add(turnNum);
          }
          renderTurnsCards(profile, varKey);
        });

        header.querySelector('.btn-add-run-inline').addEventListener('click', (e) => {
          e.stopPropagation();
          addRunToTurn(t, profile, varKey);
        });

        header.querySelector('.btn-del-turn-card').addEventListener('click', (e) => {
          e.stopPropagation();
          if (confirm(`Supprimer définitivement le Tour ${t.turn || tIdx + 1} ?`)) {
            turns.splice(tIdx, 1);
            turns.forEach((item, i) => item.turn = i + 1);
            renderTurnsCards(profile, varKey);
            markUnsaved();
          }
        });

        // Detail of Runs Section (replié par défaut)
        const body = document.createElement('div');
        body.className = 'turn-body-content';
        body.style.display = isExpanded ? 'block' : 'none';
        let tableHtml = `
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px;">
            <span style="font-size: 12px; font-weight: 700; color: var(--text-muted);">
              📋 Détail des ${t.runs.length} runs individuels pour le Tour ${t.turn || tIdx + 1} :
            </span>
            <button class="btn-ghost btn-add-run-bottom" style="padding: 3px 8px; font-size: 11px;">+ Ajouter un Run</button>
          </div>
          <div class="turns-table-wrapper">
            <table class="turns-table">
              <thead>
                <tr>
                  <th style="width: 80px;">Run</th>
                  <th style="color: #ff9944;">⚔️ Atk (Parable)</th>
                  <th style="color: #ff4757;">💥 Atk Imp</th>
                  <th style="color: #f59e0b;">💣 Tokens</th>
                  <th style="color: #c084fc;">🔄 Contre</th>
                  <th style="color: #38bdf8;">🛡️ Défense</th>
                  <th style="color: #2ed573;">💚 Soin</th>
                  <th style="text-align: center; width: 40px;">Suppr.</th>
                </tr>
              </thead>
              <tbody>
        `;

        t.runs.forEach((r, rIdx) => {
          tableHtml += `
            <tr>
              <td><span class="run-badge-pill">Run ${r.runId || rIdx + 1}</span></td>
              <td><input type="number" step="0.1" min="0" class="turn-input run-field" data-tidx="${tIdx}" data-ridx="${rIdx}" data-field="atk" value="${r.atk ?? 0}" /></td>
              <td><input type="number" step="0.1" min="0" class="turn-input run-field" data-tidx="${tIdx}" data-ridx="${rIdx}" data-field="undef" value="${r.undef ?? 0}" /></td>
              <td><input type="number" step="0.1" min="0" class="turn-input run-field" data-tidx="${tIdx}" data-ridx="${rIdx}" data-field="token" value="${r.token ?? 0}" /></td>
              <td><input type="number" step="0.1" min="0" class="turn-input run-field" data-tidx="${tIdx}" data-ridx="${rIdx}" data-field="counter" value="${r.counter ?? 0}" /></td>
              <td><input type="number" step="0.1" min="0" class="turn-input run-field" data-tidx="${tIdx}" data-ridx="${rIdx}" data-field="def" value="${r.def ?? 0}" /></td>
              <td><input type="number" step="0.1" min="0" class="turn-input run-field" data-tidx="${tIdx}" data-ridx="${rIdx}" data-field="heal" value="${r.heal ?? 0}" /></td>
              <td style="text-align: center;">
                <button class="btn-del-turn btn-del-run" data-tidx="${tIdx}" data-ridx="${rIdx}" title="Supprimer ce run">×</button>
              </td>
            </tr>
          `;
        });

        tableHtml += '</tbody></table></div>';
        body.innerHTML = tableHtml;

        body.querySelector('.btn-add-run-bottom').addEventListener('click', () => {
          addRunToTurn(t, profile, varKey);
        });

        body.querySelectorAll('.run-field').forEach(input => {
          input.addEventListener('input', () => {
            const rIdx = parseInt(input.dataset.ridx, 10);
            const field = input.dataset.field;
            t.runs[rIdx][field] = parseFloat(input.value) || 0;
            recalculateTurn(t);

            // Update top average banner values in real time!
            const elAtk = document.getElementById(`avgAtkVal_${tIdx}`);
            const elUndef = document.getElementById(`avgUndefVal_${tIdx}`);
            const elTok = document.getElementById(`avgTokVal_${tIdx}`);
            const elCount = document.getElementById(`avgCountVal_${tIdx}`);
            const elDef = document.getElementById(`avgDefVal_${tIdx}`);
            const elHeal = document.getElementById(`avgHealVal_${tIdx}`);
            if (elAtk) elAtk.textContent = t.avgAtk;
            if (elUndef) elUndef.textContent = t.avgUndef;
            if (elTok) elTok.textContent = t.avgToken;
            if (elCount) elCount.textContent = t.avgCounter;
            if (elDef) elDef.textContent = t.avgDef;
            if (elHeal) elHeal.textContent = t.avgHeal;

            markUnsaved();
          });
        });

        body.querySelectorAll('.btn-del-run').forEach(btn => {
          btn.addEventListener('click', () => {
            const rIdx = parseInt(btn.dataset.ridx, 10);
            if (t.runs.length <= 1) {
              alert('Un tour doit contenir au moins 1 run.');
              return;
            }
            t.runs.splice(rIdx, 1);
            t.runs.forEach((r, idx) => r.runId = idx + 1);
            recalculateTurn(t);
            renderTurnsCards(profile, varKey);
            markUnsaved();
          });
        });

        card.appendChild(header);
        card.appendChild(avgBanner);
        card.appendChild(body);
      } else {
        card.appendChild(header);
        card.appendChild(avgBanner);
      }

      edTurnsContainer.appendChild(card);
    });
  }

  function recalculateTurn(turnObj) {
    if (!turnObj.runs || turnObj.runs.length === 0) return;
    const len = turnObj.runs.length;
    const avg = key => +(turnObj.runs.reduce((s, r) => s + (r[key] || 0), 0) / len).toFixed(1);

    turnObj.avgAtk = avg('atk');
    turnObj.avgUndef = avg('undef');
    turnObj.avgToken = avg('token');
    turnObj.avgCounter = avg('counter');
    turnObj.avgDef = avg('def');
    turnObj.avgHeal = avg('heal');
  }

  function addRunToTurn(turnObj, profile, varKey) {
    const nextRunId = (turnObj.runs.length || 0) + 1;
    const lastRun = turnObj.runs.length > 0 ? turnObj.runs[turnObj.runs.length - 1] : { atk: 6, undef: 0, token: 0, counter: 1, def: 1, heal: 0 };
    turnObj.runs.push({ runId: nextRunId, atk: lastRun.atk, undef: lastRun.undef, token: lastRun.token, counter: lastRun.counter, def: lastRun.def, heal: lastRun.heal });
    recalculateTurn(turnObj);
    expandedTurns.add(turnObj.turn);
    renderTurnsCards(profile, varKey);
    markUnsaved();
  }

  function addTurnRow(profile, varKey) {
    if (varKey === '__combined__') {
      alert('Impossible d\'ajouter un tour directement à la moyenne combinée. Ajoutez un tour dans l\'un des styles.');
      return;
    }
    const variant = profile.variants[varKey];
    variant.turns = variant.turns || [];
    const nextTurnNum = variant.turns.length + 1;
    const lastTurn = variant.turns.length > 0 ? variant.turns[variant.turns.length - 1] : null;
    const templateAtk = lastTurn ? lastTurn.avgAtk : 6;
    const templateUndef = lastTurn ? lastTurn.avgUndef : 1;
    const templateDef = lastTurn ? lastTurn.avgDef : 2;

    variant.turns.push({
      turn: nextTurnNum,
      avgAtk: templateAtk, avgUndef: templateUndef, avgToken: 0, avgCounter: 1, avgDef: templateDef, avgHeal: 0,
      runs: [{ runId: 1, atk: templateAtk, undef: templateUndef, token: 0, counter: 1, def: templateDef, heal: 0 }]
    });

    expandedTurns.add(nextTurnNum);
    renderTurnsCards(profile, varKey);
    markUnsaved();
  }

  btnAddTurnRowBtn.addEventListener('click', () => {
    if (!selectedEditorHero) return;
    const profile = getHeroProfile(selectedEditorHero.id);
    const varKey = profile.selectedVariant || Object.keys(profile.variants)[0];
    addTurnRow(profile, varKey);
  });

  btnCombinedAverageBtn.addEventListener('click', () => {
    if (!selectedEditorHero) return;
    const profile = getHeroProfile(selectedEditorHero.id);
    profile.selectedVariant = '__combined__';
    renderEditor();
  });

  function markUnsaved() {
    saveStatusIndicator.textContent = 'Modifications non enregistrées (cliquer sur Sauvegarder)';
    saveStatusIndicator.style.color = '#f59e0b';
  }

  editorSearch.addEventListener('input', renderEditor);

  edActiveToggle.addEventListener('change', () => {
    if (!selectedEditorHero) return;
    const heroId = selectedEditorHero.id;
    if (!statsData[heroId]) statsData[heroId] = getHeroProfile(heroId);
    statsData[heroId].active = edActiveToggle.checked;
    markUnsaved();
    renderEditor();
  });

  btnAddVariantBtn.addEventListener('click', () => {
    if (!selectedEditorHero) return;
    const label = prompt('Nom du nouveau style (ex: Agro, Survie, v3...) :');
    if (label && label.trim()) {
      const key = label.trim().toLowerCase().replace(/[^a-z0-9]/g, '_');
      const profile = getHeroProfile(selectedEditorHero.id);
      profile.variants = profile.variants || {};
      profile.variants[key] = {
        label: label.trim(),
        turns: [
          { turn: 1, avgAtk: 6, avgUndef: 1, avgToken: 0, avgCounter: 1, avgDef: 2, avgHeal: 0, runs: [{ runId: 1, atk: 6, undef: 1, token: 0, counter: 1, def: 2, heal: 0 }] },
          { turn: 2, avgAtk: 6, avgUndef: 2, avgToken: 1, avgCounter: 1, avgDef: 2, avgHeal: 0, runs: [{ runId: 1, atk: 6, undef: 2, token: 1, counter: 1, def: 2, heal: 0 }] }
        ]
      };
      profile.selectedVariant = key;
      statsData[selectedEditorHero.id] = profile;
      renderEditor();
      markUnsaved();
    }
  });

  btnSaveStatsBtn.addEventListener('click', async () => {
    saveStatusIndicator.textContent = 'Enregistrement en cours...';
    saveStatusIndicator.style.color = '#fff';

    try {
      const res = await fetch('/api/save-simulation-stats', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(statsData)
      });
      if (res.ok) {
        saveStatusIndicator.textContent = '✅ Profils sauvegardés en local avec succès !';
        saveStatusIndicator.style.color = '#2ed573';
        log('💾 Profils enregistrés en local (JSON).', 'info');
      } else {
        throw new Error('Erreur HTTP ' + res.status);
      }
    } catch (e) {
      console.error(e);
      const blob = new Blob([JSON.stringify(statsData, null, 2)], { type: 'application/json' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = 'hero_simulation_stats.json';
      a.click();
      saveStatusIndicator.textContent = '⚠️ Enregistrement via téléchargement du fichier JSON';
      saveStatusIndicator.style.color = '#f59e0b';
    }
  });

  btnReloadFileBtn.addEventListener('click', async () => {
    try {
      const res = await fetch('./hero_simulation_stats.json?t=' + Date.now());
      if (res.ok) {
        statsData = await res.json();
        saveStatusIndicator.textContent = '✅ Données rechargées depuis le fichier local.';
        saveStatusIndicator.style.color = '#2ed573';
        renderEditor();
        updateSimulatorDisplay();
      }
    } catch (e) {
      alert('Impossible de recharger le fichier : ' + e.message);
    }
  });

  // =========================================================================
  // TAB 3 : STATISTIQUES & PLUS-VALUE ENGINE
  // =========================================================================
  let statsStyleA = null;
  let statsStyleB = null;

  statsModeBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      statsModeBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      statsMode = btn.dataset.mode;
      chart1Title.textContent = statsMode === 'compare' ? '⚔️ Comparatif Dégâts Cumulés : Héros A vs Héros B' : '📊 Courbes des Composantes par Tour (Atk, Imp, Def, Tokens, Soin)';
      renderStatsTab();
    });
  });

  function populateStatsSelectors() {
    const list = DTS_HEROES.filter(h => statsData[h.id]?.active);
    const pool = list.length > 0 ? list : DTS_HEROES;

    // Only populate hero options if empty
    if (statsHero1Select.options.length === 0) {
      pool.forEach(hero => {
        const opt1 = document.createElement('option');
        opt1.value = hero.id;
        opt1.textContent = hero.name;
        opt1.selected = statsHero1 && statsHero1.id === hero.id;
        statsHero1Select.appendChild(opt1);

        const opt2 = document.createElement('option');
        opt2.value = hero.id;
        opt2.textContent = hero.name;
        opt2.selected = statsHero2 && statsHero2.id === hero.id;
        statsHero2Select.appendChild(opt2);
      });
    }

    populateStatsVariantsA();
    populateStatsVariantsB();
  }

  function populateStatsVariantsA() {
    statsVariantSelectA.innerHTML = '';
    if (!statsHero1) return;
    const profile = getHeroProfile(statsHero1.id);
    const variants = profile.variants || {};

    Object.entries(variants).forEach(([k, v]) => {
      const opt = document.createElement('option');
      opt.value = k;
      opt.textContent = v.label || k;
      if (statsStyleA === k || (!statsStyleA && k === profile.selectedVariant)) opt.selected = true;
      statsVariantSelectA.appendChild(opt);
    });

    const optComb = document.createElement('option');
    optComb.value = '__combined__';
    optComb.textContent = '🔀 Moyenne Combinée';
    if (statsStyleA === '__combined__') optComb.selected = true;
    statsVariantSelectA.appendChild(optComb);
  }

  function populateStatsVariantsB() {
    statsVariantSelectB.innerHTML = '';
    if (!statsHero2) return;
    const profile = getHeroProfile(statsHero2.id);
    const variants = profile.variants || {};

    Object.entries(variants).forEach(([k, v]) => {
      const opt = document.createElement('option');
      opt.value = k;
      opt.textContent = v.label || k;
      if (statsStyleB === k || (!statsStyleB && k === profile.selectedVariant)) opt.selected = true;
      statsVariantSelectB.appendChild(opt);
    });

    const optComb = document.createElement('option');
    optComb.value = '__combined__';
    optComb.textContent = '🔀 Moyenne Combinée';
    if (statsStyleB === '__combined__') optComb.selected = true;
    statsVariantSelectB.appendChild(optComb);
  }

  statsHero1Select.addEventListener('change', () => {
    statsHero1 = DTS_HEROES.find(h => h.id === statsHero1Select.value);
    statsStyleA = null;
    populateStatsVariantsA();
    renderStatsTab();
  });

  statsHero2Select.addEventListener('change', () => {
    statsHero2 = DTS_HEROES.find(h => h.id === statsHero2Select.value);
    statsStyleB = null;
    populateStatsVariantsB();
    renderStatsTab();
  });

  statsVariantSelectA.addEventListener('change', () => {
    statsStyleA = statsVariantSelectA.value;
    renderStatsTab();
  });

  statsVariantSelectB.addEventListener('change', () => {
    statsStyleB = statsVariantSelectB.value;
    renderStatsTab();
  });

  function renderStatsTab() {
    if (!statsHero1) statsHero1 = hero1;
    if (!statsHero2) statsHero2 = hero2;

    populateStatsSelectors();

    // Show/hide Hero B based on mode
    if (statsMode === 'compare') {
      statsColB.style.display = 'flex';
      statsVsDivider.style.display = 'flex';
    } else {
      statsColB.style.display = 'none';
      statsVsDivider.style.display = 'none';
    }

    const profileA = getHeroProfile(statsHero1.id);
    const varKeyA = statsVariantSelectA.value || statsStyleA || profileA.selectedVariant || Object.keys(profileA.variants || {})[0];
    const variantA = varKeyA === '__combined__' ? getCombinedVariant(profileA) : (profileA.variants[varKeyA] || Object.values(profileA.variants)[0]);

    const profileB = getHeroProfile(statsHero2.id);
    const varKeyB = statsVariantSelectB.value || statsStyleB || profileB.selectedVariant || Object.keys(profileB.variants || {})[0];
    const variantB = varKeyB === '__combined__' ? getCombinedVariant(profileB) : (profileB.variants[varKeyB] || Object.values(profileB.variants)[0]);

    // Render Visual HeroCards
    renderCardContent(statsCardA, statsHero1, variantA.label || 'Standard');
    if (statsMode === 'compare') {
      renderCardContent(statsCardB, statsHero2, variantB.label || 'Standard');
    }

    const turnsA = variantA.turns || [];
    const turnsB = variantB.turns || [];

    // Compute KPIs
    let totalDmgA = 0, totalDefA = 0, totalHealA = 0, maxTurnDmgA = 0, peakTurnA = 1;
    turnsA.forEach(t => {
      const dmg = (t.avgAtk || 0) + (t.avgUndef || 0) + (t.avgToken || 0);
      totalDmgA += dmg;
      totalDefA += (t.avgDef || 0);
      totalHealA += (t.avgHeal || 0);
      if (dmg > maxTurnDmgA) { maxTurnDmgA = dmg; peakTurnA = t.turn; }
    });

    let totalDmgB = 0, totalDefB = 0, totalHealB = 0;
    turnsB.forEach(t => {
      totalDmgB += (t.avgAtk || 0) + (t.avgUndef || 0) + (t.avgToken || 0);
      totalDefB += (t.avgDef || 0);
      totalHealB += (t.avgHeal || 0);
    });

    const totalPlusValueA = +(totalDmgA - (totalDefA + totalHealA)).toFixed(1);
    const totalPlusValueB = +(totalDmgB - (totalDefB + totalHealB)).toFixed(1);
    const avgDmgPerTurnA = turnsA.length > 0 ? +(totalDmgA / turnsA.length).toFixed(1) : 0;
    const avgDefPerTurnA = turnsA.length > 0 ? +(totalDefA / turnsA.length).toFixed(1) : 0;

    if (statsMode === 'single') {
      statsKpisGrid.innerHTML = `
        <div class="stats-kpi-card">
          <span class="kpi-title">Dégâts Moyens / Tour (${statsHero1.name})</span>
          <span class="kpi-value" style="color: #ff9944;">${avgDmgPerTurnA} PV</span>
          <span class="kpi-subtext">Atk + Imp + Tokens</span>
        </div>
        <div class="stats-kpi-card">
          <span class="kpi-title">Défense Moyenne / Tour</span>
          <span class="kpi-value" style="color: #38bdf8;">${avgDefPerTurnA} PV</span>
          <span class="kpi-subtext">Prévention de dégâts</span>
        </div>
        <div class="stats-kpi-card">
          <span class="kpi-title">Plus-Value Totale Nette</span>
          <span class="kpi-value" style="color: ${totalPlusValueA >= 0 ? '#2ed573' : '#a855f7'};">${totalPlusValueA > 0 ? '+' : ''}${totalPlusValueA} PV</span>
          <span class="kpi-subtext">Dégâts - (Def + Soin)</span>
        </div>
        <div class="stats-kpi-card">
          <span class="kpi-title">Tour Pic d'Explosion</span>
          <span class="kpi-value" style="color: var(--accent-gold);">Tour ${peakTurnA}</span>
          <span class="kpi-subtext">${maxTurnDmgA.toFixed(1)} dégâts projetés</span>
        </div>
      `;
    } else {
      statsKpisGrid.innerHTML = `
        <div class="stats-kpi-card">
          <span class="kpi-title">Dégâts Cumulés A vs B</span>
          <span class="kpi-value" style="font-size: 20px;"><strong style="color: ${statsHero1.color};">${totalDmgA.toFixed(1)}</strong> vs <strong style="color: ${statsHero2.color};">${totalDmgB.toFixed(1)}</strong></span>
          <span class="kpi-subtext">${statsHero1.name} vs ${statsHero2.name}</span>
        </div>
        <div class="stats-kpi-card">
          <span class="kpi-title">Défense Cumulée A vs B</span>
          <span class="kpi-value" style="font-size: 20px;"><strong style="color: #38bdf8;">${totalDefA.toFixed(1)}</strong> vs <strong style="color: #38bdf8;">${totalDefB.toFixed(1)}</strong></span>
          <span class="kpi-subtext">Absorption totale bloquée</span>
        </div>
        <div class="stats-kpi-card">
          <span class="kpi-title">Différentiel Plus-Value</span>
          <span class="kpi-value" style="font-size: 20px;"><strong style="color: ${statsHero1.color};">${totalPlusValueA}</strong> vs <strong style="color: ${statsHero2.color};">${totalPlusValueB}</strong></span>
          <span class="kpi-subtext">Impact net total</span>
        </div>
        <div class="stats-kpi-card">
          <span class="kpi-title">Avantage Statistique</span>
          <span class="kpi-value" style="color: ${totalPlusValueA >= totalPlusValueB ? statsHero1.color : statsHero2.color}; font-size: 18px;">
            ${totalPlusValueA >= totalPlusValueB ? statsHero1.name : statsHero2.name}
          </span>
          <span class="kpi-subtext">+${Math.abs(totalPlusValueA - totalPlusValueB).toFixed(1)} PV de plus-value</span>
        </div>
      `;
    }

    const benchmark = computeRosterBenchmark();

    // Show/hide benchmark card: ONLY visible in 1 Hero mode
    if (chartBenchmarkCard) {
      chartBenchmarkCard.style.display = statsMode === 'single' ? 'block' : 'none';
    }

    // Update filter buttons UI
    updateFilterButtonsUI();

    // Render SVG Charts
    renderComponentsChart(turnsA, turnsB);
    if (statsMode === 'single') {
      renderBenchmarkChart(turnsA, turnsB, benchmark);
    }
    renderPlusValueChart(turnsA, turnsB, benchmark);
  }

  // Component Filter State
  let selectedComponent2H = 'avgAtk';
  const activeComponents = {
    avgAtk: true,
    avgUndef: true,
    avgToken: true,
    avgDef: true,
    avgHeal: true,
    totalDmg: false,
    plusValue: false
  };

  const COMPONENT_LABELS = {
    avgAtk: '⚔️ Atk (Parable)',
    avgUndef: '💥 Imparable',
    avgToken: '💣 Tokens / Effets',
    avgDef: '🛡️ Défense',
    avgHeal: '💚 Soin',
    totalDmg: '💥 Dégâts Totaux',
    plusValue: '⚖️ Plus-Value'
  };

  function updateFilterButtonsUI() {
    if (filterRowLabel) {
      filterRowLabel.textContent = statsMode === 'compare' ? 'Composante comparée (Couleurs Héros) :' : 'Composantes affichées :';
    }

    document.querySelectorAll('.comp-filter-btn').forEach(btn => {
      const comp = btn.dataset.comp;
      if (statsMode === 'compare') {
        btn.classList.toggle('active', comp === selectedComponent2H);
      } else {
        btn.classList.toggle('active', !!activeComponents[comp]);
      }
    });
  }

  document.querySelectorAll('.comp-filter-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const comp = btn.dataset.comp;
      if (statsMode === 'compare') {
        selectedComponent2H = comp;
      } else {
        activeComponents[comp] = !activeComponents[comp];
      }
      renderStatsTab();
    });
  });

  // Compute Meta/Roster Benchmark Average across all active heroes
  function computeRosterBenchmark() {
    const activeHeroes = DTS_HEROES.filter(h => statsData[h.id]?.active);
    const pool = activeHeroes.length > 0 ? activeHeroes : DTS_HEROES;
    const maxTurns = 8;
    const benchmark = [];

    for (let t = 1; t <= maxTurns; t++) {
      let sumAtk = 0, sumUndef = 0, sumToken = 0, sumCounter = 0, sumDef = 0, sumHeal = 0;
      let count = 0;

      pool.forEach(hero => {
        const stats = getHeroTurnStats(hero.id, t);
        sumAtk += stats.avgAtk || 0;
        sumUndef += stats.avgUndef || 0;
        sumToken += stats.avgToken || 0;
        sumCounter += stats.avgCounter || 0;
        sumDef += stats.avgDef || 0;
        sumHeal += stats.avgHeal || 0;
        count++;
      });

      const avg = sum => count > 0 ? +(sum / count).toFixed(1) : 0;
      const bAtk = avg(sumAtk);
      const bUndef = avg(sumUndef);
      const bToken = avg(sumToken);
      const bCounter = avg(sumCounter);
      const bDef = avg(sumDef);
      const bHeal = avg(sumHeal);
      const bDmg = +(bAtk + bUndef + bToken + bCounter).toFixed(1);
      const bProt = +(bDef + bHeal).toFixed(1);
      const bPlusVal = +(bDmg - bProt).toFixed(1);

      benchmark.push({
        turn: t,
        avgAtk: bAtk,
        avgUndef: bUndef,
        avgToken: bToken,
        avgCounter: bCounter,
        avgDef: bDef,
        avgHeal: bHeal,
        totalDmg: bDmg,
        totalProt: bProt,
        plusValue: bPlusVal
      });
    }

    return benchmark;
  }

  // -------------------------------------------------------------------------
  // CHART 1: Components by turn
  // In 1H mode: Multi-component curves (including Plus-Value)
  // In 2H mode: Exactly 1 component at a time, keeping Hero A & Hero B colors clean!
  // -------------------------------------------------------------------------
  function renderComponentsChart(turnsA, turnsB) {
    if (!statsComponentsSvg) return;
    statsComponentsSvg.innerHTML = '';

    const width = statsComponentsSvg.clientWidth || 500;
    const height = statsComponentsSvg.clientHeight || 260;
    const padL = 40, padR = 25, padT = 20, padB = 35;
    const chartW = width - padL - padR;
    const chartH = height - padT - padB;

    const turnsCount = Math.max(turnsA.length, (statsMode === 'compare' ? turnsB.length : 0), 1);
    
    // Support negative values if Plus-Value is active
    const includesPlusValue = (statsMode === 'single' && activeComponents.plusValue) || (statsMode === 'compare' && selectedComponent2H === 'plusValue');
    const minVal = includesPlusValue ? -8 : 0;
    const maxVal = 18;
    const range = maxVal - minVal;

    // Zero line if negative range exists
    if (minVal < 0) {
      const zeroY = padT + chartH - ((0 - minVal) / range) * chartH;
      const zeroLine = document.createElementNS('http://www.w3.org/2000/svg', 'line');
      zeroLine.setAttribute('x1', padL); zeroLine.setAttribute('y1', zeroY);
      zeroLine.setAttribute('x2', width - padR); zeroLine.setAttribute('y2', zeroY);
      zeroLine.setAttribute('stroke', 'rgba(255, 255, 255, 0.25)');
      zeroLine.setAttribute('stroke-width', '1.5');
      statsComponentsSvg.appendChild(zeroLine);
    }

    // Grid lines
    for (let v = minVal; v <= maxVal; v += (includesPlusValue ? 4 : 3)) {
      const y = padT + chartH - ((v - minVal) / range) * chartH;
      const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
      line.setAttribute('x1', padL); line.setAttribute('y1', y);
      line.setAttribute('x2', width - padR); line.setAttribute('y2', y);
      line.setAttribute('stroke', 'rgba(255, 255, 255, 0.08)');
      statsComponentsSvg.appendChild(line);

      const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      text.setAttribute('x', padL - 8); text.setAttribute('y', y + 3);
      text.setAttribute('text-anchor', 'end');
      text.setAttribute('fill', 'rgba(255, 255, 255, 0.4)');
      text.setAttribute('font-size', '10');
      text.textContent = v;
      statsComponentsSvg.appendChild(text);
    }

    const stepX = turnsCount > 1 ? chartW / (turnsCount - 1) : chartW;

    if (statsMode === 'single') {
      // 1 Hero Mode: Multi-component curves (including Plus-Value)
      chart1Title.textContent = `📊 Évolution des Composantes : ${statsHero1.name}`;
      if (chart1Sublabel) chart1Sublabel.textContent = '';

      const allSeries = [
        { key: 'avgAtk', color: '#ff9944', label: 'Atk Parable' },
        { key: 'avgUndef', color: '#ff4757', label: 'Imparable' },
        { key: 'avgToken', color: '#f59e0b', label: 'Tokens' },
        { key: 'avgDef', color: '#38bdf8', label: 'Défense' },
        { key: 'avgHeal', color: '#2ed573', label: 'Soin' },
        { key: 'totalDmg', color: '#eab308', label: 'Dégâts Totaux' },
        { key: 'plusValue', color: '#c084fc', label: '⚖️ Plus-Value' }
      ];

      const series = allSeries.filter(s => activeComponents[s.key]);

      series.forEach(s => {
        let d = '';
        turnsA.forEach((t, i) => {
          let val = 0;
          if (s.key === 'totalDmg') {
            val = (t.avgAtk || 0) + (t.avgUndef || 0) + (t.avgToken || 0);
          } else if (s.key === 'plusValue') {
            const dmg = (t.avgAtk || 0) + (t.avgUndef || 0) + (t.avgToken || 0) + (t.avgCounter || 0);
            const prot = (t.avgDef || 0) + (t.avgHeal || 0);
            val = +(dmg - prot).toFixed(1);
          } else {
            val = (t[s.key] || 0);
          }

          const x = padL + i * stepX;
          const clampedVal = Math.max(minVal, Math.min(maxVal, val));
          const y = padT + chartH - ((clampedVal - minVal) / range) * chartH;
          if (i === 0) d += `M ${x} ${y}`;
          else d += ` L ${x} ${y}`;

          const dot = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
          dot.setAttribute('cx', x); dot.setAttribute('cy', y); dot.setAttribute('r', '4');
          dot.setAttribute('fill', s.color);
          const title = document.createElementNS('http://www.w3.org/2000/svg', 'title');
          title.textContent = `${s.label} (Tour ${t.turn}) : ${val > 0 && s.key === 'plusValue' ? '+' : ''}${val.toFixed(1)}`;
          dot.appendChild(title);
          statsComponentsSvg.appendChild(dot);
        });

        const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
        path.setAttribute('d', d); path.setAttribute('fill', 'none');
        path.setAttribute('stroke', s.color); path.setAttribute('stroke-width', s.key === 'plusValue' ? '3' : '2.5');
        path.setAttribute('stroke-linecap', 'round');
        statsComponentsSvg.appendChild(path);
      });

      statsComponentsLegend.innerHTML = series.map(s => `
        <div class="legend-item"><span class="legend-color-dot" style="background: ${s.color};"></span><span>${s.label}</span></div>
      `).join('');
    } else {
      // 2 Heroes Mode: ONLY 1 COMPONENT AT A TIME to preserve hero colors!
      const compLabel = COMPONENT_LABELS[selectedComponent2H] || selectedComponent2H;
      chart1Title.textContent = `⚔️ Comparatif : ${compLabel}`;
      if (chart1Sublabel) chart1Sublabel.textContent = `${statsHero1.name} (Couleur J1) vs ${statsHero2.name} (Couleur J2)`;

      const getVal = (t) => {
        if (!t) return 0;
        if (selectedComponent2H === 'totalDmg') return (t.avgAtk || 0) + (t.avgUndef || 0) + (t.avgToken || 0);
        if (selectedComponent2H === 'plusValue') {
          const dmg = (t.avgAtk || 0) + (t.avgUndef || 0) + (t.avgToken || 0) + (t.avgCounter || 0);
          const prot = (t.avgDef || 0) + (t.avgHeal || 0);
          return +(dmg - prot).toFixed(1);
        }
        return t[selectedComponent2H] || 0;
      };

      let dA = '', dB = '';
      for (let i = 0; i < turnsCount; i++) {
        const tA = turnsA[i] || turnsA[turnsA.length - 1] || {};
        const tB = turnsB[i] || turnsB[turnsB.length - 1] || {};
        const valA = getVal(tA);
        const valB = getVal(tB);

        const x = padL + i * stepX;
        const clampedA = Math.max(minVal, Math.min(maxVal, valA));
        const clampedB = Math.max(minVal, Math.min(maxVal, valB));
        const yA = padT + chartH - ((clampedA - minVal) / range) * chartH;
        const yB = padT + chartH - ((clampedB - minVal) / range) * chartH;

        if (i === 0) { dA += `M ${x} ${yA}`; dB += `M ${x} ${yB}`; }
        else { dA += ` L ${x} ${yA}`; dB += ` L ${x} ${yB}`; }

        // Dot Hero A
        const dotA = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        dotA.setAttribute('cx', x); dotA.setAttribute('cy', yA); dotA.setAttribute('r', '4.5');
        dotA.setAttribute('fill', statsHero1.color);
        const titleA = document.createElementNS('http://www.w3.org/2000/svg', 'title');
        titleA.textContent = `${statsHero1.name} (T${i + 1}) : ${valA > 0 && selectedComponent2H === 'plusValue' ? '+' : ''}${valA.toFixed(1)}`;
        dotA.appendChild(titleA);
        statsComponentsSvg.appendChild(dotA);

        // Dot Hero B
        const dotB = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        dotB.setAttribute('cx', x); dotB.setAttribute('cy', yB); dotB.setAttribute('r', '4.5');
        dotB.setAttribute('fill', statsHero2.color);
        const titleB = document.createElementNS('http://www.w3.org/2000/svg', 'title');
        titleB.textContent = `${statsHero2.name} (T${i + 1}) : ${valB > 0 && selectedComponent2H === 'plusValue' ? '+' : ''}${valB.toFixed(1)}`;
        dotB.appendChild(titleB);
        statsComponentsSvg.appendChild(dotB);
      }

      // Path Hero A
      const pathA = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      pathA.setAttribute('d', dA); pathA.setAttribute('fill', 'none');
      pathA.setAttribute('stroke', statsHero1.color || '#ff9944'); pathA.setAttribute('stroke-width', '3');
      pathA.setAttribute('stroke-linecap', 'round');
      statsComponentsSvg.appendChild(pathA);

      // Path Hero B
      const pathB = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      pathB.setAttribute('d', dB); pathB.setAttribute('fill', 'none');
      pathB.setAttribute('stroke', statsHero2.color || '#38bdf8'); pathB.setAttribute('stroke-width', '3');
      pathB.setAttribute('stroke-linecap', 'round');
      statsComponentsSvg.appendChild(pathB);

      statsComponentsLegend.innerHTML = `
        <div class="legend-item"><span class="legend-color-dot" style="background: ${statsHero1.color};"></span><span>${statsHero1.name}</span></div>
        <div class="legend-item"><span class="legend-color-dot" style="background: ${statsHero2.color};"></span><span>${statsHero2.name}</span></div>
      `;
    }

    // X Axis Labels
    for (let i = 0; i < turnsCount; i++) {
      const x = padL + i * stepX;
      const xText = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      xText.setAttribute('x', x); xText.setAttribute('y', height - 10);
      xText.setAttribute('text-anchor', 'middle');
      xText.setAttribute('fill', 'rgba(255, 255, 255, 0.6)');
      xText.setAttribute('font-size', '10'); xText.setAttribute('font-weight', 'bold');
      xText.textContent = `T${i + 1}`;
      statsComponentsSvg.appendChild(xText);
    }
  }

  // -------------------------------------------------------------------------
  // CHART 2: Benchmark Comparison vs Active Roster Average (1 Hero Mode only)
  // -------------------------------------------------------------------------
  function renderBenchmarkChart(turnsA, turnsB, benchmark) {
    if (!statsBenchmarkSvg) return;
    statsBenchmarkSvg.innerHTML = '';

    const width = statsBenchmarkSvg.clientWidth || 500;
    const height = statsBenchmarkSvg.clientHeight || 260;
    const padL = 40, padR = 25, padT = 20, padB = 35;
    const chartW = width - padL - padR;
    const chartH = height - padT - padB;

    const count = Math.min(8, Math.max(turnsA.length, 1));
    const maxVal = 20;

    // Grid lines
    for (let v = 0; v <= maxVal; v += 5) {
      const y = padT + chartH - (v / maxVal) * chartH;
      const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
      line.setAttribute('x1', padL); line.setAttribute('y1', y);
      line.setAttribute('x2', width - padR); line.setAttribute('y2', y);
      line.setAttribute('stroke', 'rgba(255, 255, 255, 0.08)');
      statsBenchmarkSvg.appendChild(line);

      const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      text.setAttribute('x', padL - 8); text.setAttribute('y', y + 3);
      text.setAttribute('text-anchor', 'end');
      text.setAttribute('fill', 'rgba(255, 255, 255, 0.4)');
      text.setAttribute('font-size', '10');
      text.textContent = v;
      statsBenchmarkSvg.appendChild(text);
    }

    const stepX = count > 1 ? chartW / (count - 1) : chartW;

    let dHeroAtk = '', dHeroDef = '', dBenchAtk = '', dBenchDef = '';

    for (let i = 0; i < count; i++) {
      const tA = turnsA[i] || turnsA[turnsA.length - 1] || {};
      const b = benchmark[i] || {};
      const x = padL + i * stepX;

      const heroAtkDmg = (tA.avgAtk || 0) + (tA.avgUndef || 0) + (tA.avgToken || 0);
      const heroDefProt = (tA.avgDef || 0) + (tA.avgHeal || 0);
      const benchAtkDmg = (b.avgAtk || 0) + (b.avgUndef || 0) + (b.avgToken || 0);
      const benchDefProt = (b.avgDef || 0) + (b.avgHeal || 0);

      const yHAtk = padT + chartH - (Math.min(maxVal, heroAtkDmg) / maxVal) * chartH;
      const yHDef = padT + chartH - (Math.min(maxVal, heroDefProt) / maxVal) * chartH;
      const yBAtk = padT + chartH - (Math.min(maxVal, benchAtkDmg) / maxVal) * chartH;
      const yBDef = padT + chartH - (Math.min(maxVal, benchDefProt) / maxVal) * chartH;

      if (i === 0) {
        dHeroAtk += `M ${x} ${yHAtk}`;
        dHeroDef += `M ${x} ${yHDef}`;
        dBenchAtk += `M ${x} ${yBAtk}`;
        dBenchDef += `M ${x} ${yBDef}`;
      } else {
        dHeroAtk += ` L ${x} ${yHAtk}`;
        dHeroDef += ` L ${x} ${yHDef}`;
        dBenchAtk += ` L ${x} ${yBAtk}`;
        dBenchDef += ` L ${x} ${yBDef}`;
      }

      // Dots
      const dot = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      dot.setAttribute('cx', x); dot.setAttribute('cy', yHAtk); dot.setAttribute('r', '3.5');
      dot.setAttribute('fill', statsHero1.color);
      statsBenchmarkSvg.appendChild(dot);

      const dotB = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      dotB.setAttribute('cx', x); dotB.setAttribute('cy', yBAtk); dotB.setAttribute('r', '3');
      dotB.setAttribute('fill', '#ffe22d');
      statsBenchmarkSvg.appendChild(dotB);

      const xText = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      xText.setAttribute('x', x); xText.setAttribute('y', height - 10);
      xText.setAttribute('text-anchor', 'middle');
      xText.setAttribute('fill', 'rgba(255, 255, 255, 0.6)');
      xText.setAttribute('font-size', '10');
      xText.textContent = `T${i + 1}`;
      statsBenchmarkSvg.appendChild(xText);
    }

    // Hero Attack line
    const pHAtk = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    pHAtk.setAttribute('d', dHeroAtk); pHAtk.setAttribute('fill', 'none');
    pHAtk.setAttribute('stroke', statsHero1.color || '#ff9944'); pHAtk.setAttribute('stroke-width', '2.5');
    statsBenchmarkSvg.appendChild(pHAtk);

    // Hero Defense line
    const pHDef = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    pHDef.setAttribute('d', dHeroDef); pHDef.setAttribute('fill', 'none');
    pHDef.setAttribute('stroke', '#38bdf8'); pHDef.setAttribute('stroke-width', '2');
    statsBenchmarkSvg.appendChild(pHDef);

    // Benchmark Attack line (Dashed Gold)
    const pBAtk = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    pBAtk.setAttribute('d', dBenchAtk); pBAtk.setAttribute('fill', 'none');
    pBAtk.setAttribute('stroke', '#ffe22d'); pBAtk.setAttribute('stroke-width', '2');
    pBAtk.setAttribute('stroke-dasharray', '5 5');
    statsBenchmarkSvg.appendChild(pBAtk);

    // Benchmark Defense line (Dashed Slate)
    const pBDef = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    pBDef.setAttribute('d', dBenchDef); pBDef.setAttribute('fill', 'none');
    pBDef.setAttribute('stroke', '#94a3b8'); pBDef.setAttribute('stroke-width', '2');
    pBDef.setAttribute('stroke-dasharray', '3 3');
    statsBenchmarkSvg.appendChild(pBDef);

    statsBenchmarkLegend.innerHTML = `
      <div class="legend-item"><span class="legend-color-dot" style="background: ${statsHero1.color};"></span><span>${statsHero1.name} (Attaque Totale)</span></div>
      <div class="legend-item"><span class="legend-color-dot" style="background: #38bdf8;"></span><span>${statsHero1.name} (Défense + Soin)</span></div>
      <div class="legend-item"><span class="legend-color-dot" style="background: #ffe22d;"></span><span>Moyenne Roster (Attaque)</span></div>
      <div class="legend-item"><span class="legend-color-dot" style="background: #94a3b8;"></span><span>Moyenne Roster (Défense)</span></div>
    `;
  }

  // -------------------------------------------------------------------------
  // CHART 3: Line Chart of Plus-Value & Line Chart of Delta
  // -------------------------------------------------------------------------
  function renderPlusValueChart(turnsA, turnsB, benchmark) {
    if (!statsPlusValueSvg) return;
    statsPlusValueSvg.innerHTML = '';

    const width = statsPlusValueSvg.clientWidth || 500;
    const height = statsPlusValueSvg.clientHeight || 260;
    const padL = 40, padR = 25, padT = 20, padB = 35;
    const chartW = width - padL - padR;
    const chartH = height - padT - padB;

    const count = Math.min(8, Math.max(turnsA.length, (statsMode === 'compare' ? turnsB.length : 0), 1));
    if (count === 0) return;

    // Range for Plus-Value curves: -10 to +18
    const minVal = -10, maxVal = 18;
    const range = maxVal - minVal;
    const zeroY = padT + chartH - ((0 - minVal) / range) * chartH;

    // Horizontal Zero Baseline
    const zeroLine = document.createElementNS('http://www.w3.org/2000/svg', 'line');
    zeroLine.setAttribute('x1', padL); zeroLine.setAttribute('y1', zeroY);
    zeroLine.setAttribute('x2', width - padR); zeroLine.setAttribute('y2', zeroY);
    zeroLine.setAttribute('stroke', 'rgba(255, 255, 255, 0.2)');
    zeroLine.setAttribute('stroke-width', '1.5');
    statsPlusValueSvg.appendChild(zeroLine);

    // Grid lines
    for (let v = -8; v <= maxVal; v += 4) {
      if (v === 0) continue;
      const y = padT + chartH - ((v - minVal) / range) * chartH;
      const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
      line.setAttribute('x1', padL); line.setAttribute('y1', y);
      line.setAttribute('x2', width - padR); line.setAttribute('y2', y);
      line.setAttribute('stroke', 'rgba(255, 255, 255, 0.05)');
      statsPlusValueSvg.appendChild(line);

      const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      text.setAttribute('x', padL - 8); text.setAttribute('y', y + 3);
      text.setAttribute('text-anchor', 'end');
      text.setAttribute('fill', 'rgba(255, 255, 255, 0.4)');
      text.setAttribute('font-size', '10');
      text.textContent = `${v > 0 ? '+' : ''}${v}`;
      statsPlusValueSvg.appendChild(text);
    }

    const stepX = count > 1 ? chartW / (count - 1) : chartW;

    let dPvA = '', dPvB = '', dDelta = '', dBench = '';

    for (let i = 0; i < count; i++) {
      const tA = turnsA[i] || turnsA[turnsA.length - 1] || {};
      const tB = turnsB[i] || turnsB[turnsB.length - 1] || {};
      const b = benchmark[i] || {};
      const x = padL + i * stepX;

      // Formula: Tous les dégâts (dont ripostes) - (Défense + Soin)
      const dmgA = (tA.avgAtk || 0) + (tA.avgUndef || 0) + (tA.avgToken || 0) + (tA.avgCounter || 0);
      const protA = (tA.avgDef || 0) + (tA.avgHeal || 0);
      const pvA = +(dmgA - protA).toFixed(1);

      const dmgB = (tB.avgAtk || 0) + (tB.avgUndef || 0) + (tB.avgToken || 0) + (tB.avgCounter || 0);
      const protB = (tB.avgDef || 0) + (tB.avgHeal || 0);
      const pvB = +(dmgB - protB).toFixed(1);

      const bPv = b.plusValue || 0;
      const deltaVal = statsMode === 'compare' ? +(pvA - pvB).toFixed(1) : +(pvA - bPv).toFixed(1);

      const yA = padT + chartH - ((Math.min(maxVal, Math.max(minVal, pvA)) - minVal) / range) * chartH;
      const yB = padT + chartH - ((Math.min(maxVal, Math.max(minVal, pvB)) - minVal) / range) * chartH;
      const yDelta = padT + chartH - ((Math.min(maxVal, Math.max(minVal, deltaVal)) - minVal) / range) * chartH;
      const yBench = padT + chartH - ((Math.min(maxVal, Math.max(minVal, bPv)) - minVal) / range) * chartH;

      if (i === 0) {
        dPvA += `M ${x} ${yA}`;
        dPvB += `M ${x} ${yB}`;
        dDelta += `M ${x} ${yDelta}`;
        dBench += `M ${x} ${yBench}`;
      } else {
        dPvA += ` L ${x} ${yA}`;
        dPvB += ` L ${x} ${yB}`;
        dDelta += ` L ${x} ${yDelta}`;
        dBench += ` L ${x} ${yBench}`;
      }

      // Marker Hero A
      const dotA = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      dotA.setAttribute('cx', x); dotA.setAttribute('cy', yA); dotA.setAttribute('r', '4');
      dotA.setAttribute('fill', statsHero1.color);
      const titleA = document.createElementNS('http://www.w3.org/2000/svg', 'title');
      titleA.textContent = `${statsHero1.name} Plus-Value (T${i + 1}) : ${pvA > 0 ? '+' : ''}${pvA} PV`;
      dotA.appendChild(titleA);
      statsPlusValueSvg.appendChild(dotA);

      if (statsMode === 'compare') {
        // Marker Hero B
        const dotB = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        dotB.setAttribute('cx', x); dotB.setAttribute('cy', yB); dotB.setAttribute('r', '4');
        dotB.setAttribute('fill', statsHero2.color);
        const titleB = document.createElementNS('http://www.w3.org/2000/svg', 'title');
        titleB.textContent = `${statsHero2.name} Plus-Value (T${i + 1}) : ${pvB > 0 ? '+' : ''}${pvB} PV`;
        dotB.appendChild(titleB);
        statsPlusValueSvg.appendChild(dotB);
      } else {
        // Marker Benchmark
        const dotB = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
        dotB.setAttribute('cx', x); dotB.setAttribute('cy', yBench); dotB.setAttribute('r', '3');
        dotB.setAttribute('fill', '#94a3b8');
        const titleB = document.createElementNS('http://www.w3.org/2000/svg', 'title');
        titleB.textContent = `Moyenne Roster Plus-Value (T${i + 1}) : ${bPv > 0 ? '+' : ''}${bPv} PV`;
        dotB.appendChild(titleB);
        statsPlusValueSvg.appendChild(dotB);
      }

      // Marker Delta (Gold with ring)
      const dotDelta = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
      dotDelta.setAttribute('cx', x); dotDelta.setAttribute('cy', yDelta); dotDelta.setAttribute('r', '4.5');
      dotDelta.setAttribute('fill', '#ffe22d');
      dotDelta.setAttribute('stroke', '#000');
      dotDelta.setAttribute('stroke-width', '1.5');
      const titleDelta = document.createElementNS('http://www.w3.org/2000/svg', 'title');
      titleDelta.textContent = `Delta ${statsMode === 'compare' ? '(A - B)' : '(vs Roster)'} (T${i + 1}) : ${deltaVal > 0 ? '+' : ''}${deltaVal} PV`;
      dotDelta.appendChild(titleDelta);
      statsPlusValueSvg.appendChild(dotDelta);

      // X Label
      const xText = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      xText.setAttribute('x', x); xText.setAttribute('y', height - 10);
      xText.setAttribute('text-anchor', 'middle');
      xText.setAttribute('fill', 'rgba(255, 255, 255, 0.5)');
      xText.setAttribute('font-size', '10'); xText.setAttribute('font-weight', 'bold');
      xText.textContent = `T${i + 1}`;
      statsPlusValueSvg.appendChild(xText);
    }

    // Path Hero A
    const pathA = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    pathA.setAttribute('d', dPvA); pathA.setAttribute('fill', 'none');
    pathA.setAttribute('stroke', statsHero1.color || '#ff9944'); pathA.setAttribute('stroke-width', '3');
    pathA.setAttribute('stroke-linecap', 'round');
    statsPlusValueSvg.appendChild(pathA);

    if (statsMode === 'compare') {
      // Path Hero B
      const pathB = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      pathB.setAttribute('d', dPvB); pathB.setAttribute('fill', 'none');
      pathB.setAttribute('stroke', statsHero2.color || '#38bdf8'); pathB.setAttribute('stroke-width', '3');
      pathB.setAttribute('stroke-linecap', 'round');
      statsPlusValueSvg.appendChild(pathB);
    } else {
      // Path Benchmark (Slate Dashed)
      const pathBench = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      pathBench.setAttribute('d', dBench); pathBench.setAttribute('fill', 'none');
      pathBench.setAttribute('stroke', '#94a3b8'); pathBench.setAttribute('stroke-width', '2');
      pathBench.setAttribute('stroke-dasharray', '4 4');
      pathBench.setAttribute('stroke-linecap', 'round');
      statsPlusValueSvg.appendChild(pathBench);
    }

    // Path Delta Curve (Gold Line, thicker with glow)
    const pathDelta = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    pathDelta.setAttribute('d', dDelta); pathDelta.setAttribute('fill', 'none');
    pathDelta.setAttribute('stroke', '#ffe22d'); pathDelta.setAttribute('stroke-width', '2.5');
    pathDelta.setAttribute('stroke-linecap', 'round');
    pathDelta.style.filter = 'drop-shadow(0 0 6px rgba(255, 226, 45, 0.5))';
    statsPlusValueSvg.appendChild(pathDelta);

    // Legend
    if (statsMode === 'single') {
      statsPlusValueLegend.innerHTML = `
        <div class="legend-item"><span class="legend-color-dot" style="background: ${statsHero1.color};"></span><span>${statsHero1.name} (Plus-Value)</span></div>
        <div class="legend-item"><span class="legend-color-dot" style="background: #94a3b8;"></span><span>Moyenne Roster Actif</span></div>
        <div class="legend-item"><span class="legend-color-dot" style="background: #ffe22d;"></span><span>Delta vs Roster (${statsHero1.name} - Roster)</span></div>
      `;
    } else {
      statsPlusValueLegend.innerHTML = `
        <div class="legend-item"><span class="legend-color-dot" style="background: ${statsHero1.color};"></span><span>${statsHero1.name} (Plus-Value)</span></div>
        <div class="legend-item"><span class="legend-color-dot" style="background: ${statsHero2.color};"></span><span>${statsHero2.name} (Plus-Value)</span></div>
        <div class="legend-item"><span class="legend-color-dot" style="background: #ffe22d;"></span><span>Delta de Plus-Value (${statsHero1.name} - ${statsHero2.name})</span></div>
      `;
    }
  }

  // =========================================================================
  // TAB 4: PLATEAUX & FORCE DES HÉROS CONTROLLER
  // =========================================================================
  let currentBoardHeroId = 'barbarian';
  let isBoardUpgradedView = false;
  let currentBoardSubMode = 'view'; // 'view', 'compare', 'sim'

  const btnModeBoardView = document.getElementById('btnModeBoardView');
  const btnModeCompare = document.getElementById('btnModeCompare');
  const btnModeDiceSim = document.getElementById('btnModeDiceSim');

  const boardViewContainer = document.getElementById('boardViewContainer');
  const boardCompareContainer = document.getElementById('boardCompareContainer');
  const boardDiceSimContainer = document.getElementById('boardDiceSimContainer');

  const boardHeroSelectorRow = document.getElementById('boardHeroSelectorRow');
  const btnBoardLevelBase = document.getElementById('btnBoardLevelBase');
  const btnBoardLevelUpgraded = document.getElementById('btnBoardLevelUpgraded');
  const boardImageEl = document.getElementById('boardImageEl');

  const compareHeroSelectA = document.getElementById('compareHeroSelectA');
  const compareHeroSelectB = document.getElementById('compareHeroSelectB');
  const compareResultsGrid = document.getElementById('compareResultsGrid');

  const btnRunDiceCombat1 = document.getElementById('btnRunDiceCombat1');
  const btnRunDiceCombat100 = document.getElementById('btnRunDiceCombat100');
  const diceSimLog = document.getElementById('diceSimLog');

  // Sub-mode switching
  btnModeBoardView?.addEventListener('click', () => {
    currentBoardSubMode = 'view';
    updateBoardSubModeDisplay();
  });
  btnModeCompare?.addEventListener('click', () => {
    currentBoardSubMode = 'compare';
    updateBoardSubModeDisplay();
  });
  btnModeDiceSim?.addEventListener('click', () => {
    currentBoardSubMode = 'sim';
    updateBoardSubModeDisplay();
  });

  function updateBoardSubModeDisplay() {
    btnModeBoardView?.classList.toggle('active', currentBoardSubMode === 'view');
    btnModeCompare?.classList.toggle('active', currentBoardSubMode === 'compare');
    btnModeDiceSim?.classList.toggle('active', currentBoardSubMode === 'sim');

    if (boardViewContainer) boardViewContainer.style.display = currentBoardSubMode === 'view' ? 'block' : 'none';
    if (boardCompareContainer) boardCompareContainer.style.display = currentBoardSubMode === 'compare' ? 'block' : 'none';
    if (boardDiceSimContainer) boardDiceSimContainer.style.display = currentBoardSubMode === 'sim' ? 'block' : 'none';

    if (currentBoardSubMode === 'view') {
      renderBoardViewHero(currentBoardHeroId);
    } else if (currentBoardSubMode === 'compare') {
      renderBoardCompare();
    } else if (currentBoardSubMode === 'sim') {
      renderBoardDiceSim();
    }
  }

  // Level Toggle (Base vs Upgraded)
  btnBoardLevelBase?.addEventListener('click', () => {
    isBoardUpgradedView = false;
    btnBoardLevelBase.classList.add('active');
    btnBoardLevelUpgraded.classList.remove('active');
    renderBoardViewHero(currentBoardHeroId);
  });
  btnBoardLevelUpgraded?.addEventListener('click', () => {
    isBoardUpgradedView = true;
    btnBoardLevelUpgraded.classList.add('active');
    btnBoardLevelBase.classList.remove('active');
    renderBoardViewHero(currentBoardHeroId);
  });

  // Main Tab Render
  async function renderBoardsTab() {
    if (!heroBoardsData || Object.keys(heroBoardsData).length === 0) {
      try {
        const bRes = await fetch('./hero_boards.json?t=' + Date.now());
        if (bRes.ok) heroBoardsData = await bRes.json();
      } catch (e) {
        console.error('Error fetching hero_boards.json', e);
      }
    }
    if (!heroBoardsData || Object.keys(heroBoardsData).length === 0) return;

    if (!heroBoardsData[currentBoardHeroId]) {
      currentBoardHeroId = Object.keys(heroBoardsData)[0];
    }

    // Populate hero selector pills
    if (boardHeroSelectorRow) {
      boardHeroSelectorRow.innerHTML = '';
      Object.values(heroBoardsData).forEach(hero => {
        const pill = document.createElement('button');
        pill.className = `board-hero-pill ${hero.id === currentBoardHeroId ? 'active' : ''}`;
        pill.style.setProperty('--h-color', hero.color || '#e67e22');
        pill.innerHTML = `<span>${hero.name}</span>`;
        pill.addEventListener('click', () => {
          currentBoardHeroId = hero.id;
          renderBoardsTab();
        });
        boardHeroSelectorRow.appendChild(pill);
      });
    }

    updateBoardSubModeDisplay();
  }

  // Calculate Board Force & EV
  function calculateBoardForceMetrics(hero) {
    if (!hero || !hero.abilities) return { totalLvl1Dmg: 0, totalLvl2Dmg: 0, evBase: 0, evUpgraded: 0, powerGain: 0, undefShare: 0 };

    let totalLvl1Dmg = 0;
    let totalLvl2Dmg = 0;
    let totalLvl2Undef = 0;

    hero.abilities.forEach(a => {
      const l1 = a.lvl1 || {};
      const l2 = a.lvl2 || l1;
      totalLvl1Dmg += (l1.dmg || 0) + (l1.undef || 0);
      totalLvl2Dmg += (l2.dmg || 0) + (l2.undef || 0);
      totalLvl2Undef += (l2.undef || 0);
    });

    const diceFaces = hero.diceFaces || [];
    function estimateEV(isUpgraded) {
      let sumDmg = 0;
      const samples = 1500;
      for (let s = 0; s < samples; s++) {
        const d = [0,0,0,0,0].map(() => diceFaces[Math.floor(Math.random() * 6)] || { val: 1, type: 'attack' });
        const specials = d.filter(x => x.type === 'special' || x.type === 'ultimate').length;
        if (specials === 5) {
          sumDmg += 15;
          continue;
        }
        const vals = new Set(d.map(x => x.val));
        const hasLs = (vals.has(1)&&vals.has(2)&&vals.has(3)&&vals.has(4)&&vals.has(5)) ||
                      (vals.has(2)&&vals.has(3)&&vals.has(4)&&vals.has(5)&&vals.has(6));
        if (hasLs) {
          sumDmg += isUpgraded ? 13 : 10;
          continue;
        }
        const hasSs = (vals.has(1)&&vals.has(2)&&vals.has(3)&&vals.has(4)) ||
                      (vals.has(2)&&vals.has(3)&&vals.has(4)&&vals.has(5)) ||
                      (vals.has(3)&&vals.has(4)&&vals.has(5)&&vals.has(6));
        if (hasSs) {
          sumDmg += isUpgraded ? 9 : 7;
          continue;
        }
        const atks = d.filter(x => x.type === 'attack').length;
        if (atks >= 4) sumDmg += isUpgraded ? 11 : 9;
        else if (atks >= 3) sumDmg += isUpgraded ? 8 : 6;
        else if (specials >= 2) sumDmg += isUpgraded ? 8 : 6;
        else sumDmg += isUpgraded ? 5 : 4;
      }
      return +(sumDmg / samples).toFixed(1);
    }

    const evBase = estimateEV(false);
    const evUpgraded = estimateEV(true);
    const powerGain = evBase > 0 ? Math.round(((evUpgraded - evBase) / evBase) * 100) : 0;
    const undefShare = totalLvl2Dmg > 0 ? Math.round((totalLvl2Undef / totalLvl2Dmg) * 100) : 0;

    return { totalLvl1Dmg, totalLvl2Dmg, evBase, evUpgraded, powerGain, undefShare };
  }

  // Render Mode 1: Fiche & Plateau
  function renderBoardViewHero(heroId) {
    const hero = heroBoardsData[heroId];
    if (!hero) return;

    // Header Info
    const pEl = document.getElementById('boardHeroPortrait');
    const nEl = document.getElementById('boardHeroName');
    const dEl = document.getElementById('boardHeroDiffBadge');
    const sEl = document.getElementById('boardHeroSubtitle');

    if (pEl) pEl.src = hero.portrait || '';
    if (nEl) { nEl.textContent = hero.name; nEl.style.color = hero.color || '#e67e22'; }
    if (dEl) dEl.textContent = `Difficulté ${hero.difficulty || 3} / 5`;
    if (sEl) sEl.textContent = hero.subtitle || '';

    // Ratings
    const rRow = document.getElementById('boardRatingsRow');
    if (rRow && hero.ratings) {
      rRow.innerHTML = `
        <div class="board-rating-chip"><span class="r-label">Attaque</span><span class="r-val">⚔️ ${hero.ratings.attack || 4}/5</span></div>
        <div class="board-rating-chip"><span class="r-label">Défense</span><span class="r-val">🛡️ ${hero.ratings.defense || 3}/5</span></div>
        <div class="board-rating-chip"><span class="r-label">Contrôle</span><span class="r-val">🎯 ${hero.ratings.control || 3}/5</span></div>
        <div class="board-rating-chip"><span class="r-label">Économie</span><span class="r-val">💰 ${hero.ratings.economy || 2}/5</span></div>
      `;
    }

    // Board Image
    if (boardImageEl) {
      boardImageEl.src = isBoardUpgradedView ? (hero.boardUpgraded || hero.boardBase) : hero.boardBase;
    }

    // Dice Faces List
    const diceList = document.getElementById('boardDiceFacesList');
    if (diceList && hero.diceFaces) {
      diceList.innerHTML = hero.diceFaces.map(f => `
        <div class="dice-face-chip">
          <span>${f.icon || '🎲'}</span>
          <strong>${f.val} :</strong>
          <span>${f.symbol}</span>
        </div>
      `).join('');
    }

    // KPIs & Force
    const metrics = calculateBoardForceMetrics(hero);
    const kpiDmgTotal = document.getElementById('kpiDmgTotal');
    const kpiDmgSub = document.getElementById('kpiDmgSub');
    const kpiEvTotal = document.getElementById('kpiEvTotal');
    const kpiEvSub = document.getElementById('kpiEvSub');
    const kpiPowerGain = document.getElementById('kpiPowerGain');
    const kpiPowerSub = document.getElementById('kpiPowerSub');
    const kpiUndefShare = document.getElementById('kpiUndefShare');

    if (kpiDmgTotal) kpiDmgTotal.textContent = isBoardUpgradedView ? `${metrics.totalLvl2Dmg} PV` : `${metrics.totalLvl1Dmg} PV`;
    if (kpiDmgSub) kpiDmgSub.textContent = `Base: ${metrics.totalLvl1Dmg} PV ➔ Opt: ${metrics.totalLvl2Dmg} PV`;

    if (kpiEvTotal) kpiEvTotal.textContent = isBoardUpgradedView ? `${metrics.evUpgraded} PV` : `${metrics.evBase} PV`;
    if (kpiEvSub) kpiEvSub.textContent = `Base: ${metrics.evBase} PV ➔ Opt: ${metrics.evUpgraded} PV`;

    if (kpiPowerGain) kpiPowerGain.textContent = `+${metrics.powerGain}%`;
    if (kpiPowerSub) kpiPowerSub.textContent = `Gain de force offensive`;

    if (kpiUndefShare) kpiUndefShare.textContent = `${metrics.undefShare}%`;

    // Abilities Comparison Table
    const tbody = document.getElementById('boardAbilitiesTbody');
    if (tbody && hero.abilities) {
      tbody.innerHTML = '';
      hero.abilities.forEach(ab => {
        const tr = document.createElement('tr');
        const l1 = ab.lvl1 || {};
        const l2 = ab.lvl2;

        let tagClass = 'tag-parable';
        if (ab.type.includes('Imparable')) tagClass = 'tag-imparable';
        else if (ab.type.includes('Soin')) tagClass = 'tag-soin';
        else if (ab.type.includes('Altération') || ab.type.includes('Poison')) tagClass = 'tag-debuff';

        const l1Val = (l1.dmg ? `${l1.dmg} Dégâts` : '') + (l1.undef ? ` ${l1.undef} Imparables` : '') + (l1.heal ? ` +${l1.heal} Soin` : '') + (l1.token ? ` (${l1.token})` : '');
        const l2Val = l2 ? ((l2.dmg ? `${l2.dmg} Dégâts` : '') + (l2.undef ? ` ${l2.undef} Imparables` : '') + (l2.heal ? ` +${l2.heal} Soin` : '') + (l2.token ? ` (${l2.token})` : '')) : '<span style="color: var(--text-muted);">Non Améliorable</span>';

        let diffText = '-';
        if (l2) {
          const d1 = (l1.dmg || 0) + (l1.undef || 0);
          const d2 = (l2.dmg || 0) + (l2.undef || 0);
          const delta = d2 - d1;
          diffText = delta > 0 ? `<strong style="color: #2ed573;">+${delta} Dégâts</strong> (Coût: ${l2.cost || 2} PC)` : `<span style="color: #38bdf8;">Effets renforcés</span>`;
        }

        tr.innerHTML = `
          <td>
            <strong>${ab.name}</strong><br />
            <span class="ability-tag ${tagClass}">${ab.type}</span>
          </td>
          <td style="font-weight: 700; color: var(--accent-gold);">${ab.req}</td>
          <td>${l1Val}<br /><span style="font-size: 11px; color: var(--text-muted);">${l1.desc || ''}</span></td>
          <td>${l2Val}${l2 ? `<br /><span style="font-size: 11px; color: var(--text-muted);">${l2.desc || ''}</span>` : ''}</td>
          <td>${diffText}</td>
        `;
        tbody.appendChild(tr);
      });
    }
  }

  // Render Mode 2: Comparateur de Plateaux
  function renderBoardCompare() {
    if (!heroBoardsData) return;
    const hKeys = Object.keys(heroBoardsData);
    if (hKeys.length < 2) return;

    if (compareHeroSelectA && compareHeroSelectA.options.length === 0) {
      compareHeroSelectA.innerHTML = '';
      compareHeroSelectB.innerHTML = '';
      hKeys.forEach((k, idx) => {
        const optA = document.createElement('option'); optA.value = k; optA.textContent = heroBoardsData[k].name;
        const optB = document.createElement('option'); optB.value = k; optB.textContent = heroBoardsData[k].name;
        if (idx === 0) optA.selected = true;
        if (idx === 1) optB.selected = true;
        compareHeroSelectA.appendChild(optA);
        compareHeroSelectB.appendChild(optB);
      });

      compareHeroSelectA.addEventListener('change', renderBoardCompare);
      compareHeroSelectB.addEventListener('change', renderBoardCompare);
    }

    const hA = heroBoardsData[compareHeroSelectA.value];
    const hB = heroBoardsData[compareHeroSelectB.value];
    if (!hA || !hB || !compareResultsGrid) return;

    const mA = calculateBoardForceMetrics(hA);
    const mB = calculateBoardForceMetrics(hB);

    function buildHeroCard(h, m) {
      return `
        <div class="compare-hero-card">
          <div class="compare-hero-header">
            <img src="${h.portrait}" class="compare-hero-img" alt="${h.name}" />
            <div>
              <h3 style="margin: 0; color: ${h.color || '#e67e22'};">${h.name}</h3>
              <div style="font-size: 11px; color: var(--text-muted);">${h.subtitle || ''}</div>
              <span class="badge-pill" style="margin-top: 4px;">Difficulté ${h.difficulty}/5</span>
            </div>
          </div>

          <div style="display: flex; gap: 8px; flex-wrap: wrap;">
            <div class="board-rating-chip"><span class="r-label">Attaque</span><span class="r-val">${h.ratings?.attack || 4}/5</span></div>
            <div class="board-rating-chip"><span class="r-label">Défense</span><span class="r-val">${h.ratings?.defense || 3}/5</span></div>
            <div class="board-rating-chip"><span class="r-label">Contrôle</span><span class="r-val">${h.ratings?.control || 3}/5</span></div>
            <div class="board-rating-chip"><span class="r-label">Éco</span><span class="r-val">${h.ratings?.economy || 2}/5</span></div>
          </div>

          <div style="display: flex; flex-direction: column; gap: 6px; margin-top: 10px;">
            <div class="compare-stat-row"><span>Dégâts Max Cumulés (Base)</span><strong>${m.totalLvl1Dmg} PV</strong></div>
            <div class="compare-stat-row"><span>Dégâts Max Cumulés (Optimisé)</span><strong style="color: var(--accent-gold);">${m.totalLvl2Dmg} PV</strong></div>
            <div class="compare-stat-row"><span>Espérance Moyenne / Tour (EV)</span><strong style="color: #38bdf8;">${m.evBase} ➔ ${m.evUpgraded} PV</strong></div>
            <div class="compare-stat-row"><span>Gain de Force par Évolutions</span><strong style="color: #2ed573;">+${m.powerGain}%</strong></div>
            <div class="compare-stat-row"><span>Part de Dégâts Imparables</span><strong style="color: #ff4757;">${m.undefShare}%</strong></div>
          </div>

          <div style="margin-top: 10px;">
            <div style="font-size: 11px; font-weight: 800; color: var(--text-muted); margin-bottom: 6px;">DÉS (6 FACES) :</div>
            <div style="display: flex; gap: 6px; flex-wrap: wrap;">
              ${(h.diceFaces || []).map(f => `<span class="dice-face-chip">${f.icon} ${f.symbol}</span>`).join('')}
            </div>
          </div>
        </div>
      `;
    }

    compareResultsGrid.innerHTML = buildHeroCard(hA, mA) + buildHeroCard(hB, mB);
  }

  // Render Mode 3: Simulateur par les Dés
  function renderBoardDiceSim() {
    const p1El = document.getElementById('diceSimP1Name');
    const p2El = document.getElementById('diceSimP2Name');
    const h1 = heroBoardsData[currentBoardHeroId] || heroBoardsData['barbarian'];
    const h2Keys = Object.keys(heroBoardsData).filter(k => k !== h1.id);
    const h2 = heroBoardsData[h2Keys[0]] || heroBoardsData['shadowThief'];

    if (p1El) p1El.textContent = h1.name;
    if (p2El) p2El.textContent = h2.name;
  }

  // Dice simulation helpers
  function rollHeroDice(faces) {
    return faces[Math.floor(Math.random() * 6)] || { val: 1, type: 'attack' };
  }

  function simulateTurnActionWithDice(hero, isUpgraded) {
    const dice = [0,0,0,0,0].map(() => rollHeroDice(hero.diceFaces || []));
    const specials = dice.filter(d => d.type === 'special' || d.type === 'ultimate').length;
    if (specials === 5) {
      const a = (hero.abilities || []).find(ab => ab.id.includes('ultime') || ab.id === 'rage');
      return { name: a ? a.name : 'Ultime', dmg: 15, isUndef: true };
    }
    const vals = new Set(dice.map(d => d.val));
    const hasLs = (vals.has(1)&&vals.has(2)&&vals.has(3)&&vals.has(4)&&vals.has(5)) ||
                  (vals.has(2)&&vals.has(3)&&vals.has(4)&&vals.has(5)&&vals.has(6));
    if (hasLs) {
      const a = (hero.abilities || []).find(ab => ab.req.includes('Grande Suite'));
      const dmg = isUpgraded ? (a?.lvl2?.undef || 13) : (a?.lvl1?.undef || 10);
      return { name: a ? a.name : 'Grande Suite', dmg, isUndef: true };
    }
    const hasSs = (vals.has(1)&&vals.has(2)&&vals.has(3)&&vals.has(4)) ||
                  (vals.has(2)&&vals.has(3)&&vals.has(4)&&vals.has(5)) ||
                  (vals.has(3)&&vals.has(4)&&vals.has(5)&&vals.has(6));
    if (hasSs) {
      const a = (hero.abilities || []).find(ab => ab.req.includes('Petite Suite'));
      const dmg = isUpgraded ? (a?.lvl2?.dmg || a?.lvl2?.undef || 9) : (a?.lvl1?.dmg || a?.lvl1?.undef || 7);
      return { name: a ? a.name : 'Petite Suite', dmg, isUndef: false };
    }
    const atks = dice.filter(d => d.type === 'attack').length;
    if (atks >= 3) {
      const a = (hero.abilities || []).find(ab => ab.req.includes('3, 4') || ab.type.includes('Attaque Parable') || ab.req.includes('3'));
      const baseVal = atks >= 5 ? 12 : atks === 4 ? 9 : 6;
      const dmg = isUpgraded ? baseVal + 2 : baseVal;
      return { name: a ? a.name : 'Attaque', dmg, isUndef: false };
    }
    return { name: 'Frappe d\'Opportunité', dmg: isUpgraded ? 6 : 4, isUndef: false };
  }

  btnRunDiceCombat1?.addEventListener('click', () => {
    const h1 = heroBoardsData[currentBoardHeroId] || heroBoardsData['barbarian'];
    const h2Keys = Object.keys(heroBoardsData).filter(k => k !== h1.id);
    const h2 = heroBoardsData[h2Keys[0]] || heroBoardsData['shadowThief'];

    let hp1 = 50, hp2 = 50;
    let cp1 = 2, cp2 = 2;
    let up1 = false, up2 = false;
    let round = 0, attacker = 1;
    const logs = [];

    logs.push(`🎲 === DÉBUT DU COMBAT PAR JETS DE DÉS VIRTUELS ===`);
    logs.push(`Joueur 1 : ${h1.name} (50 PV) vs Joueur 2 : ${h2.name} (50 PV)\n`);

    while (hp1 > 0 && hp2 > 0 && round < 30) {
      round++;
      if (attacker === 1) {
        cp1 = Math.min(15, cp1 + 1);
        if (!up1 && cp1 >= 2) {
          cp1 -= 2;
          up1 = true;
          logs.push(`🛒 [${h1.name}] Achat de carte d'amélioration de plateau (Niveau II/III) payée avec 2 CP ! (CP: ${cp1})`);
        }
        const act = simulateTurnActionWithDice(h1, up1);
        const blocked = act.isUndef ? 0 : Math.floor(Math.random() * 3) + 1;
        const net = Math.max(0, act.dmg - blocked);
        hp2 = Math.max(0, hp2 - net);
        logs.push(`⚔️ [Tour ${round}] ${h1.name} lance ses 5 dés ➔ Déclenche "${act.name}" : inflige ${net} dégâts à ${h2.name} (${act.isUndef ? '💥 Imparable' : `🛡️ ${blocked} bloqués`}) | PV ${h2.name}: ${hp2}`);
        attacker = 2;
      } else {
        cp2 = Math.min(15, cp2 + 1);
        if (!up2 && cp2 >= 2) {
          cp2 -= 2;
          up2 = true;
          logs.push(`🛒 [${h2.name}] Achat de carte d'amélioration de plateau (Niveau II/III) payée avec 2 CP ! (CP: ${cp2})`);
        }
        const act = simulateTurnActionWithDice(h2, up2);
        const blocked = act.isUndef ? 0 : Math.floor(Math.random() * 3) + 1;
        const net = Math.max(0, act.dmg - blocked);
        hp1 = Math.max(0, hp1 - net);
        logs.push(`⚔️ [Tour ${round}] ${h2.name} lance ses 5 dés ➔ Déclenche "${act.name}" : inflige ${net} dégâts à ${h1.name} (${act.isUndef ? '💥 Imparable' : `🛡️ ${blocked} bloqués`}) | PV ${h1.name}: ${hp1}`);
        attacker = 1;
      }
    }

    const winner = hp1 > hp2 ? h1.name : h2.name;
    logs.push(`\n🏆 VICTOIRE de ${winner} en ${round} tours ! (PV Finaux : ${h1.name} ${hp1} - ${hp2} ${h2.name})`);

    if (diceSimLog) {
      diceSimLog.innerHTML = logs.map(l => `<div>${l}</div>`).join('');
      diceSimLog.scrollTop = 0;
    }
  });

  btnRunDiceCombat100?.addEventListener('click', () => {
    const h1 = heroBoardsData[currentBoardHeroId] || heroBoardsData['barbarian'];
    const h2Keys = Object.keys(heroBoardsData).filter(k => k !== h1.id);
    const h2 = heroBoardsData[h2Keys[0]] || heroBoardsData['shadowThief'];

    let p1Wins = 0, p2Wins = 0, totalR = 0;
    const runs = 100;

    for (let i = 0; i < runs; i++) {
      let hp1 = 50, hp2 = 50;
      let cp1 = 2, cp2 = 2;
      let up1 = false, up2 = false;
      let round = 0;
      let attacker = (i < 50) ? 1 : 2;

      while (hp1 > 0 && hp2 > 0 && round < 35) {
        round++;
        if (attacker === 1) {
          cp1 = Math.min(15, cp1 + 1);
          if (!up1 && cp1 >= 2) { cp1 -= 2; up1 = true; }
          const act = simulateTurnActionWithDice(h1, up1);
          const net = Math.max(0, act.dmg - (act.isUndef ? 0 : Math.floor(Math.random() * 3) + 1));
          hp2 = Math.max(0, hp2 - net);
          attacker = 2;
        } else {
          cp2 = Math.min(15, cp2 + 1);
          if (!up2 && cp2 >= 2) { cp2 -= 2; up2 = true; }
          const act = simulateTurnActionWithDice(h2, up2);
          const net = Math.max(0, act.dmg - (act.isUndef ? 0 : Math.floor(Math.random() * 3) + 1));
          hp1 = Math.max(0, hp1 - net);
          attacker = 1;
        }
      }
      totalR += round;
      if (hp1 > hp2) p1Wins++;
      else p2Wins++;
    }

    const avgR = (totalR / runs).toFixed(1);
    const resMsg = `📊 RÉSULTAT DES 100 COMBATS PAR DÉS VIRTUELS & CARTES D'ÉVOLUTION :\n\n` +
      `• ${h1.name} (J1) : ${p1Wins} victoires (${p1Wins}%)\n` +
      `• ${h2.name} (J2) : ${p2Wins} victoires (${p2Wins}%)\n\n` +
      `• Durée moyenne des duels : ${avgR} tours\n` +
      `Chaque combat a simulé les vrais jets de 5 dés des plateaux et l'achat dynamique d'évolutions de niveau II/III en CP.`;

    alert(resMsg);
    if (diceSimLog) {
      diceSimLog.innerHTML = `<div style="font-weight: bold; color: var(--accent-gold);">${resMsg.replace(/\n/g, '<br />')}</div>`;
    }
  });

  // Log Helper
  function log(message, type = 'info') {
    const entry = document.createElement('div');
    entry.className = `log-entry ${type}`;
    const time = new Date().toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
    entry.innerHTML = `<span style="opacity: 0.5;">[${time}]</span> ${message}`;
    combatLog.prepend(entry);
  }

  // Initial Run
  updateSimulatorDisplay();
  log('⚡ Simulateur initialisé avec graphiques, multi-styles et tokens spécifiques.', 'info');
});
