import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  CacheService._();

  static const String _cachePrefix = 'fintrack_cache_';
  static const String _securePrefix = 'fintrack_secure_cache_v1_';
  static const String _userPreferencePrefix = 'fintrack_user_';
  static const maxAge = Duration(hours: 24);
  static FlutterSecureStorage _storage = const FlutterSecureStorage();
  @visibleForTesting
  static void useStorageForTesting(FlutterSecureStorage storage) =>
      _storage = storage;
  static final Map<String, String> _memory = {};
  static SharedPreferences? _prefs;
  static Future<void>? _operations;
  static bool _memoryOnly = kIsWeb;
  static int? _userId;
  static int _generation = 0;

  static int? get userId => _userId;

  static void setUserId(int? userId) {
    if (_userId != userId) {
      _generation++;
      _memory.clear();
    }
    _userId = userId;
  }

  static String userScopedKey(String key) =>
      '$_userPreferencePrefix${_userId ?? 'anonymous'}_$key';

  static String _cacheKey(String key) =>
      '$_securePrefix${_userId ?? 'anonymous'}_$key';

  // Serialize writes/erasure: a pending response cannot recreate cache after
  // logout or place one user's response into another user's storage namespace.
  // The queue reference is dropped once it drains: retaining a completed future
  // keeps its originating zone alive and would stall later callers that run in a
  // different zone (for example consecutive widget tests in one isolate).
  static Future<T> _serial<T>(Future<T> Function() action) {
    final previous = _operations;
    final result = previous == null
        ? Future<T>.sync(action)
        : previous.then((_) => action());
    final completion = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _operations = completion;
    completion.whenComplete(() {
      if (identical(_operations, completion)) _operations = null;
    });
    return result;
  }

  static bool _legacyFinancialKey(String key) =>
      key.startsWith(_cachePrefix) ||
      key == 'dashboard_cache' ||
      key.startsWith('transactions_') ||
      key.startsWith('budget_') ||
      key.startsWith('accounts_');

  static Future<void> _preparePreferences() async {
    _prefs = await SharedPreferences.getInstance();
    // Discard only replaceable legacy response caches; never migrate plaintext
    // into another plaintext store or remove server records/exported reports.
    for (final key in _prefs!.getKeys().where(_legacyFinancialKey).toList()) {
      await _prefs!.remove(key);
    }
  }

  static Future<void> initialize({bool memoryOnly = false}) =>
      _serial(() async {
        _memoryOnly = kIsWeb || memoryOnly;
        _memory.clear();
        try {
          await _preparePreferences();
        } catch (_) {
          // Optional cache storage never blocks online financial operations.
        }
      });

  static Future<void> save(String key, dynamic data) {
    final generation = _generation;
    final storageKey = _cacheKey(key);
    final useMemory = _memoryOnly || _userId == null;
    return _serial(() async {
      if (generation != _generation) return;
      try {
        final encoded = json.encode({
          'version': 1,
          'cachedAt': DateTime.now().toUtc().toIso8601String(),
          'data': data,
        });
        if (useMemory) {
          _memory[storageKey] = encoded;
        } else {
          await _storage.write(key: storageKey, value: encoded);
          if (generation != _generation) await _storage.delete(key: storageKey);
        }
      } catch (_) {
        // Fail closed: no plaintext fallback when platform secure storage fails.
      }
    });
  }

  static Future<dynamic> get(String key) {
    final generation = _generation;
    final storageKey = _cacheKey(key);
    final useMemory = _memoryOnly || _userId == null;
    return _serial(() async {
      try {
        final value = useMemory
            ? _memory[storageKey]
            : await _storage.read(key: storageKey);
        if (generation != _generation || value == null) return null;
        final record = json.decode(value);
        final cachedAt = record is Map
            ? DateTime.tryParse(record['cachedAt']?.toString() ?? '')
            : null;
        final age = cachedAt == null
            ? null
            : DateTime.now().toUtc().difference(cachedAt);
        if (record is! Map ||
            record['version'] != 1 ||
            age == null ||
            age.isNegative ||
            age > maxAge) {
          if (useMemory) {
            _memory.remove(storageKey);
          } else {
            await _storage.delete(key: storageKey);
          }
          return null;
        }
        return record['data'];
      } on FormatException {
        _memory.remove(storageKey);
        if (!useMemory) {
          try {
            await _storage.delete(key: storageKey);
          } catch (_) {}
        }
        return null;
      } catch (_) {
        return null;
      }
    });
  }

  static Future<void> remove(String key) {
    final storageKey = _cacheKey(key);
    return _serial(() async {
      _memory.remove(storageKey);
      try {
        await _storage.delete(key: storageKey);
      } catch (_) {}
    });
  }

  static Future<void> clearBudgetCaches() {
    final userPrefix = _cacheKey('');
    bool matches(String key) =>
        key.startsWith(userPrefix) &&
        (key.substring(userPrefix.length).startsWith('budget_') ||
            key.substring(userPrefix.length).startsWith('budget_status_') ||
            key.substring(userPrefix.length).startsWith('budget_progress_'));
    return _serial(() async {
      _memory.removeWhere((key, _) => matches(key));
      if (!_memoryOnly) {
        try {
          final values = await _storage.readAll();
          for (final key in values.keys.where(matches)) {
            await _storage.delete(key: key);
          }
        } catch (_) {}
      }
    });
  }

  static Future<void> clearAll() {
    _generation++;
    _memory.clear();
    return _serial(() async {
      // Never use secure-storage deleteAll: the token is owned by TokenService.
      if (!_memoryOnly) {
        try {
          final values = await _storage.readAll();
          for (final key in values.keys.where(
            (key) => key.startsWith(_securePrefix),
          )) {
            await _storage.delete(key: key);
          }
        } catch (_) {}
      }
      try {
        await _preparePreferences();
        for (final key
            in _prefs!
                .getKeys()
                .where(
                  (key) =>
                      key.startsWith(_userPreferencePrefix) ||
                      key == 'last_sms_import_time',
                )
                .toList()) {
          await _prefs!.remove(key);
        }
      } catch (_) {}
    });
  }
}
