// lib/services/api_service.dart

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";
  static const Duration _timeout = Duration(seconds: 60);

  static Future<Map<String, dynamic>> uploadResume({
    required PlatformFile file, // ← PlatformFile not String path (web compatible)
    String? jdUrl,
    String? jdText,
  }) async {
    final uri = Uri.parse("$baseUrl/resume/upload-resume");

    var request = http.MultipartRequest("POST", uri);

    // fromBytes works on web AND mobile — fromPath crashes on web
    final bytes = file.bytes;
    if (bytes == null) {
      throw Exception(
        "Could not read file bytes. Try selecting the file again.",
      );
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        "resume",
        bytes,
        filename: file.name,
      ),
    );

    if (jdUrl != null && jdUrl.isNotEmpty) {
      request.fields["jd_url"] = jdUrl;
    }
    if (jdText != null && jdText.isNotEmpty) {
      request.fields["jd_text"] = jdText;
    }

    try {
      final streamedResponse = await request.send().timeout(
        _timeout,
        onTimeout: () => throw Exception(
          "Request timed out after ${_timeout.inSeconds}s. "
          "The server may be processing a large file — try again.",
        ),
      );

      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }

      Map<String, dynamic> errorJson = {};
      try {
        errorJson = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (_) {}

      final detail = errorJson['detail'] ?? responseBody;
      throw Exception(
        "Upload failed (HTTP ${streamedResponse.statusCode}): $detail",
      );
    } on Exception {
      rethrow;
    }
  }
}