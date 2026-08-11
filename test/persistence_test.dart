import 'package:dice_throne_survie/main.dart';
import 'package:dice_throne_survie/supabase_service.dart';
import 'package:dice_throne_survie/history_repository.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Persistence Serialization Tests', () {
    test('GameRecord toSupabase encodes correctly', () {
      final now = DateTime.now();
      final record = GameRecord(
        id: null, // should not be in toSupabase (added by SupabaseService)
        hero: HeroType.alchemist,
        mode: SurvivalMode.mediumFixed,
        date: now,
        isVictory: true,
        score: 125,
        healthRemaining: 15,
        bossHealthRemaining: 0,
      );

      final map = record.toSupabase();
      
      expect(map['hero'], equals('alchemist'));
      expect(map['mode'], equals('mediumFixed'));
      expect(map['played_at'], equals(now.toUtc().toIso8601String()));
      expect(map['is_victory'], isTrue);
      expect(map['score'], equals(125));
      expect(map['health_remaining'], equals(15));
      expect(map['boss_health_remaining'], equals(0));
      expect(map.containsKey('id'), isFalse);
    });

    test('GameRecord fromSupabase decodes correctly', () {
      final nowStr = DateTime.now().toIso8601String();
      final map = {
        'id': 'db-uuid-1234',
        'hero': 'benjamin',
        'mode': 'mediumRandom',
        'played_at': nowStr,
        'is_victory': false,
        'score': 10,
        'health_remaining': 0,
        'boss_health_remaining': 5,
      };

      final record = GameRecord.fromSupabase(map);
      
      expect(record.id, equals('db-uuid-1234'));
      expect(record.hero, equals(HeroType.benjamin));
      expect(record.mode, equals(SurvivalMode.mediumRandom));
      expect(record.date.toIso8601String(), equals(nowStr));
      expect(record.isVictory, isFalse);
      expect(record.score, equals(10));
      expect(record.healthRemaining, equals(0));
      expect(record.bossHealthRemaining, equals(5));
    });

    test('GameRecord fromSupabase handles nulls gracefully', () {
      final map = <String, dynamic>{}; // Empty map (bad data)
      final record = GameRecord.fromSupabase(map);
      
      expect(record.id, isNull);
      expect(record.hero, equals(HeroType.alchemist)); // fallback
      expect(record.mode, equals(SurvivalMode.mediumFixed)); // fallback
      expect(record.isVictory, isFalse); // fallback
      expect(record.score, equals(0));
    });
  });

  group('HistoryRepository Tests', () {
    late FakeSupabaseService fakeSupabase;
    final Map<String, String> fakeStorage = {};

    setUp(() {
      fakeSupabase = FakeSupabaseService();
      SupabaseService.instance = fakeSupabase;
      
      const channel = MethodChannel('dt_solo_quest/active_adventure');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        final args = call.arguments as Map<dynamic, dynamic>?;
        final key = args?['key'] as String?;
        if (call.method == 'read') {
          return fakeStorage[key];
        } else if (call.method == 'write') {
          fakeStorage[key!] = args?['value'] as String;
          return null;
        } else if (call.method == 'clear') {
          fakeStorage.remove(key);
          return null;
        }
        return null;
      });
    });

    test('add record offline falls back to local cache, load online fetches from db', () async {
      final record = GameRecord(
        hero: HeroType.alchemist,
        mode: SurvivalMode.mediumFixed,
        date: DateTime.now(),
        isVictory: true,
        score: 125,
        healthRemaining: 15,
        bossHealthRemaining: 0,
      );
      
      final saved = await HistoryRepository.instance.add(record);
      expect(saved.id, isNull); // Offline, so no server ID is assigned
      
      // Load offline, should return local cache containing the record
      final offlineLoaded = await HistoryRepository.instance.load();
      expect(offlineLoaded.length, equals(1));
      
      fakeSupabase.setSignedIn();
      final onlineLoaded = await HistoryRepository.instance.load();
      
      // Since simulatedDb is empty, online load overwrites cache with empty db
      expect(onlineLoaded.length, equals(0)); 
    });

    test('add record online syncs to db and returns with ID', () async {
      fakeSupabase.setSignedIn();
      
      final record = GameRecord(
        hero: HeroType.alchemist,
        mode: SurvivalMode.mediumFixed,
        date: DateTime.now(),
        isVictory: true,
        score: 125,
        healthRemaining: 15,
        bossHealthRemaining: 0,
      );
      
      final saved = await HistoryRepository.instance.add(record);
      expect(saved.id, isNotNull); 
      expect(fakeSupabase.simulatedDb.length, equals(1));
    });
  });
}

class FakeSupabaseService implements SupabaseService {
  AuthSession _session = const AuthSession(status: AuthStatus.signedOut);
  
  void setSignedIn() {
    _session = const AuthSession(status: AuthStatus.signedIn, userId: 'test-user-id');
  }
  
  @override
  Stream<AuthSessionEvent> get sessionStream => const Stream.empty();
  
  @override
  AuthSession currentSession() => _session;
  
  List<Map<String, dynamic>> simulatedDb = [];
  
  @override
  Future<List<Map<String, dynamic>>> fetchHistory() async => simulatedDb;
  
  @override
  Future<String?> insertRecord(Map<String, dynamic> record) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    record['id'] = id;
    simulatedDb.insert(0, record);
    return id;
  }
  
  @override
  Future<bool> deleteRecord(String id) async {
    simulatedDb.removeWhere((r) => r['id'] == id);
    return true;
  }
  
  @override
  Future<void> initialize() async {}
  @override
  Future<AuthSession> signInWithGoogle() async => _session;
  @override
  Future<AuthSession> signInAnonymously() async => _session;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> updateHeroCollection(Set<String> heroNames) async {}
}
