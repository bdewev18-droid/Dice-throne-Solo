void main() {
  final tokens = ['Cosmic flare', 'Cosmic flare', 'Cosmic flare'];
  print('Initial: $tokens');
  tokens.removeWhere((t) => t.toLowerCase() == 'cosmic flare'.toLowerCase());
  print('After remove: $tokens');
  for (var i = 0; i < 2; i++) {
    tokens.add('Cosmic flare');
  }
  print('Final: $tokens');
}
