import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/job_model.dart';

class SavedJobsService {
  static const String _savedJobsKey = 'saved_jobs_data';
  
  // Save swiped jobs to local storage
  static Future<void> saveSwipedJobs(List<JobModel> savedJobs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert the List<JobModel> to a List<Map<String, dynamic>>
      final jobsJson = savedJobs.map((job) => {
        'title': job.title,
        'company': job.company,
        'location': job.location,
        'experienceLevel': job.experienceLevel,
        'requiredSkills': job.requiredSkills.toList(),
        'description': job.description,
        'companyLogo': job.companyLogo.codePoint, // Convert IconData to int
        'applylink': job.applylink,               // <-- ADDED
      }).toList();
      
      final jsonString = jsonEncode(jobsJson);
      await prefs.setString(_savedJobsKey, jsonString);
    } catch (e) {
      // Handle error silently, or log it
      print('Error saving jobs: $e');
    }
  }
  
  // Load swiped jobs from local storage
  static Future<List<JobModel>> loadSwipedJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_savedJobsKey);
      
      if (jsonString != null) {
        final List<dynamic> jobsData = jsonDecode(jsonString);
        
        // Convert the List<Map<String, dynamic>> back to a List<JobModel>
        final jobs = jobsData.map((jobData) => JobModel(
          title: jobData['title'] ?? '',
          company: jobData['company'] ?? '',
          location: jobData['location'] ?? '',
          experienceLevel: jobData['experienceLevel'] ?? '',
          requiredSkills: (jobData['requiredSkills'] as List<dynamic>?)?.map((e) => e.toString()).toSet() ?? <String>{},
          description: jobData['description'] ?? '',
          companyLogo: IconData(jobData['companyLogo'] as int? ?? 0xe7f1, fontFamily: 'MaterialIcons'), // 0xe7f1 is Icons.business
          applylink: jobData['applylink'] ?? '', // <-- ADDED
        )).toList();
        
        return jobs;
      }
    } catch (e) {
      // Handle error silently, or log it
      print('Error loading jobs: $e');
    }
    // Return an empty list if anything fails
    return [];
  }
  
  // Clear saved jobs
  static Future<void> clearSavedJobs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedJobsKey);
    } catch (e) {
      // Handle error silently
      print('Error clearing jobs: $e');
    }
  }
}