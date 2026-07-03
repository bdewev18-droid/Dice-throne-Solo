import 'package:flutter/services.dart';

import 'active_adventure_storage.dart';

class NativeActiveAdventureStorage extends ActiveAdventureStorage {
  const NativeActiveAdventureStorage();

  static const MethodChannel _channel = MethodChannel(
    'dt_solo_quest/active_adventure',
  );

  @override
  Future<String?> read(String key) async {
    try {
      return _channel.invokeMethod<String>('read', {'key': key});
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      await _channel.invokeMethod<void>('write', {'key': key, 'value': value});
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<void> clear(String key) async {
    try {
      await _channel.invokeMethod<void>('clear', {'key': key});
    } on MissingPluginException {
      return;
    }
  }
}

ActiveAdventureStorage createActiveAdventureStorageImpl() =>
    const NativeActiveAdventureStorage();
