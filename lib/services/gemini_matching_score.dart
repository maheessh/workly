import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';

class GeminiMatchingService {
  static const String _geminiApiKey = 'AIzaSyBg0bYzNqyw5tH_p_AM0PSaVvmhGeFhYjY';

  static GenerativeModel? _model;

  static GenerativeModel _getGenerativeModel() {
    if (_geminiApiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('Please add your Gemini API Key to gemini_matching_service.dart');
    }
    _model ??= GenerativeModel(
      model: 'gemini-2.5-flash', // Using your specific model
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
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

      final userJson = jsonEncode(user.toJson());
      final jobJson = jsonEncode(job.toJson());
      final prompt = _buildPrompt(userJson, jobJson);

      final response = await model.generateContent([Content.text(prompt)]);
      final jsonString = response.text;

      // This is the fix for the FormatException.
      // If safety settings block, the API returns an empty string.
      if (jsonString == null || jsonString.trim().isEmpty) {
        throw Exception('AI returned no data (empty response). Check safety settings or API key.');
      }

      debugPrint('Gemini JSON Response: $jsonString');

      // Because we use responseMimeType: 'application/json',
      // we can parse directly. No regex needed.
      final Map<String, dynamic> result = jsonDecode(jsonString);
      return result;

    } catch (e) {
      debugPrint('Error with Gemini API: $e');
      return {
        'score': 0,
        'positiveMatchReason': 'Error: Could not calculate score.',
        'negativeMatchReason': 'Check API key, billing, or model name.',
        'resumeSuggestion': 'N/A', // Add defaults for new fields
        'coverLetterSuggestion': 'N/A',
      };
    }
  }

  /// Creates the specialized prompt for the AI
  static String _buildPrompt(String userJson, String jobJson) {
    // We've added two new fields: resumeSuggestion and coverLetterSuggestion
    return '''
    You are an expert HR recruiter. Analyze the USER_PROFILE and JOB_DESCRIPTION.
    
    USER_PROFILE:
    $userJson

    JOB_DESCRIPTION:
    $jobJson

    Respond ONLY with a valid JSON object in the following format:
    {
      "score": <number from 0-100>,
      "positiveMatchReason": "<A single, concise sentence (max 15 words) explaining the strongest reason for this match.>",
      "negativeMatchReason": "<A single, concise sentence (max 15 words) explaining the biggest missing piece or mismatch.>",
      "resumeSuggestion": "<A short, actionable, one-sentence suggestion for the user's resume.>",
      "coverLetterSuggestion": "<A short, actionable, one-sentence suggestion for the user's cover letter.>"
    }
    ''';
  }
}