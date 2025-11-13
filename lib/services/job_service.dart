// lib/services/job_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_model.dart';

class JobService {
  // 🔽 !!! PASTE YOUR GOOGLE APPS SCRIPT URL HERE !!! 🔽
  static const String _appsScriptUrl = "https://script.google.com/macros/s/AKfycbx0-_4J-Wb92C5rumKhhmnjwmZciIfShU5jhPxd0iGQtmEfk1elyEyZ_6uT8FhRQbdF/exec";

  Future<List<JobModel>> fetchJobs() async {
    try {
      final response = await http.get(Uri.parse(_appsScriptUrl));

      if (response.statusCode == 200) {
        // Decode the JSON list returned from your script
        final List<dynamic> jsonList = jsonDecode(response.body);

        // Map the JSON list to a List<JobModel> using your factory
        List<JobModel> jobs = jsonList
            .map((jsonItem) => JobModel.fromJson(jsonItem as Map<String, dynamic>))
            .toList();
            
        return jobs;
      } else {
        // If the server did not return a 200 OK response
        throw Exception('Failed to load jobs (Status code: ${response.statusCode})');
      }
    } catch (e) {
      // Handle network errors or JSON parsing errors
      throw Exception('Failed to fetch jobs: $e');
    }
  }
}