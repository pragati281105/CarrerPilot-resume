// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000";

  // How long to wait before giving up on a request
  static const Duration _timeout = Duration(seconds: 60);

  static Future<Map<String, dynamic>> uploadResume({
    required String filePath,
    String? jdUrl,
    String? jdText,
  }) async {
    final uri = Uri.parse("$baseUrl/resume/upload-resume"); // ← fixed path

    var request = http.MultipartRequest("POST", uri);

    request.files.add(
      await http.MultipartFile.fromPath("resume", filePath),
    );

    if (jdUrl != null && jdUrl.isNotEmpty) {
      request.fields["jd_url"] = jdUrl;
    }
    if (jdText != null && jdText.isNotEmpty) {
      request.fields["jd_text"] = jdText;
    }

    try {
      // Send with timeout — OCR on images can be slow
      final streamedResponse = await request.send().timeout(
        _timeout,
        onTimeout: () => throw Exception(
          "Request timed out after ${_timeout.inSeconds}s. "
          "The server may be processing a large file — try again.",
        ),
      );

      final responseBody = await streamedResponse.stream.bytesToString();

      // Check status code before decoding
      if (streamedResponse.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      }

      // Try to parse the error detail from FastAPI's error response format
      // FastAPI returns: { "detail": "..." } on errors
      Map<String, dynamic> errorJson = {};
      try {
        errorJson = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (_) {
        // response body wasn't valid JSON — use raw text
      }

      final detail = errorJson['detail'] ?? responseBody;

      throw Exception(
        "Upload failed (HTTP ${streamedResponse.statusCode}): $detail",
      );

    } on Exception {
      rethrow; // let the caller (provider/screen) handle and show the error
    }
  }
}