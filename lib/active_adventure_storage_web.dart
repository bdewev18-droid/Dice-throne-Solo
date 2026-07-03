// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'active_adventure_storage.dart';

class WebActiveAdventureStorage extends ActiveAdventureStorage {
  const WebActiveAdventureStorage();

  @override
  Future<String?> read(String key) async => html.window.localStorage[key];

  @override
  Future<void> write(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<void> clear(String key) async {
    html.window.localStorage.remove(key);
  }
}

ActiveAdventureStorage createActiveAdventureStorageImpl() =>
    const WebActiveAdventureStorage();
