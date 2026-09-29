void main() {
  bool isRollPhase = false;
  final tokens = ['Cosmic flare', 'Cosmic flare', 'Cosmic flare'];
  final ruleLabel = 'Cosmic flare';

  final tokenKey = ruleLabel.toLowerCase();
  final isCosmicFlare = tokenKey == 'cosmic flare';
  final isUnitary = !isRollPhase;

  final initialCount = ((isUnitary && !isCosmicFlare)
    ? 1
    : tokens.where((t) => t.toLowerCase() == ruleLabel.toLowerCase()).length);

  print('initialCount = $initialCount');
}
