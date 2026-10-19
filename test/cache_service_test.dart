import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:frontend/core/services/cache_service.dart';

class _UnavailableStorage extends FlutterSecureStorage {
  const _UnavailableStorage();
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
  }) async {
    throw StateError('Synthetic secure storage unavailable');
  }
}

class _DelayedStorage extends FlutterSecureStorage {
  final started = Completer<void>();
  final releaseWrite = Completer<void>();
  final values = <String, String>{};
  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
  }) async {
    started.complete();
    await releaseWrite.future;
    if (value != null) values[key] = value;
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
  }) async {
    values.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WindowsOptions? wOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
  }) async => Map.of(values);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    CacheService.useStorageForTesting(const FlutterSecureStorage());
    CacheService.setUserId(null);
    await CacheService.initialize();
  });

  test('keeps cached responses isolated by authenticated user', () async {
    CacheService.setUserId(41);
    await CacheService.save('dashboard_cache', const {'balance': 250});

    CacheService.setUserId(42);
    expect(await CacheService.get('dashboard_cache'), isNull);

    CacheService.setUserId(41);
    expect(await CacheService.get('dashboard_cache'), {'balance': 250});
  });

  test(
    'purges legacy plaintext caches while preserving unrelated preferences',
    () async {
      final preferences = await SharedPreferences.getInstance();
      CacheService.setUserId(41);
      await preferences.setString('fintrack_cache_41_corrupt', '{');
      await preferences.setString('user_currency_code', 'EUR');

      await CacheService.initialize();
      expect(await CacheService.get('corrupt'), isNull);
      expect(preferences.containsKey('fintrack_cache_41_corrupt'), isFalse);

      await CacheService.clearAll();

      expect(preferences.getString('user_currency_code'), 'EUR');
    },
  );

  test(
    'financial responses never enter SharedPreferences and logout preserves the token owner',
    () async {
      CacheService.setUserId(41);
      await const FlutterSecureStorage().write(
        key: 'access_token',
        value: 'synthetic-token',
      );
      await CacheService.save('dashboard_cache', {
        'balance': 1234.56,
        'note': 'synthetic-private',
      });
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getKeys().any((key) => key.startsWith('fintrack_cache_')),
        isFalse,
      );
      final secure = await const FlutterSecureStorage().readAll();
      expect(
        secure.keys,
        contains('fintrack_secure_cache_v1_41_dashboard_cache'),
      );
      await CacheService.clearAll();
      expect(await CacheService.get('dashboard_cache'), isNull);
      expect(
        await const FlutterSecureStorage().read(key: 'access_token'),
        'synthetic-token',
      );
    },
  );

  test('expired and corrupted secure caches fail closed', () async {
    CacheService.setUserId(41);
    await const FlutterSecureStorage().write(
      key: 'fintrack_secure_cache_v1_41_expired',
      value: jsonEncode({
        'version': 1,
        'cachedAt': DateTime.now()
            .toUtc()
            .subtract(const Duration(hours: 25))
            .toIso8601String(),
        'data': {'balance': 5},
      }),
    );
    await const FlutterSecureStorage().write(
      key: 'fintrack_secure_cache_v1_41_corrupt',
      value: '{',
    );
    expect(await CacheService.get('expired'), isNull);
    expect(await CacheService.get('corrupt'), isNull);
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
  });

  test('browser mode uses memory only and clears on account changes', () async {
    await CacheService.initialize(memoryOnly: true);
    CacheService.setUserId(41);
    await CacheService.save('dashboard_cache', {'balance': 55});
    expect(await CacheService.get('dashboard_cache'), {'balance': 55});
    expect(await const FlutterSecureStorage().readAll(), isEmpty);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
    CacheService.setUserId(42);
    CacheService.setUserId(41);
    expect(await CacheService.get('dashboard_cache'), isNull);
  });

  test('secure storage failure never falls back to plaintext', () async {
    CacheService.setUserId(41);
    CacheService.useStorageForTesting(const _UnavailableStorage());
    await CacheService.save('dashboard_cache', {'balance': 999});
    expect(await CacheService.get('dashboard_cache'), isNull);
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });

  test(
    'an in-flight secure write cannot repopulate caches after logout',
    () async {
      CacheService.setUserId(41);
      final storage = _DelayedStorage();
      CacheService.useStorageForTesting(storage);
      final saving = CacheService.save('dashboard_cache', {'balance': 1});
      await storage.started.future;
      CacheService.setUserId(null);
      final clearing = CacheService.clearAll();
      storage.releaseWrite.complete();
      await saving;
      await clearing;
      expect(storage.values, isEmpty);
    },
  );
}
