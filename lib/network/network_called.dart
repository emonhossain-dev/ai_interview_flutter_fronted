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
              final requestOptions = error.requestOptions;

              requestOptions.headers['Authorization'] =
              'Bearer $newToken';

              try {
                final response = await _dio.fetch(requestOptions);
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

  // ---------------- RESPONSE HANDLER ----------------
  static NetworkResponse _handle(Response response) {
    final data = response.data;

    return NetworkResponse(
      statusCode: response.statusCode ?? -1,
      isSuccess: response.statusCode == 200 ||
          response.statusCode == 201,
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

  static void _log(String title, dynamic data) {
    debugPrint("$title => $data");
  }

  static Future<String?> refreshAccessToken() async {
    try {
      final refreshToken = await AuthService.getRefreshToken();

      final dio = Dio();

      final response = await dio.post(
       ApiURL.RefreshToken,
        data: {
          "refresh_token": refreshToken,
        },
      );

      final newAccessToken = response.data["access_token"];

      await AuthService.saveAccessToken(newAccessToken);

      return newAccessToken;
    } catch (e) {
      return null;
    }
  }



}