import 'dart:io';
import 'package:ai_interview/Service/auth_service.dart';
import 'package:ai_interview/network/Api_URL.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/NetworkResponse.dart';

class NetworkCaller {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      followRedirects: true,
      headers: {
        "ngrok-skip-browser-warning": "true",
        'Content-Type': 'application/json',
      },
    ),
  );

  /// INIT
  static void init() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        // ---------------- REQUEST ----------------
        onRequest: (options, handler) async {
          final token = await AuthService.getAccessToken();
          final requiresAuth = options.extra["requiresAuth"] ?? true;

          if (token != null && requiresAuth) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },

        // ---------------- ERROR (REFRESH LOGIC) ----------------
        onError: (error, handler) async {
          final is401 = error.response?.statusCode == 401;

          if (is401) {
            debugPrint("❌ Token expired → refreshing...");

            final newToken = await refreshAccessToken();

            if (newToken != null) {
              final opts = error.requestOptions;

              try {
                final response = await _dio.request(
                  opts.path,
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                  options: Options(
                    method: opts.method,
                    headers: {
                      ...opts.headers,
                      'Authorization': 'Bearer $newToken',
                    },
                    extra: opts.extra,
                    contentType: opts.contentType,
                  ),
                );
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            } else {
              debugPrint("❌ Refresh failed → logout required");
              await AuthService.logout();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  // ---------------- GET ----------------
  static Future<NetworkResponse> getRequest(String url) async {
    try {
      _log("GET URL", url);

      final response = await _dio.get(url);

      _log("STATUS CODE", response.statusCode);
      _log("RESPONSE", response.data);

      return _handle(response);
    } catch (e) {
      _log("ERROR", e);
      return _error(e);
    }
  }

  // ---------------- POST JSON ----------------
  static Future<NetworkResponse> postJson(
      String url,
      Map<String, dynamic> body, {
        bool requiresAuth = true,
      }) async {
    try {
      _log("POST JSON URL", url);
      _log("REQUEST BODY", body);

      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          extra: {"requiresAuth": requiresAuth},
        ),
      );

      _log("STATUS CODE", response.statusCode);
      _log("RESPONSE", response.data);

      return _handle(response);
    } catch (e) {
      _log("ERROR", e);
      return _error(e);
    }
  }

  // ---------------- POST FORM ----------------
  static Future<NetworkResponse> postForm(
      String url,
      Map<String, dynamic> body, {
        bool requiresAuth = true,
      }) async {
    try {
      final formData = FormData.fromMap(body);

      _log("POST FORM URL", url);
      _log("FORM DATA", body);

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          extra: {"requiresAuth": requiresAuth},
        ),
      );

      _log("STATUS CODE", response.statusCode);
      _log("RESPONSE", response.data);

      return _handle(response);
    } catch (e) {
      _log("ERROR", e);
      return _error(e);
    }
  }

  // ---------------- PUT ----------------
  static Future<NetworkResponse> putRequest(
      String url,
      Map<String, dynamic> body, {
        bool requiresAuth = true,
      }) async {
    try {
      _log("PUT URL", url);
      _log("REQUEST BODY", body);

      final response = await _dio.put(
        url,
        data: body,
        options: Options(
          extra: {"requiresAuth": requiresAuth},
        ),
      );

      _log("STATUS CODE", response.statusCode);
      _log("RESPONSE", response.data);

      return _handle(response);
    } catch (e) {
      _log("ERROR", e);
      return _error(e);
    }
  }

  // ---------------- UPLOAD RESUME ----------------
  static Future<NetworkResponse> uploadResume({
    required String url,
    required int userId,
    required String title,
    required String summary,
    required File file,
    bool requiresAuth = true,
    Function(int, int)? onSendProgress,
  }) async {
    try {
      String fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        "user_id": userId,
        "title": title,
        "summary": summary,
        "file": await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        url,
        data: formData,
        onSendProgress: onSendProgress,
        options: Options(
          extra: {"requiresAuth": requiresAuth},
          contentType: "multipart/form-data",
        ),
      );

      return _handle(response);
    } catch (e) {
      return _error(e);
    }
  }

  // ---------------- DELETE RESUME ----------------
  static Future<NetworkResponse> deleteResume({
    required String url,
    bool requiresAuth = true,
  }) async {
    try {
      final response = await _dio.delete(
        url,
        options: Options(
          extra: {"requiresAuth": requiresAuth},
        ),
      );

      return _handle(response);
    } catch (e) {
      return _error(e);
    }
  }

  // ---------------- UPLOAD PROFILE IMAGE ----------------
  static Future<NetworkResponse> uploadProfileImage({
    required String url,
    required File file,
  }) async {
    try {
      String fileName = file.path.split('/').last;

      FormData formData = FormData.fromMap({
        "image": await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      final response = await _dio.put(
        url,
        data: formData,
        options: Options(
          extra: {"requiresAuth": true},
          contentType: "multipart/form-data",
        ),
      );

      return _handle(response);
    } catch (e) {
      return _error(e);
    }
  }

  // ---------------- RESPONSE HANDLER ----------------
  static NetworkResponse _handle(Response response) {
    final data = response.data;

    return NetworkResponse(
      statusCode: response.statusCode ?? -1,
      isSuccess:
      response.statusCode == 200 || response.statusCode == 201,
      responseData: data,
      errorMessage: (response.statusCode != 200 &&
          response.statusCode != 201)
          ? data.toString()
          : "",
    );
  }

  // ---------------- ERROR HANDLER ----------------
  static NetworkResponse _error(dynamic e) {
    debugPrint("❌ Exception: $e");

    return NetworkResponse(
      statusCode: -1,
      isSuccess: false,
      errorMessage: e.toString(),
    );
  }

  // ---------------- LOGGER ----------------
  static void _log(String title, dynamic data) {
    debugPrint("$title => $data");
  }

  // ---------------- REFRESH TOKEN ----------------
  static Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await AuthService.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        await AuthService.logout();
        return null;
      }

      final dio = Dio();

      final response = await dio.post(
        ApiURL.RefreshToken,
        data: {"refresh_token": refreshToken},
      );

      final newAccessToken = response.data["access_token"];

      if (newAccessToken == null || newAccessToken.toString().isEmpty) {
        await AuthService.logout();
        return null;
      }

      await AuthService.saveAccessToken(newAccessToken);

      debugPrint("New Access Token: $newAccessToken");

      return newAccessToken;
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401 || statusCode == 403) {
          await AuthService.logout();
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}