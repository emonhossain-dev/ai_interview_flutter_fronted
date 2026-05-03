import 'dart:io';
import 'package:ai_interview/Service/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/NetworkResponse.dart';
import '../models/TokenStore.dart';

class NetworkCaller {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      followRedirects: true, // 👈 IMPORTANT
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  /// INIT
  static void init() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthService.getAccessToken();

          if (token != null && options.headers['requiresAuth'] != false) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          return handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            debugPrint("❌ Unauthorized");
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

  // ======================================================
  // 🔥 1. RAW JSON REQUEST (NO FILE)
  // ======================================================
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
          headers: {"requiresAuth": requiresAuth},
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

  // ======================================================
  // 🔥 2. FORM DATA REQUEST (FILE SUPPORT)
  // ======================================================
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
          headers: {"requiresAuth": requiresAuth},
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

  // ---------------- RESPONSE ----------------
  static NetworkResponse _handle(Response response) {
    final data = response.data;

    return NetworkResponse(
      statusCode: response.statusCode ?? -1,
      isSuccess: response.statusCode == 200 || response.statusCode == 201,
      responseData: data,
      errorMessage: (response.statusCode != 200 &&
          response.statusCode != 201)
          ? data.toString()
          : "",
    );
  }

  // ---------------- ERROR ----------------
  static NetworkResponse _error(dynamic e) {
    debugPrint("❌ Exception: $e");

    return NetworkResponse(
      statusCode: -1,
      isSuccess: false,
      errorMessage: e.toString(),
    );
  }

  static void _log(String title, dynamic data) {
    debugPrint(data.toString());
  }

}
