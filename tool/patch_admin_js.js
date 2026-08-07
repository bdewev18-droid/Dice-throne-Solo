const fs = require('fs');
const path = require('path');

const adminJsPath = path.join(__dirname, '..', 'web', 'admin', 'admin.js');
let code = fs.readFileSync(adminJsPath, 'utf8');

// 1. Authentication Setup
const authCode = `
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
  
  const { data: { session } } = await supabaseClient.auth.getSession();
  checkSession(session);
  
  supabaseClient.auth.onAuthStateChange((event, session) => {
    checkSession(session);
  });
  
  $('googleLoginBtn').onclick = async () => {
    $('authError').textContent = '';
    const { error } = await supabaseClient.auth.signInWithOAuth({
      provider: 'google',
      options: {
        redirectTo: window.location.origin + window.location.pathname
      }
    });
    if (error) $('authError').textContent = error.message;
  };
  
  $('logoutBtn').onclick = async () => {
    await supabaseClient.auth.signOut();
  };
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
`;

// Insert auth code right after DOMContentLoaded
code = code.replace(
  "document.addEventListener('DOMContentLoaded', () => {",
  "document.addEventListener('DOMContentLoaded', () => {\n  initAuth();\n  setupUIEnhancements();\n"
);
code = authCode + '\n' + code;

// 2. Direct Save logic
code = code.replace(
  "async function saveLocalFile() {",
  `async function saveLocalFile() {
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
`
);

// 3. UI Enhancements (Collapse & Highlight)
const uiEnhancementsCode = `
function setupUIEnhancements() {
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
      text = text.replace(/(\\{token:[^}]+\\})/g, '<span class="token-highlight">$1</span>');
      // Ensure trailing newlines render correctly in div
      if (text.endsWith('\\n')) text += ' ';
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
`;

code = code + '\n' + uiEnhancementsCode;

// Call window.bindHighlights() after renderDisplayRows and conditional rules render
code = code.replace(
  "function renderDisplayRowsPreviews() {",
  "function renderDisplayRowsPreviews() {\n  if(window.bindHighlights) window.bindHighlights();\n"
);
code = code.replace(
  "function renderConditionalRules() {",
  "function renderConditionalRules() {\n  if(window.bindHighlights) setTimeout(window.bindHighlights, 50);\n"
);

// Add logic to trigger text regeneration for a single rule
code = code.replace(
  "div.querySelector('.remove-rule').onclick = () => {",
  `div.querySelector('.rule-generate-btn').onclick = () => {
    const generatedRows = buildActionRows(rule.condition, rule.effect);
    rule.displayRows = generatedRows;
    setDirty('enemy');
    renderConditionalRules();
    renderPreview();
  };
  div.querySelector('.remove-rule').onclick = () => {`
);

// Make token catalog show `{token:...}` instead of just the title
code = code.replace(
  `'</div></div></div>' +`,
  `'<div class="token-highlight" style="font-size:12px; margin-top:4px;">{token:' + escapeText(token.label) + '}</div>' + '</div></div></div>' +`
);

fs.writeFileSync(adminJsPath, code);
console.log('admin.js patched.');
