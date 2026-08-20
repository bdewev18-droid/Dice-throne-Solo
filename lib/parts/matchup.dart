part of '../main.dart';

/// ============================================================================
/// SECTION MATCH-UP (Format Tournoi Ban 3.1)
/// ============================================================================

class MatchupSetupPage extends StatefulWidget {
  const MatchupSetupPage({super.key});

  @override
  State<MatchupSetupPage> createState() => _MatchupSetupPageState();
}

class _MatchupSetupPageState extends State<MatchupSetupPage> {
  final List<HeroType> _selectedPlayerHeroes = [];
  final Set<HeroSegment> _selectedSegments = {};
  final Set<int> _selectedComplexities = {1, 2, 3, 4, 5, 6};
  final TextEditingController _searchController = TextEditingController();
  bool _onlyFavorites = false;

  @override
  void initState() {
    super.initState();
    AppSettings.instance.addListener(_handleSettingsChanged);
  }

  @override
  void dispose() {
    AppSettings.instance.removeListener(_handleSettingsChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSettingsChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _toggleHeroSelection(HeroType hero) {
    setState(() {
      if (_selectedPlayerHeroes.contains(hero)) {
        _selectedPlayerHeroes.remove(hero);
      } else {
        if (_selectedPlayerHeroes.length < 3) {
          _selectedPlayerHeroes.add(hero);
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tu as déjà sélectionné 3 héros. Décoche-en un pour changer.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final heroes = HeroType.values
        .where((h) => h != HeroType.benjamin)
        .where((h) => h.label.toLowerCase().contains(query))
        .where((h) => _selectedSegments.isEmpty || h.segments.any(_selectedSegments.contains))
        .where((h) => _selectedComplexities.contains(h.complexity))
        .where((h) => !_onlyFavorites || AppSettings.instance.isFavoriteHero(h))
        .toList();

    // Tri : Favoris en tête, puis alphabétique
    heroes.sort((a, b) {
      final aFav = AppSettings.instance.isFavoriteHero(a);
      final bFav = AppSettings.instance.isFavoriteHero(b);
      if (aFav && !bFav) return -1;
      if (!aFav && bFav) return 1;
      return a.label.compareTo(b.label);
    });

    final isReady = _selectedPlayerHeroes.length == 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Match-up — Ton Trio',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: Colors.black,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.92),
            border: const Border(top: BorderSide(color: Colors.white24)),
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: isReady
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MatchupEnemySelectionPage(
                            playerTrio: List.from(_selectedPlayerHeroes),
                          ),
                        ),
                      );
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff8f43ff),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                isReady
                    ? 'Suivant : Sélection adverse'
                    : 'Sélectionne 3 héros (${_selectedPlayerHeroes.length}/3)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          children: [
            // Bandeau explicatif du format
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xff8f43ff).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xff8f43ff).withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xffc599ff), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Format Tournoi Ban 3.1 : Choisis 3 héros. Il y aura 1 ban, puis un blind pick parmi les 2 restants.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Barre des 3 slots sélectionnés
            _SelectedHeroSlotsBar(
              selectedHeroes: _selectedPlayerHeroes,
              onRemove: (hero) => setState(() => _selectedPlayerHeroes.remove(hero)),
            ),
            const SizedBox(height: 14),

            // Filtres & Recherche
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Rechercher un héros',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  onPressed: () => setState(() => _onlyFavorites = !_onlyFavorites),
                  icon: Icon(
                    _onlyFavorites ? Icons.favorite : Icons.favorite_border,
                    color: _onlyFavorites ? Colors.redAccent : Colors.white70,
                  ),
                  tooltip: 'Favoris uniquement',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: _onlyFavorites
                        ? Colors.redAccent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            HeroSegmentFilters(
              selectedSegments: _selectedSegments,
              myHeroesOnly: false,
              onMyHeroesChanged: (_) {},
              onChanged: (segment, selected) {
                setState(() {
                  if (segment == null) {
                    _selectedSegments.clear();
                  } else if (selected) {
                    _selectedSegments
                      ..clear()
                      ..add(segment);
                  } else {
                    _selectedSegments.remove(segment);
                  }
                });
              },
            ),
            const SizedBox(height: 14),

            // Grille de sélection des héros (Style Rectangulaire Plein Art)
            if (heroes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('Aucun héros trouvé', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.58,
                ),
                itemCount: heroes.length,
                itemBuilder: (context, index) {
                  final hero = heroes[index];
                  final selectedIndex = _selectedPlayerHeroes.indexOf(hero);
                  final isSelected = selectedIndex != -1;
                  final isFav = AppSettings.instance.isFavoriteHero(hero);

                  return _MatchupHeroPickerCard(
                    hero: hero,
                    isSelected: isSelected,
                    selectionIndex: isSelected ? selectedIndex + 1 : null,
                    isFavorite: isFav,
                    onTap: () => _toggleHeroSelection(hero),
                    onToggleFavorite: () {
                      AppSettings.instance.toggleFavoriteHero(hero);
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// Carte de sélection rectangulaire avec grand visuel comme sur le choix des héros
class _MatchupHeroPickerCard extends StatelessWidget {
  const _MatchupHeroPickerCard({
    required this.hero,
    required this.isSelected,
    required this.selectionIndex,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final HeroType hero;
  final bool isSelected;
  final int? selectionIndex;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xffbb67ff) : Colors.white24,
            width: isSelected ? 3.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xff8f43ff).withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Visuel Plein Art Rectangulaire
              Transform.scale(
                scale: hero.imageScale,
                child: Image.asset(
                  hero.asset,
                  fit: BoxFit.cover,
                  alignment: hero.imageAlignment,
                ),
              ),

              // Dégradé sombre pour la lisibilité
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),

              // Badge de complexité
              Positioned(
                top: 8,
                left: 8,
                child: _HeroComplexityBadge(hero: hero),
              ),

              // Bouton Favori
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onToggleFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isFavorite ? Colors.redAccent : Colors.white24,
                      ),
                    ),
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: isFavorite ? Colors.redAccent : Colors.white70,
                    ),
                  ),
                ),
              ),

              // Badge d'ordre de sélection (#1, #2, #3)
              if (isSelected && selectionIndex != null)
                Positioned(
                  top: 8,
                  left: 42,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xff8f43ff),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      '#$selectionIndex',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

              // Nom du héros en bas
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  child: Text(
                    hero.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      color: isSelected ? const Color(0xffd18aff) : Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barre horizontale résumant les 3 héros sélectionnés en cartes rectangulaires
class _SelectedHeroSlotsBar extends StatelessWidget {
  const _SelectedHeroSlotsBar({
    required this.selectedHeroes,
    required this.onRemove,
  });

  final List<HeroType> selectedHeroes;
  final ValueChanged<HeroType> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xff18181f),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TES 3 HÉROS SÉLECTIONNÉS',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${selectedHeroes.length} / 3',
                style: TextStyle(
                  color: selectedHeroes.length == 3 ? const Color(0xff8f43ff) : Colors.white54,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (index) {
              final hero = index < selectedHeroes.length ? selectedHeroes[index] : null;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 0 : 4,
                    right: index == 2 ? 0 : 4,
                  ),
                  child: _HeroSlotCard(
                    slotNumber: index + 1,
                    hero: hero,
                    onTap: hero != null ? () => onRemove(hero) : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _HeroSlotCard extends StatelessWidget {
  const _HeroSlotCard({
    required this.slotNumber,
    required this.hero,
    this.onTap,
  });

  final int slotNumber;
  final HeroType? hero;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (hero == null) {
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline, color: Colors.white24, size: 22),
              const SizedBox(height: 4),
              Text(
                'Héros #$slotNumber',
                style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xff8f43ff), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: hero!.imageScale,
                child: Image.asset(
                  hero!.asset,
                  fit: BoxFit.cover,
                  alignment: hero!.imageAlignment,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xff8f43ff),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#$slotNumber',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white70, size: 12),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    hero!.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// ÉTAPE 2 : CONFIGURATION DES 3 HÉROS ADVERSES (4 MODES + EXPERT)
/// ============================================================================

class MatchupEnemySelectionPage extends StatefulWidget {
  const MatchupEnemySelectionPage({
    required this.playerTrio,
    super.key,
  });

  final List<HeroType> playerTrio;

  @override
  State<MatchupEnemySelectionPage> createState() => _MatchupEnemySelectionPageState();
}

class _MatchupEnemySelectionPageState extends State<MatchupEnemySelectionPage> {
  MatchupMode _selectedMode = MatchupMode.top10;
  bool _expertMode = false;
  final List<HeroType> _manualEnemyTrio = [];

  void _openManualEnemyPicker() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ManualEnemyPickerModal(
          initialSelection: _manualEnemyTrio,
          onDone: (selected) {
            setState(() {
              _manualEnemyTrio
                ..clear()
                ..addAll(selected);
            });
          },
        ),
      ),
    );
  }

  void _launchMatchup() {
    List<HeroType> enemyTrio;

    if (_selectedMode == MatchupMode.free) {
      if (_manualEnemyTrio.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez sélectionner 3 héros adverses en mode libre.')),
        );
        return;
      }
      enemyTrio = List.from(_manualEnemyTrio);
    } else {
      enemyTrio = MatchupData.generateEnemyTrio(
        mode: _selectedMode,
        expert: _expertMode,
        playerTrio: widget.playerTrio,
      );
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MatchupArenaPage(
          playerTrio: widget.playerTrio,
          enemyTrio: enemyTrio,
          mode: _selectedMode,
          expert: _expertMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canLaunch = _selectedMode != MatchupMode.free || _manualEnemyTrio.length == 3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Adverse', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.black,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.92),
            border: const Border(top: BorderSide(color: Colors.white24)),
          ),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: canLaunch ? _launchMatchup : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff8f43ff),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.sports_kabaddi),
              label: const Text(
                'Lancer le Match-up',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            // Rappel du trio joueur en rectangles
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xff1a1a24),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TON TRIO SÉLECTIONNÉ',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: widget.playerTrio.map((h) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _RectangleHeroDisplayCard(hero: h, height: 95),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            const Text(
              'CHOISIS LE MODE DE SÉLECTION ADVERSE',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),

            // Mode Libre
            _MatchupModeOptionCard(
              mode: MatchupMode.free,
              selected: _selectedMode == MatchupMode.free,
              icon: Icons.edit,
              onTap: () => setState(() => _selectedMode = MatchupMode.free),
              extraContent: _selectedMode == MatchupMode.free
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: OutlinedButton.icon(
                        onPressed: _openManualEnemyPicker,
                        icon: const Icon(Icons.touch_app),
                        label: Text(
                          _manualEnemyTrio.isEmpty
                              ? 'Choisir les 3 héros ennemis'
                              : 'Modifier (${_manualEnemyTrio.map((e) => e.label).join(', ')})',
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 10),

            // Mode Aléatoire
            _MatchupModeOptionCard(
              mode: MatchupMode.random,
              selected: _selectedMode == MatchupMode.random,
              icon: Icons.casino,
              onTap: () => setState(() => _selectedMode = MatchupMode.random),
            ),
            const SizedBox(height: 10),

            // Mode Top 10
            _MatchupModeOptionCard(
              mode: MatchupMode.top10,
              selected: _selectedMode == MatchupMode.top10,
              icon: Icons.leaderboard,
              onTap: () => setState(() => _selectedMode = MatchupMode.top10),
            ),
            const SizedBox(height: 10),

            // Mode Top 5
            _MatchupModeOptionCard(
              mode: MatchupMode.top5,
              selected: _selectedMode == MatchupMode.top5,
              icon: Icons.star,
              onTap: () => setState(() => _selectedMode = MatchupMode.top5),
            ),
            const SizedBox(height: 18),

            // Checkbox Mode Expert
            Container(
              decoration: BoxDecoration(
                color: _expertMode ? const Color(0xff3b1e54) : const Color(0xff1c1c24),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _expertMode ? const Color(0xffbb67ff) : Colors.white12,
                  width: _expertMode ? 1.5 : 1,
                ),
              ),
              child: SwitchListTile(
                title: const Row(
                  children: [
                    Icon(Icons.psychology, color: Color(0xffd18aff)),
                    SizedBox(width: 10),
                    Text(
                      'Mode Expert (Synergie & Couverture IA)',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Pour le Top 10 / Top 5, l\'IA compose un trio très fort et complémentaire sans faiblesse statistique.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                value: _expertMode,
                activeTrackColor: const Color(0xffbb67ff),
                onChanged: (val) => setState(() => _expertMode = val),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchupModeOptionCard extends StatelessWidget {
  const _MatchupModeOptionCard({
    required this.mode,
    required this.selected,
    required this.icon,
    required this.onTap,
    this.extraContent,
  });

  final MatchupMode mode;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? extraContent;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? const Color(0xff291d3d) : const Color(0xff18181f),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: selected ? const Color(0xff8f43ff) : Colors.white10,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: selected ? const Color(0xffc599ff) : Colors.white54, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: selected ? Colors.white : Colors.white70,
                          ),
                        ),
                        Text(
                          mode.description,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selected ? const Color(0xff8f43ff) : Colors.white38,
                    size: 22,
                  ),
                ],
              ),
              ?extraContent,
            ],
          ),
        ),
      ),
    );
  }
}

