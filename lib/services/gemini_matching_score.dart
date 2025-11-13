import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_model.dart';
import '../models/job_model.dart';

class GeminiMatchingService {
  static const String _geminiApiKey = 'AIzaSyBg0bYzNqyw5tH_p_AM0PSaVvmhGeFhYjY';

  static GenerativeModel? _jsonModel;
  static GenerativeModel? _textModel;
  static final _safetySettings = [
    SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
    SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
    SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
    SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
  ];

  static GenerativeModel _getJsonModel() {
    if (_geminiApiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('Please add your Gemini API Key');
    }
    _jsonModel ??= GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
      safetySettings: _safetySettings,
    );
    return _jsonModel!;
  }

  static GenerativeModel _getTextModel() {
    if (_geminiApiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('Please add your Gemini API Key');
    }
    _textModel ??= GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _geminiApiKey,
      safetySettings: _safetySettings,
    );
    return _textModel!;
  }

  /// Wraps an API call with exponential backoff for retries.
  static Future<T> _withRetry<T>(Future<T> Function() apiCall) async {
    // (This retry logic function is unchanged)
    int retries = 0;
    int maxRetries = 3;
    Duration delay = const Duration(seconds: 1);

    while (retries < maxRetries) {
      try {
        return await apiCall();
      } catch (e) {
        if (e.toString().contains('503') || e.toString().contains('UNAVAILABLE')) {
          retries++;
          if (retries >= maxRetries) {
            debugPrint('Gemini API overloaded. Max retries reached. Failing.');
            throw e;
          }
          debugPrint('Gemini API overloaded. Retrying in ${delay.inSeconds}s... ($retries/$maxRetries)');
          await Future.delayed(delay);
          delay *= 2;
        } else {
          throw e;
        }
      }
    }
    throw Exception('Retry loop failed unexpectedly.');
  }

  // ===================================================================
  // FEATURE 1: JOB MATCH SCORE
  // ===================================================================
  static Future<Map<String, dynamic>> getMatchScore({
    required UserModel user,
    required JobModel job,
  }) async {
    // (This function is unchanged)
    try {
      final model = _getJsonModel();
      final userJson = jsonEncode(user.toJson());
      final jobJson = jsonEncode(job.toJson());
      final prompt = _buildMatchPrompt(userJson, jobJson);

      final response = await _withRetry(() => model.generateContent([Content.text(prompt)]));
      
      final jsonString = response.text;

      if (jsonString == null || jsonString.trim().isEmpty) {
        throw Exception('AI returned no data (empty response).');
      }

      debugPrint('Gemini JSON Response: $jsonString');
      return jsonDecode(jsonString);
    } catch (e) {
      debugPrint('Error with Gemini API (getMatchScore): $e');
      return {
        'score': 0,
        'positiveMatchReason': 'Error: Could not calculate score.',
        'negativeMatchReason': e.toString(),
        'resumeSuggestion': 'N/A',
        'coverLetterSuggestion': 'N/A',
      };
    }
  }

  static String _buildMatchPrompt(String userJson, String jobJson) {
    // (This prompt is unchanged)
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

  // ===================================================================
  // FEATURE 2: COVER LETTER GENERATOR
  // ===================================================================
  static Future<String> generateCoverLetter({
    required UserModel user,
    required JobModel job,
  }) async {
    // (This function is unchanged)
    try {
      final model = _getTextModel();
      final userJson = jsonEncode(user.toJson());
      final jobJson = jsonEncode(job.toJson());
      final prompt = _buildCoverLetterPrompt(userJson, jobJson);

      final response = await _withRetry(() => model.generateContent([Content.text(prompt)]));
      
      return response.text ?? "Error: Could not generate cover letter.";
    } catch (e) {
      debugPrint('Error with Gemini API (generateCoverLetter): $e');
      return "An error occurred while generating your cover letter. Please try again.";
    }
  }

  static String _buildCoverLetterPrompt(String userJson, String jobJson) {
    // (This prompt is unchanged)
    return '''
    You are a professional career coach. A user is applying for a job.
    ...
    Respond *only* with the full text of the cover letter. Do not add any text like "Here is the cover letter:"
    ''';
  }

  // ===================================================================
  // --- MODIFICATION: Renamed and added a new "start" function ---
  // ===================================================================

  // --- NEW FUNCTION ---
  /// Starts a new chat session for the general AI Career Coach.
  static ChatSession startAiCoachChat() {
    final model = _getTextModel();
    final systemPrompt = _buildAiCoachSystemPrompt();
    // Return a chat session with just the system prompt
    return model.startChat(history: [Content.text(systemPrompt)]);
  }

  /// Starts a new chat session for a *specific* mock interview.
  static ChatSession startInterviewChat({required JobModel job}) {
    final model = _getTextModel();
    final systemPrompt = _buildInterviewSystemPrompt(job);
    // Return a chat session with just the system prompt
    return model.startChat(history: [Content.text(systemPrompt)]);
  }

  // --- RENAMED FUNCTION (was sendInterviewMessage) ---
  /// Sends a message to an *existing* chat session (for either Coach or Interview).
  static Future<String> sendChatMessage({
    required ChatSession chat,
    required String message,
  }) async {
    try {
      final response = await _withRetry(() => chat.sendMessage(Content.text(message)));
      return response.text ?? "Error: No response from AI.";
    } catch (e) {
      debugPrint('Error with Gemini API (sendChatMessage): $e');
      return "An error occurred. Please try again.";
    }
  }

  // --- NEW PROMPT ---
  static String _buildAiCoachSystemPrompt() {
    return '''
    You are "Workly", an expert career coach and AI assistant. 
    The user will ask you general questions about job searching, resume writing, interview tips, or career advice. 
    Be friendly, encouraging, and provide clear, actionable advice.
    Start the conversation by introducing yourself and asking how you can help.
    ''';
  }

  static String _buildInterviewSystemPrompt(JobModel job) {
    // (This prompt is unchanged)
    return '''
    You are an expert HR manager at ${job.company}, hiring for the ${job.title} role. 
    ...
    Ask a mix of behavioral ("Tell me about a time...") and technical questions...
    ''';
  }
}