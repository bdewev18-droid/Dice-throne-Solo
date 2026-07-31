import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Identifiants du projet Supabase.
///
/// La anon key est *publiable* par design (c'est sa destination) : elle ne
/// donne accès qu'aux données autorisées par les policies RLS. Ne jamais y
/// mettre la service_role.
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = 'https://rqxfjffwzdfefinfcxjo.supabase.co';
  static const String anonKey =
      'sb_publishable_3EuoFYUzqUvNX7IPrhZKpQ_mkW-Gl97';
}

/// État de session exposé à l'UI : user connecté, en cours de connexion,
/// ou invité (anonyme local).
enum AuthStatus { unknown, signedOut, signingIn, signedIn }

/// Encapsule la session Google/Supabase actuelle.
class AuthSession {
  const AuthSession({
    required this.status,
    this.userId,
    this.email,
    this.isAnonymous = false,
  });

  final AuthStatus status;
  final String? userId;
  final String? email;
  final bool isAnonymous;

  bool get isSignedIn => status == AuthStatus.signedIn && userId != null;

  static const AuthSession unknown = AuthSession(status: AuthStatus.unknown);
  static const AuthSession signedOut = AuthSession(status: AuthStatus.signedOut);
}

/// Singleton d'accès à Supabase (auth + historique).
///
/// Historique des parties : insert / select / delete sur `game_records`.
/// Auth : Google Sign-In (et fallback anonyme via Supabase si Google
/// n'est pas configuré).
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const String _table = 'game_records';

  late final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  /// Initialise le client Supabase. À appeler dans main() avant runApp.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    _googleSignIn = GoogleSignIn(
      scopes: const ['email', 'openid', 'profile'],
      signInOption: SignInOption.standard,
    );
    _initialized = true;
  }

  SupabaseClient get _client => Supabase.instance.client;

  /// Session actuelle (peut être null si pas initialisé).
  AuthSession currentSession() {
    if (!_initialized) {
      return AuthSession.unknown;
    }
    final session = _client.auth.currentSession;
    if (session == null) {
      return AuthSession.signedOut;
    }
    final user = _client.auth.currentUser;
    final isAnon = session.user?.isAnonymous ?? false;
    return AuthSession(
      status: AuthStatus.signedIn,
      userId: user?.id,
      email: user?.email,
      isAnonymous: isAnon,
    );
  }

  /// Tente une connexion Google.
  ///
  /// - Sur **web** : déclenche le flux OAuth Supabase (redirect vers Google
  ///   puis retour). La page se recharge à la fin du flux ; la session est
  ///   restaurée au prochain démarrage via [currentSession].
  /// - Sur **mobile** : utilise `google_sign_in` puis échange l'idToken
  ///   contre une session Supabase via `signInWithIdToken`.
  ///
  /// Si l'utilisateur annule (mobile), renvoie [AuthSession.signedOut].
  Future<AuthSession> signInWithGoogle() async {
    if (!_initialized) {
      throw StateError('SupabaseService non initialisé');
    }
    if (kIsWeb) {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: '${_webBaseUrl()}Dice-throne-Solo/',
      );
      // Le navigateur va rediriger : on ne peut pas lire la session ici.
      return const AuthSession(status: AuthStatus.signingIn);
    }
    final account = await _googleSignIn.signIn();
    if (account == null) {
      return AuthSession.signedOut;
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;
    if (idToken == null || idToken.isEmpty) {
      return AuthSession.signedOut;
    }
    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    final user = response.user;
    return AuthSession(
      status: AuthStatus.signedIn,
      userId: user?.id,
      email: user?.email,
      isAnonymous: false,
    );
  }

  /// Base URL de l'app pour le redirect OAuth web (sans trailing slash).
  String _webBaseUrl() {
    const String fallback = 'http://localhost:8082/';
    try {
      final uri = Uri.base;
      if (uri.host.isEmpty) {
        return fallback;
      }
      final origin = '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      return '$origin/';
    } catch (_) {
      return fallback;
    }
  }

  /// Crée/ restaure une session anonyme (utile tant que Google OAuth
  /// n'est pas configuré côté Supabase, ou comme filet de sécurité).
  Future<AuthSession> signInAnonymously() async {
    if (!_initialized) {
      throw StateError('SupabaseService non initialisé');
    }
    final response = await _client.auth.signInAnonymously();
    final user = response.user;
    return AuthSession(
      status: AuthStatus.signedIn,
      userId: user?.id,
      email: user?.email,
      isAnonymous: true,
    );
  }

  /// Déconnexion : ferme la session Supabase et Google.
  Future<void> signOut() async {
    if (!_initialized) {
      return;
    }
    await _client.auth.signOut();
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
  }

  /// Insère un record de partie pour le user courant.
  ///
  /// Renvoie l'id de la ligne insérée, ou null si pas connecté / échec.
  Future<String?> insertRecord(Map<String, dynamic> record) async {
    final uid = _currentUserId();
    if (uid == null) {
      return null;
    }
    final payload = Map<String, dynamic>.from(record);
    payload['user_id'] = uid;
    final response =
        await _client.from(_table).insert(payload).select('id').maybeSingle();
    if (response == null) {
      return null;
    }
    return response['id'] as String?;
  }

  /// Charge l'historique du user courant, trié par date de partie
  /// décroissante (la plus récente en premier). Limite 500 records.
  Future<List<Map<String, dynamic>>> fetchHistory() async {
    final uid = _currentUserId();
    if (uid == null) {
      return <Map<String, dynamic>>[];
    }
    final response = await _client
        .from(_table)
        .select()
        .eq('user_id', uid)
        .order('played_at', ascending: false)
        .limit(500);
    final list = response as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// Supprime un record par son id (la policy RLS vérifie user_id).
  Future<bool> deleteRecord(String id) async {
    final uid = _currentUserId();
    if (uid == null) {
      return false;
    }
    await _client.from(_table).delete().eq('id', id).eq('user_id', uid);
    return true;
  }

  String? _currentUserId() {
    if (!_initialized) {
      return null;
    }
    return _client.auth.currentUser?.id;
  }
}
