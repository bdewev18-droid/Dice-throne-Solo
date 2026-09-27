document.addEventListener('DOMContentLoaded', () => {
  let appData = { versions: [], components: [] };
  let recetteState = loadRecetteState();
  let activeTab = 'journal';
  let searchQuery = '';
  let activeTag = 'ALL';

  // DOM Elements
  const tabBtns = document.querySelectorAll('.tab-btn');
  const tabPanes = document.querySelectorAll('.tab-pane');
  const searchInput = document.getElementById('search-input');
  const tagFiltersContainer = document.getElementById('tag-filters');
  const versionsList = document.getElementById('versions-list');
  const recetteAccordion = document.getElementById('recette-accordion');
  const componentsGrid = document.getElementById('components-grid');
  const exportBtn = document.getElementById('btn-export');
  const importBtn = document.getElementById('btn-import');
  const importFileInput = document.getElementById('import-file-input');

  // Load JSON Data
  fetch('recette_data.json')
    .then(res => res.json())
    .then(data => {
      appData = data;
      initApp();
    })
    .catch(err => {
      console.error('Erreur chargement recette_data.json:', err);
    });

  function initApp() {
    setupEventListeners();
    renderTags();
    renderJournal();
    renderRecette();
    renderComponents();
  }

  // LocalStorage handling
  function loadRecetteState() {
    try {
      const saved = localStorage.getItem('dts_recette_state');
      return saved ? JSON.parse(saved) : {};
    } catch (e) {
      console.error('Erreur chargement localStorage:', e);
      return {};
    }
  }

  function saveRecetteState() {
    try {
      localStorage.setItem('dts_recette_state', JSON.stringify(recetteState));
    } catch (e) {
      console.error('Erreur sauvegarde localStorage:', e);
    }
  }

  // Event Listeners Setup
  function setupEventListeners() {
    // Tabs Navigation
    tabBtns.forEach(btn => {
      btn.addEventListener('click', () => {
        const targetTab = btn.getAttribute('data-tab');
        tabBtns.forEach(b => b.classList.remove('active'));
        tabPanes.forEach(p => p.classList.remove('active'));

        btn.classList.add('active');
        document.getElementById(`tab-${targetTab}`).classList.add('active');
        activeTab = targetTab;
      });
    });

    // Search Engine Input
    if (searchInput) {
      searchInput.addEventListener('input', (e) => {
        searchQuery = e.target.value.toLowerCase().trim();
        renderJournal();
        renderRecette();
      });
    }

    // Export State JSON
    if (exportBtn) {
      exportBtn.addEventListener('click', () => {
        const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(recetteState, null, 2));
        const downloadAnchor = document.createElement('a');
        downloadAnchor.setAttribute("href", dataStr);
        downloadAnchor.setAttribute("download", `recette_validation_export_${new Date().toISOString().slice(0,10)}.json`);
        document.body.appendChild(downloadAnchor);
        downloadAnchor.click();
        downloadAnchor.remove();
      });
    }

    // Import State JSON
    if (importBtn && importFileInput) {
      importBtn.addEventListener('click', () => importFileInput.click());
      importFileInput.addEventListener('change', (e) => {
        const file = e.target.files[0];
        if (!file) return;
        const reader = new FileReader();
        reader.onload = (event) => {
          try {
            const imported = JSON.parse(event.target.result);
            recetteState = imported;
            saveRecetteState();
            renderRecette();
            alert('Données de recette importées avec succès !');
          } catch (err) {
            alert('Fichier JSON d\'import invalide.');
          }
        };
        reader.readAsText(file);
      });
    }
  }

  // Render Tag Filters
  function renderTags() {
    if (!tagFiltersContainer) return;
    const allTags = new Set();
    appData.versions.forEach(v => (v.tags || []).forEach(t => allTags.add(t)));

    tagFiltersContainer.innerHTML = '';
    const allBtn = document.createElement('button');
    allBtn.className = `tag-btn ${activeTag === 'ALL' ? 'active' : ''}`;
    allBtn.textContent = 'Tous';
    allBtn.addEventListener('click', () => {
      activeTag = 'ALL';
      renderTags();
      renderJournal();
      renderRecette();
    });
    tagFiltersContainer.appendChild(allBtn);

    allTags.forEach(tag => {
      const btn = document.createElement('button');
      btn.className = `tag-btn ${activeTag === tag ? 'active' : ''}`;
      btn.textContent = tag;
      btn.addEventListener('click', () => {
        activeTag = tag;
        renderTags();
        renderJournal();
        renderRecette();
      });
      tagFiltersContainer.appendChild(btn);
    });
  }

  // Render Onglet 1: Journal de modifications (Git Real)
  function renderJournal() {
    if (!versionsList) return;
    versionsList.innerHTML = '';

    const filtered = appData.versions.filter(v => {
      const matchesSearch = !searchQuery || 
        v.version.toLowerCase().includes(searchQuery) ||
        (v.commit && v.commit.toLowerCase().includes(searchQuery)) ||
        v.title.toLowerCase().includes(searchQuery) ||
        v.summary.toLowerCase().includes(searchQuery) ||
        (v.tags && v.tags.some(t => t.toLowerCase().includes(searchQuery)));
      
      const matchesTag = activeTag === 'ALL' || (v.tags && v.tags.includes(activeTag));
      return matchesSearch && matchesTag;
    });

    if (filtered.length === 0) {
      versionsList.innerHTML = '<div style="text-align:center; padding: 3rem; color: var(--text-muted);">Aucune version ne correspond à la recherche.</div>';
      return;
    }

    filtered.forEach(v => {
      const card = document.createElement('div');
      card.className = 'version-card';
      card.innerHTML = `
        <div class="version-header">
          <div class="version-title-group">
            <span class="version-badge">v${v.version}</span>
            <span class="version-title">${v.title}</span>
          </div>
          <div class="version-meta">
            <span>📅 ${v.date}</span>
            <span>👤 ${v.author}</span>
            <span><code>Git: ${v.commit}</code></span>
            <span># Build ${v.buildNumber}</span>
          </div>
        </div>
        <div class="version-body">
          <p class="version-summary">${v.summary}</p>
          <div class="badge-list">
            ${(v.tags || []).map(t => `<span class="badge">${t}</span>`).join('')}
          </div>
        </div>
      `;
      versionsList.appendChild(card);
    });
  }

  // Render Onglet 2: Checklist de Recette Granulaire (Détaillée)
  function renderRecette() {
    if (!recetteAccordion) return;
    recetteAccordion.innerHTML = '';

    const filteredVersions = appData.versions.filter(v => {
      const matchesSearch = !searchQuery || 
        v.version.toLowerCase().includes(searchQuery) ||
        (v.commit && v.commit.toLowerCase().includes(searchQuery)) ||
        v.title.toLowerCase().includes(searchQuery) ||
        v.prompts.some(p => p.userPrompt.toLowerCase().includes(searchQuery) || p.items.some(i => i.title.toLowerCase().includes(searchQuery) || i.description.toLowerCase().includes(searchQuery)));
      const matchesTag = activeTag === 'ALL' || (v.tags && v.tags.includes(activeTag));
      return matchesSearch && matchesTag;
    });

    if (filteredVersions.length === 0) {
      recetteAccordion.innerHTML = '<div style="text-align:center; padding: 3rem; color: var(--text-muted);">Aucun prompt ou élément de recette trouvé.</div>';
      return;
    }

    filteredVersions.forEach((v, index) => {
      // Calculate version progress
      let totalItems = 0;
      let validatedItems = 0;

      v.prompts.forEach(p => {
        p.items.forEach(item => {
          totalItems++;
          const state = recetteState[item.id] || {};
          if (state.status === 'validated') validatedItems++;
        });
      });

      const progressPercent = totalItems > 0 ? Math.round((validatedItems / totalItems) * 100) : 0;

      const accItem = document.createElement('div');
      accItem.className = `accordion-item ${index === 0 ? 'open' : ''}`;
      accItem.innerHTML = `
        <div class="accordion-header">
          <div class="accordion-title-area">
            <span class="version-badge">v${v.version}</span>
            <div>
              <div style="font-weight:700; font-size:1.05rem;">${v.title} <span style="font-size:0.8rem; opacity:0.7;">(${v.commit})</span></div>
              <div style="font-size:0.8rem; color:var(--text-muted);">${v.prompts.length} demande(s) • ${totalItems} point(s) de contrôle granulaire</div>
            </div>
          </div>
          <div style="display:flex; align-items:center; gap: 1.5rem;">
            <div class="progress-container">
              <div class="progress-bar-bg">
                <div class="progress-bar-fill" style="width: ${progressPercent}%;"></div>
              </div>
              <span class="progress-text">${validatedItems}/${totalItems} (${progressPercent}%)</span>
            </div>
            <span class="accordion-toggle-icon">▼</span>
          </div>
        </div>
        <div class="accordion-body">
          ${v.prompts.map(p => `
            <div class="prompt-block">
              <div class="prompt-header">
                <span class="prompt-icon">PROMPT USER</span>
                <span class="prompt-text">${p.userPrompt}</span>
              </div>
              <div class="response-text">🛠️ <strong>Réponse & Correction :</strong> ${p.aiResponse}</div>
              <div class="qa-items-list">
                ${p.items.map(item => {
                  const itemState = recetteState[item.id] || { status: 'pending', comment: '' };
                  return `
                    <div class="qa-item-row ${itemState.status}" id="row-${item.id}">
                      <div class="qa-item-main">
                        <div class="qa-item-info">
                          <div class="qa-item-title">
                            <span class="badge" style="margin-right:0.5rem;">${item.category}</span>
                            ${item.title}
                          </div>
                          <div class="qa-item-desc">${item.description}</div>
                        </div>
                        <div class="status-selector">
                          <button class="status-btn ${itemState.status === 'pending' ? 'active' : ''}" data-item="${item.id}" data-status="pending">⏱ À tester</button>
                          <button class="status-btn ${itemState.status === 'validated' ? 'active' : ''}" data-item="${item.id}" data-status="validated">✅ Validé</button>
                          <button class="status-btn ${itemState.status === 'rejected' ? 'active' : ''}" data-item="${item.id}" data-status="rejected">❌ Rejeté</button>
                        </div>
                      </div>
                      <div>
                        <textarea class="comment-input" data-item="${item.id}" placeholder="Ajouter un commentaire de test / retour recette...">${itemState.comment || ''}</textarea>
                      </div>
                    </div>
                  `;
                }).join('')}
              </div>
            </div>
          `).join('')}
        </div>
      `;

      // Accordion Toggle click
      const headerEl = accItem.querySelector('.accordion-header');
      headerEl.addEventListener('click', () => {
        accItem.classList.toggle('open');
      });

      // Status selector click events
      accItem.querySelectorAll('.status-btn').forEach(btn => {
        btn.addEventListener('click', (e) => {
          e.stopPropagation();
          const itemId = btn.getAttribute('data-item');
          const newStatus = btn.getAttribute('data-status');
          
          if (!recetteState[itemId]) recetteState[itemId] = {};
          recetteState[itemId].status = newStatus;
          saveRecetteState();
          renderRecette();
        });
      });

      // Comment input change events
      accItem.querySelectorAll('.comment-input').forEach(txt => {
        txt.addEventListener('input', (e) => {
          const itemId = txt.getAttribute('data-item');
          if (!recetteState[itemId]) recetteState[itemId] = {};
          recetteState[itemId].comment = e.target.value;
          saveRecetteState();
        });
      });

      recetteAccordion.appendChild(accItem);
    });
  }

  // Render Onglet 3: Galerie de Composants UI (App Réels avec Assets Images)
  function renderComponents() {
    if (!componentsGrid) return;
    componentsGrid.innerHTML = '';

    appData.components.forEach(comp => {
      const card = document.createElement('div');
      card.className = 'component-card';
      
      let stageContent = '';

      if (comp.id.startsWith('token-popin-')) {
        stageContent = `
          <div class="mock-token-popin">
            <div class="mock-popin-header">
              <img class="mock-token-img" src="${comp.data.image}" alt="${comp.data.tokenName}" onerror="this.src='../favicon.png';">
              ${comp.data.secondaryImage ? `<img class="mock-token-img" src="${comp.data.secondaryImage}" alt="Secondary" style="width:32px; height:32px; margin-left:-0.5rem;" onerror="this.src='../favicon.png';">` : ''}
              <div style="margin-left:0.5rem;">
                <div class="mock-token-title">${comp.data.tokenName}</div>
                <span class="mock-token-badge">${comp.data.type}</span>
              </div>
            </div>
            <p class="mock-token-effect">${comp.data.effect}</p>
            <div style="background:var(--bg-input); padding:0.5rem; border-radius:var(--radius-sm); border:1px solid var(--border-color); font-size:0.75rem; color:var(--text-secondary); margin-bottom:0.75rem;">
              ℹ️ <strong>Règle App :</strong> ${comp.data.appDetails}
            </div>
            <div style="display:flex; justify-content:space-between; align-items:center; font-size:0.8rem; color:var(--text-muted);">
              <span>Cumul max: <strong>${comp.data.maxStacks}</strong></span>
              <span>Stacks actifs: <strong style="color:var(--accent-gold); font-size:1rem;">${comp.data.stacks}</strong></span>
            </div>
          </div>
        `;
      } else if (comp.id === 'attack-token-bar-real') {
        stageContent = `
          <div style="width:100%;">
            <div class="mock-token-bar">
              <div class="mock-attack-info">
                <span class="mock-attack-name">⚔️ ${comp.data.attackName}</span>
                <span class="mock-attack-dmg" id="real-atk-total-dmg">Dégâts Totaux: 13 (Base ${comp.data.baseDamage} + 5 Modificateurs)</span>
              </div>
              <div class="mock-applied-tokens" id="real-interactive-tokens-row">
                ${comp.data.tokensApplied.map((t, i) => `
                  <div class="mock-token-chip ${t.active ? '' : 'inactive'}" data-dmg="${t.damageValue}">
                    <img src="${t.icon}" width="20" height="20" alt="${t.name}" onerror="this.style.display='none';">
                    <span>${t.name} (${t.modifier})</span>
                  </div>
                `).join('')}
              </div>
            </div>
          </div>
        `;
      } else if (comp.id === 'combat-dice-module') {
        stageContent = `
          <div style="width:100%; display:flex; flex-direction:column; gap:1rem; align-items:center;">
            <div class="badge" style="background:rgba(59,130,246,0.2); color:#93c5fd; padding:0.4rem 1rem; border-radius:20px;">
              🎲 ${comp.data.phaseName} • Relances restantes: <strong>${comp.data.rerollsLeft} / ${comp.data.maxRerolls}</strong>
            </div>
            <div style="display:flex; gap:0.75rem;">
              ${comp.data.dice.map(d => `
                <div style="width:54px; height:54px; background:${d.locked ? '#374151' : '#1e293b'}; border:2px solid ${d.diceCubeLocked ? 'var(--accent-gold)' : (d.locked ? '#9ca3af' : 'var(--border-color)')}; border-radius:10px; display:flex; flex-direction:column; align-items:center; justify-content:center; position:relative; box-shadow:0 4px 10px rgba(0,0,0,0.4);">
                  ${d.diceCubeLocked ? `<span style="position:absolute; top:-8px; right:-6px; background:var(--accent-gold); color:#000; font-size:10px; padding:2px 4px; border-radius:4px; font-weight:bold;">🔒 CUBE</span>` : ''}
                  <span style="font-size:1.2rem;">${d.symbol}</span>
                  <span style="font-size:0.75rem; font-weight:bold; color:var(--text-secondary);">${d.value}</span>
                </div>
              `).join('')}
            </div>
          </div>
        `;
      } else if (comp.id === 'combat-status-card-real') {
        stageContent = `
          <div class="mock-boss-card">
            <div style="display:flex; justify-content:space-between; align-items:center;">
              <span style="font-weight:bold; color:var(--text-primary); font-size:1.05rem;">👾 ${comp.data.bossName}</span>
              <span class="badge" style="background:rgba(245,158,11,0.2); color:var(--accent-gold);">PV: ${comp.data.currentHp} / ${comp.data.maxHp}</span>
            </div>
            <div class="mock-hp-bar">
              <div class="mock-hp-fill" style="width: ${(comp.data.currentHp / comp.data.maxHp) * 100}%;"></div>
            </div>
            <div style="display:flex; justify-content:space-between; font-size:0.8rem; color:var(--text-secondary);">
              <span>🛡️ Bouclier: ${comp.data.shield} | ⚡ CP: ${comp.data.cp}</span>
            </div>
            <div style="border-top:1px dashed var(--border-color); pt-0.5rem; margin-top:0.25rem;">
              <div style="font-size:0.75rem; color:var(--text-muted); margin-bottom:0.4rem;">Statuts & Jetons Actifs :</div>
              <div style="display:flex; gap:0.5rem; flex-wrap:wrap;">
                ${comp.data.activeTokens.map(t => `
                  <div style="background:var(--bg-input); border:1px solid var(--border-color); border-radius:15px; padding:0.2rem 0.5rem; font-size:0.75rem; display:flex; align-items:center; gap:0.35rem;">
                    <img src="${t.icon}" width="16" height="16" alt="${t.name}" onerror="this.style.display='none';">
                    <span>${t.name}</span>
                    <span style="background:var(--accent-gold); color:#000; border-radius:50%; width:16px; height:16px; display:inline-flex; align-items:center; justify-content:center; font-size:10px; font-weight:bold;">${t.stacks}</span>
                  </div>
                `).join('')}
              </div>
            </div>
          </div>
        `;
      } else if (comp.id.startsWith('roll-popin-')) {
        stageContent = `
          <div style="width: 100%; display: flex; justify-content: center; background: #000; padding: 2rem 0; border-radius: 8px;">
            <div style="position: relative; width: 320px; background: #130a1e; border: 2px solid rgba(155, 81, 224, 0.4); border-radius: 12px; box-shadow: 0 0 25px rgba(155, 81, 224, 0.3); padding: 1.5rem; text-align: center; color: white; font-family: 'Segoe UI', Roboto, sans-serif; overflow: hidden;">
              <!-- Subtle top glow -->
              <div style="position: absolute; top: -50px; left: 50%; transform: translateX(-50%); width: 200px; height: 100px; background: radial-gradient(circle, rgba(155, 81, 224, 0.4) 0%, transparent 70%); border-radius: 50%;"></div>
              
              <!-- Close X -->
              <div style="position: absolute; top: 12px; right: 12px; cursor: pointer; color: #9ca3af; font-size: 1.2rem; line-height: 1;">&times;</div>
              
              <!-- Icon -->
              <div style="margin: 0 auto 1rem; width: 80px; height: 80px; border-radius: 50%; background: #1a2035; box-shadow: 0 0 35px rgba(155,81,224,0.7); display: flex; align-items: center; justify-content: center; border: 2px solid rgba(255,255,255,0.1);">
                <img src="${comp.data.icon}" alt="icon" style="width: 60px; height: 60px; object-fit: contain;" onerror="this.outerHTML='<span style=\'font-size:3rem;color:white;font-weight:bold;\'>&#x1F441;</span>'">
              </div>
              
              <!-- Title and Subtitle -->
              <h3 style="margin: 0 0 0.25rem 0; font-size: 1.2rem; font-weight: 700; position:relative; z-index:2;">${comp.data.title}</h3>
              <div style="color: #a78bfa; font-size: 0.8rem; margin-bottom: 1.2rem; position:relative; z-index:2;">${comp.data.subtitle}</div>
              
              <!-- Description Box -->
              <div style="background: #231b2e; border-radius: 8px; padding: 1rem; font-size: 0.8rem; color: #d1d5db; margin-bottom: 1rem; position:relative; z-index:2; text-align: left; line-height: 1.45;">
                ${comp.data.descriptionText}
              </div>
              
              <!-- Roll Section Box -->
              <div style="background: #1f162c; border: 1px solid rgba(155, 81, 224, 0.3); border-radius: 8px; padding: 1.25rem 1rem; position:relative; z-index:2; display: flex; flex-direction: column; align-items: center;">
                <div style="font-weight: bold; font-size: 0.95rem; margin-bottom: 1rem;">${comp.data.rollTitle}</div>
                
                <!-- Die placeholder -->
                <div style="width: 48px; height: 48px; background: #372b47; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 1.2rem; font-weight: bold; margin-bottom: 1.25rem; box-shadow: inset 0 2px 4px rgba(0,0,0,0.4);">
                  ${comp.data.dieValue}
                </div>
                
                <!-- Buttons Row -->
                <div style="display: flex; gap: 0.75rem; width: 100%; justify-content: center;">
                  <button style="background: #a855f7; color: white; border: none; padding: 0.6rem 1.2rem; border-radius: 20px; font-weight: 600; font-size: 0.85rem; cursor: pointer; display: flex; align-items: center; gap: 0.4rem; box-shadow: 0 4px 10px rgba(168,85,247,0.4);">
                    <span style="font-size: 1.1rem; line-height: 1;">&#x1F3B2;</span> ${comp.data.btnRollText}
                  </button>
                  <button style="background: transparent; color: white; border: 1px solid rgba(255,255,255,0.7); padding: 0.6rem 1.2rem; border-radius: 20px; font-weight: 600; font-size: 0.85rem; cursor: pointer; display: flex; align-items: center; gap: 0.4rem;">
                    <span style="font-size: 1.1rem; line-height: 1;">&#x270F;&#xFE0F;</span> ${comp.data.btnEditText}
                  </button>
                </div>
              </div>
            </div>
          </div>
        `;
      } else if (comp.id.startsWith('confirm-popin-')) {
        stageContent = `
          <div style="width: 100%; display: flex; justify-content: center; background: #000; padding: 2rem 0; border-radius: 8px;">
            <div style="position: relative; width: 280px; background: #130a1e; border: 2px solid rgba(155, 81, 224, 0.4); border-radius: 12px; box-shadow: 0 0 25px rgba(155, 81, 224, 0.3); padding: 1.5rem; text-align: center; color: white; font-family: 'Segoe UI', Roboto, sans-serif; overflow: hidden;">
              <!-- Subtle top glow -->
              <div style="position: absolute; top: -50px; left: 50%; transform: translateX(-50%); width: 200px; height: 100px; background: radial-gradient(circle, rgba(155, 81, 224, 0.4) 0%, transparent 70%); border-radius: 50%;"></div>
              
              <!-- Title Row (Icon + Text) -->
              <div style="display: flex; align-items: center; justify-content: center; gap: 0.5rem; margin-bottom: 1rem; position:relative; z-index:2;">
                <img src="${comp.data.icon}" alt="icon" style="width: 24px; height: 24px; object-fit: contain;" onerror="this.outerHTML='<span style=\'font-size:1.5rem;\'>&#x1F916;</span>'">
                <h3 style="margin: 0; font-size: 1.25rem; font-weight: 600; color: #a855f7;">${comp.data.title}</h3>
              </div>
              
              <!-- Question Text -->
              <div style="font-size: 0.95rem; color: #e5e7eb; margin-bottom: 1.5rem; position:relative; z-index:2; line-height: 1.4;">
                ${comp.data.questionText}
              </div>
              
              <!-- Buttons Row -->
              <div style="display: flex; gap: 0.75rem; width: 100%; justify-content: center; position:relative; z-index:2;">
                <button style="flex: 1; background: transparent; color: white; border: 1px solid #a855f7; padding: 0.6rem 0; border-radius: 20px; font-weight: 600; font-size: 0.9rem; cursor: pointer;">
                  ${comp.data.btnNoText}
                </button>
                <button style="flex: 1; background: #a855f7; color: white; border: none; padding: 0.6rem 0; border-radius: 20px; font-weight: 600; font-size: 0.9rem; cursor: pointer; box-shadow: 0 4px 10px rgba(168,85,247,0.4);">
                  ${comp.data.btnYesText}
                </button>
              </div>
            </div>
          </div>
        `;
      } else if (comp.id.startsWith('choice-popin-')) {
        stageContent = `
          <div style="width: 100%; display: flex; justify-content: center; background: #000; padding: 2rem 0; border-radius: 8px;">
            <div style="position: relative; width: 280px; background: #130a1e; border: 2px solid rgba(155, 81, 224, 0.4); border-radius: 12px; box-shadow: 0 0 25px rgba(155, 81, 224, 0.3); padding: 1.5rem; text-align: center; color: white; font-family: 'Segoe UI', Roboto, sans-serif; overflow: hidden;">
              <!-- Subtle top glow -->
              <div style="position: absolute; top: -50px; left: 50%; transform: translateX(-50%); width: 200px; height: 100px; background: radial-gradient(circle, rgba(155, 81, 224, 0.4) 0%, transparent 70%); border-radius: 50%;"></div>
              
              <!-- Close X -->
              <div style="position: absolute; top: 12px; right: 12px; cursor: pointer; color: #9ca3af; font-size: 1.2rem; line-height: 1;">&times;</div>
              
              <!-- Icon -->
              <div style="margin: 0 auto 1rem; width: 80px; height: 80px; border-radius: 50%; background: #1a2035; box-shadow: 0 0 35px rgba(155,81,224,0.7); display: flex; align-items: center; justify-content: center; border: 2px solid rgba(255,255,255,0.1);">
                <img src="${comp.data.icon}" alt="icon" style="width: 60px; height: 60px; object-fit: contain;" onerror="this.outerHTML='<span style=\'font-size:3rem;color:white;font-weight:bold;\'>&#x2694;</span>'">
              </div>
              
              <!-- Title and Subtitle -->
              <h3 style="margin: 0 0 0.25rem 0; font-size: 1.2rem; font-weight: 700; position:relative; z-index:2;">${comp.data.title}</h3>
              <div style="color: #a78bfa; font-size: 0.8rem; margin-bottom: 1.2rem; position:relative; z-index:2;">${comp.data.subtitle}</div>
              
              <!-- Description Box -->
              <div style="background: #231b2e; border-radius: 8px; padding: 0.75rem; font-size: 0.8rem; color: #d1d5db; margin-bottom: 1.2rem; position:relative; z-index:2; text-align: left; line-height: 1.45;">
                ${comp.data.descriptionText}
              </div>
              
              <!-- Buttons Row -->
              <div style="display: flex; gap: 0.5rem; width: 100%; justify-content: center; position:relative; z-index:2;">
                ${comp.data.choices.map(c => `
                  <button style="flex: 1; background: #a855f7; color: white; border: none; padding: 0.6rem 0.25rem; border-radius: 20px; font-weight: 600; font-size: 0.8rem; cursor: pointer; box-shadow: 0 4px 10px rgba(168,85,247,0.4); text-align: center; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
                    ${c}
                  </button>
                `).join('')}
              </div>
            </div>
          </div>
        `;
      } else if (comp.id === 'token-action-bar') {
        stageContent = `
          <div style="width: 100%; display: flex; flex-direction: column; gap: 0.5rem; background: #0b0710; padding: 2rem; border-radius: 8px;">
            <!-- Simulation du bandeau d'activation -->
            <div style="display: flex; align-items: center; background: #130a1e; border: 1.5px solid #a78bfa; border-radius: 8px; padding: 0.5rem 0.75rem; color: white; font-family: 'Segoe UI', sans-serif; max-width: 380px; margin: 0 auto; width: 100%;">
              <div style="width: 26px; height: 26px; background: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-right: 0.75rem; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.5);">
                <img src="${comp.data.icon}" style="width: 100%; height: 100%; object-fit: contain;" onerror="this.outerHTML='<span style=\'color:black; font-size: 14px; font-weight: 900;\'>W</span>'">
              </div>
              <span style="font-size: 1rem; font-weight: bold; letter-spacing: 0.5px;">${comp.data.tokenName} (${comp.data.tokenCount})</span>
              <div style="flex-grow: 1;"></div>
              <button style="background: #a855f7; color: white; border: none; border-radius: 20px; padding: 0.4rem 1.25rem; font-weight: 800; font-size: 0.95rem; cursor: pointer; box-shadow: 0 4px 6px rgba(168,85,247,0.4);">
                ${comp.data.btnText}
              </button>
            </div>
          </div>
        `;
      } else if (comp.id === 'hero-token-bar') {
        stageContent = `
          <div style="width: 100%; display: flex; flex-direction: column; gap: 0.5rem; background: #0b0710; padding: 2rem; border-radius: 8px;">
            ${comp.data.tokens.map(t => `
              <div style="display: flex; align-items: center; background: #112316; border: 1.5px solid #4ade80; border-radius: 8px; padding: 0.5rem 0.75rem; color: white; font-family: 'Segoe UI', sans-serif; max-width: 380px; margin: 0 auto; width: 100%;">
                <div style="width: 26px; height: 26px; background: rgba(0,0,0,0.3); border-radius: 50%; display: flex; align-items: center; justify-content: center; margin-right: 0.75rem; overflow: hidden; box-shadow: inset 0 2px 4px rgba(0,0,0,0.3);">
                  <img src="${t.icon}" style="width: 100%; height: 100%; object-fit: contain;" onerror="this.outerHTML='<span style=\'color:white; font-size: 14px; font-weight: 900;\'>+</span>'">
                </div>
                <span style="font-size: 1rem; font-weight: bold; letter-spacing: 0.5px;">${t.name}</span>
                <div style="flex-grow: 1;"></div>
                <div style="display: flex; align-items: center; border: 1.5px solid #4ade80; padding: 0.3rem 0.75rem; border-radius: 20px;">
                  <span style="color: #4ade80; font-size: 0.9rem; margin-right: 0.4rem;">&#x2714;</span>
                  <span style="color: #4ade80; font-size: 0.85rem; font-weight: bold;">${t.activeText}</span>
                </div>
              </div>
            `).join('')}
          </div>
        `;
            } else if (comp.id === 'wither-popin') {
        stageContent = `
          <div style="width: 100%; display: flex; justify-content: center; background: rgba(0,0,0,0.8); padding: 2rem 0; border-radius: 8px;">
            <div style="background: #1e1b2e; border: 1px solid #3d355c; border-radius: 12px; padding: 1.5rem; max-width: 350px; width: 100%; text-align: center; position: relative; box-shadow: 0 10px 25px rgba(0,0,0,0.5);">
              ${comp.data.btnCancel ? `<button style="position: absolute; top: 10px; right: 10px; background: transparent; border: none; color: #a19db3; font-size: 1.2rem; cursor: pointer;">&times;</button>` : ''}
              
              <div style="display: flex; align-items: center; justify-content: center; margin-bottom: 1rem;">
                ${comp.data.tokenIcon ? `<img src="${comp.data.tokenIcon}" style="width: 32px; height: 32px; margin-right: 0.75rem;" onerror="this.style.display='none'">` : ''}
                <h3 style="color: white; margin: 0; font-size: 1.2rem; font-weight: bold;">${comp.data.title}</h3>
              </div>
              
              <p style="color: #c7c4d6; font-size: 0.95rem; line-height: 1.5; margin-bottom: 1.5rem; text-align: left;">
                ${comp.data.text}
              </p>

              ${comp.data.showMaskCheckbox ? `
              <div style="display: flex; align-items: center; justify-content: flex-start; margin-bottom: 1.5rem;">
                <input type="checkbox" id="hide-wither" style="margin-right: 8px; width: 16px; height: 16px; accent-color: #a855f7;">
                <label for="hide-wither" style="color: #a19db3; font-size: 0.9rem; cursor: pointer;">Ne plus afficher ce jeton persistant</label>
              </div>
              ` : ''}
              
              <button style="width: 100%; background: #a855f7; color: white; border: none; border-radius: 8px; padding: 0.75rem; font-weight: bold; font-size: 1rem; cursor: pointer;">
                ${comp.data.btnText}
              </button>
            </div>
          </div>
        `;
} else if (comp.id === 'silence-popin') {
        stageContent = `
          <div style="width: 100%; display: flex; justify-content: center; background: rgba(0,0,0,0.8); padding: 2rem 0; border-radius: 8px;">
            <div style="background: #1e1b2e; border: 1px solid #3d355c; border-radius: 12px; padding: 1.5rem; max-width: 350px; width: 100%; text-align: center; position: relative; box-shadow: 0 10px 25px rgba(0,0,0,0.5);">
              ${comp.data.btnCancel ? `<button style="position: absolute; top: 10px; right: 10px; background: transparent; border: none; color: #a19db3; font-size: 1.2rem; cursor: pointer;">&times;</button>` : ''}
              
              <div style="display: flex; align-items: center; justify-content: center; margin-bottom: 1rem;">
                ${comp.data.tokenIcon ? `<img src="${comp.data.tokenIcon}" style="width: 32px; height: 32px; margin-right: 0.75rem;" onerror="this.style.display='none'">` : ''}
                <h3 style="color: white; margin: 0; font-size: 1.2rem; font-weight: bold;">${comp.data.title}</h3>
              </div>
              
              <p style="color: #c7c4d6; font-size: 0.95rem; line-height: 1.5; margin-bottom: 1.5rem; text-align: left;">
                ${comp.data.text}
              </p>
              
              <button style="width: 100%; background: #a855f7; color: white; border: none; border-radius: 8px; padding: 0.75rem; font-weight: bold; font-size: 1rem; cursor: pointer;">
                ${comp.data.btnText}
              </button>
            </div>
          </div>
        `;
      } else if (comp.id === 'roll-token-action') {
        stageContent = `
          <div style="width: 100%; display: flex; justify-content: center; background: #0b0710; padding: 2rem 0; border-radius: 8px;">
            <div style="display: flex; flex-direction: column; gap: 0.6rem; width: 100%; max-width: 380px; background: transparent; padding: 1rem; border-radius: 12px;">
              
              <!-- Token Action Button -->
              <button style="background: #22c55e; color: white; border: none; padding: 0.8rem; border-radius: 8px; font-weight: bold; font-size: 1rem; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.5rem; box-shadow: 0 4px 6px rgba(34,197,94,0.3);">
                <img src="${comp.data.icon}" style="width: 22px; height: 22px; object-fit: contain;" onerror="this.style.display='none'">
                ${comp.data.tokenName}
              </button>

              <!-- Disabled Reroll Button -->
              <button disabled style="background: #14532d; color: rgba(74, 222, 128, 0.4); border: none; padding: 0.8rem; border-radius: 8px; font-weight: 800; font-size: 1.1rem; cursor: not-allowed;">
                Reroll
              </button>
              
              <!-- Bottom Action Row -->
              <div style="display: flex; gap: 0.5rem; margin-top: 0.4rem;">
                <button style="flex: 1; background: #fde047; color: black; border: none; padding: 0.6rem; border-radius: 8px; font-weight: 800; font-size: 0.9rem; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.4rem; box-shadow: 0 2px 4px rgba(0,0,0,0.2);">
                  <span style="font-size: 1rem; transform: scaleX(-1); display: inline-block;">&#x21C4;</span> Edit a die
                </button>
                <button style="flex: 1; background: #fde047; color: black; border: none; padding: 0.6rem; border-radius: 8px; font-weight: 800; font-size: 0.9rem; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.4rem; box-shadow: 0 2px 4px rgba(0,0,0,0.2);">
                  <span style="font-size: 1.1rem; line-height: 1;">&#x21BB;</span> Reroll a die
                </button>
              </div>

            </div>
          </div>
        `;
      } else if (comp.id === 'attack-cover-btn') {
        stageContent = `
          <div style="width: 100%; display: flex; justify-content: center; background: #0b0710; padding: 2rem 0; border-radius: 8px;">
            <div style="display: flex; gap: 0.5rem; width: 100%; max-width: 380px; background: #130a1e; padding: 1rem 0.5rem; border-radius: 20px; align-items: center; border: 1px solid rgba(255,255,255,0.05); border-bottom: 4px solid #000;">
              
              <!-- Attack Cover Button (Blinding Light) -->
              <button style="flex: 1; background: #a855f7; color: white; border: none; padding: 0; height: 55px; border-radius: 8px; font-weight: 800; font-size: 0.95rem; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.5rem; box-shadow: 0 4px 6px rgba(0,0,0,0.2);">
                <img src="${comp.data.atkIcon}" style="width: 22px; height: 22px; object-fit: contain;" onerror="this.style.display='none'">
                ${comp.data.atkText}
              </button>

              <!-- Defense Cover Button (Blind) - from the screenshot -->
              <button style="flex: 1; background: #fde047; color: black; border: none; padding: 0; height: 55px; border-radius: 8px; font-weight: 800; font-size: 0.95rem; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.5rem; box-shadow: 0 4px 6px rgba(0,0,0,0.2);">
                <img src="${comp.data.defIcon}" style="width: 22px; height: 22px; object-fit: contain;" onerror="this.style.display='none'">
                ${comp.data.defText}
              </button>

            </div>
          </div>
        `;
      } else if (comp.id === 'defense-cover-btn') {
        stageContent = `
          <div style="width: 100%; display: flex; justify-content: center; background: #0b0710; padding: 2rem 0; border-radius: 8px;">
            <!-- Simulation de la bottom bar -->
            <div style="display: flex; gap: 0.5rem; width: 100%; max-width: 380px; background: #130a1e; padding: 1rem 0.5rem; border-radius: 20px; align-items: center; border: 1px solid rgba(255,255,255,0.05); border-bottom: 4px solid #000;">
              
              <!-- ATK Counter -->
              <div style="background: #151816; border: 1px solid #253327; border-radius: 12px; padding: 0.4rem 0.75rem; display: flex; align-items: center; gap: 1rem;">
                <div style="width: 26px; height: 26px; border-radius: 50%; border: 1.5px solid #4ade80; display: flex; align-items: center; justify-content: center; color: #4ade80; font-weight: normal; font-size: 1.2rem; cursor: pointer;">-</div>
                <div style="display: flex; flex-direction: column; align-items: center; line-height: 1;">
                  <span style="color: #4ade80; font-size: 0.65rem; font-weight: bold; letter-spacing: 1px;">ATK</span>
                  <span style="color: #4ade80; font-size: 1.3rem; font-weight: 900; margin-top: 2px;">${comp.data.atkValue}</span>
                </div>
                <div style="width: 26px; height: 26px; border-radius: 50%; border: 1.5px solid #4ade80; display: flex; align-items: center; justify-content: center; color: #4ade80; font-weight: normal; font-size: 1.2rem; cursor: pointer;">+</div>
              </div>

              <!-- Only Cards Button (Cover) -->
              <button style="flex: 1; background: #fde047; color: black; border: none; padding: 0; height: 48px; border-radius: 8px; font-weight: 700; font-size: 0.95rem; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.5rem; box-shadow: 0 4px 6px rgba(0,0,0,0.2);">
                ${comp.data.tokenIcon ? `<img src="${comp.data.tokenIcon}" style="width: 20px; height: 20px; object-fit: contain;" onerror="this.style.display='none'">` : ''}
                ${comp.data.text}
              </button>
              
              <!-- OK Button -->
              <button style="background: #a855f7; color: white; border: none; padding: 0 1rem; height: 48px; border-radius: 12px; font-weight: 800; font-size: 1.1rem; cursor: pointer;">
                ${comp.data.btnOkText}
              </button>

            </div>
          </div>
        `;
      } else if (comp.id === 'token-modifier-bar') {
        stageContent = `
          <div style="width: 100%; display: flex; flex-direction: column; gap: 0.5rem; background: #0b0710; padding: 1.5rem; border-radius: 8px;">
            ${comp.data.tokens.map(t => `
              <div style="display: flex; align-items: center; background: #271830; border: 1.2px solid #8f43ff; border-radius: 8px; padding: 0.5rem 0.75rem; color: white; font-family: sans-serif;">
                <img src="${t.icon}" style="width: 22px; height: 22px; object-fit: contain; margin-right: 0.5rem;" onerror="this.outerHTML='<span style=\'font-size:1.2rem; margin-right:0.5rem;\'>&#x1F525;</span>'">
                <span style="font-size: 0.85rem; font-weight: bold;">${t.name} : </span>
                <span style="font-size: 0.85rem; font-weight: 900; color: #8f43ff; margin-left: 0.25rem;">${t.modifier}</span>
                <div style="flex-grow: 1;"></div>
                <div style="display: flex; align-items: center; background: rgba(0,0,0,0.2); padding: 0.2rem 0.5rem; border-radius: 4px;">
                  <span style="color: #8f43ff; font-size: 0.8rem; margin-right: 0.25rem;">&#x2714;</span>
                  <span style="font-size: 0.75rem; font-weight: bold;">${t.activeText}</span>
                </div>
              </div>
            `).join('')}
            
            <div style="display: flex; align-items: center; justify-content: center; margin-top: 1rem; gap: 0.5rem;">
              <div style="background: #000; border: 1.5px solid #8f43ff; border-radius: 20px; padding: 0.4rem 1rem; display: flex; align-items: center; gap: 0.5rem;">
                <span style="color: #8f43ff; font-size: 1.2rem; font-weight: bold;">-</span>
                <div style="display: flex; flex-direction: column; align-items: center; line-height: 1;">
                  <span style="color: #a78bfa; font-size: 0.6rem; font-weight: bold;">ATK</span>
                  <span style="color: #fbbf24; font-size: 1.2rem; font-weight: 900;">${comp.data.baseAtk} <span style="color: #a78bfa; font-size: 0.9rem;">${comp.data.modifier === 0 ? '+0' : (comp.data.modifier > 0 ? '+' + comp.data.modifier : comp.data.modifier)}</span></span>
                </div>
                <span style="color: #8f43ff; font-size: 1.2rem; font-weight: bold;">+</span>
              </div>
            </div>
          </div>
        `;
      } else if (comp.id.startsWith('result-popin-')) {
        stageContent = `
          <div style="width: 100%; display: flex; justify-content: center; background: #000; padding: 2rem 0; border-radius: 8px;">
            <div style="position: relative; width: 280px; background: #130a1e; border: 2px solid rgba(155, 81, 224, 0.4); border-radius: 12px; box-shadow: 0 0 25px rgba(155, 81, 224, 0.3); padding: 1.5rem; text-align: center; color: white; font-family: 'Segoe UI', Roboto, sans-serif; overflow: hidden;">
              <!-- Subtle top glow -->
              <div style="position: absolute; top: -50px; left: 50%; transform: translateX(-50%); width: 200px; height: 100px; background: radial-gradient(circle, rgba(155, 81, 224, 0.4) 0%, transparent 70%); border-radius: 50%;"></div>
              
              <!-- Close X -->
              <div style="position: absolute; top: 12px; right: 12px; cursor: pointer; color: #9ca3af; font-size: 1.2rem; line-height: 1;">&times;</div>
              
              <!-- Icon -->
              <div style="margin: 0 auto 1rem; width: 80px; height: 80px; border-radius: 50%; background: #1a2035; box-shadow: 0 0 35px rgba(155,81,224,0.7); display: flex; align-items: center; justify-content: center; border: 2px solid rgba(255,255,255,0.1);">
                <img src="${comp.data.icon}" alt="icon" style="width: 60px; height: 60px; object-fit: contain;" onerror="this.outerHTML='<span style=\'font-size:3rem;color:white;font-weight:bold;\'>&#x2620;</span>'">
              </div>
              
              <!-- Title and Subtitle -->
              <h3 style="margin: 0 0 0.25rem 0; font-size: 1.2rem; font-weight: 700; position:relative; z-index:2;">${comp.data.title}</h3>
              <div style="color: #a78bfa; font-size: 0.8rem; margin-bottom: 1.2rem; position:relative; z-index:2;">${comp.data.subtitle}</div>
              
              <!-- Description Box -->
              <div style="background: #231b2e; border-radius: 8px; padding: 0.75rem; font-size: 0.8rem; color: #d1d5db; margin-bottom: 1rem; position:relative; z-index:2; text-align: left; line-height: 1.45;">
                ${comp.data.descriptionText}
              </div>
              
              <!-- Result Box -->
              <div style="background: #1f162c; border: 1px solid rgba(155, 81, 224, 0.5); border-radius: 8px; padding: 0.8rem; font-size: 0.95rem; font-weight: bold; color: white; margin-bottom: 1.25rem; position:relative; z-index:2; display:flex; justify-content:center; align-items:center; gap:0.5rem; box-shadow: inset 0 2px 4px rgba(0,0,0,0.3);">
                ${comp.data.resultText}
              </div>
              
              <!-- Buttons Row -->
              <div style="display: flex; gap: 0.75rem; width: 100%; justify-content: center; position:relative; z-index:2;">
                <button style="background: transparent; color: white; border: 1px solid rgba(255,255,255,0.7); padding: 0.5rem 1.2rem; border-radius: 20px; font-weight: 600; font-size: 0.85rem; cursor: pointer; display: flex; align-items: center; gap: 0.4rem;">
                  <span style="font-size: 1rem; line-height: 1;">&#x270F;&#xFE0F;</span> ${comp.data.btnEditText}
                </button>
                <button style="background: #a855f7; color: white; border: none; padding: 0.5rem 1.8rem; border-radius: 20px; font-weight: 600; font-size: 0.85rem; cursor: pointer; display: flex; align-items: center; box-shadow: 0 4px 10px rgba(168,85,247,0.4);">
                  ${comp.data.btnOkText}
                </button>
              </div>
            </div>
          </div>
        `;
      } else if (comp.id.startsWith('info-popin-')) {
        stageContent = `
          <div style="width: 100%; display: flex; justify-content: center; background: #000; padding: 2rem 0; border-radius: 8px;">
            <div style="position: relative; width: 280px; background: #130a1e; border: 2px solid rgba(155, 81, 224, 0.4); border-radius: 12px; box-shadow: 0 0 25px rgba(155, 81, 224, 0.3); padding: 1.5rem; text-align: center; color: white; font-family: 'Segoe UI', Roboto, sans-serif; overflow: hidden;">
              <!-- Subtle top glow -->
              <div style="position: absolute; top: -50px; left: 50%; transform: translateX(-50%); width: 200px; height: 100px; background: radial-gradient(circle, rgba(155, 81, 224, 0.4) 0%, transparent 70%); border-radius: 50%;"></div>
              
              <!-- Close X -->
              <div style="position: absolute; top: 12px; right: 12px; cursor: pointer; color: #9ca3af; font-size: 1.2rem; line-height: 1;">&times;</div>
              
              <!-- Icon -->
              <div style="margin: 0 auto 1rem; width: 80px; height: 80px; border-radius: 50%; background: #5a0000; box-shadow: 0 0 35px rgba(155,81,224,0.7); display: flex; align-items: center; justify-content: center; border: 2px solid rgba(255,255,255,0.1);">
                <img src="${comp.data.icon}" alt="icon" style="width: 60px; height: 60px; object-fit: contain;" onerror="this.outerHTML='<span style=\'font-size:3rem;color:white;font-weight:bold;\'>&#x21BA;</span>'">
              </div>
              
              <!-- Title and Subtitle -->
              <h3 style="margin: 0 0 0.25rem 0; font-size: 1.2rem; font-weight: 700; position:relative; z-index:2;">${comp.data.title}</h3>
              <div style="color: #a78bfa; font-size: 0.8rem; margin-bottom: 1.2rem; position:relative; z-index:2;">${comp.data.subtitle}</div>
              
              <!-- Description Box -->
              <div style="background: #231b2e; border-radius: 8px; padding: 0.75rem; font-size: 0.85rem; color: #d1d5db; margin-bottom: 1.2rem; position:relative; z-index:2;">
                ${comp.data.descriptionText}
              </div>
              
              <!-- Button -->
              <button style="background: #a855f7; color: white; border: none; padding: 0.5rem 2rem; border-radius: 20px; font-weight: bold; font-size: 0.9rem; cursor: pointer; width: 120px; box-shadow: 0 4px 10px rgba(168,85,247,0.4); position:relative; z-index:2;">
                ${comp.data.buttonText}
              </button>
            </div>
          </div>
        `;
      }

      card.innerHTML = `
        <div class="component-header">
          <div>
            <div class="component-category">${comp.category}</div>
            <div class="component-title">${comp.title}</div>
          </div>
        </div>
        <div class="component-stage">
          ${stageContent}
        </div>
        <div class="component-footer">
          ${comp.description}
        </div>
      `;

      componentsGrid.appendChild(card);

      // Real Attack Bar Damage Calculation Event
      if (comp.id === 'attack-token-bar-real') {
        const tokensRow = card.querySelector('#real-interactive-tokens-row');
        const totalDmgEl = card.querySelector('#real-atk-total-dmg');
        if (tokensRow && totalDmgEl) {
          tokensRow.querySelectorAll('.mock-token-chip').forEach(chip => {
            chip.addEventListener('click', () => {
              chip.classList.toggle('inactive');
              // Recalculate real damage formula
              let addedDmg = 0;
              tokensRow.querySelectorAll('.mock-token-chip').forEach(c => {
                if (!c.classList.contains('inactive')) {
                  addedDmg += Number(c.getAttribute('data-dmg') || 0);
                }
              });
              const total = comp.data.baseDamage + addedDmg;
              totalDmgEl.textContent = `Dégâts Totaux: ${total} (Base ${comp.data.baseDamage} + ${addedDmg} Modificateurs)`;
            });
          });
        }
      }
    });
  }
});
