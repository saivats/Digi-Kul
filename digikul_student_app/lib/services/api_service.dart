import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cohort.dart';
import '../models/lecture.dart';
import '../models/material.dart';

const String baseUrl = 'http://192.168.29.104:5000'; // For physical device

class ApiService {
  static String? _sessionCookie;

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password, 'user_type': 'student'}),
    );

    if (response.statusCode == 200) {
      final String? rawCookie = response.headers['set-cookie'];
      if (rawCookie != null) {
        int index = rawCookie.indexOf(';');
        _sessionCookie = (index == -1) ? rawCookie : rawCookie.substring(0, index);
        return true;
      }
    }
    // If we reach here, login failed or cookie was not set.
    final errorBody = json.decode(response.body);
    throw Exception(errorBody['error'] ?? 'Failed to login');
  }

  static Future<List<Lecture>> getAvailableLectures() async {
    if (_sessionCookie == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$baseUrl/api/student/lectures/available'),
      headers: {'Cookie': _sessionCookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List lecturesJson = data['lectures'];
      return lecturesJson.map((json) => Lecture.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load available lectures');
    }
  }

  static Future<List<Lecture>> getEnrolledLectures() async {
    if (_sessionCookie == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$baseUrl/api/student/enrolled_lectures'),
      headers: {'Cookie': _sessionCookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List lecturesJson = data['lectures'];
      return lecturesJson.map((json) => Lecture.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load enrolled lectures');
    }
  }

  static Future<List<Cohort>> getStudentCohorts() async {
    if (_sessionCookie == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$baseUrl/api/student/cohorts'),
      headers: {'Cookie': _sessionCookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List cohortsJson = data['cohorts'];
      return cohortsJson.map((json) => Cohort.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load student cohorts');
    }
  }

  static Future<List<MaterialItem>> getLectureMaterials(String lectureId) async {
    if (_sessionCookie == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$baseUrl/api/student/lecture/$lectureId/materials'),
      headers: {'Cookie': _sessionCookie!},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List materialsJson = data['materials'];
      return materialsJson.map((json) => MaterialItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load materials');
    }
  }

  static Future<void> enrollInLecture(String lectureId) async {
    if (_sessionCookie == null) throw Exception('Not authenticated');
    final response = await http.post(
      Uri.parse('$baseUrl/api/student/enroll'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': _sessionCookie!,
      },
      body: json.encode({'lecture_id': lectureId}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to enroll: ${response.body}');
    }
  }

  static String getDownloadUrl(String materialId) {
    return '$baseUrl/api/download/$materialId';
  }

  static Future<void> joinCohortByCode(String code) async {
    if (_sessionCookie == null) throw Exception('Not authenticated');
    final response = await http.post(
      Uri.parse('$baseUrl/api/student/join_cohort'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': _sessionCookie!,
      },
      body: json.encode({'code': code}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to join cohort: ${response.body}');
    }
  }
}