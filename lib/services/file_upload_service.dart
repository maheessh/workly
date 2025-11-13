import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'resume_parser.dart';

class FileUploadService {
  static Future<String?> pickResumeFile() async {
    try {
      // Only request storage permission on mobile platforms
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // For Android 13+ (API 33+), we don't need storage permission for file picker
        if (Platform.isAndroid) {
          // Try to request permission, but don't fail if it's not needed
          try {
            await Permission.storage.request();
            // Continue even if permission is denied, as file picker might still work
          } catch (e) {
            // Ignore permission errors on Android
          }
        } else if (Platform.isIOS) {
          final permission = await Permission.storage.request();
          if (!permission.isGranted) {
            throw Exception('Storage permission denied');
          }
        }
      }

      // Pick resume file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (kIsWeb) {
          // For web, we can't save files locally, so we'll use a mock path
          // In a real app, you'd upload to a server
          return 'web_resume_${DateTime.now().millisecondsSinceEpoch}.${file.extension}';
        } else if (file.path != null) {
          // For mobile/desktop, copy file to app directory
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'resume_${DateTime.now().millisecondsSinceEpoch}.${file.extension}';
          final newPath = '${appDir.path}/$fileName';
          
          final sourceFile = File(file.path!);
          await sourceFile.copy(newPath);
          
          return newPath;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick file: $e');
    }
  }

  // New method for web file parsing
  static Future<Map<String, dynamic>?> pickAndParseResumeFile() async {
    try {
      // Pick resume file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        if (kIsWeb && file.bytes != null) {
          // For web, parse the file bytes directly
          final result = await ResumeParser.parseResumeFromBytes(file.bytes!, file.name);
          result['fileExtension'] = file.extension;
          return result;
        } else if (!kIsWeb && file.path != null) {
          // For mobile/desktop, use the file path
          final result = await ResumeParser.parseResume(file.path!);
          result['fileExtension'] = file.extension;
          return result;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick and parse file: $e');
    }
  }

  static Future<bool> deleteResumeFile(String filePath) async {
    try {
      if (kIsWeb) {
        // On web, we can't delete files, just return true
        return true;
      }
      
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> fileExists(String filePath) async {
    try {
      if (kIsWeb) {
        // On web, assume file exists if it has a web_resume prefix
        return filePath.startsWith('web_resume_');
      }
      
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}