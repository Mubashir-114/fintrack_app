import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/api_response.dart';
import '../models/auth_response.dart';

class AuthRepository {
  AuthRepository({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  Future<ApiResponse<ProfileResponse>> updateProfile({
    required String name,
    required String email,
  }) async {
    final response = await _dio.put(
      'auth/me',
      data: {'name': name, 'email': email},
    );
    return ApiResponse.fromJson(
      response.data,
      (json) => ProfileResponse.fromJson(json),
    );
  }

  Future<Uint8List?> getAvatar() async {
    final response = await _dio.get('auth/avatar');
    final value = response.data['data']['avatar'] as String?;
    return value == null ? null : base64Decode(value);
  }

  Future<Uint8List?> saveAvatar(Uint8List? bytes) async {
    final response = bytes == null
        ? await _dio.delete('auth/avatar')
        : await _dio.put('auth/avatar', data: {'image': base64Encode(bytes)});
    final value = response.data['data']['avatar'] as String?;
    return value == null ? null : base64Decode(value);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.put(
      'auth/password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }

  Future<void> deleteAccount({required String password}) async {
    await _dio.delete(
      'auth/me',
      data: {'password': password, 'confirmation': 'DELETE'},
    );
  }

  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      "auth/login",
      data: {"email": email, "password": password},
      options: Options(extra: const {'skipAuth': true}),
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => AuthResponse.fromJson(json),
    );
  }

  Future<ApiResponse<AuthResponse>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      "auth/register",
      data: {"name": name, "email": email, "password": password},
      options: Options(extra: const {'skipAuth': true}),
    );

    return ApiResponse.fromJson(
      response.data,
      (json) => AuthResponse.fromJson(json),
    );
  }

  Future<ApiResponse<ProfileResponse>> getProfile() async {
    final response = await _dio.get("auth/me");

    return ApiResponse.fromJson(
      response.data,
      (json) => ProfileResponse.fromJson(json),
    );
  }
}
