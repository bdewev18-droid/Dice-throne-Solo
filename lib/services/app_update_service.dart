import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';

class RemoteAppVersion {
  const RemoteAppVersion({
    required this.version,
    required this.buildNumber,
    required this.apkUrl,
    this.releaseNotes,
  });

  final String version;
  final int buildNumber;
  final String apkUrl;
  final String? releaseNotes;

  factory RemoteAppVersion.fromJson(Map<String, dynamic> json) {
    return RemoteAppVersion(
      version: (json['version'] as String?)?.trim() ?? '',
      buildNumber: json['buildNumber'] is int
          ? json['buildNumber'] as int
          : int.tryParse(json['buildNumber']?.toString() ?? '') ?? 0,
      apkUrl: (json['apkUrl'] as String?)?.trim() ?? '',
      releaseNotes: (json['releaseNotes'] as String?)?.trim(),
    );
  }
}

class AppUpdateService {
  AppUpdateService._();

  static const String versionCheckUrl =
      'https://bdewev18-droid.github.io/Dice-throne-Solo/version.json';

  static bool _dialogShownThisSession = false;

  /// Vérifie si une mise à jour est disponible sur GitHub Pages.
  /// Ne s'exécute que sur mobile (Android) et jamais sur le Web.
  static Future<RemoteAppVersion?> checkUpdate() async {
    if (kIsWeb) return null;
    if (defaultTargetPlatform != TargetPlatform.android) return null;

    try {
      final uri = Uri.parse('$versionCheckUrl?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri).timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final remote = RemoteAppVersion.fromJson(json);

      if (remote.buildNumber > appBuildNumber && remote.apkUrl.isNotEmpty) {
        return remote;
      }
    } catch (_) {
      // Échec silencieux si pas de réseau
    }
    return null;
  }

  /// Vérifie et affiche la popin de mise à jour au lancement si nécessaire.
  static Future<void> checkAndPrompt(BuildContext context) async {
    if (_dialogShownThisSession) return;
    final update = await checkUpdate();
    if (update == null || !context.mounted) return;

    _dialogShownThisSession = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xff1e1e2c),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xff8f43ff), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: heroAccent, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Update Available',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A new version is available: v${update.version} (Build ${update.buildNumber}).',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Current version: v${appVersionLabel.replaceAll('Version ', '')} (Build $appBuildNumber).',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (update.releaseNotes != null && update.releaseNotes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  update.releaseNotes!,
                  style: const TextStyle(color: Color(0xffcbd8cc), fontSize: 12),
                ),
              ),
            ],
            const SizedBox(height: 14),
            const Text(
              'Do you want to download and install this update now?',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Later', style: TextStyle(color: Colors.white60)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff8f43ff),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              final uri = Uri.parse(update.apkUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Update Now'),
          ),
        ],
      ),
    );
  }
}
