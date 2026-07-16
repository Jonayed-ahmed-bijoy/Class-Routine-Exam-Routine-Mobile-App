import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/routine_entry.dart';
import '../models/exam_entry.dart';

class ApiService {
  ApiService._();

  static final ApiService instance = ApiService._();

  /// Firebase Realtime Database
  static const String dbUrl =
      "https://class-routine-app-f3871-default-rtdb.asia-southeast1.firebasedatabase.app/current_routine.json";

  /// Firebase Realtime Database — Exam Schedule node
  static const String examDbUrl =
      "https://class-routine-app-f3871-default-rtdb.asia-southeast1.firebasedatabase.app/current_exam_schedule.json";

  /// Flask Backend URL
  ///
  /// Chrome/Web:
  /// http://127.0.0.1:8000
  ///
  /// Android Emulator:
  /// http://10.0.2.2:8000
  ///
  /// Real Phone:
  /// http://YOUR_PC_IP:8000
  static const String apiBaseUrl = "http://192.168.0.103:8000";

  static String get uploadUrl => "$apiBaseUrl/api/upload";

  //==================================================
  // Fetch Routine
  //==================================================

  Future<RoutineResponse> fetchRoutine() async {
    final response = await http.get(Uri.parse(dbUrl));

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load routine (${response.statusCode})",
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded == null || decoded["data"] == null) {
      return const RoutineResponse(
        data: [],
        updatedAt: null,
      );
    }

    final List<dynamic> rawList = decoded["data"];

    final entries = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => RoutineEntry.fromJson(e))
        .toList();

    return RoutineResponse(
      data: entries,
      updatedAt: decoded["updatedAt"]?.toString(),
    );
  }

  //==================================================
  // Fetch Exam Schedule
  //==================================================

  Future<ExamScheduleResponse> fetchExamSchedule() async {
    final response = await http.get(Uri.parse(examDbUrl));

    if (response.statusCode != 200) {
      throw Exception(
        "Failed to load exam schedule (${response.statusCode})",
      );
    }

    final decoded = jsonDecode(response.body);

    if (decoded == null || decoded["data"] == null) {
      return const ExamScheduleResponse(
        data: [],
        updatedAt: null,
      );
    }

    final List<dynamic> rawList = decoded["data"];

    final entries = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => ExamEntry.fromJson(e))
        .toList();

    return ExamScheduleResponse(
      data: entries,
      updatedAt: decoded["updatedAt"]?.toString(),
    );
  }

  //==================================================
  // Upload Routine
  //==================================================

  Future<Map<String, dynamic>> uploadRoutine({
    required Uint8List fileBytes,
    required String fileName,
    required String password,
  }) async {
    final request =
    http.MultipartRequest("POST", Uri.parse(uploadUrl));

    request.fields["password"] = password;

    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        fileBytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();

    final response =
    await http.Response.fromStream(streamedResponse);

    Map<String, dynamic> body;

    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = {
        "error": "Unexpected server response",
      };
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        body["error"] ?? "Upload failed",
      );
    }

    return body;
  }
}