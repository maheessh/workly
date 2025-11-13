// lib/providers/job_provider.dart
import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../services/job_service.dart';

// Represents the different states your data can be in
enum NotifierState { initial, loading, loaded, error }

class JobProvider extends ChangeNotifier {
  final JobService _jobService = JobService();

  NotifierState _state = NotifierState.initial;
  NotifierState get state => _state;

  List<JobModel> _jobs = [];
  List<JobModel> get jobs => _jobs;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  // This is the function your UI will call to get the jobs
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

  // Helper method to set state and notify listeners
  void _setState(NotifierState state) {
    _state = state;
    notifyListeners();
  }
}