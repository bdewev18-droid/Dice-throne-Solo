import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Identifiants du projet Supabase + Google.
///
/// La anon key Supabase est *publiable* par design (c'est sa destination) :
/// elle ne donne accès qu'aux données autorisées par les policies RLS. Ne
/// jamais y mettre la service_role.
///
/// [googleWebClientId] est le **Web Application** OAuth Client ID créé dans
/// Google Cloud Console (format `xxxx.apps.googleusercontent.com`). Il est
/// OBLIGATOIRE pour que l'APK échange un idToken valide auprès de Supabase :
/// sans lui, Google émet un token dont l'audience ne correspond pas au
/// provider Supabase, et `signInWithIdToken` échoue. Il doit aussi être
/// déclaré côté Supabase (Auth > Providers > Google > Authorized Client IDs).
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = 'https://rqxfjffwzdfefinfcxjo.supabase.co';
  static const String anonKey =
      'sb_publishable_3EuoFYUzqUvNX7IPrhZKpQ_mkW-Gl97';

  /// Web OAuth Client ID Google Cloud (format
  /// `xxxx.apps.googleusercontent.com`). Obligatoire pour que l'APK échange
  /// un idToken valide auprès de Supabase. Doit aussi être déclaré côté
  /// Supabase (Auth > Providers > Google > Authorized Client IDs).
  static const String googleWebClientId =
      '46362990646-g8jlqo1t641ivopje5ebojjnrccrv2hb.apps.googleusercontent.com';

  /// iOS : reversed client ID optionnel (GoogleService-Info.plist suffit en
  /// général). Laisser vide si la config plist est en place.
  static const String googleIosClientId = '';
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

/// Snapshot de session diffusé par [SupabaseService.sessionStream].
///
/// [transition] vaut true pour l'événement qui marque la fin d'un flux
/// de connexion (succès ou échec), afin que l'UI cesse d'afficher le
/// spinner "signingIn".
class AuthSessionEvent {
  const AuthSessionEvent({required this.session, this.transition = false});

  final AuthSession session;
  final bool transition;
}

