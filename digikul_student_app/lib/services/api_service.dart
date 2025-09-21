import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cohort.dart';
import '../models/lecture.dart';
import '../models/material.dart';

// Dynamic base URL - can be configured based on environment
String getBaseUrl() {
  // Try to detect if running on emulator vs physical device
  // For development, you can change this IP to your computer's IP
  return 'http://192.168.29.104:5000'; // Update this to your server IP
}

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
      Uri.parse('$baseUrl/api/student/cohorts/join'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': _sessionCookie!,
      },
      body: json.encode({'cohort_code': code}),
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to join cohort: ${response.body}');
    }
  }

  static Future<List<Lecture>> getCohortLectures(String cohortId) async {
    if (_sessionCookie == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$baseUrl/api/student/cohort/$cohortId/lectures'),
      headers: {'Cookie': _sessionCookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List lecturesJson = data['lectures'];
      return lecturesJson.map((json) => Lecture.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cohort lectures');
    }
  }

  static Future<List<Poll>> getLecturePolls(String lectureId) async {
    if (_sessionCookie == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$baseUrl/api/lectures/$lectureId/polls'),
      headers: {'Cookie': _sessionCookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List pollsJson = data['polls'];
      return pollsJson.map((json) => Poll.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load polls');
    }
  }

  static Future<void> voteOnPoll(String pollId, String response) async {
    if (_sessionCookie == null) throw Exception('Not authenticated');
    final httpResponse = await http.post(
      Uri.parse('$baseUrl/api/polls/$pollId/vote'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': _sessionCookie!,
      },
      body: json.encode({'response': response}),
    );
    if (httpResponse.statusCode != 200) {
      throw Exception('Failed to vote: ${httpResponse.body}');
    }
  }

  static Future<PollResults> getPollResults(String pollId) async {
    if (_sessionCookie == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$baseUrl/api/polls/$pollId/results'),
      headers: {'Cookie': _sessionCookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PollResults.fromJson(data['results']);
    } else {
      throw Exception('Failed to load poll results');
    }
  }

  static Future<String?> getActiveSessionId(String lectureId) async {
    if (_sessionCookie == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$baseUrl/api/session/by_lecture/$lectureId'),
      headers: {'Cookie': _sessionCookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['session_id'];
    } else {
      return null; // No active session
    }
  }

  // Validate current session
  static Future<Map<String, dynamic>?> validateSession() async {
    if (_sessionCookie == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/validate-session'),
        headers: {'Cookie': _sessionCookie!},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['valid']) {
          return data;
        }
      }
      
      // Session invalid, clear it
      _sessionCookie = null;
      return null;
    } catch (e) {
      _sessionCookie = null;
      return null;
    }
  }

  // Get all student polls
  static Future<List<Poll>> getStudentPolls() async {
    if (_sessionCookie == null) throw Exception('Not authenticated');
    final response = await http.get(
      Uri.parse('$baseUrl/api/student/polls'),
      headers: {'Cookie': _sessionCookie!},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List pollsJson = data['polls'];
      return pollsJson.map((json) => Poll.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load student polls');
    }
  }

  static Future<void> logout() async {
    if (_sessionCookie == null) return;
    
    try {
      await http.post(
        Uri.parse('$baseUrl/api/logout'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': _sessionCookie!,
        },
      );
    } catch (e) {
      // Even if logout fails on server, clear local session
      print('Logout error: $e');
    } finally {
      _sessionCookie = null;
    }
  }

  static bool get isLoggedIn => _sessionCookie != null;
}

// Poll model
class Poll {
  final String id;
  final String question;
  final List<String> options;
  final DateTime createdAt;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.createdAt,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

// Poll results model
class PollResults {
  final String pollId;
  final String question;
  final int totalVotes;
  final List<PollOptionResult> results;

  PollResults({
    required this.pollId,
    required this.question,
    required this.totalVotes,
    required this.results,
  });

  factory PollResults.fromJson(Map<String, dynamic> json) {
    return PollResults(
      pollId: json['poll_id'] ?? '',
      question: json['question'] ?? '',
      totalVotes: json['total_votes'] ?? 0,
      results: (json['results'] as List)
          .map((result) => PollOptionResult.fromJson(result))
          .toList(),
    );
  }
}

class PollOptionResult {
  final String option;
  final int votes;
  final double percentage;

  PollOptionResult({
    required this.option,
    required this.votes,
    required this.percentage,
  });

  factory PollOptionResult.fromJson(Map<String, dynamic> json) {
    return PollOptionResult(
      option: json['option'] ?? '',
      votes: json['votes'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
    );
  }
}