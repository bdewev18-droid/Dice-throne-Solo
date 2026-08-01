import json, re

d = json.load(open('docs/enemy_profiles.json', encoding='utf-8'))
verts = [p for p in d['profiles'] if p.get('rank') == 'green']

def strip(s):
    s = s.lower()
    repl = [('à','a'),('â','a'),('ä','a'),('é','e'),('è','e'),('ê','e'),('ë','e'),
            ('î','i'),('ï','i'),('ô','o'),('ö','o'),('û','u'),('ù','u'),('ü','u'),
            ('ç','c'),('œ','oe'),('æ','ae')]
    for a,b in repl: s = s.replace(a,b)
    return s

def extract_dmg_from_text(text):
    """Extract damage values from display text. Returns list of (value, imparable)."""
    t = strip(text)
    results = []
    for m in re.finditer(r'(\d+)\s*(degats|damage)', t):
        val = int(m.group(1))
        rest = t[m.end():m.end()+25]
        imp = 'imparable' in rest or 'undefendable' in rest
        results.append((val, imp))
    return results

def extract_cp(text):
    t = strip(text)
    m = re.search(r'vole\s+(\d+)\s+cp', t)
    if m: return int(m.group(1))
    m = re.search(r'(\d+)\s+cp', t)
    if m: return int(m.group(1))
    return 0

print("ANALYSE DES PROFILS VERTS")
print("Comparaison texte d'affichage <-> JSON attackPlan")
print("="*70)
print()

issues_total = 0
for p in verts:
    k = p['key']
    ap = p.get('attackPlan', {})
    style = ap.get('style')
    attacks = p.get('attacks', [])
    text = '\n'.join(attacks)

    if style == 'none':
        print(f"{k} ({p['name']}) - [none, fallback]")
        print("  (skip: pas de plan d'attaque JSON)")
        print()
        continue

    issues = []

    if style == 'symbols':
        goals = ap.get('goals', [])
        actions = ap.get('actions', [])
        action_map = {}
        for a in actions:
            c = a.get('condition', {})
            if c.get('type') != 'symbols':
                continue
            s = c.get('symbols', {})
            key = (s.get('white',0), s.get('orange', s.get('yellow',0)), s.get('red',0))
            action_map[key] = a

        # Check 1: every goal has an action
        for g in goals:
            gt = (g.get('white',0), g.get('orange', g.get('yellow',0)), g.get('red',0))
            if gt not in action_map:
                issues.append(f"GOAL {gt} SANS ACTION dans JSON (retombe sur fallback texte)")

        # Check 2: damage in JSON matches damage in text
        text_dmgs = extract_dmg_from_text(text)
        sym_actions = [a for a in actions if a.get('condition',{}).get('type')=='symbols']
        json_dmgs = [(a.get('damage',0), a.get('undefendable',False)) for a in sym_actions]

        for a in sym_actions:
            jd = a.get('damage',0)
            ju = a.get('undefendable',False)
            if jd == 0:
                # 0 damage - could be dynamic or missing
                if 'degat' in strip(text) or 'damage' in strip(text):
                    # damage mentioned but 0 in JSON - flag as potential issue
                    c = a.get('condition',{})
                    s = c.get('symbols',{})
                    gt = (s.get('white',0), s.get('orange', s.get('yellow',0)), s.get('red',0))
                    issues.append(f"JSON goal {gt} dmg=0 mais texte mentionne degats (dynamique ou manquant)")
            else:
                found = False
                for td, tu in text_dmgs:
                    if td == jd:
                        found = True
                        if ju and not tu:
                            c = a.get('condition',{})
                            s = c.get('symbols',{})
                            gt = (s.get('white',0), s.get('orange', s.get('yellow',0)), s.get('red',0))
                            issues.append(f"JSON goal {gt} dmg={jd} imparable=True mais texte ne dit pas imparable")
                        if not ju and tu:
                            c = a.get('condition',{})
                            s = c.get('symbols',{})
                            gt = (s.get('white',0), s.get('orange', s.get('yellow',0)), s.get('red',0))
                            issues.append(f"JSON goal {gt} dmg={jd} non-imparable mais texte dit imparable")
                        break
                if not found:
                    c = a.get('condition',{})
                    s = c.get('symbols',{})
                    gt = (s.get('white',0), s.get('orange', s.get('yellow',0)), s.get('red',0))
                    issues.append(f"JSON goal {gt} dmg={jd} {'imparable ' if ju else ''}INTROUVABLE dans le texte")

        # Check 3: tokens in JSON should appear in text
        for a in sym_actions:
            tokens = a.get('tokens', [])
            for tok in tokens:
                tnorm = strip(tok)
                if tnorm and tnorm not in strip(text):
                    issues.append(f"Token JSON '{tok}' absent du texte d'affichage")

        # Check 4: CP steal
        for a in sym_actions:
            cp = a.get('stealCp', 0)
            if cp > 0:
                tcp = extract_cp(text)
                if tcp != cp:
                    issues.append(f"stealCp JSON={cp} vs texte={tcp}")

    elif style == 'suite':
        actions = ap.get('actions', [])
        suite_actions = [a for a in actions if a.get('condition',{}).get('type')=='suite']
        for length in [3,4,5]:
            found = [a for a in suite_actions if a.get('condition',{}).get('length')==length]
            if not found:
                issues.append(f"Suite length={length} MANQUANTE dans JSON (retombe sur fallback texte)")

        text_dmgs = extract_dmg_from_text(text)
        for a in suite_actions:
            jd = a.get('damage',0)
            ju = a.get('undefendable',False)
            length = a.get('condition',{}).get('length')
            if jd > 0:
                found = any(td==jd for td,tu in text_dmgs)
                if not found:
                    issues.append(f"JSON suite len={length} dmg={jd} INTROUVABLE dans le texte")
            if ju:
                if not any(tu for td,tu in text_dmgs):
                    issues.append(f"JSON suite len={length} imparable=True mais texte ne dit pas imparable")

    status = "OK" if not issues else f"{len(issues)} divergence(s)"
    print(f"{k} ({p['name']})")
    print(f"  [{style}] {status}")
    for iss in issues:
        print(f"    - {iss}")
    if issues: issues_total += len(issues)
    print()

print("="*70)
print(f"TOTAL divergences: {issues_total}")
