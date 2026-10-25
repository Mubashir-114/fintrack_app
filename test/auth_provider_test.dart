import 'dart:typed_data';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/services/cache_service.dart';
import 'package:frontend/models/api_response.dart';
import 'package:frontend/models/auth_response.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TokenState {
  String? value;
  int removals = 0;
}

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository({this.loginHandler, this.profileHandler})
    : super(dio: Dio());

  @override
  Future<Uint8List?> getAvatar() async => null;

  Future<ApiResponse<AuthResponse>> Function()? loginHandler;
  Future<ApiResponse<ProfileResponse>> Function()? profileHandler;
  Future<void> Function()? passwordHandler;
  Future<void> Function()? deletionHandler;
  Future<ApiResponse<ProfileResponse>> Function()? updateHandler;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => passwordHandler!();
  @override
  Future<void> deleteAccount({required String password}) => deletionHandler!();
  @override
  Future<ApiResponse<ProfileResponse>> updateProfile({
    required String name,
    required String email,
  }) => updateHandler!();

  @override
  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) => loginHandler!();

  @override
  Future<ApiResponse<ProfileResponse>> getProfile() => profileHandler!();
}

UserModel _user(int id, {String? name}) => UserModel(
  id: id,
  name: name ?? 'Test User $id',
  email: 'user$id@example.test',
);

ApiResponse<AuthResponse> _authResponse(UserModel user, String token) =>
    ApiResponse(
      success: true,
      message: 'Authenticated',
      data: AuthResponse(token: token, user: user),
    );

ApiResponse<ProfileResponse> _profileResponse(UserModel user) => ApiResponse(
  success: true,
  message: 'Profile loaded',
  data: ProfileResponse(user: user),
);

