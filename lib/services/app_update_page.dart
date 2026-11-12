import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../main.dart' show appBuildNumber, appVersionLabel, heroAccent;
import 'app_update_service.dart';

enum UpdateDownloadStatus { idle, downloading, completed, failed }

class AppUpdatePage extends StatefulWidget {
  const AppUpdatePage({
    super.key,
    required this.update,
  });

  final RemoteAppVersion update;

  @override
  State<AppUpdatePage> createState() => _AppUpdatePageState();
}

class _AppUpdatePageState extends State<AppUpdatePage> {
  UpdateDownloadStatus _status = UpdateDownloadStatus.idle;
  double _progress = 0.0;
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  String? _errorMessage;
  String? _savedApkPath;
  bool _cancelled = false;
  http.Client? _httpClient;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDownload();
    });
  }

  @override
  void dispose() {
    _cancelled = true;
    _httpClient?.close();
    super.dispose();
  }

  Future<void> _startDownload() async {
    if (!mounted) return;
    setState(() {
      _status = UpdateDownloadStatus.downloading;
      _progress = 0.0;
      _downloadedBytes = 0;
      _totalBytes = 0;
      _errorMessage = null;
      _cancelled = false;
    });

    _httpClient = http.Client();
    IOSink? fileSink;
    File? tempFile;

    try {
      String? storageDir;
      try {
        const channel = MethodChannel('dt_solo_quest/active_adventure');
        storageDir = await channel.invokeMethod<String>('getAppStorageDir');
      } catch (err) {
        debugPrint('getAppStorageDir error: $err');
      }

      if (storageDir == null || storageDir.isEmpty) {
        throw Exception('Device storage path is unavailable on this device.');
      }

      tempFile = File('$storageDir/app-update.apk');
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }

      final request = http.Request('GET', Uri.parse(widget.update.apkUrl));
      final response = await _httpClient!.send(request);

      if (response.statusCode >= 400) {
        throw Exception('Server returned HTTP ${response.statusCode}');
      }

      final total = response.contentLength ?? 0;
      if (mounted) {
        setState(() {
          _totalBytes = total;
        });
      }

      fileSink = tempFile.openWrite();
      var received = 0;

      await for (final chunk in response.stream) {
        if (_cancelled) {
          await fileSink.close();
          try {
            await tempFile.delete();
          } catch (_) {}
          return;
        }

        fileSink.add(chunk);
        received += chunk.length;

        if (mounted) {
          setState(() {
            _downloadedBytes = received;
            if (total > 0) {
              _progress = (received / total).clamp(0.0, 1.0);
            }
          });
        }
      }

      await fileSink.flush();
      await fileSink.close();
      fileSink = null;

      if (!mounted || _cancelled) return;

      setState(() {
        _status = UpdateDownloadStatus.completed;
        _savedApkPath = tempFile!.path;
        _progress = 1.0;
      });

      // Auto-trigger installation prompt
      await _triggerInstall(tempFile.path);
    } catch (error) {
      if (_cancelled) return;
      if (fileSink != null) {
        try {
          await fileSink.close();
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _status = UpdateDownloadStatus.failed;
          _errorMessage = error.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _triggerInstall(String filePath) async {
    try {
      const channel = MethodChannel('dt_solo_quest/active_adventure');
      final result = await channel.invokeMethod<bool>('installApk', {
        'filePath': filePath,
      });
      debugPrint('Install APK invoked: $result');
    } catch (err) {
      debugPrint('Direct install error: $err');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xff7f1d1d),
            content: Text(
              'Package installer error: $err. You can open the download link directly.',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openExternalBrowser() async {
    final uri = Uri.parse(widget.update.apkUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 MB';
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xff0d0f17),
      appBar: AppBar(
        backgroundColor: const Color(0xff131622),
        elevation: 0,
        title: const Text(
          'App Update & Installation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () {
            _cancelled = true;
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          children: [
            // Target Version Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff181b29),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xff8f43ff).withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff8f43ff).withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xff8f43ff).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xffa855f7).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Icon(
                          Icons.system_update_rounded,
                          color: heroAccent,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dice Throne Solo Quest',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'v${widget.update.version} (Build ${widget.update.buildNumber})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xff059669).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xff34d399).withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Color(0xff6ee7b7),
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Installed version: $appVersionLabel (Build $appBuildNumber)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  if (widget.update.releaseNotes != null &&
                      widget.update.releaseNotes!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'RELEASE NOTES',
                      style: TextStyle(
                        color: Color(0xffa78bfa),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        widget.update.releaseNotes!,
                        style: const TextStyle(
                          color: Color(0xffcbd5e1),
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Progress Display Area
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xff181b29),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _status == UpdateDownloadStatus.completed
                      ? const Color(0xff10b981)
                      : (_status == UpdateDownloadStatus.failed
                          ? const Color(0xffef4444)
                          : const Color(0xff2d334d)),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // State 1: Downloading
                  if (_status == UpdateDownloadStatus.downloading ||
                      _status == UpdateDownloadStatus.idle) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Downloading update...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$percent %',
                          style: const TextStyle(
                            color: heroAccent,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xff0f121d),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: _progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xff8f43ff),
                                      Color(0xffa855f7),
                                      Color(0xff34d399),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _totalBytes > 0
                              ? '${_formatBytes(_downloadedBytes)} / ${_formatBytes(_totalBytes)}'
                              : 'Connecting to server...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(heroAccent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      onPressed: () {
                        _cancelled = true;
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Cancel'),
                    ),
                  ],

                  // State 2: Completed
                  if (_status == UpdateDownloadStatus.completed) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xff065f46).withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xff34d399), width: 2),
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Color(0xff34d399),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Download Complete (100%)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'APK file is saved (${_formatBytes(_downloadedBytes)}). The package installer should launch automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xff10b981),
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          if (_savedApkPath != null) {
                            _triggerInstall(_savedApkPath!);
                          }
                        },
                        icon: const Icon(Icons.install_mobile, size: 20),
                        label: const Text(
                          'Open Package Installer',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],

                  // State 3: Failed
                  if (_status == UpdateDownloadStatus.failed) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xff7f1d1d).withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xffef4444), width: 2),
                      ),
                      child: const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xffef4444),
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Download Failed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _errorMessage ?? 'An error occurred during download.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xfffca5a5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white30),
                            ),
                            onPressed: _startDownload,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Retry'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xff8f43ff),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _openExternalBrowser,
                            icon: const Icon(Icons.open_in_browser, size: 18),
                            label: const Text('Browser'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Fallback action row
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xff94a3b8),
                ),
                onPressed: _openExternalBrowser,
                icon: const Icon(Icons.open_in_new, size: 15),
                label: const Text(
                  'Direct download link (GitHub Releases)',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