/// Singleton d'accès à Supabase (auth + historique).
///
/// Historique des parties : insert / select / delete sur `game_records`.
/// Auth : Google Sign-In (et fallback anonyme via Supabase si Google
/// n'est pas configuré).
///
/// La session est suivie via [sessionStream] (branché sur
/// `onAuthStateChange`) : l'UI n'a plus à interroger l'état après un flux
/// OAuth web (qui recharge la page), la session restaurée au démarrage
/// est diffusée automatiquement.
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const String _table = 'game_records';

  late final GoogleSignIn _googleSignIn;
  bool _initialized = false;
  bool _initializing = false;
  final Completer<void> _initCompleter = Completer<void>();

  StreamSubscription<AuthState>? _authSub;
  // ignore: close_sinks
  final StreamController<AuthSessionEvent> _sessionController =
      StreamController<AuthSessionEvent>.broadcast();

  /// Flux de session à consommer par l'UI. Émet l'état courant à chaque
  /// changement d'auth Supabase (connexion, déconnexion, refresh, restore).
  Stream<AuthSessionEvent> get sessionStream =>
      _sessionController.stream;

  /// Initialise le client Supabase. À appeler dans main() avant runApp.
  /// Idempotent et safe en cas d'appels concurrents (Completer).
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    if (_initializing) {
      return _initCompleter.future;
    }
    _initializing = true;
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
        // PKCE est activé par défaut dans supabase_flutter >= 2.5. L'échange
        // du code OAuth au chargement de la page est géré automatiquement,
        // à condition que initialize() s'exécute avant runApp (voir main()).
      );
      _googleSignIn = GoogleSignIn(
        scopes: const ['email', 'openid', 'profile'],
        signInOption: SignInOption.standard,
        // Le serverClientId force Google à émettre un idToken dont
        // l'audience correspond au provider Google configuré dans Supabase.
        // Sans lui, signInWithIdToken échoue sur Android.
        serverClientId: SupabaseConfig.googleWebClientId.isEmpty
            ? null
            : SupabaseConfig.googleWebClientId,
        forceCodeForRefreshToken: false,
      );
      _subscribeAuthChanges();
      _initialized = true;
    } catch (e) {
      _initializing = false;
      rethrow;
    }
    _initializing = false;
    _initCompleter.complete();
  }

  void _subscribeAuthChanges() {
    _authSub = _client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;
      _sessionController.add(
        AuthSessionEvent(
          session: _sessionFromSupabase(session, event),
          transition: event == AuthChangeEvent.signedIn ||
              event == AuthChangeEvent.signedOut ||
              event == AuthChangeEvent.tokenRefreshed,
        ),
      );
    });
  }

  AuthSession _sessionFromSupabase(Session? session, AuthChangeEvent event) {
    if (session == null) {
      return AuthSession.signedOut;
    }
    final user = session.user;
    return AuthSession(
      status: AuthStatus.signedIn,
      userId: user.id,
      email: user.email,
      isAnonymous: user.isAnonymous,
    );
  }

  SupabaseClient get _client => Supabase.instance.client;

  /// Session actuelle (peut être null si pas initialisé). Synchrone, pour
  /// un état initial rapide au démarrage avant le premier événement stream.
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
  ///   puis retour). La session est restaurée automatiquement au retour par
  ///   [sessionStream] (pas de rechargement manuel de l'UI).
  /// - Sur **mobile** : utilise `google_sign_in` (silencieux d'abord, puis
  ///   interactif si nécessaire) puis échange l'idToken contre une session
  ///   Supabase via `signInWithIdToken`.
  ///
  /// Si l'utilisateur annule (mobile) ou si l'idToken est absent, renvoie
  /// [AuthSession.signedOut].
  Future<AuthSession> signInWithGoogle() async {
    if (!_initialized) {
      throw StateError('SupabaseService non initialisé');
    }
    if (kIsWeb) {
      final redirect = _webRedirect();
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirect.isEmpty ? null : redirect,
      );
      // Le navigateur va rediriger : on ne peut pas lire la session ici.
      // La session restaurée sera poussée via sessionStream au retour.
      return const AuthSession(status: AuthStatus.signingIn);
    }

    // Mobile : essai silencieux d'abord (rapide, pas de popup) puis
    // interactif. Restaure une session existante sans interaction si
    // possible, ce qui rend la reconnexion quasi-instantanée.
    GoogleSignInAccount? account = await _trySilent();
    if (account == null) {
      account = await _googleSignIn.signIn();
    }
    if (account == null) {
      // signIn() retourne null silencieusement quand Google refuse
      // d'émettre un token pour cette app : cause typique = SHA-1 du
      // keystore non enregistré dans Google Cloud Console (OAuth Client
      // Android manquant pour com.bdewev18.dicethronesolo). On lève
      // explicitement au lieu de revenir muettement à signedOut, sinon
      // l'UI ne montre aucune erreur (symptôme "rien ne se passe").
      throw StateError(
        'Google a renvoyé un compte nul. Cause probable : SHA-1 du '
        'keystore de l\'APK non enregistré dans Google Cloud Console '
        '(créer un OAuth Client Android pour le package '
        'com.bdewev18.dicethronesolo), ou Google Play Services absent '
        'de l\'appareil.',
      );
    }
    return _exchangeWithSupabase(account);
  }

  /// Restauration silencieuse : tente `signInSilently` (pas de popup). Renvoie
  /// null si l'utilisateur n'a pas de compte Google connecté sur l'appareil
  /// ou s'il a annulé. Échecs réseau gérés sans lever d'exception.
  Future<GoogleSignInAccount?> _trySilent() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {
      return null;
    }
  }

  /// Échange l'idToken Google contre une session Supabase. Centralise la
  /// logique de validation (idToken requis) pour les chemins silencieux et
  /// interactif.
  ///
  /// Lève une exception explicite en cas d'échec (au lieu de revenir
  /// silencieusement à signedOut) afin que l'UI affiche la cause réelle
  /// via le SnackBar "Connexion impossible : ...".
  Future<AuthSession> _exchangeWithSupabase(GoogleSignInAccount account) async {
    final GoogleSignInAuthentication auth;
    try {
      auth = await account.authentication;
    } catch (error) {
      // Souvent : Google Play Services indisponible ou réseau coupé.
      throw StateError('Google auth indisponible: $error');
    }
    final idToken = auth.idToken;
    final accessToken = auth.accessToken;
    if (idToken == null || idToken.isEmpty) {
      // Cause n°1 sur Android : aucun client OAuth Android (SHA-1 du
      // keystore) enregistré dans Google Cloud Console pour ce package.
      // Le picker s'ouvre mais Google refuse d'émettre un idToken.
      throw StateError(
        'idToken Google vide. Vérifiez que le SHA-1 du keystore de '
        'l\'APK est enregistré dans Google Cloud Console (OAuth Client '
        'Android, package com.bdewev18.dicethronesolo).',
      );
    }
    final AuthResponse response;
    try {
      response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } on AuthException catch (error) {
      // Erreur serveur Supabase : token invalide, audience, nonce, etc.
      throw StateError('Supabase a refusé le token Google: ${error.message}');
    } catch (error) {
      throw StateError('Échange Supabase échoué: $error');
    }
    final user = response.user;
    return AuthSession(
      status: AuthStatus.signedIn,
      userId: user?.id,
      email: user?.email,
      isAnonymous: false,
    );
  }

  /// URL de redirect OAuth web = la page où l'app se recharge après le
  /// callback Supabase. Conserve le sous-chemin de déploiement
  /// `/Dice-throne-Solo/` (déclaré dans Google Console URI 1 et à ajouter
  /// dans la allowlist "Redirect URLs" de Supabase).
  String _webRedirect() {
    const String path = 'Dice-throne-Solo/';
    const String fallback = 'http://localhost:8082/';
    try {
      final uri = Uri.base;
      if (uri.host.isEmpty) {
        return '$fallback$path';
      }
      final origin =
          '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}/';
      return '$origin$path';
    } catch (_) {
      return '$fallback$path';
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

  /// Déconnexion : ferme la session Supabase et Google. Le listener
  /// `onAuthStateChange` émettra `signedOut` via [sessionStream].
  Future<void> signOut() async {
    if (!_initialized) {
      return;
    }
    try {
      await _client.auth.signOut();
    } catch (_) {
      // La session locale peut déjà être invalide ; on ignore et nettoie.
    }
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {
      // Google sign-out peut échouer hors-ligne ; non bloquant.
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

/// ---------------------------------------------------------------------------
/// Guide de configuration Google Sign-In (APK + web).
/// ---------------------------------------------------------------------------
///
/// 1. Google Cloud Console → APIs & Services → Credentials → Create
///    Credentials → OAuth client ID → **Web application**.
///    - Authorized JavaScript origins :
///      - https://rqxfjffwzdfefinfcxjo.supabase.co  (dev web local si besoin)
///    - Authorized redirect URIs :
///      - https://rqxfjffwzdfefinfcxjo.supabase.co/auth/v1/callback
///    Copier le **Client ID** (format `xxxx.apps.googleusercontent.com`).
///
/// 2. Supabase Dashboard → Authentication → Providers → Google :
///    - Enable Google.
///    - Coller le Client ID + Client secret du Web Application.
///    - Ajouter le même Client ID dans "Authorized Client IDs".
///
/// 3. Dans `lib/supabase_service.dart`, renseigner :
///      static const String googleWebClientId = 'XXXX.apps.googleusercontent.com';
///
/// 4. (iOS) Déposer GoogleService-Info.plist dans ios/Runner/ et activer
///    GoogleService dans Xcode. Pas besoin de googleIosClientId ici.
///
/// 5. (Android) Aucun google-services.json requis pour le flux idToken :
///    le serverClientId passé au plugin suffit. Vérifier la permission
///    INTERNET (normalement présente par défaut).
///
/// Une fois l'étape 3 faite, l'APK échangera un idToken valide et la
/// connexion fonctionnera sans recharger l'app.
/// ---------------------------------------------------------------------------
