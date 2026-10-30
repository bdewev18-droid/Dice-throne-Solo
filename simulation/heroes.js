// Dataset des héros Dice Throne extrait de l'application
const DTS_SEGMENTS = {
  season1: { id: 'season1', label: 'Saison 1', icon: '⚡' },
  season2: { id: 'season2', label: 'Saison 2', icon: '⚔️' },
  avengers: { id: 'avengers', label: 'Marvel Avengers', icon: '🛡️' },
  xmen: { id: 'xmen', label: 'Marvel X-Men', icon: '🧬' },
  outcast: { id: 'outcast', label: 'Outcast', icon: '🌑' },
  santaKrampus: { id: 'santaKrampus', label: 'Santa vs Krampus', icon: '❄️' },
  other: { id: 'other', label: 'Autres', icon: '✨' },
  dev: { id: 'dev', label: 'Dev Mode', icon: '🛠️' },
};

const DTS_HEROES = [
  {
    id: 'alchemist',
    name: 'Alchemist',
    asset: 'assets/personnages/Alchemist.png',
    color: '#35c7a0',
    complexity: 5,
    segments: ['other'],
    hp: 50,
    cp: 2
  },
  {
    id: 'artificer',
    name: 'Artificer',
    asset: 'assets/personnages/artificer.jpg',
    color: '#37b8ff',
    complexity: 6,
    segments: ['season2'],
    hp: 50,
    cp: 2
  },
  {
    id: 'barbare',
    name: 'Barbarian',
    asset: 'assets/personnages/Barbarian.png',
    color: '#d94a24',
    complexity: 1,
    segments: ['season1'],
    hp: 50,
    cp: 2
  },
  {
    id: 'blackPanther',
    name: 'Black Panther',
    asset: 'assets/personnages/BlackPanther.png',
    color: '#7a65ff',
    complexity: 2,
    segments: ['avengers'],
    hp: 50,
    cp: 2
  },
  {
    id: 'blackWidow',
    name: 'Black Widow',
    asset: 'assets/personnages/BlackWidow.png',
    color: '#db3d48',
    complexity: 4,
    segments: ['avengers'],
    hp: 50,
    cp: 2
  },
  {
    id: 'captainMarvel',
    name: 'Captain Marvel',
    asset: 'assets/personnages/CaptMarvel.png',
    color: '#ffc64d',
    complexity: 2,
    segments: ['avengers'],
    hp: 50,
    cp: 2
  },
  {
    id: 'cyclops',
    name: 'Cyclops',
    asset: 'assets/personnages/Cyclops.png',
    color: '#f0c044',
    complexity: 4,
    segments: ['xmen'],
    hp: 50,
    cp: 2
  },
  {
    id: 'cursedPirate',
    name: 'Cursed Pirate',
    asset: 'assets/personnages/cursed-pirate.jpg',
    color: '#20c7b8',
    complexity: 4,
    segments: ['season2'],
    hp: 50,
    cp: 2
  },
  {
    id: 'deadpool',
    name: 'Deadpool',
    asset: 'assets/personnages/Deadpool.webp',
    color: '#d9232e',
    complexity: 3,
    segments: ['other'],
    hp: 50,
    cp: 2
  },
  {
    id: 'doctorStrange',
    name: 'Doctor Strange',
    asset: 'assets/personnages/DrStrange.png',
    color: '#e14646',
    complexity: 5,
    segments: ['avengers'],
    hp: 50,
    cp: 2
  },
  {
    id: 'druid',
    name: 'Druid',
    asset: 'assets/personnages/Druid.png',
    color: '#7ac66a',
    complexity: 4,
    segments: ['other'],
    hp: 50,
    cp: 2
  },
  {
    id: 'duelist',
    name: 'Duelist',
    asset: 'assets/personnages/Duelist.png',
    color: '#d6a052',
    complexity: 3,
    segments: ['other'],
    hp: 50,
    cp: 2
  },
  {
    id: 'elfeLunaire',
    name: 'Moon Elf',
    asset: 'assets/personnages/moon-elf-hp.jpg',
    color: '#64b7e8',
    complexity: 2,
    segments: ['season1'],
    hp: 50,
    cp: 2
  },
  {
    id: 'forgemaster',
    name: 'Forgemaster',
    asset: 'assets/personnages/Forgemaster.png',
    color: '#f09a43',
    complexity: 4,
    segments: ['other'],
    hp: 50,
    cp: 2
  },
  {
    id: 'gambit',
    name: 'Gambit',
    asset: 'assets/personnages/Gambit.png',
    color: '#bb67ff',
    complexity: 6,
    segments: ['xmen'],
    hp: 50,
    cp: 2
  },
  {
    id: 'gunslinger',
    name: 'Gunslinger',
    asset: 'assets/personnages/gunslinger.jpg',
    color: '#c57a35',
    complexity: 2,
    segments: ['season2'],
    hp: 50,
    cp: 2
  },
  {
    id: 'headlessHorseman',
    name: 'Headless Horseman',
    asset: 'assets/personnages/HeadlessHorseman.png',
    color: '#f06a2b',
    complexity: 4,
    segments: ['outcast'],
    hp: 50,
    cp: 2
  },
  {
    id: 'huntress',
    name: 'Huntress',
    asset: 'assets/personnages/Huntress.png',
    color: '#4fa95b',
    complexity: 5,
    segments: ['season2'],
    hp: 50,
    cp: 2
  },
  {
    id: 'iceman',
    name: 'Iceman',
    asset: 'assets/personnages/Iceman.png',
    color: '#8de9ff',
    complexity: 4,
    segments: ['xmen'],
    hp: 50,
    cp: 2
  },
  {
    id: 'jeanGrey',
    name: 'Jean Grey',
    asset: 'assets/personnages/JeanGrey.png',
    color: '#ff8b45',
    complexity: 6,
    segments: ['xmen'],
    hp: 50,
    cp: 2
  },
  {
    id: 'krampus',
    name: 'Krampus',
    asset: 'assets/personnages/Krampus.png',
    color: '#b44335',
    complexity: 4,
    segments: ['santaKrampus'],
    hp: 50,
    cp: 2
  },
  {
    id: 'loki',
    name: 'Loki',
    asset: 'assets/personnages/Loki.png',
    color: '#57b966',
    complexity: 4,
    segments: ['avengers'],
    hp: 50,
    cp: 2
  },
  {
    id: 'monk',
    name: 'Monk',
    asset: 'assets/personnages/monk.jpg',
    color: '#d7a55a',
    complexity: 4,
    segments: ['season1'],
    hp: 50,
    cp: 2
  },
  {
    id: 'mysticBrawler',
    name: 'Mystic Brawler',
    asset: 'assets/personnages/MysticBrawler.png',
    color: '#7cc5ff',
    complexity: 3,
    segments: ['other'],
    hp: 50,
    cp: 2
  },
  {
    id: 'necromancer',
    name: 'Necromancer',
    asset: 'assets/personnages/Necromancer.png',
    color: '#75d16b',
    complexity: 6,
    segments: ['outcast'],
    hp: 50,
    cp: 2
  },
  {
    id: 'ninja',
    name: 'Ninja',
    asset: 'assets/personnages/Ninja.png',
    color: '#2cc6a8',
    complexity: 2,
    segments: ['season1'],
    hp: 50,
    cp: 2
  },
  {
    id: 'paladin',
    name: 'Paladin',
    asset: 'assets/personnages/Paladin.png',
    color: '#f4c95a',
    complexity: 5,
    segments: ['season1'],
    hp: 50,
    cp: 2
  },
  {
    id: 'paleLady',
    name: 'Pale Lady',
    asset: 'assets/personnages/PaleLady.png',
    color: '#cfd6ff',
    complexity: 3,
    segments: ['outcast'],
    hp: 50,
    cp: 2
  },
  {
    id: 'psylocke',
    name: 'Psylocke',
    asset: 'assets/personnages/Psylocke.png',
    color: '#d15cff',
    complexity: 3,
    segments: ['xmen'],
    hp: 50,
    cp: 2
  },
  {
    id: 'pyromancer',
    name: 'Pyromancer',
    asset: 'assets/personnages/pyromancer.png',
    color: '#ff6a21',
    complexity: 3,
    segments: ['season1'],
    hp: 50,
    cp: 2
  },
  {
    id: 'raveness',
    name: 'Raveness',
    asset: 'assets/personnages/Raveness.png',
    color: '#7f5cff',
    complexity: 3,
    segments: ['outcast'],
    hp: 50,
    cp: 2
  },
  {
    id: 'rogue',
    name: 'Rogue',
    asset: 'assets/personnages/Rouge.png',
    color: '#6dcc5d',
    complexity: 3,
    segments: ['xmen'],
    hp: 50,
    cp: 2
  },
  {
    id: 'samurai',
    name: 'Samurai',
    asset: 'assets/personnages/Samurai.jpg',
    color: '#a82828',
    complexity: 3,
    segments: ['season2'],
    hp: 50,
    cp: 2
  },
  {
    id: 'santa',
    name: 'Santa',
    asset: 'assets/personnages/Santa.png',
    color: '#de2f3f',
    complexity: 2,
    segments: ['santaKrampus'],
    hp: 50,
    cp: 2
  },
  {
    id: 'scarletWitch',
    name: 'Scarlet Witch',
    asset: 'assets/personnages/ScarletWich.png',
    color: '#d8233f',
    complexity: 4,
    segments: ['avengers'],
    hp: 50,
    cp: 2
  },
  {
    id: 'seraph',
    name: 'Seraph',
    asset: 'assets/personnages/Seraph.png',
    color: '#ffd35c',
    complexity: 3,
    segments: ['season2'],
    hp: 50,
    cp: 2
  },
  {
    id: 'shadowThief',
    name: 'Shadow Thief',
    asset: 'assets/personnages/ShadowThief.png',
    color: '#8f4dff',
    complexity: 5,
    segments: ['season1'],
    hp: 50,
    cp: 2
  },
  {
    id: 'spiderman',
    name: 'Miles Morales Spider-Man',
    asset: 'assets/personnages/Spiderman.png',
    color: '#e02c35',
    complexity: 2,
    segments: ['avengers'],
    hp: 50,
    cp: 2
  },
  {
    id: 'storm',
    name: 'Storm',
    asset: 'assets/personnages/Storm.png',
    color: '#c8d9ff',
    complexity: 4,
    segments: ['xmen'],
    hp: 50,
    cp: 2
  },
  {
    id: 'sunElf',
    name: 'Sun Elf',
    asset: 'assets/personnages/SunElf.png',
    color: '#ffc857',
    complexity: 3,
    segments: ['other'],
    hp: 50,
    cp: 2
  },
  {
    id: 'tacticien',
    name: 'Tactician',
    asset: 'assets/personnages/Tactician.png',
    color: '#d92f2f',
    complexity: 5,
    segments: ['season2'],
    hp: 50,
    cp: 2
  },
  {
    id: 'thor',
    name: 'Thor',
    asset: 'assets/personnages/Thor.png',
    color: '#5ca7ff',
    complexity: 3,
    segments: ['avengers'],
    hp: 50,
    cp: 2
  },
  {
    id: 'treant',
    name: 'Treant',
    asset: 'assets/personnages/Treeant.png',
    color: '#70b85a',
    complexity: 5,
    segments: ['season1'],
    hp: 50,
    cp: 2
  },
  {
    id: 'vampireLord',
    name: 'Vampire Lord',
    asset: 'assets/personnages/VampireLord.png',
    color: '#9f2035',
    complexity: 4,
    segments: ['season2'],
    hp: 50,
    cp: 2
  },
  {
    id: 'wolverine',
    name: 'Wolverine',
    asset: 'assets/personnages/Wolverine.png',
    color: '#ffc134',
    complexity: 2,
    segments: ['xmen'],
    hp: 50,
    cp: 2
  },
  {
    id: 'benjamin',
    name: 'Benjamin',
    asset: 'assets/personnages/benji.webp',
    color: '#2196f3',
    complexity: 6,
    segments: ['dev'],
    hp: 50,
    cp: 2
  }
];