/// Modal pour choisir manuellement les 3 ennemis en mode libre (rectangles)
class _ManualEnemyPickerModal extends StatefulWidget {
  const _ManualEnemyPickerModal({
    required this.initialSelection,
    required this.onDone,
  });

  final List<HeroType> initialSelection;
  final ValueChanged<List<HeroType>> onDone;

  @override
  State<_ManualEnemyPickerModal> createState() => _ManualEnemyPickerModalState();
}

class _ManualEnemyPickerModalState extends State<_ManualEnemyPickerModal> {
  late final List<HeroType> _selected = List.from(widget.initialSelection);
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggle(HeroType hero) {
    setState(() {
      if (_selected.contains(hero)) {
        _selected.remove(hero);
      } else if (_selected.length < 3) {
        _selected.add(hero);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final heroes = HeroType.values
        .where((h) => h != HeroType.benjamin)
        .where((h) => h.label.toLowerCase().contains(query))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    return Scaffold(
      appBar: AppBar(
        title: Text('3 Héros adverses (${_selected.length}/3)'),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _selected.length == 3
                ? () {
                    widget.onDone(_selected);
                    Navigator.of(context).pop();
                  }
                : null,
            child: const Text('Valider', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Rechercher',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.58,
                ),
                itemCount: heroes.length,
                itemBuilder: (context, index) {
                  final hero = heroes[index];
                  final isSel = _selected.contains(hero);
                  final selIndex = _selected.indexOf(hero);
                  return GestureDetector(
                    onTap: () => _toggle(hero),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel ? const Color(0xffbb67ff) : Colors.white12,
                          width: isSel ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Transform.scale(
                              scale: hero.imageScale,
                              child: Image.asset(
                                hero.asset,
                                fit: BoxFit.cover,
                                alignment: hero.imageAlignment,
                              ),
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black87],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: _HeroComplexityBadge(hero: hero),
                            ),
                            if (isSel)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff8f43ff),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '#${selIndex + 1}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                ),
                              ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  hero.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSel ? const Color(0xffd18aff) : Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// ÉTAPE 3 : ARÈNE DE MATCH-UP (DÉS, BAN, BLIND PICK, ANALYSE IA CHAT)
/// ============================================================================

class MatchupArenaPage extends StatefulWidget {
  const MatchupArenaPage({
    required this.playerTrio,
    required this.enemyTrio,
    required this.mode,
    required this.expert,
    super.key,
  });

  final List<HeroType> playerTrio;
  final List<HeroType> enemyTrio;
  final MatchupMode mode;
  final bool expert;

  @override
  State<MatchupArenaPage> createState() => _MatchupArenaPageState();
}

enum _ArenaPhase {
  diceRoll, // Lancer de dé pour la priorité
  priorityChoice, // Le gagnant choisit qui commence à bannir
  banPhase, // Bannissement (1 ban pour chaque camp)
  blindPickPhase, // Choix secret parmi les 2 restants
  revealAndAnalysis, // Révélation et Coaching IA Chat
}

class _MatchupArenaPageState extends State<MatchupArenaPage> {
  _ArenaPhase _phase = _ArenaPhase.diceRoll;

  int? _diceValue;
  bool _playerWonDice = false;
  bool _playerBansFirst = false;

  HeroType? _playerBannedEnemy;
  HeroType? _enemyBannedPlayer;

  HeroType? _playerSelectedHero;
  HeroType? _enemySelectedHero;

  BanAnalysis? _banAnalysis;
  PickAnalysis? _pickAnalysis;

  void _rollDice() {
    final roll = Random().nextInt(6) + 1; // 1 à 6
    setState(() {
      _diceValue = roll;
      // 1, 2, 3 = adversaire gagne; 4, 5, 6 = joueur gagne
      _playerWonDice = roll >= 4;
      _phase = _ArenaPhase.priorityChoice;
    });

    if (!_playerWonDice) {
      final aiWantsToBanFirst = widget.expert ? true : Random().nextBool();
      setState(() {
        _playerBansFirst = !aiWantsToBanFirst;
      });
    }
  }

  void _choosePriority(bool playerFirst) {
    setState(() {
      _playerBansFirst = playerFirst;
      _phase = _ArenaPhase.banPhase;
    });

    if (!_playerBansFirst) {
      _performAiBan();
    }
  }

  void _performAiBan() {
    final aiBan = MatchupData.pickAiBan(
      playerTrio: widget.playerTrio,
      enemyTrio: widget.enemyTrio,
      expert: widget.expert,
    );
    setState(() {
      _enemyBannedPlayer = aiBan;
    });
  }

  void _handlePlayerBan(HeroType enemyHero) {
    if (_playerBannedEnemy != null) return;

    setState(() {
      _playerBannedEnemy = enemyHero;
    });

    if (_enemyBannedPlayer == null) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _performAiBan();
          _checkBansComplete();
        });
      });
    } else {
      _checkBansComplete();
    }
  }

  void _checkBansComplete() {
    if (_playerBannedEnemy != null && _enemyBannedPlayer != null) {
      final enemyRemaining = widget.enemyTrio.where((h) => h != _playerBannedEnemy).toList();
      final playerRemaining = widget.playerTrio.where((h) => h != _enemyBannedPlayer).toList();

      _enemySelectedHero = MatchupData.pickAiHero(
        enemyRemainingTwo: enemyRemaining,
        playerRemainingTwo: playerRemaining,
        expert: widget.expert,
      );

      setState(() {
        _phase = _ArenaPhase.blindPickPhase;
      });
    }
  }

  void _handlePlayerHeroPick(HeroType hero) {
    setState(() {
      _playerSelectedHero = hero;
    });
  }

  void _confirmBlindPick() {
    if (_playerSelectedHero == null || _enemySelectedHero == null) return;

    final enemyRemaining = widget.enemyTrio.where((h) => h != _playerBannedEnemy).toList();
    final playerRemaining = widget.playerTrio.where((h) => h != _enemyBannedPlayer).toList();

    final banAnalysis = MatchupData.analyzePlayerBan(
      bannedEnemy: _playerBannedEnemy!,
      originalEnemyTrio: widget.enemyTrio,
      originalPlayerTrio: widget.playerTrio,
    );

    final pickAnalysis = MatchupData.analyzePlayerPick(
      pickedPlayerHero: _playerSelectedHero!,
      playerRemainingTwo: playerRemaining,
      pickedEnemyHero: _enemySelectedHero!,
      enemyRemainingTwo: enemyRemaining,
    );

    setState(() {
      _banAnalysis = banAnalysis;
      _pickAnalysis = pickAnalysis;
      _phase = _ArenaPhase.revealAndAnalysis;
    });
  }

  void _restartMatchup() {
    setState(() {
      _phase = _ArenaPhase.diceRoll;
      _diceValue = null;
      _playerWonDice = false;
      _playerBansFirst = false;
      _playerBannedEnemy = null;
      _enemyBannedPlayer = null;
      _playerSelectedHero = null;
      _enemySelectedHero = null;
      _banAnalysis = null;
      _pickAnalysis = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Arène Match-up (Ban 3.1)', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recommencer',
            onPressed: _restartMatchup,
          ),
        ],
      ),
      body: SafeArea(
        child: switch (_phase) {
          _ArenaPhase.diceRoll => _buildDiceRollView(),
          _ArenaPhase.priorityChoice => _buildPriorityChoiceView(),
          _ArenaPhase.banPhase => _buildBanPhaseView(),
          _ArenaPhase.blindPickPhase => _buildBlindPickView(),
          _ArenaPhase.revealAndAnalysis => _buildRevealAndAnalysisView(),
        },
      ),
    );
  }

