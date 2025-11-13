// lib/providers/job_provider.dart
import 'package:flutter/material.dart';
import 'package:job_tinder/services/gemini_matching_score.dart';
import '../models/job_model.dart';
import '../models/user_model.dart'; // <-- ADD THIS
import '../services/job_service.dart';

enum NotifierState { initial, loading, loaded, error }

class JobProvider extends ChangeNotifier {
  final JobService _jobService = JobService();

  NotifierState _state = NotifierState.initial;
  NotifierState get state => _state;

  List<JobModel> _jobs = [];
  List<JobModel> get jobs => _jobs;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // --- NEW: State for storing match scores ---
  // We use a Map to cache scores. The key is a unique ID (e.g., job.title + job.company)
  // The value is the full response from Gemini.
  final Map<String, Map<String, dynamic>> _jobMatchScores = {};
  Map<String, Map<String, dynamic>> get jobMatchScores => _jobMatchScores;
  // ---

  // Method to fetch jobs (this is your existing function)
  Future<void> fetchJobs() async {
    _setState(NotifierState.loading);
    try {
      _jobs = await _jobService.fetchJobs();
      _setState(NotifierState.loaded);
    } catch (e) {
      _errorMessage = e.toString();
      _setState(NotifierState.error);
    }
  }

  // --- NEW: Function to get a match score for a single job ---
  Future<void> fetchMatchScore({
    required UserModel user,
    required JobModel job,
  }) async {
    // Create a unique key for this job to store in our map
    final key = job.title + job.company;

    // Check if score is already fetched or is being fetched
    if (_jobMatchScores.containsKey(key)) {
      return; // We already have this score, no need to call API again
    }

    try {
      // Set a "loading" state for this specific card
      // This prevents multiple, rapid calls for the same card
      _jobMatchScores[key] = {'score': -1, 'positiveMatchReason': 'Loading...'};
      
      // We don't notify listeners yet, to prevent a fast "loading" flash

      // Call the Gemini service
      final scoreData = await GeminiMatchingService.getMatchScore(
        user: user,
        job: job,
      );

      // Store the actual score
      _jobMatchScores[key] = scoreData;

      // NOW notify listeners to update the UI with the new score
      notifyListeners();
    } catch (e) {
      // If Gemini fails, store a 0 score
      _jobMatchScores[key] = {
        'score': 0,
        'positiveMatchReason': 'Error calculating score.',
        'negativeMatchReason': e.toString(),
      };
      notifyListeners(); // Notify even on error
    }
  }

  void _setState(NotifierState state) {
    _state = state;
    notifyListeners();
  }
}