AuthProvider _provider({
  required _FakeAuthRepository repository,
  required _TokenState token,
  void Function()? onSessionReset,
}) => AuthProvider(
  repository: repository,
  onSessionReset: onSessionReset,
  tokenReader: () async => token.value,
  tokenWriter: (value) async => token.value = value,
  tokenRemover: () async {
    token.removals++;
    token.value = null;
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CacheService.setUserId(null);
    await CacheService.initialize();
  });

  test(
    'password success clears session, tokens and financial caches; failure preserves them',
    () async {
      final token = _TokenState()..value = 'synthetic-session';
      final repository = _FakeAuthRepository(
        profileHandler: () async => _profileResponse(_user(41)),
      );
      var resets = 0;
      final auth = _provider(
        repository: repository,
        token: token,
        onSessionReset: () => resets++,
      );
      await auth.loadCurrentUser();
      await CacheService.save('dashboard_cache', {'balance': 45});
      repository.passwordHandler = () async {
        throw StateError('synthetic failure');
      };
      expect(
        await auth.changePassword(currentPassword: 'old', newPassword: 'new'),
        isFalse,
      );
      expect(auth.isLoggedIn, isTrue);
      expect(token.removals, 0);
      repository.passwordHandler = () async {};
      expect(
        await auth.changePassword(currentPassword: 'old', newPassword: 'new'),
        isTrue,
      );
      expect(auth.isLoggedIn, isFalse);
      expect(token.value, isNull);
      expect(resets, 1);
      CacheService.setUserId(41);
      expect(await CacheService.get('dashboard_cache'), isNull);
    },
  );

  test(
    'profile update success is applied; a response from an old session is ignored',
    () async {
      final token = _TokenState()..value = 'synthetic-session';
      final repository = _FakeAuthRepository(
        profileHandler: () async => _profileResponse(_user(41)),
      );
      final auth = _provider(repository: repository, token: token);
      await auth.loadCurrentUser();
      repository.updateHandler = () async =>
          _profileResponse(_user(41, name: 'Updated name'));
      expect(
        await auth.updateProfile(
          name: 'Updated name',
          email: 'user41@example.test',
        ),
        isTrue,
      );
      expect(auth.currentUser?.name, 'Updated name');
      final response = Completer<ApiResponse<ProfileResponse>>();
      repository.updateHandler = () => response.future;
      final updating = auth.updateProfile(
        name: 'Stale name',
        email: 'user41@example.test',
      );
      await auth.logout();
      response.complete(_profileResponse(_user(41, name: 'Stale name')));
      expect(await updating, isFalse);
      expect(auth.currentUser, isNull);
    },
  );

  test(
    'confirmed deletion is not reported as a server failure when local token erasure fails',
    () async {
      final repository = _FakeAuthRepository()..deletionHandler = () async {};
      final auth = AuthProvider(
        repository: repository,
        tokenRemover: () async {
          throw StateError('synthetic storage failure');
        },
      );
      expect(await auth.deleteAccount(password: 'synthetic-password'), isTrue);
      expect(auth.isLoggedIn, isFalse);
      expect(auth.errorMessage, contains('local credential removal'));
    },
  );

  test('restores a profile without receiving or replacing a token', () async {
    final token = _TokenState()..value = 'stored-test-token';
    final repository = _FakeAuthRepository(
      profileHandler: () async => _profileResponse(_user(41)),
    );
    final provider = _provider(repository: repository, token: token);

    expect(await provider.loadCurrentUser(), isTrue);

    expect(provider.isLoggedIn, isTrue);
    expect(provider.currentUser?.id, 41);
    expect(CacheService.userId, 41);
    expect(token.value, 'stored-test-token');
    expect(token.removals, 0);
  });

  test('invalidates a session after an authenticated 401', () async {
    final token = _TokenState()..value = 'expired-test-token';
    final request = RequestOptions(path: '/api/auth/me');
    final repository = _FakeAuthRepository(
      profileHandler: () async => throw DioException(
        requestOptions: request,
        response: Response(
          requestOptions: request,
          statusCode: 401,
          data: {'message': 'Unauthorized'},
        ),
      ),
    );
    final provider = _provider(repository: repository, token: token);

    expect(await provider.loadCurrentUser(), isFalse);

    expect(token.value, isNull);
    expect(token.removals, 1);
    expect(provider.isLoggedIn, isFalse);
  });

  test(
    'a stale profile 401 preserves a replacement token and current user',
    () async {
      final token = _TokenState();
      final repository = _FakeAuthRepository(
        loginHandler: () async => _authResponse(_user(41), 'old-test-token'),
      );
      final provider = _provider(repository: repository, token: token);
      expect(
        await provider.login(
          email: 'user41@example.test',
          password: 'test-password',
        ),
        isTrue,
      );
      final currentUser = provider.currentUser;
      repository.profileHandler = () async {
        token.value = 'replacement-test-token';
        final request = RequestOptions(path: '/api/auth/me');
        throw DioException(
          requestOptions: request,
          response: Response(
            requestOptions: request,
            statusCode: 401,
            data: {'message': 'Unauthorized'},
          ),
        );
      };

      expect(await provider.loadCurrentUser(), isFalse);

      expect(token.value, 'replacement-test-token');
      expect(token.removals, 0);
      expect(provider.currentUser, currentUser);
      expect(provider.isLoggedIn, isTrue);
    },
  );

  test(
    'preserves recoverable sessions on offline, timeout, and server errors',
    () async {
      final failures = <DioException>[
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/me'),
          type: DioExceptionType.connectionError,
        ),
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/me'),
          type: DioExceptionType.receiveTimeout,
        ),
        DioException(
          requestOptions: RequestOptions(path: '/api/auth/me'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/me'),
            statusCode: 503,
            data: {'message': 'Temporarily unavailable'},
          ),
        ),
      ];

      for (final failure in failures) {
        final token = _TokenState()..value = 'recoverable-test-token';
        final repository = _FakeAuthRepository(
          profileHandler: () async => throw failure,
        );
        final provider = _provider(repository: repository, token: token);

        expect(await provider.loadCurrentUser(), isFalse);
        expect(token.value, 'recoverable-test-token');
        expect(token.removals, 0);
        expect(provider.errorMessage, isNotNull);
      }
    },
  );

  test(
    'a rejected public login preserves an existing authenticated session',
    () async {
      final token = _TokenState();
      final repository = _FakeAuthRepository(
        loginHandler: () async =>
            _authResponse(_user(41), 'existing-test-token'),
      );
      final provider = _provider(repository: repository, token: token);

      expect(
        await provider.login(
          email: 'user41@example.test',
          password: 'test-password',
        ),
        isTrue,
      );
      final existingUser = provider.currentUser;
      repository.loginHandler = () async {
        final request = RequestOptions(path: '/api/auth/login');
        throw DioException(
          requestOptions: request,
          response: Response(
            requestOptions: request,
            statusCode: 401,
            data: {'message': 'Invalid credentials'},
          ),
        );
      };

      expect(
        await provider.login(
          email: 'wrong@example.test',
          password: 'wrong-password',
        ),
        isFalse,
      );

      expect(provider.currentUser, existingUser);
      expect(token.value, 'existing-test-token');
      expect(token.removals, 0);
    },
  );

  test('logout rejects a stale profile restoration response', () async {
    final token = _TokenState()..value = 'stored-test-token';
    final profileCompleter = Completer<ApiResponse<ProfileResponse>>();
    final profileRequested = Completer<void>();
    final repository = _FakeAuthRepository(
      profileHandler: () {
        profileRequested.complete();
        return profileCompleter.future;
      },
    );
    final provider = _provider(repository: repository, token: token);

    final restoration = provider.loadCurrentUser();
    await profileRequested.future;
    await provider.logout();
    profileCompleter.complete(_profileResponse(_user(41)));

    expect(await restoration, isFalse);
    expect(provider.isLoggedIn, isFalse);
    expect(CacheService.userId, isNull);
    expect(token.value, isNull);
  });

  test('account switching rejects a stale restoration response', () async {
    final token = _TokenState()..value = 'old-test-token';
    final profileCompleter = Completer<ApiResponse<ProfileResponse>>();
    final profileRequested = Completer<void>();
    final repository = _FakeAuthRepository(
      loginHandler: () async => _authResponse(_user(42), 'new-test-token'),
      profileHandler: () {
        profileRequested.complete();
        return profileCompleter.future;
      },
    );
    CacheService.setUserId(41);
    final provider = _provider(repository: repository, token: token);

    final restoration = provider.loadCurrentUser();
    await profileRequested.future;
    expect(
      await provider.login(
        email: 'user42@example.test',
        password: 'test-password',
      ),
      isTrue,
    );
    profileCompleter.complete(_profileResponse(_user(41)));

    expect(await restoration, isFalse);
    expect(provider.currentUser?.id, 42);
    expect(CacheService.userId, 42);
    expect(token.value, 'new-test-token');
  });

  group('auth error formatting and status code distinction', () {
    final testCases = <Map<String, dynamic>>[
      {
        'name': 'HTTP 400 with validation errors array extracts field message',
        'error': DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            statusCode: 400,
            data: {
              'success': false,
              'message': 'Validation failed',
              'errors': [
                {'field': 'email', 'message': 'Valid email required'},
              ],
            },
          ),
        ),
        'expected': 'Valid email required',
      },
      {
        'name': 'HTTP 401 invalid credentials uses backend message',
        'error': DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            statusCode: 401,
            data: {'success': false, 'message': 'Invalid credentials'},
          ),
        ),
        'expected': 'Invalid credentials',
      },
      {
        'name': 'HTTP 403 access forbidden maps properly',
        'error': DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            statusCode: 403,
            data: {'success': false, 'message': 'Not allowed by CORS'},
          ),
        ),
        'expected': 'Not allowed by CORS',
      },
      {
        'name': 'HTTP 429 rate limit exceeded maps properly',
        'error': DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            statusCode: 429,
            data: {
              'success': false,
              'message': 'Too many attempts. Please try again in 15 minutes.',
            },
          ),
        ),
        'expected': 'Too many attempts. Please try again in 15 minutes.',
      },
      {
        'name':
            'HTTP 500 with generic Internal Server Error displays user-friendly message',
        'error': DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            statusCode: 500,
            data: {'success': false, 'message': 'Internal Server Error'},
          ),
        ),
        'expected':
            'The server is temporarily unavailable. Please try again shortly.',
      },
      {
        'name': 'HTTP 503 with specific database message preserves information',
        'error': DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            statusCode: 503,
            data: {
              'success': false,
              'message':
                  'Database service unavailable. Please try again shortly.',
            },
          ),
        ),
        'expected': 'Database service unavailable. Please try again shortly.',
      },
      {
        'name': 'HTTP 502 with HTML payload does not crash and handles safely',
        'error': DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          response: Response(
            requestOptions: RequestOptions(path: '/api/auth/login'),
            statusCode: 502,
            data: '<html><head><title>502 Bad Gateway</title></head></html>',
          ),
        ),
        'expected':
            'The server is temporarily unavailable. Please try again shortly.',
      },
      {
        'name': 'connectionTimeout provides clear timeout guidance',
        'error': DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          type: DioExceptionType.connectionTimeout,
        ),
        'expected':
            'Connection timed out. The server may be waking up or your network is slow. Please try again.',
      },
      {
        'name': 'connectionError provides clear network guidance',
        'error': DioException(
          requestOptions: RequestOptions(path: '/api/auth/login'),
          type: DioExceptionType.connectionError,
        ),
        'expected':
            'Unable to reach the server. Please check your internet connection.',
      },
    ];

    for (final tc in testCases) {
      test(tc['name'] as String, () async {
        final token = _TokenState();
        final repository = _FakeAuthRepository(
          loginHandler: () async => throw tc['error'] as Object,
        );
        final provider = _provider(repository: repository, token: token);

        expect(
          await provider.login(
            email: 'test@example.com',
            password: 'password123',
          ),
          isFalse,
        );
        expect(provider.errorMessage, tc['expected']);
      });
    }
  });
}
