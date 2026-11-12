document.addEventListener('DOMContentLoaded', () => {
  let appData = { components: [] };
  let searchQuery = '';

  const searchInput = document.getElementById('search-input');
  const componentsGrid = document.getElementById('components-grid');

  // Load JSON Data
  fetch('recette_data.json')
    .then(res => res.json())
    .then(data => {
      appData = data;
      renderComponents();
    })
    .catch(err => {
      console.error('Erreur chargement recette_data.json:', err);
    });

  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      searchQuery = e.target.value.toLowerCase().trim();
      renderComponents();
    });
  }

  // Render Galerie de Composants UI
  function renderComponents() {
    if (!componentsGrid) return;
    componentsGrid.innerHTML = '';

    const list = (appData.components || []).filter(comp => {
      if (!searchQuery) return true;
      const haystack = `${comp.title || ''} ${comp.category || ''} ${comp.description || ''} ${comp.id || ''}`.toLowerCase();
      return haystack.includes(searchQuery);
    });

    if (list.length === 0) {
      componentsGrid.innerHTML = `
        <div style="grid-column: 1 / -1; text-align: center; padding: 3rem; color: var(--text-muted);">
          Aucun composant UI ne correspond à votre recherche.
        </div>
      `;
      return;
    }

    list.forEach(comp => {
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
                ${comp.data.tokensApplied.map((t) => `
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
              <div style="position: absolute; top: -50px; left: 50%; transform: translateX(-50%); width: 200px; height: 100px; background: radial-gradient(circle, rgba(155, 81, 224, 0.4) 0%, transparent 70%); border-radius: 50%;"></div>
              <div style="position: absolute; top: 12px; right: 12px; cursor: pointer; color: #9ca3af; font-size: 1.2rem; line-height: 1;">&times;</div>
              <div style="margin: 0 auto 1rem; width: 80px; height: 80px; border-radius: 50%; background: #1a2035; box-shadow: 0 0 35px rgba(155,81,224,0.7); display: flex; align-items: center; justify-content: center; border: 2px solid rgba(255,255,255,0.1);">
                <img src="${comp.data.icon}" alt="icon" style="width: 60px; height: 60px; object-fit: contain;" onerror="this.outerHTML='<span style=\\'font-size:3rem;color:white;font-weight:bold;\\'>👁</span>'">
              </div>
              <h3 style="margin: 0 0 0.25rem 0; font-size: 1.2rem; font-weight: 700; position:relative; z-index:2;">${comp.data.title}</h3>
              <div style="color: #a78bfa; font-size: 0.8rem; margin-bottom: 1.2rem; position:relative; z-index:2;">${comp.data.subtitle}</div>
              <div style="background: #231b2e; border-radius: 8px; padding: 1rem; font-size: 0.8rem; color: #d1d5db; margin-bottom: 1rem; position:relative; z-index:2; text-align: left; line-height: 1.45;">
                ${comp.data.descriptionText}
              </div>
              <div style="background: #1f162c; border: 1px solid rgba(155, 81, 224, 0.3); border-radius: 8px; padding: 1.25rem 1rem; position:relative; z-index:2; display: flex; flex-direction: column; align-items: center;">
                <div style="font-weight: bold; font-size: 0.95rem; margin-bottom: 1rem;">${comp.data.rollTitle}</div>
                <div style="width: 48px; height: 48px; background: #372b47; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 1.2rem; font-weight: bold; margin-bottom: 1.25rem; box-shadow: inset 0 2px 4px rgba(0,0,0,0.4);">
                  ${comp.data.dieValue}
                </div>
                <div style="display: flex; gap: 0.75rem; width: 100%; justify-content: center;">
                  <button style="background: #a855f7; color: white; border: none; padding: 0.6rem 1.2rem; border-radius: 20px; font-weight: 600; font-size: 0.85rem; cursor: pointer; display: flex; align-items: center; gap: 0.4rem; box-shadow: 0 4px 10px rgba(168,85,247,0.4);">
                    <span style="font-size: 1.1rem; line-height: 1;">🎲</span> ${comp.data.btnRollText}
                  </button>
                  <button style="background: transparent; color: white; border: 1px solid rgba(255,255,255,0.7); padding: 0.6rem 1.2rem; border-radius: 20px; font-weight: 600; font-size: 0.85rem; cursor: pointer; display: flex; align-items: center; gap: 0.4rem;">
                    <span style="font-size: 1.1rem; line-height: 1;">✏️</span> ${comp.data.btnEditText}
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
              <div style="position: absolute; top: -50px; left: 50%; transform: translateX(-50%); width: 200px; height: 100px; background: radial-gradient(circle, rgba(155, 81, 224, 0.4) 0%, transparent 70%); border-radius: 50%;"></div>
              <div style="display: flex; align-items: center; justify-content: center; gap: 0.5rem; margin-bottom: 1rem; position:relative; z-index:2;">
                <img src="${comp.data.icon}" alt="icon" style="width: 24px; height: 24px; object-fit: contain;" onerror="this.outerHTML='<span style=\\'font-size:1.5rem;\\'>🤖</span>'">
                <h3 style="margin: 0; font-size: 1.25rem; font-weight: 600; color: #a855f7;">${comp.data.title}</h3>
              </div>
              <div style="font-size: 0.95rem; color: #e5e7eb; margin-bottom: 1.5rem; position:relative; z-index:2; line-height: 1.4;">
                ${comp.data.questionText}
              </div>
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
              <div style="position: absolute; top: -50px; left: 50%; transform: translateX(-50%); width: 200px; height: 100px; background: radial-gradient(circle, rgba(155, 81, 224, 0.4) 0%, transparent 70%); border-radius: 50%;"></div>
              <div style="position: absolute; top: 12px; right: 12px; cursor: pointer; color: #9ca3af; font-size: 1.2rem; line-height: 1;">&times;</div>
              <div style="margin: 0 auto 1rem; width: 80px; height: 80px; border-radius: 50%; background: #1a2035; box-shadow: 0 0 35px rgba(155,81,224,0.7); display: flex; align-items: center; justify-content: center; border: 2px solid rgba(255,255,255,0.1);">
                <img src="${comp.data.icon}" alt="icon" style="width: 60px; height: 60px; object-fit: contain;" onerror="this.outerHTML='<span style=\\'font-size:3rem;color:white;font-weight:bold;\\'>⚔️</span>'">
              </div>
              <h3 style="margin: 0 0 0.25rem 0; font-size: 1.2rem; font-weight: 700; position:relative; z-index:2;">${comp.data.title}</h3>
              <div style="color: #a78bfa; font-size: 0.8rem; margin-bottom: 1.2rem; position:relative; z-index:2;">${comp.data.subtitle}</div>
              <div style="background: #231b2e; border-radius: 8px; padding: 0.75rem; font-size: 0.8rem; color: #d1d5db; margin-bottom: 1.2rem; position:relative; z-index:2; text-align: left; line-height: 1.45;">
                ${comp.data.descriptionText}
              </div>
              <div style="display: flex; gap: 0.5rem; width: 100%; justify-content: center; position:relative; z-index:2;">
                ${(comp.data.choices || []).map(c => `
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
            <div style="display: flex; align-items: center; background: #130a1e; border: 1.5px solid #a78bfa; border-radius: 8px; padding: 0.5rem 0.75rem; color: white; font-family: 'Segoe UI', sans-serif; max-width: 380px; margin: 0 auto; width: 100%;">
              <div style="width: 24px; height: 24px; border-radius: 4px; overflow: hidden; margin-right: 0.5rem; flex-shrink: 0; box-shadow: 0 1px 3px rgba(0,0,0,0.4);">
                <img src="../assets/personnages/Barbarian.png" style="width: 100%; height: 100%; object-fit: cover;" onerror="this.src='../assets/enemy_previews/bleu-001.webp'">
              </div>
              <div style="width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; margin-right: 0.5rem; flex-shrink: 0;">
                <img src="${comp.data.icon}" style="width: 100%; height: 100%; object-fit: contain;" onerror="this.outerHTML='<span style=\\'color:#a78bfa; font-size: 14px; font-weight: 900;\\'>+</span>'">
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
            ${(comp.data.tokens || []).map(t => `
              <div style="display: flex; align-items: center; background: #112316; border: 1.5px solid #4ade80; border-radius: 8px; padding: 0.5rem 0.75rem; color: white; font-family: 'Segoe UI', sans-serif; max-width: 380px; margin: 0 auto; width: 100%;">
                <div style="width: 24px; height: 24px; border-radius: 4px; overflow: hidden; margin-right: 0.5rem; flex-shrink: 0; box-shadow: 0 1px 3px rgba(0,0,0,0.4);">
                  <img src="../assets/personnages/Barbarian.png" style="width: 100%; height: 100%; object-fit: cover;">
                </div>
                <div style="width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; margin-right: 0.5rem; flex-shrink: 0;">
                  <img src="${t.icon}" style="width: 100%; height: 100%; object-fit: contain;" onerror="this.outerHTML='<span style=\\'color:#4ade80; font-size: 14px; font-weight: 900;\\'>+</span>'">
                </div>
                <span style="font-size: 1rem; font-weight: bold; letter-spacing: 0.5px;">${t.name}</span>
                <div style="flex-grow: 1;"></div>
                <div style="display: flex; align-items: center; border: 1.5px solid #4ade80; padding: 0.3rem 0.75rem; border-radius: 20px;">
                  <span style="color: #4ade80; font-size: 0.9rem; margin-right: 0.4rem;">✔</span>
                  <span style="color: #4ade80; font-size: 0.85rem; font-weight: bold;">${t.activeText}</span>
                </div>
              </div>
            `).join('')}
          </div>
        `;
      } else if (comp.id === 'multi-roll-token-bar') {
        stageContent = `
          <div style="width: 100%; display: flex; flex-direction: column; gap: 0.5rem; background: #0b0710; padding: 2rem; border-radius: 8px;">
            <div style="display: flex; align-items: center; background: #1f1a2e; border: 1.5px solid rgba(143, 67, 255, 0.6); border-radius: 8px; padding: 0.5rem 0.75rem; color: white; font-family: 'Segoe UI', sans-serif; max-width: 480px; margin: 0 auto; width: 100%;">
              <div style="width: 22px; height: 22px; border-radius: 4px; overflow: hidden; margin-right: 0.5rem; flex-shrink: 0; box-shadow: 0 1px 3px rgba(0,0,0,0.4);">
                <img src="../assets/personnages/Barbarian.png" style="width: 100%; height: 100%; object-fit: cover;">
              </div>
              <div style="width: 22px; height: 22px; display: flex; align-items: center; justify-content: center; margin-right: 0.5rem; flex-shrink: 0;">
                <img src="${comp.data.icon}" style="width: 100%; height: 100%; object-fit: contain;" onerror="this.outerHTML='<span style=\\'color:#a78bfa; font-size: 14px; font-weight: 900;\\'>+</span>'">
              </div>
              <span style="font-size: 1rem; font-weight: bold; letter-spacing: 0.5px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 130px;">Barbed Vine</span>
              <div style="flex-grow: 1;"></div>
              
              <span style="font-size: 12px; font-weight: bold; color: rgba(255,255,255,0.7); margin-right: 6px;">Rolls</span>
              <div style="display: flex; gap: 4px; margin-right: 8px;">
                <div style="padding: 4px 6px; border: 1px solid #8f43ff; background: #8f43ff; border-radius: 4px; font-size: 12px; font-weight: bold; color: black; cursor: pointer;">x1</div>
                <div style="padding: 4px 6px; border: 1px solid #8f43ff; background: transparent; border-radius: 4px; font-size: 12px; font-weight: bold; color: white; cursor: pointer;">x2</div>
                <div style="padding: 4px 6px; border: 1px solid #8f43ff; background: transparent; border-radius: 4px; font-size: 12px; font-weight: bold; color: white; cursor: pointer;">x3</div>
              </div>
              
              <button style="background: #8f43ff; color: white; border: none; border-radius: 6px; padding: 0.4rem 0.8rem; font-weight: 800; font-size: 0.85rem; cursor: pointer;">
                ${comp.data.btnText}
              </button>
            </div>
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
              <button style="background: #22c55e; color: white; border: none; padding: 0.8rem; border-radius: 8px; font-weight: bold; font-size: 1rem; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.5rem; box-shadow: 0 4px 6px rgba(34,197,94,0.3);">
                <img src="${comp.data.icon}" style="width: 22px; height: 22px; object-fit: contain;" onerror="this.style.display='none'">
                ${comp.data.tokenName}
              </button>
              <button disabled style="background: #14532d; color: rgba(74, 222, 128, 0.4); border: none; padding: 0.8rem; border-radius: 8px; font-weight: 800; font-size: 1.1rem; cursor: not-allowed;">
                Reroll
              </button>
              <div style="display: flex; gap: 0.5rem; margin-top: 0.4rem;">
                <button style="flex: 1; background: #fde047; color: black; border: none; padding: 0.6rem; border-radius: 8px; font-weight: 800; font-size: 0.9rem; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.4rem;">
                  <span style="font-size: 1rem; transform: scaleX(-1); display: inline-block;">⇄</span> Edit a die
                </button>
                <button style="flex: 1; background: #fde047; color: black; border: none; padding: 0.6rem; border-radius: 8px; font-weight: 800; font-size: 0.9rem; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.4rem;">
                  <span style="font-size: 1.1rem; line-height: 1;">↺</span> Reroll a die
                </button>
              </div>
            </div>
          </div>
        `;
      } else if (comp.id === 'attack-cover-btn') {
        stageContent = `
          <div style="width: 100%; display: flex; justify-content: center; background: #0b0710; padding: 2rem 0; border-radius: 8px;">
            <div style="display: flex; gap: 0.5rem; width: 100%; max-width: 380px; background: #130a1e; padding: 1rem 0.5rem; border-radius: 20px; align-items: center; border: 1px solid rgba(255,255,255,0.05); border-bottom: 4px solid #000;">
              <button style="flex: 1; background: #a855f7; color: white; border: none; padding: 0; height: 55px; border-radius: 8px; font-weight: 800; font-size: 0.95rem; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.5rem;">
                <img src="${comp.data.atkIcon}" style="width: 22px; height: 22px; object-fit: contain;" onerror="this.style.display='none'">
                ${comp.data.atkText}
              </button>
              <button style="flex: 1; background: #fde047; color: black; border: none; padding: 0; height: 55px; border-radius: 8px; font-weight: 800; font-size: 0.95rem; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.5rem;">
                <img src="${comp.data.defIcon}" style="width: 22px; height: 22px; object-fit: contain;" onerror="this.style.display='none'">
                ${comp.data.defText}
              </button>
            </div>
          </div>
        `;
      } else if (comp.id === 'defense-cover-btn') {
        stageContent = `
          <div style="width: 100%; display: flex; justify-content: center; background: #0b0710; padding: 2rem 0; border-radius: 8px;">
            <div style="display: flex; gap: 0.5rem; width: 100%; max-width: 380px; background: #130a1e; padding: 1rem 0.5rem; border-radius: 20px; align-items: center; border: 1px solid rgba(255,255,255,0.05); border-bottom: 4px solid #000;">
              <div style="background: #151816; border: 1px solid #253327; border-radius: 12px; padding: 0.4rem 0.75rem; display: flex; align-items: center; gap: 1rem;">
                <div style="width: 26px; height: 26px; border-radius: 50%; border: 1.5px solid #4ade80; display: flex; align-items: center; justify-content: center; color: #4ade80; font-size: 1.2rem; cursor: pointer;">-</div>
                <div style="display: flex; flex-direction: column; align-items: center; line-height: 1;">
                  <span style="color: #4ade80; font-size: 0.65rem; font-weight: bold; letter-spacing: 1px;">ATK</span>
                  <span style="color: #4ade80; font-size: 1.3rem; font-weight: 900; margin-top: 2px;">${comp.data.atkValue}</span>
                </div>
                <div style="width: 26px; height: 26px; border-radius: 50%; border: 1.5px solid #4ade80; display: flex; align-items: center; justify-content: center; color: #4ade80; font-size: 1.2rem; cursor: pointer;">+</div>
              </div>
              <button style="flex: 1; background: #fde047; color: black; border: none; padding: 0; height: 48px; border-radius: 8px; font-weight: 700; font-size: 0.95rem; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 0.5rem;">
                ${comp.data.tokenIcon ? `<img src="${comp.data.tokenIcon}" style="width: 20px; height: 20px; object-fit: contain;" onerror="this.style.display='none'">` : ''}
                ${comp.data.text}
              </button>
              <button style="background: #a855f7; color: white; border: none; padding: 0 1rem; height: 48px; border-radius: 12px; font-weight: 800; font-size: 1.1rem; cursor: pointer;">
                ${comp.data.btnOkText}
              </button>
            </div>
          </div>
        `;
      } else if (comp.id === 'token-modifier-bar') {
        stageContent = `
          <div style="width: 100%; display: flex; flex-direction: column; gap: 0.5rem; background: #0b0710; padding: 1.5rem; border-radius: 8px;">
            ${(comp.data.tokens || []).map(t => `
              <div style="display: flex; align-items: center; background: #271830; border: 1.2px solid #8f43ff; border-radius: 8px; padding: 0.5rem 0.75rem; color: white; font-family: sans-serif;">
                <div style="width: 24px; height: 24px; border-radius: 4px; overflow: hidden; margin-right: 0.5rem; flex-shrink: 0; box-shadow: 0 1px 3px rgba(0,0,0,0.4);">
                  <img src="../assets/personnages/Barbarian.png" style="width: 100%; height: 100%; object-fit: cover;" onerror="this.src='../assets/enemy_previews/bleu-001.webp'">
                </div>
                <img src="${t.icon}" style="width: 22px; height: 22px; object-fit: contain; margin-right: 0.5rem;" onerror="this.outerHTML='<span style=\\'font-size:1.2rem; margin-right:0.5rem;\\'>🔥</span>'">
                <span style="font-size: 0.85rem; font-weight: bold;">${t.name} : </span>
                <span style="font-size: 0.85rem; font-weight: 900; color: #8f43ff; margin-left: 0.25rem;">${t.modifier}</span>
                <div style="flex-grow: 1;"></div>
                <div style="display: flex; align-items: center; background: rgba(0,0,0,0.2); padding: 0.2rem 0.5rem; border-radius: 4px;">
                  <span style="color: #8f43ff; font-size: 0.8rem; margin-right: 0.25rem;">✔</span>
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
              <div style="position: absolute; top: -50px; left: 50%; transform: translateX(-50%); width: 200px; height: 100px; background: radial-gradient(circle, rgba(155, 81, 224, 0.4) 0%, transparent 70%); border-radius: 50%;"></div>
              <div style="position: absolute; top: 12px; right: 12px; cursor: pointer; color: #9ca3af; font-size: 1.2rem; line-height: 1;">&times;</div>
              <div style="margin: 0 auto 1rem; width: 80px; height: 80px; border-radius: 50%; background: #1a2035; box-shadow: 0 0 35px rgba(155,81,224,0.7); display: flex; align-items: center; justify-content: center; border: 2px solid rgba(255,255,255,0.1);">
                <img src="${comp.data.icon}" alt="icon" style="width: 60px; height: 60px; object-fit: contain;" onerror="this.outerHTML='<span style=\\'font-size:3rem;color:white;font-weight:bold;\\'>☠️</span>'">
              </div>
              <h3 style="margin: 0 0 0.25rem 0; font-size: 1.2rem; font-weight: 700; position:relative; z-index:2;">${comp.data.title}</h3>
              <div style="color: #a78bfa; font-size: 0.8rem; margin-bottom: 1.2rem; position:relative; z-index:2;">${comp.data.subtitle}</div>
              <div style="background: #231b2e; border-radius: 8px; padding: 0.75rem; font-size: 0.8rem; color: #d1d5db; margin-bottom: 1rem; position:relative; z-index:2; text-align: left; line-height: 1.45;">
                ${comp.data.descriptionText}
              </div>
              <div style="background: #1f162c; border: 1px solid rgba(155, 81, 224, 0.5); border-radius: 8px; padding: 0.8rem; font-size: 0.95rem; font-weight: bold; color: white; margin-bottom: 1.25rem; position:relative; z-index:2; display:flex; justify-content:center; align-items:center; gap:0.5rem; box-shadow: inset 0 2px 4px rgba(0,0,0,0.3);">
                ${comp.data.resultText}
              </div>
              <div style="display: flex; gap: 0.75rem; width: 100%; justify-content: center; position:relative; z-index:2;">
                <button style="background: transparent; color: white; border: 1px solid rgba(255,255,255,0.7); padding: 0.5rem 1.2rem; border-radius: 20px; font-weight: 600; font-size: 0.85rem; cursor: pointer; display: flex; align-items: center; gap: 0.4rem;">
                  <span style="font-size: 1rem; line-height: 1;">✏️</span> ${comp.data.btnEditText}
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
              <div style="position: absolute; top: -50px; left: 50%; transform: translateX(-50%); width: 200px; height: 100px; background: radial-gradient(circle, rgba(155, 81, 224, 0.4) 0%, transparent 70%); border-radius: 50%;"></div>
              <div style="position: absolute; top: 12px; right: 12px; cursor: pointer; color: #9ca3af; font-size: 1.2rem; line-height: 1;">&times;</div>
              <div style="margin: 0 auto 1rem; width: 80px; height: 80px; border-radius: 50%; background: #5a0000; box-shadow: 0 0 35px rgba(155,81,224,0.7); display: flex; align-items: center; justify-content: center; border: 2px solid rgba(255,255,255,0.1);">
                <img src="${comp.data.icon}" alt="icon" style="width: 60px; height: 60px; object-fit: contain;" onerror="this.outerHTML='<span style=\\'font-size:3rem;color:white;font-weight:bold;\\'>↺</span>'">
              </div>
              <h3 style="margin: 0 0 0.25rem 0; font-size: 1.2rem; font-weight: 700; position:relative; z-index:2;">${comp.data.title}</h3>
              <div style="color: #a78bfa; font-size: 0.8rem; margin-bottom: 1.2rem; position:relative; z-index:2;">${comp.data.subtitle}</div>
              <div style="background: #231b2e; border-radius: 8px; padding: 0.75rem; font-size: 0.85rem; color: #d1d5db; margin-bottom: 1.2rem; position:relative; z-index:2;">
                ${comp.data.descriptionText}
              </div>
              <button style="background: #a855f7; color: white; border: none; padding: 0.5rem 2rem; border-radius: 20px; font-weight: bold; font-size: 0.9rem; cursor: pointer; width: 120px; box-shadow: 0 4px 10px rgba(168,85,247,0.4); position:relative; z-index:2;">
                ${comp.data.buttonText}
              </button>
            </div>
          </div>
        `;
      } else {
        stageContent = `
          <div style="padding: 2.5rem 1rem; text-align: center; color: var(--text-muted); font-style: italic; background: rgba(0,0,0,0.3); border-radius: 8px;">
            ${comp.title} (Emplacement réservé)
          </div>
        `;
      }

      card.innerHTML = `
        <div class="component-header">
          <div>
            <div class="component-category">${comp.category || 'UI Module'}</div>
            <div class="component-title">${comp.title || comp.id}</div>
          </div>
        </div>
        <div class="component-stage">
          ${stageContent}
        </div>
        <div class="component-footer">
          ${comp.description || ''}
        </div>
      `;

      componentsGrid.appendChild(card);
    });
  }
});


// ============================================================
// BUG TAB & SUPABASE RUN LOGS INSPECTOR
// ============================================================
document.addEventListener('DOMContentLoaded', () => {
  const SUPABASE_URL = 'https://rqxfjffwzdfefinfcxjo.supabase.co';
  const SUPABASE_ANON_KEY = 'sb_publishable_3EuoFYUzqUvNX7IPrhZKpQ_mkW-Gl97';
  const ADMIN_EMAIL = 'bdewev18@gmail.com';

  let sbClient = null;
  let allBugRecords = [];
  let selectedBugId = null;
  let detailViewMode = 'chat'; // 'chat' | 'json'
  let enemyProfiles = [];
  let tokenCatalog = [];

  const tabButtons = document.querySelectorAll('.tab-btn');
  const tabPanes = document.querySelectorAll('.tab-pane');
  const bugTabBadge = document.getElementById('bug-tab-badge');
  const authStatusEl = document.getElementById('bug-auth-status');
  const loginBtn = document.getElementById('bug-google-login-btn');
  const refreshBtn = document.getElementById('bug-refresh-btn');
  const logoutBtn = document.getElementById('bug-logout-btn');
  const bugSearchInput = document.getElementById('bug-search-input');
  const bugOnlyCheckbox = document.getElementById('bug-only-checkbox');
  const showArchivedCheckbox = document.getElementById('bug-show-archived-checkbox');
  const ARCHIVED_STORAGE_KEY = 'dts_archived_bug_ids';

  function getLocalArchivedIds() {
    try {
      const raw = localStorage.getItem(ARCHIVED_STORAGE_KEY);
      const arr = raw ? JSON.parse(raw) : [];
      return new Set(Array.isArray(arr) ? arr.map(String) : []);
    } catch (_) {
      return new Set();
    }
  }

  function setLocalArchived(id, archived) {
    const set = getLocalArchivedIds();
    if (archived) set.add(String(id));
    else set.delete(String(id));
    try {
      localStorage.setItem(ARCHIVED_STORAGE_KEY, JSON.stringify([...set]));
    } catch (_) {}
  }

  function isRecordArchived(rec) {
    if (!rec) return false;
    return Boolean(rec.is_archived) || getLocalArchivedIds().has(String(rec.id));
  }

  async function toggleArchiveRecord(rec) {
    const nextArchived = !isRecordArchived(rec);
    rec.is_archived = nextArchived;
    setLocalArchived(rec.id, nextArchived);

    if (sbClient && !String(rec.id).startsWith('manual-')) {
      try {
        await sbClient
          .from('combat_run_logs')
          .update({ is_archived: nextArchived })
          .eq('id', rec.id);
      } catch (_) {
        // Fallback persisted in localStorage
      }
    }

    if (nextArchived && rec.id === selectedBugId && !showArchivedCheckbox?.checked) {
      const nextVisible = allBugRecords.find((r) => !isRecordArchived(r) && (!bugOnlyCheckbox?.checked || r.has_ai_bug));
      selectedBugId = nextVisible ? nextVisible.id : null;
    }

    renderBugList();
    renderBugEnemyPreview();
    renderBugDetail();
  }
  const pasteJsonBtn = document.getElementById('bug-paste-json-btn');
  const pastePanel = document.getElementById('bug-paste-panel');
  const pasteTextarea = document.getElementById('bug-paste-textarea');
  const pasteCancelBtn = document.getElementById('bug-paste-cancel-btn');
  const pasteLoadBtn = document.getElementById('bug-paste-load-btn');
  const bugListPane = document.getElementById('bug-list-pane');
  const bugEnemyPreviewPane = document.getElementById('bug-enemy-preview-pane');
  const bugDetailPane = document.getElementById('bug-detail-pane');

  function escapeHtml(str) {
    return String(str ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function formatAiMessageHtml(msg) {
    if (!msg) return '';
    let html = escapeHtml(msg);
    html = html.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    html = html.replace(/_([^_]+)_/g, '<em>$1</em>');
    html = html.replace(/\{[^}]+\}/g, '');
    return html.trim();
  }

  function phaseLabel(phase) {
    const map = {
      intro: 'Intro',
      heroUpkeep: 'Hero Upkeep',
      hero: 'Hero Roll / Defense',
      minionUpkeep: 'Minion Upkeep',
      minionAttack: 'Minion Roll / Attack',
    };
    return map[phase] || phase || 'Phase';
  }

  // Tab switching
  tabButtons.forEach((btn) => {
    btn.addEventListener('click', () => {
      const target = btn.getAttribute('data-tab');
      tabButtons.forEach((b) => b.classList.toggle('active', b === btn));
      tabPanes.forEach((p) => {
        p.classList.toggle('active', p.id === `tab-${target}`);
      });
    });
  });

  if (window.location.hash === '#bug' || window.location.hash === '#bugs') {
    const bugBtn = document.getElementById('tab-btn-bugs');
    if (bugBtn) bugBtn.click();
  } else if (window.location.hash === '#community') {
    const commBtn = document.getElementById('tab-btn-community');
    if (commBtn) commBtn.click();
  }

  // Paste manual JSON
  if (pasteJsonBtn) {
    pasteJsonBtn.addEventListener('click', () => {
      pastePanel.style.display = pastePanel.style.display === 'none' ? 'block' : 'none';
    });
  }
  if (pasteCancelBtn) {
    pasteCancelBtn.addEventListener('click', () => {
      pastePanel.style.display = 'none';
    });
  }
  if (pasteLoadBtn) {
    pasteLoadBtn.addEventListener('click', () => {
      try {
        const parsed = JSON.parse(pasteTextarea.value);
        const manualRecord = {
          id: `manual-${Date.now()}`,
          user_email: 'Import manuel JSON',
          hero: parsed.run?.hero || 'Héros inconnu',
          enemy_name: parsed.combat?.enemy?.name || 'Ennemi inconnu',
          enemy_rank: parsed.combat?.enemy?.rank || '',
          mode: parsed.run?.mode || '',
          outcome: parsed.outcome || 'in_progress',
          has_ai_bug: Boolean(parsed.hasAiDeselectBug || (parsed.deselectBugCount || 0) > 0),
          deselect_count: parsed.deselectBugCount || 0,
          created_at: parsed.createdAt || new Date().toISOString(),
          run_log_json: parsed,
        };
        allBugRecords = [manualRecord, ...allBugRecords.filter((r) => r.id !== manualRecord.id)];
        selectedBugId = manualRecord.id;
        pastePanel.style.display = 'none';
        renderBugList();
        renderBugEnemyPreview();
        renderBugDetail();
      } catch (err) {
        alert('JSON invalide : ' + err.message);
      }
    });
  }

  if (bugSearchInput) {
    bugSearchInput.addEventListener('input', renderBugList);
  }
  if (bugOnlyCheckbox) {
    bugOnlyCheckbox.addEventListener('change', renderBugList);
  }
  if (showArchivedCheckbox) {
    showArchivedCheckbox.addEventListener('change', () => {
      renderBugList();
      renderBugEnemyPreview();
      renderBugDetail();
    });
  }

  async function loadEnemyAndTokenCatalogs() {
    try {
      const [profilesRes, tokensRes] = await Promise.all([
        fetch('../docs/enemy_profiles.json').catch(() => null),
        fetch('../assets/data/token_catalog.json').catch(() => null),
      ]);
      if (profilesRes && profilesRes.ok) {
        const pJson = await profilesRes.json();
        enemyProfiles = Array.isArray(pJson?.profiles) ? pJson.profiles : [];
      }
      if (tokensRes && tokensRes.ok) {
        const tJson = await tokensRes.json();
        tokenCatalog = Array.isArray(tJson?.tokens) ? tJson.tokens : [];
      }
      renderBugEnemyPreview();
    } catch (_) {
      // ignore catalog load failure
    }
  }

  async function initSupabaseBugs() {
    loadEnemyAndTokenCatalogs();
    if (!window.supabase) {
      if (authStatusEl) authStatusEl.textContent = 'SDK Supabase non chargé (mode inspection JSON manuel disponible).';
      return;
    }
    sbClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

    if (loginBtn) {
      loginBtn.onclick = async () => {
        try {
          authStatusEl.textContent = 'Connexion Google en cours...';
          const { error } = await sbClient.auth.signInWithOAuth({
            provider: 'google',
            options: {
              redirectTo: window.location.origin + window.location.pathname + '#bugs',
            },
          });
          if (error) authStatusEl.textContent = 'Erreur : ' + error.message;
        } catch (err) {
          authStatusEl.textContent = 'Erreur : ' + err.message;
        }
      };
    }

    if (refreshBtn) {
      refreshBtn.onclick = () => fetchCombatLogs();
    }

    if (logoutBtn) {
      logoutBtn.onclick = async () => {
        await sbClient.auth.signOut();
      };
    }

    sbClient.auth.onAuthStateChange((_event, session) => {
      updateAuthUi(session);
    });

    try {
      const { data: { session } } = await sbClient.auth.getSession();
      updateAuthUi(session);
    } catch (err) {
      if (authStatusEl) authStatusEl.textContent = 'Session indisponible : ' + err.message;
    }
  }

  function updateAuthUi(session) {
    updateCommunityAuthUi(session);
    if (!session) {
      if (authStatusEl) authStatusEl.textContent = 'Non connecté. Connectez-vous en Admin pour lire les bugs Supabase.';
      if (loginBtn) loginBtn.style.display = 'inline-flex';
      if (refreshBtn) refreshBtn.style.display = 'none';
      if (logoutBtn) logoutBtn.style.display = 'none';
      return;
    }
    const email = session.user?.email || '';
    if (email !== ADMIN_EMAIL) {
      if (authStatusEl) authStatusEl.textContent = `Connecté (${email}) — Accès restreint à ${ADMIN_EMAIL} pour tous les bugs.`;
    } else {
      if (authStatusEl) authStatusEl.textContent = `Connecté en Admin (${email})`;
    }
    if (loginBtn) loginBtn.style.display = 'none';
    if (refreshBtn) refreshBtn.style.display = 'inline-flex';
    if (logoutBtn) logoutBtn.style.display = 'inline-flex';
    fetchCombatLogs();
  }

  async function fetchCombatLogs() {
    if (!sbClient || !bugListPane) return;
    bugListPane.innerHTML = '<div class="bug-empty-state">Chargement des rapports depuis Supabase...</div>';
    try {
      const { data, error } = await sbClient
        .from('combat_run_logs')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(200);

      if (error) {
        bugListPane.innerHTML = `
          <div class="bug-empty-state" style="color:#fca5a5;">
            Erreur Supabase : ${escapeHtml(error.message)}<br>
            <small style="color:var(--text-secondary);">Assurez-vous que la table <code>combat_run_logs</code> est créée (voir <code>supabase/schema.sql</code>).</small>
          </div>
        `;
        return;
      }

      const manualEntries = allBugRecords.filter((r) => String(r.id).startsWith('manual-'));
      allBugRecords = [...manualEntries, ...(data || [])];
      updateBugBadge();
      if (!selectedBugId && allBugRecords.length > 0) {
        const firstActiveBug = allBugRecords.find((r) => !isRecordArchived(r) && r.has_ai_bug)
          || allBugRecords.find((r) => !isRecordArchived(r));
        selectedBugId = firstActiveBug ? firstActiveBug.id : null;
      }
      renderBugList();
      renderBugEnemyPreview();
      renderBugDetail();
    } catch (err) {
      bugListPane.innerHTML = `<div class="bug-empty-state" style="color:#fca5a5;">Erreur réseau : ${escapeHtml(err.message)}</div>`;
    }
  }

  function updateBugBadge() {
    if (!bugTabBadge) return;
    const bugCount = allBugRecords.filter((r) => r.has_ai_bug && !isRecordArchived(r)).length;
    bugTabBadge.textContent = String(bugCount);
  }

  function rankColorHex(rank) {
    const map = {
      green: '#34d36d',
      blue: '#3bb9ff',
      violet: '#9b58ff',
      orange: '#ff8a2b',
      viseer: '#ff8a2b',
      naraxus: '#d51f2a',
    };
    return map[String(rank || '').toLowerCase()] || '#9ca3af';
  }

  function epTokenIcon(name) {
    const needle = String(name || '').toLowerCase().trim();
    const tok = tokenCatalog.find((t) =>
      [t.label, t.frLabel, ...(t.aliases || [])]
        .filter(Boolean)
        .some((v) => String(v).toLowerCase() === needle)
    );
    if (!tok?.imageAsset) return '';
    return `<img class="ep-token-img" src="../${escapeHtml(tok.imageAsset)}" alt="${escapeHtml(name)}" onerror="this.style.display='none';">`;
  }

  function epSymIcons(face, count = 0) {
    const n = Number(count) || 0;
    if (n <= 0) return '';
    const srcMap = {
      white: '../assets/dice_faces/symbol_white.webp',
      orange: '../assets/dice_faces/symbol_orange.webp',
      red: '../assets/dice_faces/symbol_red.webp',
    };
    const src = srcMap[face] || srcMap.white;
    return Array.from({ length: n })
      .map(() => `<img class="ep-die-sym" src="${src}" alt="${escapeHtml(face)}">`)
      .join('');
  }

  function epConditionHtml(condition = {}) {
    if (!condition) return '';
    const prefix = condition.repeat ? '<span style="font-weight:900;">x</span>' : '';
    if (condition.type === 'suite') {
      return `${prefix}<span class="ep-chip">${escapeHtml(condition.suite || 'suite')} ${escapeHtml(condition.length || '')}</span>`;
    }
    if (condition.type === 'number') {
      return `${prefix}<span class="ep-die-num">${escapeHtml(condition.value ?? '?')}</span>`;
    }
    if (condition.type === 'any') {
      return `${prefix}<span class="ep-chip">Any</span>`;
    }
    if (condition.type === 'text') {
      return `${prefix}<span class="ep-chip">Text</span>`;
    }
    const syms = condition.symbols || {};
    const orWO = condition.orWhiteOrange || syms.orWhiteOrange;
    const orOR = condition.orOrangeRed || syms.orOrangeRed;
    const parts = [];
    const w = epSymIcons('white', syms.white);
    const o = epSymIcons('orange', syms.orange ?? syms.yellow);
    const r = epSymIcons('red', syms.red);
    if (w) parts.push(w);
    if (orWO && w && o) parts.push('<span style="font-size:0.65rem;color:var(--text-muted);font-weight:800;">or</span>');
    if (o) parts.push(o);
    if (orOR && o && r) parts.push('<span style="font-size:0.65rem;color:var(--text-muted);font-weight:800;">or</span>');
    if (r) parts.push(r);
    return `${prefix}${parts.join('')}`;
  }

  function epEffectHtml(eff = {}) {
    const bits = [];
    if (Array.isArray(eff.tokens) && eff.tokens.length) {
      const counts = {};
      eff.tokens.forEach((t) => { counts[t] = (counts[t] || 0) + 1; });
      Object.entries(counts).forEach(([tok, cnt]) => {
        const pfx = cnt > 1 ? `${cnt}x ` : '';
        bits.push(`<span class="ep-chip">${pfx}${epTokenIcon(tok)}${escapeHtml(tok)}</span>`);
      });
    }
    if (eff.damage) bits.push(`<span class="ep-badge ${eff.undefendable ? 'undef' : 'damage'}">${escapeHtml(eff.damage)} DMG</span>`);
    if (eff.prevent) bits.push(`<span class="ep-badge prevent">🛡️ ${escapeHtml(eff.prevent)}</span>`);
    if (eff.returnDamage) bits.push(`<span class="ep-badge ${eff.undefendable ? 'undef' : 'damage'}">↩ ${escapeHtml(eff.returnDamage)}</span>`);
    if (eff.stealHp) bits.push(`<span class="ep-badge heal">Steal ${escapeHtml(eff.stealHp)} HP</span>`);
    if (eff.loseHp) bits.push(`<span class="ep-badge losehp">-${escapeHtml(eff.loseHp)} HP</span>`);
    if (eff.heal) bits.push(`<span class="ep-badge heal">+${escapeHtml(eff.heal)} HP</span>`);
    if (eff.drawCards) bits.push(`<span class="ep-chip">Draw ${escapeHtml(eff.drawCards)}</span>`);
    if (eff.discardCards) bits.push(`<span class="ep-chip">Discard ${escapeHtml(eff.discardCards)}</span>`);
    if (Array.isArray(eff.formulas) && eff.formulas.length) {
      eff.formulas.forEach((f) => bits.push(`<span class="ep-chip">${escapeHtml(f)}</span>`));
    }
    if (eff.extraRoll?.dice) {
      bits.push(`<span class="ep-chip">🎲 Extra ${escapeHtml(eff.extraRoll.dice)}d</span>`);
    }
    if (Array.isArray(eff.notes) && eff.notes.length) {
      eff.notes.forEach((n) => bits.push(`<span class="ep-chip">${escapeHtml(n)}</span>`));
    }
    return bits.join('') || '<span class="ep-chip">-</span>';
  }

  function epGoalHtml(goal = {}, idx = 0) {
    const syms = goal.symbols || goal;
    const icons = [
      epSymIcons('white', syms.white),
      epSymIcons('orange', syms.orange ?? syms.yellow),
      epSymIcons('red', syms.red),
    ].filter(Boolean).join('');
    const dmg = goal.damage ? `<span class="ep-badge ${goal.undefendable ? 'undef' : 'damage'}">${escapeHtml(goal.damage)}</span>` : '';
    const name = goal.name || goal.label || `Objectif #${idx + 1}`;
    return `
      <div class="ep-row">
        <div class="ep-row-left">
          <span style="color:var(--text-muted);font-weight:800;">#${idx + 1}</span>
          ${icons || `<span class="ep-chip">${escapeHtml(name)}</span>`}
          <span style="color:var(--text-secondary);">${escapeHtml(name)}</span>
        </div>
        <div class="ep-row-right">${dmg}</div>
      </div>
    `;
  }

  function renderBugEnemyPreview() {
    if (!bugEnemyPreviewPane) return;
    const rec = allBugRecords.find((r) => r.id === selectedBugId);
    if (!rec) {
      bugEnemyPreviewPane.innerHTML = '<div class="bug-empty-state" style="padding:1rem;">Sélectionnez un bug ci-dessus pour voir la fiche de l\'ennemi.</div>';
      return;
    }

    const jsonEnemy = rec.run_log_json?.combat?.enemy || {};
    const enemyKey = rec.enemy_key || jsonEnemy.profileKey || '';
    const enemyName = rec.enemy_name || jsonEnemy.name || '';
    const profile = enemyProfiles.find((p) => p.key === enemyKey)
      || enemyProfiles.find((p) => String(p.name || '').toLowerCase() === String(enemyName).toLowerCase());

    if (!profile) {
      bugEnemyPreviewPane.innerHTML = `
        <div class="ep-header">
          <div>
            <div class="ep-title">${escapeHtml(enemyName || 'Ennemi inconnu')}</div>
            <div class="ep-stats">Profil détaillé non trouvé dans <code>docs/enemy_profiles.json</code> (clé: ${escapeHtml(enemyKey || '-')})</div>
          </div>
        </div>
      `;
      return;
    }

    const rankCol = rankColorHex(profile.rank);
    const initTokens = Array.isArray(profile.initialTokens) && profile.initialTokens.length
      ? profile.initialTokens.map((t) => `<span class="ep-chip">${epTokenIcon(t)}${escapeHtml(t)}</span>`).join('')
      : '';

    const styleLabel = profile.attackPlan?.style || 'none';
    const goals = Array.isArray(profile.attackPlan?.goals) ? profile.attackPlan.goals : [];
    const goalsHtml = styleLabel === 'suite'
      ? `<div class="ep-row"><div class="ep-row-left"><span class="ep-chip">Style : Suite (Petite / Grande)</span></div></div>`
      : (goals.length
          ? goals.map((g, idx) => epGoalHtml(g, idx)).join('')
          : `<div class="ep-row"><div class="ep-row-left"><span style="color:var(--text-muted);">Style : ${escapeHtml(styleLabel)}</span></div></div>`);

    const actions = Array.isArray(profile.attackPlan?.actions) ? profile.attackPlan.actions : [];
    const condRules = Array.isArray(profile.attackPlan?.conditionalRules) ? profile.attackPlan.conditionalRules : [];
    const attackRows = [
      ...actions.map((a) => `
        <div class="ep-row">
          <div class="ep-row-left">${epConditionHtml(a.condition)} <strong>${escapeHtml(a.label || '')}</strong></div>
          <div class="ep-row-right">${epEffectHtml(a)}</div>
        </div>
      `),
      ...condRules.map((r) => `
        <div class="ep-row">
          <div class="ep-row-left"><span class="ep-chip">⚙ ${escapeHtml(r.label || 'Condition')}</span></div>
          <div class="ep-row-right">${epEffectHtml(r)}</div>
        </div>
      `),
    ].join('') || (Array.isArray(profile.attacks) ? profile.attacks.map((t) => `<div class="ep-row"><span>${escapeHtml(t)}</span></div>`).join('') : '<div class="ep-row"><span style="color:var(--text-muted);">Aucune attaque</span></div>');

    const defEffects = Array.isArray(profile.defensePlan?.effects) ? profile.defensePlan.effects : [];
    const defenseRows = defEffects.length
      ? defEffects.map((e) => `
          <div class="ep-row">
            <div class="ep-row-left">${epConditionHtml(e.condition)}</div>
            <div class="ep-row-right">${epEffectHtml(e)}</div>
          </div>
        `).join('')
      : `<div class="ep-row"><span>${escapeHtml(profile.defense || 'Aucune défense')}</span></div>`;

    const passives = [
      ...(Array.isArray(profile.passives) ? profile.passives : []),
      ...(Array.isArray(profile.attackPlan?.passives) ? profile.attackPlan.passives : []),
    ];
    const passivesHtml = passives.length
      ? `<div class="ep-section"><div class="ep-section-title">✨ Passifs</div>${passives.map((p) => `<div style="font-size:0.74rem;color:var(--text-secondary);">${escapeHtml(p.text || p)}</div>`).join('')}</div>`
      : '';

    bugEnemyPreviewPane.innerHTML = `
      <div class="ep-header">
        <img class="ep-thumb" src="../${escapeHtml(profile.cardAsset)}" alt="${escapeHtml(profile.name)}" onerror="this.style.display='none';">
        <div style="flex:1; min-width:0;">
          <div class="ep-title">
            <span>${escapeHtml(profile.name)}</span>
            <span class="ep-rank-pill" style="color:${rankCol};">${escapeHtml(profile.rank)}</span>
          </div>
          <div class="ep-stats">
            <span>❤️ ${escapeHtml(profile.maxHealth)} HP</span>
            <span>⚡ ${escapeHtml(profile.cp)} CP</span>
            <span>🎲 Atk ${escapeHtml(profile.attackDice || 5)} / Def ${escapeHtml(profile.defenseDice || 0)}</span>
          </div>
          ${initTokens ? `<div style="display:flex;gap:0.3rem;flex-wrap:wrap;margin-top:0.3rem;">${initTokens}</div>` : ''}
        </div>
      </div>

      <div class="ep-section">
        <div class="ep-section-title">🎯 Objectif de Roll (${escapeHtml(styleLabel)})</div>
        ${goalsHtml}
      </div>

      <div class="ep-section">
        <div class="ep-section-title">⚔️ Attaque</div>
        ${attackRows}
      </div>

      <div class="ep-section">
        <div class="ep-section-title">🛡️ Défense (${escapeHtml(profile.defenseDice || 0)} dés)</div>
        ${defenseRows}
      </div>

      ${passivesHtml}
    `;
  }

  function renderBugList() {
    if (!bugListPane) return;
    updateBugBadge();

    const q = (bugSearchInput?.value || '').toLowerCase().trim();
    const bugsOnly = Boolean(bugOnlyCheckbox?.checked);
    const showArchived = Boolean(showArchivedCheckbox?.checked);

    const filtered = allBugRecords.filter((rec) => {
      const archived = isRecordArchived(rec);
      if (!showArchived && archived) return false;
      if (bugsOnly && !rec.has_ai_bug) return false;
      if (!q) return true;
      const hay = `${rec.user_email || ''} ${rec.hero || ''} ${rec.enemy_name || ''} ${rec.mode || ''} ${rec.outcome || ''}`.toLowerCase();
      return hay.includes(q);
    });

    if (filtered.length === 0) {
      bugListPane.innerHTML = `<div class="bug-empty-state">${bugsOnly ? 'Aucun bug actif de désélection IA.' : 'Aucun combat trouvé.'}</div>`;
      return;
    }

    bugListPane.innerHTML = '';
    filtered.forEach((rec) => {
      const archived = isRecordArchived(rec);
      const item = document.createElement('div');
      item.className = `bug-list-item ${rec.id === selectedBugId ? 'selected' : ''} ${archived ? 'archived' : ''}`;
      const dateStr = rec.created_at ? new Date(rec.created_at).toLocaleString('fr-FR') : '-';
      const bugBadge = rec.has_ai_bug
        ? `<span class="bug-pill bug-pill-danger">🐛 ${rec.deselect_count || 1} désélection(s)</span>`
        : `<span class="bug-pill bug-pill-ok">✓ Aucun bug</span>`;
      const archivedBadge = archived
        ? `<span class="bug-pill bug-pill-archived">📦 Historisé</span>`
        : '';

      item.innerHTML = `
        <div class="bug-item-top">
          <span class="bug-matchup">${escapeHtml(rec.hero)} vs ${escapeHtml(rec.enemy_name)}</span>
          <div style="display:flex;gap:0.3rem;align-items:center;flex-wrap:wrap;">
            ${archivedBadge}
            ${bugBadge}
          </div>
        </div>
        <div class="bug-item-meta">
          <span>👤 ${escapeHtml(rec.user_email || 'Guest')}</span>
          <span>🏁 ${escapeHtml(rec.outcome || '-')}</span>
        </div>
        <div class="bug-item-meta">
          <span>🕒 ${escapeHtml(dateStr)}</span>
          ${rec.mode ? `<span>🎮 ${escapeHtml(rec.mode)}</span>` : ''}
        </div>
        <div class="bug-item-actions">
          <button type="button" class="bug-archive-btn" title="${archived ? 'Restaurer ce bug' : 'Historiser (archiver) ce bug'}">
            ${archived ? '↩️ Restaurer' : '📦 Historiser'}
          </button>
        </div>
      `;

      const archiveBtn = item.querySelector('.bug-archive-btn');
      if (archiveBtn) {
        archiveBtn.onclick = (e) => {
          e.stopPropagation();
          toggleArchiveRecord(rec);
        };
      }

      item.onclick = () => {
        selectedBugId = rec.id;
        renderBugList();
        renderBugEnemyPreview();
        renderBugDetail();
      };
      bugListPane.appendChild(item);
    });
  }

  function faceImgHtml(val, inline = false) {
    const num = Number(val);
    if (!Number.isInteger(num) || num < 1 || num > 6) {
      return `<span>🎲 ${escapeHtml(val ?? '-')}</span>`;
    }
    const cls = inline ? 'ai-die-img-inline' : 'ai-die-img';
    return `<img class="${cls}" src="../assets/dice_faces/face_${num}.webp" alt="Dé ${num}" onerror="this.outerHTML='<span>🎲 ${num}</span>';">`;
  }

  function renderDiceStrip(dice, highlightDeselectedIds = []) {
    if (!Array.isArray(dice) || dice.length === 0) return '';
    const chips = dice.map((d) => {
      const val = d.value == null ? '-' : d.value;
      const isDeselected = highlightDeselectedIds.includes(d.id);
      const cls = isDeselected ? 'deselected' : (d.reserved ? 'reserved' : '');
      const tag = isDeselected
        ? '🐛 Désél.'
        : (d.reserved ? '🔒 Gardé' : (d.locked ? '🔐 Cube' : `#${d.id}`));
      return `
        <div class="ai-die-chip ${cls}" title="Dé #${d.id} : valeur ${val}">
          ${faceImgHtml(val, false)}
          <span class="ai-die-tag">${tag}</span>
        </div>
      `;
    }).join('');
    return `<div class="ai-dice-strip">${chips}</div>`;
  }

  function renderChatTimeline(json) {
    const timeline = Array.isArray(json.timeline) ? json.timeline : [];
    if (timeline.length === 0) {
      const logs = Array.isArray(json.run?.logs) ? json.run.logs : [];
      if (logs.length === 0) {
        return '<div class="bug-empty-state">Aucune étape de timeline ou log disponible dans ce JSON.</div>';
      }
      return `
        <div class="ai-chat-timeline">
          ${logs.map((line, i) => {
            const isBug = String(line).includes('[AI_DESELECT_BUG]');
            return `
              <div class="ai-step-card ${isBug ? 'is-bug' : ''}">
                <div class="ai-step-header">
                  <span class="ai-badge">#${i + 1}</span>
                  ${isBug ? '<span class="ai-badge ai-badge-bug">🐛 BUG DÉSÉLECTION IA</span>' : ''}
                </div>
                <div class="ai-chat-bubble">${escapeHtml(line)}</div>
              </div>
            `;
          }).join('')}
        </div>
      `;
    }

    const cardsHtml = timeline.map((step) => {
      const type = step.type || 'step';
      const isBug = type === 'ai_deselect_bug';
      const isEdit = type === 'dice_edit';
      const isReroll = type === 'dice_reroll_one';
      const cardClass = isBug ? 'is-bug' : (isEdit ? 'is-edit' : (isReroll ? 'is-reroll' : ''));

      let typeBadge = '';
      let calloutHtml = '';
      let deselectedIds = [];

      if (type === 'combat_start') {
        typeBadge = '<span class="ai-badge">⚔️ Début du combat</span>';
      } else if (type === 'phase_change') {
        typeBadge = '<span class="ai-badge">➡️ Changement de phase</span>';
      } else if (type === 'dice_roll') {
        typeBadge = `<span class="ai-badge">🎲 Lancer ${step.rollCount || 0}/${step.maxRolls || 0}</span>`;
      } else if (isEdit) {
        typeBadge = '<span class="ai-badge ai-badge-edit">✏️ Édition dé</span>';
        calloutHtml = `<div class="ai-event-callout edit">✏️ Édition manuelle : Dé #${escapeHtml(step.dieId)} ${faceImgHtml(step.oldValue, true)} ➔ ${faceImgHtml(step.newValue, true)}</div>`;
      } else if (isReroll) {
        typeBadge = '<span class="ai-badge ai-badge-reroll">🔄 Relance 1 dé</span>';
        calloutHtml = `<div class="ai-event-callout reroll">🔄 Relance spéciale : Dé #${escapeHtml(step.dieId)} ${faceImgHtml(step.oldValue, true)} ➔ ${faceImgHtml(step.newValue, true)}</div>`;
      } else if (isBug) {
        typeBadge = '<span class="ai-badge ai-badge-bug">🐛 BUG DÉSÉLECTION IA</span>';
        const desList = Array.isArray(step.deselectedDice) ? step.deselectedDice : [];
        deselectedIds = desList.map((d) => d.id);
        const desc = desList.map((d) => `Dé #${escapeHtml(d.id)} ${faceImgHtml(d.value, true)}`).join(' , ');
        calloutHtml = `<div class="ai-event-callout bug">🐛 BUG SIGNALÉ : L'utilisateur a désélectionné ${desc || 'un dé'} réservé par l'IA !</div>`;
      } else if (type === 'combat_end') {
        typeBadge = `<span class="ai-badge">🏁 Fin : ${escapeHtml(step.outcome || '')}</span>`;
      }

      const aiMsgHtml = formatAiMessageHtml(step.aiMessage);
      const diceHtml = renderDiceStrip(step.dice, deselectedIds);
      const timeStr = step.timestamp ? new Date(step.timestamp).toLocaleTimeString('fr-FR') : '';

      return `
        <div class="ai-step-card ${cardClass}">
          <div class="ai-step-header">
            <div class="ai-step-badges">
              <span class="ai-badge">#${escapeHtml(step.seq)}</span>
              <span class="ai-badge ai-badge-phase">${escapeHtml(phaseLabel(step.phase))}</span>
              ${typeBadge}
              ${timeStr ? `<span style="color:var(--text-muted);">${escapeHtml(timeStr)}</span>` : ''}
            </div>
            <div class="ai-vitals-strip">
              🦸 ${escapeHtml(step.heroHp)} HP / ${escapeHtml(step.heroCp)} CP &nbsp;|&nbsp; 👹 ${escapeHtml(step.enemyHp)} HP / ${escapeHtml(step.enemyCp)} CP
            </div>
          </div>
          ${calloutHtml}
          ${aiMsgHtml ? `<div class="ai-chat-bubble">${aiMsgHtml}</div>` : ''}
          ${diceHtml}
        </div>
      `;
    }).join('');

    return `<div class="ai-chat-timeline">${cardsHtml}</div>`;
  }

  function renderBugDetail() {
    if (!bugDetailPane) return;
    const rec = allBugRecords.find((r) => r.id === selectedBugId);
    if (!rec) {
      bugDetailPane.innerHTML = '<div class="bug-empty-state">Sélectionnez un rapport dans la liste pour afficher le détail du combat.</div>';
      return;
    }

    const json = rec.run_log_json || {};
    const prettyJson = JSON.stringify(json, null, 2);
    const dateStr = rec.created_at ? new Date(rec.created_at).toLocaleString('fr-FR') : '-';

    bugDetailPane.innerHTML = `
      <div class="bug-detail-header">
        <div>
          <h3 style="font-size:1.15rem; color:var(--text-primary);">
            ${escapeHtml(rec.hero)} <span style="color:var(--text-muted);">vs</span> ${escapeHtml(rec.enemy_name)}
            ${rec.has_ai_bug ? `<span class="bug-pill bug-pill-danger" style="margin-left:0.5rem;">🐛 ${rec.deselect_count || 1} désélection(s)</span>` : ''}
          </h3>
          <div class="bug-detail-meta-grid">
            <span>👤 Qui : <strong>${escapeHtml(rec.user_email || 'Guest')}</strong></span>
            <span>🎭 Perso : <strong>${escapeHtml(rec.hero)}</strong></span>
            <span>👹 Ennemi : <strong>${escapeHtml(rec.enemy_name)} (${escapeHtml(rec.enemy_rank || '-')})</strong></span>
            <span>🎮 Mode : <strong>${escapeHtml(rec.mode || '-')}</strong></span>
            <span>🏁 Issue : <strong>${escapeHtml(rec.outcome || '-')}</strong></span>
            <span>🕒 Date : <strong>${escapeHtml(dateStr)}</strong></span>
          </div>
        </div>
        <div style="display:flex; gap:0.5rem; align-items:center; flex-wrap:wrap;">
          <div class="bug-view-switch">
            <button class="bug-view-btn ${detailViewMode === 'chat' ? 'active' : ''}" id="btn-view-chat">💬 AI Chat (Étapes)</button>
            <button class="bug-view-btn ${detailViewMode === 'json' ? 'active' : ''}" id="btn-view-json">📄 JSON</button>
          </div>
          <button class="btn btn-sm" id="btn-copy-bug-json">📋 Copier JSON</button>
        </div>
      </div>
      <div id="bug-detail-body">
        ${detailViewMode === 'chat'
          ? renderChatTimeline(json)
          : `<pre class="bug-json-pre">${escapeHtml(prettyJson)}</pre>`}
      </div>
    `;

    const btnChat = document.getElementById('btn-view-chat');
    const btnJson = document.getElementById('btn-view-json');
    const btnCopy = document.getElementById('btn-copy-bug-json');

    if (btnChat) {
      btnChat.onclick = () => {
        detailViewMode = 'chat';
        renderBugDetail();
      };
    }
    if (btnJson) {
      btnJson.onclick = () => {
        detailViewMode = 'json';
        renderBugDetail();
      };
    }
    if (btnCopy) {
      btnCopy.onclick = () => {
        navigator.clipboard.writeText(prettyJson).then(() => {
          btnCopy.textContent = '✅ Copié !';
          setTimeout(() => { btnCopy.textContent = '📋 Copier JSON'; }, 1500);
        });
      };
    }
  }

  // ============================================================
  // COMMUNITY ENEMY PROPOSALS TAB
  // ============================================================
  const commTabBadge = document.getElementById('community-tab-badge');
  const commAuthStatus = document.getElementById('comm-auth-status');
  const commLoginBtn = document.getElementById('comm-google-login-btn');
  const commRefreshBtn = document.getElementById('comm-refresh-btn');
  const commShowRejectedCheckbox = document.getElementById('comm-show-rejected-checkbox');
  const commSearchInput = document.getElementById('comm-search-input');
  const commMinionCountEl = document.getElementById('comm-minion-count');
  const commBossCountEl = document.getElementById('comm-boss-count');
  const commMinionListEl = document.getElementById('comm-minion-list');
  const commBossListEl = document.getElementById('comm-boss-list');
  const commDetailPane = document.getElementById('comm-detail-pane');

  let allCommunityProposals = [];
  let selectedProposalId = null;

  if (commLoginBtn) {
    commLoginBtn.onclick = async () => {
      if (!sbClient) return;
      await sbClient.auth.signInWithOAuth({
        provider: 'google',
        options: {
          redirectTo: window.location.origin + window.location.pathname + '#community',
        },
      });
    };
  }
  if (commRefreshBtn) {
    commRefreshBtn.onclick = () => fetchCommunityProposals();
  }
  if (commShowRejectedCheckbox) {
    commShowRejectedCheckbox.addEventListener('change', () => {
      renderCommunityLists();
      renderCommunityDetail();
    });
  }
  if (commSearchInput) {
    commSearchInput.addEventListener('input', renderCommunityLists);
  }

  function updateCommunityAuthUi(session) {
    if (!session) {
      if (commAuthStatus) commAuthStatus.textContent = 'Non connecté. Connectez-vous en Admin pour gérer les propositions.';
      if (commLoginBtn) commLoginBtn.style.display = 'inline-flex';
      if (commRefreshBtn) commRefreshBtn.style.display = 'none';
      return;
    }
    const email = session.user?.email || '';
    if (commAuthStatus) {
      commAuthStatus.textContent = email === ADMIN_EMAIL
        ? `Connecté en Admin (${email})`
        : `Connecté (${email})`;
    }
    if (commLoginBtn) commLoginBtn.style.display = 'none';
    if (commRefreshBtn) commRefreshBtn.style.display = 'inline-flex';
    fetchCommunityProposals();
  }

  async function fetchCommunityProposals() {
    if (!sbClient || !commMinionListEl || !commBossListEl) return;
    commMinionListEl.innerHTML = '<div class="bug-empty-state" style="padding:1rem;">Chargement...</div>';
    commBossListEl.innerHTML = '<div class="bug-empty-state" style="padding:1rem;">Chargement...</div>';
    try {
      const { data, error } = await sbClient
        .from('community_enemy_proposals')
        .select('*')
        .order('created_at', { ascending: false })
        .limit(200);
      if (error) {
        const msg = `<div class="bug-empty-state" style="color:#fca5a5;padding:1rem;">Erreur : ${escapeHtml(error.message)}</div>`;
        commMinionListEl.innerHTML = msg;
        commBossListEl.innerHTML = msg;
        return;
      }
      allCommunityProposals = data || [];
      if (!selectedProposalId && allCommunityProposals.length > 0) {
        selectedProposalId = allCommunityProposals[0].id;
      }
      renderCommunityLists();
      renderCommunityDetail();
    } catch (err) {
      const msg = `<div class="bug-empty-state" style="color:#fca5a5;padding:1rem;">Erreur réseau : ${escapeHtml(err.message)}</div>`;
      commMinionListEl.innerHTML = msg;
      commBossListEl.innerHTML = msg;
    }
  }

  function rankAssetFor(rank) {
    const map = {
      green: '../assets/map_green.jpg',
      blue: '../assets/map_blue.png',
      violet: '../assets/map_violet.png',
      orange: '../assets/map_orange.png',
    };
    return map[String(rank || '').toLowerCase()] || '../assets/map_green.jpg';
  }

  function rankLabelFor(rank) {
    const map = {
      green: 'Level 1 (Green)',
      blue: 'Level 2 (Blue)',
      violet: 'Level 3 (Violet)',
      orange: 'Level 4 (Orange)',
    };
    return map[String(rank || '').toLowerCase()] || rank || '-';
  }

  function statusBadgeHtml(status) {
    if (status === 'rejected') return '<span class="comm-status-pill comm-status-rejected">❌ Rejeté</span>';
    if (status === 'accepted') return '<span class="comm-status-pill comm-status-accepted">✅ Accepté</span>';
    return '<span class="comm-status-pill comm-status-pending">⏳ En attente</span>';
  }

  async function updateProposalStatus(proposal, newStatus) {
    const prev = proposal.status;
    proposal.status = newStatus;
    renderCommunityLists();
    renderCommunityDetail();
    if (!sbClient) return;
    try {
      const { error } = await sbClient
        .from('community_enemy_proposals')
        .update({ status: newStatus })
        .eq('id', proposal.id);
      if (error) {
        proposal.status = prev;
        renderCommunityLists();
        renderCommunityDetail();
        alert('Erreur mise à jour statut : ' + error.message);
      }
    } catch (err) {
      proposal.status = prev;
      renderCommunityLists();
      renderCommunityDetail();
      alert('Erreur : ' + err.message);
    }
  }

  function renderCommunityListInto(listEl, countEl, items, isBoss) {
    if (!listEl) return;
    if (countEl) countEl.textContent = String(items.length);
    if (items.length === 0) {
      listEl.innerHTML = `<div class="bug-empty-state" style="padding:1rem;">Aucun ${isBoss ? 'boss' : 'minion'} proposé.</div>`;
      return;
    }
    listEl.innerHTML = '';
    items.forEach((p) => {
      const card = document.createElement('div');
      card.className = `bug-list-item ${p.id === selectedProposalId ? 'selected' : ''} ${p.status === 'rejected' ? 'archived' : ''}`;
      const dateStr = p.created_at ? new Date(p.created_at).toLocaleDateString('fr-FR') : '-';
      const iconHtml = isBoss
        ? '<span>🐉</span>'
        : `<img class="comm-rank-icon" src="${rankAssetFor(p.minion_rank)}" alt="${escapeHtml(p.minion_rank || '')}">`;

      card.innerHTML = `
        <div class="bug-item-top">
          <span class="bug-matchup" style="display:flex;align-items:center;gap:0.4rem;">
            ${iconHtml}
            <span>${escapeHtml(p.name)}</span>
          </span>
          ${statusBadgeHtml(p.status)}
        </div>
        <div class="bug-item-meta">
          <span>📧 ${escapeHtml(p.user_email || '-')}</span>
          <span>🕒 ${escapeHtml(dateStr)}</span>
        </div>
        <div class="bug-item-meta">
          <span>❤️ ${escapeHtml(p.hp ?? '-')} HP</span>
          <span>⚡ ${p.cp_infinite ? '∞ Infini' : escapeHtml(p.cp ?? '-')} CP</span>
        </div>
        <div class="bug-item-actions">
          ${p.status !== 'rejected'
            ? '<button type="button" class="bug-archive-btn comm-reject-btn">❌ Rejeter</button>'
            : '<button type="button" class="bug-archive-btn comm-restore-btn">↩️ Remettre en attente</button>'}
        </div>
      `;

      const rejectBtn = card.querySelector('.comm-reject-btn');
      if (rejectBtn) {
        rejectBtn.onclick = (e) => {
          e.stopPropagation();
          updateProposalStatus(p, 'rejected');
        };
      }
      const restoreBtn = card.querySelector('.comm-restore-btn');
      if (restoreBtn) {
        restoreBtn.onclick = (e) => {
          e.stopPropagation();
          updateProposalStatus(p, 'pending');
        };
      }

      card.onclick = () => {
        selectedProposalId = p.id;
        renderCommunityLists();
        renderCommunityDetail();
      };
      listEl.appendChild(card);
    });
  }

  function renderCommunityLists() {
    const q = (commSearchInput?.value || '').toLowerCase().trim();
    const showRejected = Boolean(commShowRejectedCheckbox?.checked);

    const activeCount = allCommunityProposals.filter((p) => p.status !== 'rejected').length;
    if (commTabBadge) commTabBadge.textContent = String(activeCount);

    const filtered = allCommunityProposals.filter((p) => {
      if (!showRejected && p.status === 'rejected') return false;
      if (!q) return true;
      const hay = `${p.name || ''} ${p.user_email || ''} ${p.minion_rank || ''} ${p.description || ''}`.toLowerCase();
      return hay.includes(q);
    });

    const minions = filtered.filter((p) => p.enemy_type === 'minion');
    const bosses = filtered.filter((p) => p.enemy_type === 'boss');

    renderCommunityListInto(commMinionListEl, commMinionCountEl, minions, false);
    renderCommunityListInto(commBossListEl, commBossCountEl, bosses, true);
  }

  function renderCommunityDetail() {
    if (!commDetailPane) return;
    const p = allCommunityProposals.find((x) => x.id === selectedProposalId);
    if (!p) {
      commDetailPane.innerHTML = '<div class="bug-empty-state">Sélectionnez un minion ou un boss proposé à gauche pour consulter tous ses détails.</div>';
      return;
    }

    const isBoss = p.enemy_type === 'boss';
    const dateStr = p.created_at ? new Date(p.created_at).toLocaleString('fr-FR') : '-';
    const typeDisplay = isBoss
      ? '🐉 Boss'
      : `<img class="comm-rank-icon" src="${rankAssetFor(p.minion_rank)}" alt=""> Minion — ${escapeHtml(rankLabelFor(p.minion_rank))}`;

    let imageSectionHtml = '<span style="color:var(--text-muted);">Non renseigné</span>';
    if (p.image_value) {
      if (p.image_mode === 'link') {
        const safeHref = escapeHtml(p.image_value);
        imageSectionHtml = `<a href="${safeHref}" target="_blank" rel="noopener noreferrer" style="color:var(--accent-cyan);word-break:break-all;">🔗 ${safeHref}</a>`;
      } else {
        imageSectionHtml = `
          <div class="comm-detail-text">${escapeHtml(p.image_value)}</div>
          <button type="button" class="btn btn-sm" id="comm-copy-prompt-btn" style="margin-top:0.5rem;">📋 Copier le prompt image</button>
        `;
      }
    }

    commDetailPane.innerHTML = `
      <div class="bug-detail-header">
        <div>
          <h3 style="font-size:1.25rem; color:var(--text-primary); display:flex; align-items:center; gap:0.5rem; flex-wrap:wrap;">
            <span>${escapeHtml(p.name)}</span>
            ${statusBadgeHtml(p.status)}
          </h3>
          <div class="bug-detail-meta-grid">
            <span>📌 Type : <strong>${typeDisplay}</strong></span>
            <span>📧 Email : <strong>${escapeHtml(p.user_email || '-')}</strong></span>
            <span>❤️ HP : <strong>${escapeHtml(p.hp ?? '-')}</strong></span>
            <span>⚡ CP : <strong>${p.cp_infinite ? '∞ Infini' : escapeHtml(p.cp ?? '-')}</strong></span>
            <span>🕒 Date : <strong>${escapeHtml(dateStr)}</strong></span>
          </div>
        </div>
        <div style="display:flex; gap:0.45rem; flex-wrap:wrap;">
          <button type="button" class="btn btn-sm" id="comm-btn-pending">⏳ En attente</button>
          <button type="button" class="btn btn-sm" id="comm-btn-accept" style="border-color:var(--accent-green);color:#6ee7b7;">✅ Accepter</button>
          <button type="button" class="btn btn-sm" id="comm-btn-reject" style="border-color:var(--accent-red);color:#fca5a5;">❌ Rejeter</button>
        </div>
      </div>

      <div class="comm-detail-block">
        <div class="comm-detail-block-title">📝 Description</div>
        <div class="comm-detail-text">${escapeHtml(p.description || 'Aucune description.')}</div>
      </div>

      <div class="comm-detail-block">
        <div class="comm-detail-block-title">${p.image_mode === 'link' ? '🖼️ Lien Image (Drive / URL)' : '🎨 Prompt de génération image'}</div>
        ${imageSectionHtml}
      </div>

      <div class="comm-detail-block">
        <div class="comm-detail-block-title">⚔️ Attaques</div>
        <div class="comm-detail-text">${escapeHtml(p.attacks_text || 'Non renseigné.')}</div>
      </div>

      <div class="comm-detail-block">
        <div class="comm-detail-block-title">✨ Passif (optionnel)</div>
        <div class="comm-detail-text">${escapeHtml(p.passives_text || 'Aucun passif.')}</div>
      </div>

      <div class="comm-detail-block">
        <div class="comm-detail-block-title">🛡️ Défense</div>
        <div class="comm-detail-text">${escapeHtml(p.defense_text || 'Non renseigné.')}</div>
      </div>
    `;

    const btnPending = document.getElementById('comm-btn-pending');
    const btnAccept = document.getElementById('comm-btn-accept');
    const btnReject = document.getElementById('comm-btn-reject');
    const btnCopyPrompt = document.getElementById('comm-copy-prompt-btn');

    if (btnPending) btnPending.onclick = () => updateProposalStatus(p, 'pending');
    if (btnAccept) btnAccept.onclick = () => updateProposalStatus(p, 'accepted');
    if (btnReject) btnReject.onclick = () => updateProposalStatus(p, 'rejected');
    if (btnCopyPrompt) {
      btnCopyPrompt.onclick = () => {
        navigator.clipboard.writeText(p.image_value || '').then(() => {
          btnCopyPrompt.textContent = '✅ Prompt copié !';
          setTimeout(() => { btnCopyPrompt.textContent = '📋 Copier le prompt image'; }, 1500);
        });
      };
    }
  }

  initSupabaseBugs();
});
