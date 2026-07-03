import 'active_adventure_storage_native.dart'
    if (dart.library.html) 'active_adventure_storage_web.dart';

abstract class ActiveAdventureStorage {
  const ActiveAdventureStorage();

  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> clear(String key);
}

ActiveAdventureStorage createActiveAdventureStorage() =>
    createActiveAdventureStorageImpl();
