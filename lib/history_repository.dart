import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;

import 'active_adventure_storage.dart';
import 'main.dart' show GameRecord;
import 'supabase_service.dart';

/// Stockage local de l'historique (cache hors-ligne / démarrage).
/// Réutilise la même couche platform-agnostic que la partie en cours
/// mais avec une clé dédiée pour ne pas écraser `active_adventure_v1`.
class _HistoryCache {
  _HistoryCache() : _storage = createActiveAdventureStorage();

  final ActiveAdventureStorage _storage;
  static const String _key = 'history_cache_v1';

  Future<String?> read() => _storage.read(_key);
  Future<void> write(String value) => _storage.write(_key, value);
  Future<void> clear() => _storage.clear(_key);
}

/// Repository d'historique des parties.
///
/// Source de vérité : Supabase (table `game_records`). Quand le user est
/// connecté, tout est lu/écrit dans Supabase et l'historique survit aux
/// changements de navigateur / appareil (plus de problème de cache).
///
/// Filet de sécurité : un cache local (localStorage sur web, SharedPreferences
/// via [ActiveAdventureStore] sur natif) conserve le dernier historique
/// chargé, pour affichage immédiat au démarrage et usage hors-ligne.
class HistoryRepository {
  HistoryRepository._();

  @visibleForTesting
  static HistoryRepository instance = HistoryRepository._();

  final _HistoryCache _cache = _HistoryCache();

  /// Charge l'historique : Supabase si connecté, sinon le cache local.
  ///
  /// Renvoie toujours une liste (vide si rien). Met à jour le cache local
  /// avec le résultat Supabase quand la requête réussit.
  Future<List<GameRecord>> load() async {
    final session = SupabaseService.instance.currentSession();
    if (session.isSignedIn) {
      try {
        final rows =
            await SupabaseService.instance.fetchHistory();
        final records = rows
            .map(GameRecord.fromSupabase)
            .toList(growable: false);
        await _writeCache(records);
        return records;
      } catch (_) {
        // Réseau down / erreur : on retombe sur le cache local.
        return _readCache();
      }
    }
    // Non connecté : on sert le cache local (au pire vide).
    return _readCache();
  }

  /// Ajoute un record. Si connecté, l'insère dans Supabase et renvoie le
  /// record complété avec son id serveur. Sinon, l'ajoute au cache local.
  Future<GameRecord> add(GameRecord record) async {
    final session = SupabaseService.instance.currentSession();
    if (session.isSignedIn) {
      try {
        final id = await SupabaseService.instance
            .insertRecord(record.toSupabase());
        final saved = id == null
            ? record
            : GameRecord(
                id: id,
                hero: record.hero,
                date: record.date,
                score: record.score,
                mode: record.mode,
                healthRemaining: record.healthRemaining,
                bossHealthRemaining: record.bossHealthRemaining,
                enemiesDefeated: record.enemiesDefeated,
                duration: record.duration,
                isVictory: record.isVictory,
              );
        await _refreshCache();
        return saved;
      } catch (_) {
        await _appendCache(record);
        return record;
      }
    }
    await _appendCache(record);
    return record;
  }

  /// Supprime un record. Si connecté et le record a un id serveur, le
  /// supprime de Supabase. Met à jour le cache local dans tous les cas.
  Future<void> delete(GameRecord record) async {
    final session = SupabaseService.instance.currentSession();
    if (session.isSignedIn && record.id != null) {
      try {
        await SupabaseService.instance.deleteRecord(record.id!);
      } catch (_) {
        // On supprime quand même du cache local.
      }
    }
    await _refreshCache();
  }

  // ---- Cache local (filet hors-ligne / démarrage) ----

  Future<void> _writeCache(List<GameRecord> records) async {
    final payload = jsonEncode(
      records.map(_recordToJson).toList(),
    );
    await _cache.write(payload);
  }

  Future<void> _appendCache(GameRecord record) async {
    final current = await _readCache();
    current.insert(0, record);
    await _writeCache(current);
  }

  Future<void> _refreshCache() async {
    // Recharge depuis Supabase et re-sauve le cache ; ignore les erreurs.
    try {
      final rows = await SupabaseService.instance.fetchHistory();
      final records =
          rows.map(GameRecord.fromSupabase).toList(growable: false);
      await _writeCache(records);
    } catch (_) {
      // Sans connexion : on garde le cache existant.
    }
  }

  Future<List<GameRecord>> _readCache() async {
    final raw = await _cache.read();
    if (raw == null || raw.isEmpty) {
      return <GameRecord>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <GameRecord>[];
      }
      return decoded
          .whereType<Map>()
          .map((m) => _recordFromCache(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return <GameRecord>[];
    }
  }

  Map<String, dynamic> _recordToJson(GameRecord r) => {
        'id': r.id,
        'hero': r.hero.name,
        'mode': r.mode.name,
        'score': r.score,
        'enemies_defeated': r.enemiesDefeated,
        'health_remaining': r.healthRemaining,
        'boss_health_remaining': r.bossHealthRemaining,
        'duration_ms': r.duration.inMilliseconds,
        'is_victory': r.isVictory,
        'played_at': r.date.toIso8601String(),
      };

  GameRecord _recordFromCache(Map<String, dynamic> m) {
    // Réutilise le décodage Supabase : la forme est la même.
    return GameRecord.fromSupabase(m);
  }
}

/// Indique si le localStorage du navigateur est disponible (web uniquement).
bool get hasLocalStorageCache => kIsWeb;
