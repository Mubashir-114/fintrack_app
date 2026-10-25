import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../core/services/cache_service.dart';
import '../core/services/token_service.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    this.onSessionReset,
    AuthRepository? repository,
    Future<String?> Function()? tokenReader,
    Future<void> Function(String token)? tokenWriter,
    Future<void> Function()? tokenRemover,
  }) : _repository = repository ?? AuthRepository(),
       _tokenReader = tokenReader ?? TokenService.getToken,
       _tokenWriter = tokenWriter ?? TokenService.saveToken,
       _tokenRemover = tokenRemover ?? TokenService.removeToken;

  final VoidCallback? onSessionReset;
  final AuthRepository _repository;
  final Future<String?> Function() _tokenReader;
  final Future<void> Function(String token) _tokenWriter;
  final Future<void> Function() _tokenRemover;

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;
  int _avatarRevision = 0;
  Uint8List? _avatarBytes;
  Uint8List? get avatarBytes => _avatarBytes;

  Future<void> loadAvatar() async {
    final generation = _sessionGeneration;
    final revision = ++_avatarRevision;
    try {
      final bytes = await _repository.getAvatar();
      if (generation != _sessionGeneration) return;
      if (revision != _avatarRevision) return;
      _avatarBytes = bytes;
      notifyListeners();
    } catch (_) {
      /* A missing/unavailable avatar never prevents sign-in. */
    }
  }

  Future<bool> saveAvatar(Uint8List? bytes) async {
    final generation = _sessionGeneration;
    final revision = ++_avatarRevision;
    try {
      final saved = await _repository.saveAvatar(bytes);
      if (generation != _sessionGeneration) return false;
      if (revision != _avatarRevision) return false;
      _avatarBytes = saved;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      if (generation != _sessionGeneration) return false;
      _errorMessage = _accountError(
        error,
        'Photo could not be saved. Please retry.',
      );
      notifyListeners();
      return false;
    }
  }

  int _sessionGeneration = 0;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  UserModel? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  Future<bool> login({required String email, required String password}) async {
    final generation = ++_sessionGeneration;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _repository.login(
        email: email,
        password: password,
      );

      if (generation != _sessionGeneration) return false;
      if (!await _prepareSession(
        response.data.user.id,
        generation: generation,
      )) {
        return false;
      }
      await _tokenWriter(response.data.token);
      if (generation != _sessionGeneration) return false;

      _currentUser = response.data.user;
      loadAvatar();

      notifyListeners();

      return true;
    } on DioException catch (e) {
      if (generation != _sessionGeneration) return false;
      _errorMessage = _formatAuthError(e, fallback: "Login failed");
      notifyListeners();
      return false;
    } catch (e) {
      if (generation != _sessionGeneration) return false;
      _errorMessage = _formatAuthError(e, fallback: "Login failed");
      notifyListeners();
      return false;
    } finally {
      if (generation == _sessionGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final generation = ++_sessionGeneration;
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await _repository.register(
        name: name,
        email: email,
        password: password,
      );

      if (generation != _sessionGeneration) return false;
      if (!await _prepareSession(
        response.data.user.id,
        generation: generation,
      )) {
        return false;
      }
      await _tokenWriter(response.data.token);
      if (generation != _sessionGeneration) return false;

      _currentUser = response.data.user;
      loadAvatar();

      notifyListeners();

      return true;
    } on DioException catch (e) {
      if (generation != _sessionGeneration) return false;
      _errorMessage = _formatAuthError(e, fallback: "Registration failed");
      notifyListeners();
      return false;
    } catch (e) {
      if (generation != _sessionGeneration) return false;
      _errorMessage = _formatAuthError(e, fallback: "Registration failed");
      notifyListeners();
      return false;
    } finally {
      if (generation == _sessionGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> logout() async {
    final generation = ++_sessionGeneration;
    CacheService.setUserId(null);
    onSessionReset?.call();
    _currentUser = null;
    _avatarBytes = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();

    try {
      await _tokenRemover();
    } catch (_) {
      if (generation == _sessionGeneration) {
        _errorMessage =
            'Signed out, but local credential removal could not be confirmed.';
        notifyListeners();
      }
    } finally {
      if (generation == _sessionGeneration) {
        await CacheService.clearAll();
      }
    }
  }

  Future<bool> loadCurrentUser() async {
    final generation = _sessionGeneration;
    String? token;
    try {
      token = await _tokenReader();

      if (generation != _sessionGeneration || token == null || token.isEmpty) {
        return false;
      }

      final response = await _repository.getProfile();
      if (generation != _sessionGeneration || await _tokenReader() != token) {
        return false;
      }
      if (!await _prepareSession(
        response.data.user.id,
        generation: generation,
      )) {
        return false;
      }

      _currentUser = response.data.user;
      loadAvatar();
      _errorMessage = null;

      notifyListeners();

      return true;
    } on DioException catch (e) {
      if (generation != _sessionGeneration) return false;
      if (e.response?.statusCode == 401) {
        if (token != null && await _tokenReader() == token) {
          await logout();
        }
      } else {
        _errorMessage = _formatAuthError(
          e,
          fallback: "Unable to restore session",
        );
        notifyListeners();
      }
      return false;
    } catch (e) {
      if (generation == _sessionGeneration) {
        _errorMessage = _formatAuthError(
          e,
          fallback: "Unable to restore session",
        );
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
  }) async {
    final generation = _sessionGeneration;
    try {
      final response = await _repository.updateProfile(
        name: name,
        email: email,
      );
      if (generation != _sessionGeneration) return false;
      _currentUser = response.data.user;
      loadAvatar();
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (error) {
      if (generation != _sessionGeneration) return false;
      _errorMessage = _accountError(
        error,
        'Unable to update profile. Please try again.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final generation = _sessionGeneration;
    try {
      await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (generation != _sessionGeneration) return false;
      await logout();
      return true;
    } catch (error) {
      if (generation != _sessionGeneration) return false;
      _errorMessage = _accountError(
        error,
        'Unable to update password. Please try again.',
      );
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount({required String password}) async {
    final generation = _sessionGeneration;
    try {
      await _repository.deleteAccount(password: password);
      if (generation != _sessionGeneration) return false;
      await logout();
      return true;
    } catch (error) {
      if (generation != _sessionGeneration) return false;
      _errorMessage = _accountError(
        error,
        'Unable to confirm deletion. Check your connection and try again.',
      );
      notifyListeners();
      return false;
    }
  }

  String _accountError(Object error, String fallback) {
    return _formatAuthError(error, fallback: fallback);
  }

  String _formatAuthError(Object error, {required String fallback}) {
    if (error is! DioException) {
      final text = error.toString();
      return text.isNotEmpty ? text : fallback;
    }

    final dioError = error;

    if (dioError.type == DioExceptionType.connectionTimeout ||
        dioError.type == DioExceptionType.sendTimeout ||
        dioError.type == DioExceptionType.receiveTimeout) {
      return 'Connection timed out. The server may be waking up or your network is slow. Please try again.';
    }

    if (dioError.type == DioExceptionType.connectionError) {
      return 'Unable to reach the server. Please check your internet connection.';
    }

    final response = dioError.response;
    final statusCode = response?.statusCode;
    final data = response?.data;

    String? serverMessage;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        final first = errors.first;
        if (first is Map &&
            first['message'] is String &&
            (first['message'] as String).trim().isNotEmpty) {
          serverMessage = (first['message'] as String).trim();
        }
      }
      if (serverMessage == null &&
          data['message'] is String &&
          (data['message'] as String).trim().isNotEmpty) {
        serverMessage = (data['message'] as String).trim();
      }
    }

    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return serverMessage ?? 'Invalid request. Please check your input.';
        case 401:
          return serverMessage ??
              'Invalid email or password. Please try again.';
        case 403:
          return serverMessage ??
              'Access denied. Please check your permissions.';
        case 429:
          return serverMessage ??
              'Too many attempts. Please try again in 15 minutes.';
        case 500:
        case 502:
        case 503:
        case 504:
          if (serverMessage != null &&
              serverMessage != 'Internal Server Error') {
            return serverMessage;
          }
          return 'The server is temporarily unavailable. Please try again shortly.';
        default:
          return serverMessage ?? fallback;
      }
    }

    if (serverMessage != null) {
      return serverMessage;
    }

    if (dioError.message != null && dioError.message!.trim().isNotEmpty) {
      return dioError.message!.trim();
    }

    return fallback;
  }

  Future<bool> _prepareSession(int userId, {required int generation}) async {
    if (generation != _sessionGeneration) return false;
    if (CacheService.userId != null && CacheService.userId != userId) {
      await CacheService.clearAll();
      if (generation != _sessionGeneration) return false;
      onSessionReset?.call();
      _avatarBytes = null;
    }
    if (generation != _sessionGeneration) return false;
    CacheService.setUserId(userId);
    return true;
  }
}
