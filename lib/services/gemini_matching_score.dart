import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';

class GeminiMatchingService {
  // --- PASTE YOUR API KEY HERE ---
  // ⚠️ WARNING: For a real app, store this securely (like in a .env file),
  // not directly in your code.
  static const String _geminiApiKey = 'AIzaSyCt4mW7lzomvOsHOsG8ISdftI4_zv-JZfY';

  static GenerativeModel? _model;

  static GenerativeModel _getGenerativeModel() {
    if (_geminiApiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('Please add your Gemini API Key to gemini_matching_service.dart');
    }
    _model ??= GenerativeModel(
      // Use 'gemini-1.5-flash' - it's the fastest model
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
    );
    return _model!;
  }

  /// Calculates a match score by sending user and job data to Gemini.
  static Future<Map<String, dynamic>> getMatchScore({
    required UserModel user,
    required JobModel job,
  }) async {
    try {
      final model = _getGenerativeModel();

      // 1. Convert your Dart objects to JSON strings
      final userJson = jsonEncode(user.toJson());
      final jobJson = jsonEncode(job.toJson()); // Assumes JobModel has toJson()

      // 2. This is the "prompt" - it's the most important part
      final prompt = _buildPrompt(userJson, jobJson);

      // 3. Send the prompt to the API
      final response = await model.generateContent([Content.text(prompt)]);
      final jsonString = response.text;

      if (jsonString == null) {
        throw Exception('AI returned no data.');
      }

      // 4. Clean and parse the JSON response from the AI
      final cleanedJson = jsonString
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      
      final Map<String, dynamic> result = jsonDecode(cleanedJson);
      return result;

    } catch (e) {
      debugPrint('Error with Gemini API: $e');
      return {
        'score': 0,
        'positiveMatchReason': 'Error: Could not calculate score.',
        'negativeMatchReason': '',
      };
    }
  }

  /// Creates the specialized prompt for the AI
  static String _buildPrompt(String userJson, String jobJson) {
    return '''
    You are an expert HR recruiter and data analyst. Your task is to calculate a job match score.

    Analyze the following USER_PROFILE and JOB_DESCRIPTION.
    
    USER_PROFILE:
    $userJson

    JOB_DESCRIPTION:
    $jobJson

    Based on this data, please provide a match score from 0 to 100.
    - 100 is a perfect match.
    - 0 is no match at all.

    Pay close attention to:
    1.  **Skills:** How well do the user's skills match the job's required skills?
    2.  **Experience:** Does the user's experience (e.g., "Senior") match the job's (e.g., "Mid-Level")? "Senior" can match "Mid-Level", but "Entry-Level" cannot match "Senior".
    3.  **Context:** Read the user's summary and the job's description for contextual matches.

    Respond *only* with a valid JSON object in the following format. Do not add any text before or after the JSON.

    {
      "score": <number>,
      "positiveMatchReason": "<A single, concise sentence (max 15 words) explaining the strongest reason for this match.>",
      "negativeMatchReason": "<A single, concise sentence (max 15 words) explaining the biggest missing piece or mismatch.>"
    }
    ''';
  }
}