  // ==========================================
  // VUE 1 : LANCER DE DÉ (1-3 vs 4-6)
  // ==========================================
  Widget _buildDiceRollView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xff1a1726),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xff8f43ff), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff8f43ff).withValues(alpha: 0.35),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.casino, size: 70, color: Color(0xffc599ff)),
            ),
            const SizedBox(height: 24),
            const Text(
              'LANCER DE DÉ POUR LA PRIORITÉ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
            const SizedBox(height: 10),
            const Text(
              '🎲 1, 2, 3  =  L\'adversaire décide\n🎲 4, 5, 6  =  Le joueur décide',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _rollDice,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xff8f43ff),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Lancer le dé (1D6)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VUE 2 : DÉCISION DE PRIORITÉ
  // ==========================================
  Widget _buildPriorityChoiceView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Résultat du dé : $_diceValue',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xffffe22d)),
            ),
            const SizedBox(height: 12),
            if (_playerWonDice) ...[
              const Text(
                '🎉 Tu as remporté le lancer !',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.greenAccent),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu peux choisir qui commence à bannir en premier :',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => _choosePriority(true),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff8f43ff)),
                child: const Text('Je bannis en premier'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => _choosePriority(false),
                child: const Text('Je donne la main (l\'adversaire bannit en 1er)'),
              ),
            ] else ...[
              const Text(
                '🤖 L\'adversaire a remporté le lancer !',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.orangeAccent),
              ),
              const SizedBox(height: 12),
              Text(
                _playerBansFirst
                    ? 'L\'adversaire décide de te laisser bannir en premier.'
                    : 'L\'adversaire décide de bannir en premier.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => setState(() {
                  _phase = _ArenaPhase.banPhase;
                  if (!_playerBansFirst) {
                    _performAiBan();
                  }
                }),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff8f43ff)),
                child: const Text('Passer à la phase de ban'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // VUE 3 : PHASE DE BANNISSEMENT (1 ban chacun - Cartes Rectangulaires)
  // ==========================================
  Widget _buildBanPhaseView() {
    final playerNeedsToBan = _playerBannedEnemy == null;
    final isPlayerTurn = _playerBansFirst ? playerNeedsToBan : _enemyBannedPlayer != null && playerNeedsToBan;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Consigne
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xff291d3d),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xff8f43ff)),
          ),
          child: Row(
            children: [
              const Icon(Icons.block, color: Colors.redAccent, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isPlayerTurn
                      ? '👉 C\'est ton tour : Clique sur un héros adverse pour le bannir !'
                      : '⏳ L\'adversaire réfléchit à son ban...',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section Héros Adverses
        const Row(
          children: [
            Icon(Icons.shield, color: Colors.redAccent, size: 18),
            SizedBox(width: 8),
            Text(
              'ÉQUIPE ADVERSE (Clique pour bannir)',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: widget.enemyTrio.map((hero) {
            final isBanned = _playerBannedEnemy == hero;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _BanRectangleCard(
                  hero: hero,
                  isBanned: isBanned,
                  canBan: isPlayerTurn && _playerBannedEnemy == null,
                  onBan: () => _handlePlayerBan(hero),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        // Section Héros Joueur
        const Row(
          children: [
            Icon(Icons.person, color: Color(0xff8f43ff), size: 18),
            SizedBox(width: 8),
            Text(
              'TON ÉQUIPE',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: widget.playerTrio.map((hero) {
            final isBanned = _enemyBannedPlayer == hero;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _BanRectangleCard(
                  hero: hero,
                  isBanned: isBanned,
                  canBan: false,
                  onBan: null,
                ),
              ),
            );
          }).toList(),
        ),

        if (_enemyBannedPlayer != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
            ),
            child: Text(
              '🤖 L\'adversaire a banni : ${_enemyBannedPlayer!.label}',
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  // ==========================================
  // VUE 4 : BLIND PICK AVEC RAPPEL DES 2 RESTANTS DE CHAQUE CÔTÉ
  // ==========================================
  Widget _buildBlindPickView() {
    final playerAvailable = widget.playerTrio.where((h) => h != _enemyBannedPlayer).toList();
    final enemyAvailable = widget.enemyTrio.where((h) => h != _playerBannedEnemy).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xff1f1c2b),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xffbb67ff)),
          ),
          child: const Row(
            children: [
              Icon(Icons.visibility_off, color: Color(0xffd18aff), size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Choix secret : Sélectionne ton combattant parmi tes 2 héros restants.',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Rappel des 2 personnages adverses restants
        Row(
          children: [
            const Icon(Icons.shield, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            const Text(
              '2 HÉROS ADVERSES RESTANTS (Choix secret de l\'IA)',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: enemyAvailable.map((hero) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Transform.scale(
                          scale: hero.imageScale,
                          child: Image.asset(
                            hero.asset,
                            fit: BoxFit.cover,
                            alignment: hero.imageAlignment,
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.lock, size: 11, color: Colors.redAccent),
                                SizedBox(width: 4),
                                Text(
                                  'Restant',
                                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Text(
                              hero.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        // Sélection parmi les 2 héros joueur restants
        Row(
          children: [
            const Icon(Icons.person, color: Color(0xff8f43ff), size: 18),
            const SizedBox(width: 8),
            const Text(
              'TES 2 HÉROS RESTANTS (Clique pour choisir ton héros)',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: playerAvailable.map((hero) {
            final isSelected = _playerSelectedHero == hero;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => _handlePlayerHeroPick(hero),
                  child: Container(
                    height: 170,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xffbb67ff) : Colors.white24,
                        width: isSelected ? 3.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xff8f43ff).withValues(alpha: 0.45),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Transform.scale(
                            scale: hero.imageScale,
                            child: Image.asset(
                              hero.asset,
                              fit: BoxFit.cover,
                              alignment: hero.imageAlignment,
                            ),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black87],
                              ),
                            ),
                          ),
                          if (isSelected)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xff8f43ff),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'CHOISI ✓',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                hero.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xffd18aff) : Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 32),

        FilledButton.icon(
          onPressed: _playerSelectedHero != null ? _confirmBlindPick : null,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xff8f43ff),
            minimumSize: const Size.fromHeight(50),
          ),
          icon: const Icon(Icons.remove_red_eye),
          label: const Text('Révéler la confrontation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }

  // ==========================================
  // VUE 5 : RÉVÉLATION DU FACE-À-FACE & COACHING IA
  // ==========================================
  Widget _buildRevealAndAnalysisView() {
    final playerHero = _playerSelectedHero!;
    final enemyHero = _enemySelectedHero!;
    final directWinrate = _pickAnalysis?.directWinrate;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // Face-à-face en grands rectangles
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff2a1845), Color(0xff1b1424)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xff8f43ff), width: 1.5),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      SizedBox(
                        width: 110,
                        height: 155,
                        child: _RectangleHeroDisplayCard(hero: playerHero, height: 155),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Ton Choix',
                        style: TextStyle(color: Color(0xffc599ff), fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ],
                  ),
                  const Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xffffe22d),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: 110,
                        height: 155,
                        child: _RectangleHeroDisplayCard(hero: enemyHero, height: 155),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Choix Adverse',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),

              // Winrate Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Taux de victoire estimé : ',
                    style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: directWinrate == null
                          ? Colors.grey.withValues(alpha: 0.2)
                          : directWinrate >= 55.0
                          ? Colors.green.withValues(alpha: 0.25)
                          : directWinrate <= 45.0
                          ? Colors.red.withValues(alpha: 0.25)
                          : Colors.amber.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: directWinrate == null
                            ? Colors.grey
                            : directWinrate >= 55.0
                            ? Colors.greenAccent
                            : directWinrate <= 45.0
                            ? Colors.redAccent
                            : Colors.amberAccent,
                      ),
                    ),
                    child: Text(
                      directWinrate != null ? '${directWinrate.toStringAsFixed(1)}%' : 'N/A',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: directWinrate == null
                            ? Colors.grey
                            : directWinrate >= 55.0
                            ? Colors.greenAccent
                            : directWinrate <= 45.0
                            ? Colors.redAccent
                            : Colors.amberAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Zone AI Chat Coach
        _AiChatCoachCard(
          banAnalysis: _banAnalysis!,
          pickAnalysis: _pickAnalysis!,
        ),
        const SizedBox(height: 20),

        // Bouton Réessayer
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Changer de mode'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: _restartMatchup,
                style: FilledButton.styleFrom(backgroundColor: const Color(0xff8f43ff)),
                icon: const Icon(Icons.replay),
                label: const Text('Réessayer'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Carte rectangulaire d'affichage d'un héros plein art
class _RectangleHeroDisplayCard extends StatelessWidget {
  const _RectangleHeroDisplayCard({
    required this.hero,
    required this.height,
  });

  final HeroType hero;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: hero.imageScale,
              child: Image.asset(
                hero.asset,
                fit: BoxFit.cover,
                alignment: hero.imageAlignment,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  hero.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Carte de bannissement visuelle rectangulaire
class _BanRectangleCard extends StatelessWidget {
  const _BanRectangleCard({
    required this.hero,
    required this.isBanned,
    required this.canBan,
    required this.onBan,
  });

  final HeroType hero;
  final bool isBanned;
  final bool canBan;
  final VoidCallback? onBan;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canBan ? onBan : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 155,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isBanned
                ? Colors.redAccent
                : canBan
                ? const Color(0xffbb67ff)
                : Colors.white24,
            width: isBanned ? 2.5 : (canBan ? 2 : 1),
          ),
          boxShadow: canBan && !isBanned
              ? [
                  BoxShadow(
                    color: const Color(0xff8f43ff).withValues(alpha: 0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColorFiltered(
                colorFilter: isBanned
                    ? const ColorFilter.matrix(<double>[
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 0.45, 0,
                      ])
                    : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                child: Transform.scale(
                  scale: hero.imageScale,
                  child: Image.asset(
                    hero.asset,
                    fit: BoxFit.cover,
                    alignment: hero.imageAlignment,
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: _HeroComplexityBadge(hero: hero),
              ),
              if (isBanned)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 6)],
                    ),
                    child: const Text(
                      'BANNI',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                  ),
                ),
              if (canBan && !isBanned)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xff8f43ff),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.touch_app, size: 14, color: Colors.white),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(
                    hero.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isBanned ? Colors.white38 : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte IA Chat Coach présentant l'analyse critique
class _AiChatCoachCard extends StatelessWidget {
  const _AiChatCoachCard({
    required this.banAnalysis,
    required this.pickAnalysis,
  });

  final BanAnalysis banAnalysis;
  final PickAnalysis pickAnalysis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xff161622),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xff4a3b69)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête Coach IA
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xff8f43ff).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffbb67ff)),
                ),
                child: const Icon(Icons.smart_toy, color: Color(0xffd18aff), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'COACHING & ANALYSE TACTIQUE IA',
                  style: TextStyle(
                    color: Color(0xffd18aff),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 12),

          // Diagnostic 1 : Le Ban
          Row(
            children: [
              Icon(
                banAnalysis.isOptimal ? Icons.check_circle : Icons.warning_amber_rounded,
                color: banAnalysis.isOptimal ? Colors.greenAccent : Colors.amberAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                banAnalysis.isOptimal ? 'Analyse du Ban : Optimal' : 'Analyse du Ban : Améliorable',
                style: TextStyle(
                  color: banAnalysis.isOptimal ? Colors.greenAccent : Colors.amberAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            banAnalysis.explanation,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),

          // Diagnostic 2 : Le Choix du Héros
          Row(
            children: [
              Icon(
                pickAnalysis.rating == 'Avantageux'
                    ? Icons.stars
                    : pickAnalysis.rating == 'Équilibré'
                    ? Icons.balance
                    : Icons.report_problem,
                color: pickAnalysis.rating == 'Avantageux'
                    ? Colors.greenAccent
                    : pickAnalysis.rating == 'Équilibré'
                    ? Colors.amberAccent
                    : Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Choix du Héros : ${pickAnalysis.rating}',
                style: TextStyle(
                  color: pickAnalysis.rating == 'Avantageux'
                      ? Colors.greenAccent
                      : pickAnalysis.rating == 'Équilibré'
                      ? Colors.amberAccent
                      : Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pickAnalysis.comment,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
