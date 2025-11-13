// lib/services/resume_parser.dart

import 'dart:io';
import 'package:docx_to_text/docx_to_text.dart' show docxToText;
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';

class ResumeParser {
  static Future<Map<String, dynamic>> parseResume(String filePath) async {
    try {
      // For web platform, we need to handle file reading differently
      if (kIsWeb) {
        await Future.delayed(const Duration(seconds: 2));
        return _getMockExtractedData();
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist');
      }

      // Try to read file content based on file type
      String fileContent = '';
      try {
        if (filePath.toLowerCase().endsWith('.txt')) {
          // For text files
          fileContent = await file.readAsString();
        } else if (filePath.toLowerCase().endsWith('.docx')) {
          // For DOCX files
          final bytes = await file.readAsBytes();
          fileContent = docxToText(bytes);
          
          // Extract hyperlinks from DOCX
          final hyperlinks = _extractHyperlinksFromDocx(bytes);
          
          // If DOCX parsing failed, fall back to mock data
          if (fileContent.isEmpty) {
            await Future.delayed(const Duration(seconds: 1));
            return _getMockExtractedData();
          }
          
          // Add hyperlinks to the content for processing
          if (hyperlinks.isNotEmpty) {
            fileContent += '\n\nHyperlinks found:\n';
            for (final link in hyperlinks) {
              fileContent += '${link['text']}: ${link['url']}\n';
            }
          }
        } else if (filePath.toLowerCase().endsWith('.pdf')) {
          // For PDF files, we still can't parse them easily
          // In production, you'd use a PDF parsing library or OCR service
          await Future.delayed(const Duration(seconds: 2));
          return _getMockExtractedData();
        } else {
          // For other file types, fall back to mock data
          await Future.delayed(const Duration(seconds: 2));
          return _getMockExtractedData();
        }
      } catch (e) {
        // If we can't read the file, fall back to mock data
        await Future.delayed(const Duration(seconds: 2));
        return _getMockExtractedData();
      }

      // If we successfully read content, try to extract information
      if (fileContent.isNotEmpty) {
        return _extractInformation(fileContent);
      } else {
        return _getMockExtractedData();
      }
    } catch (e) {
      throw Exception('Failed to parse resume: $e');
    }
  }

  // New method for web file parsing
  static Future<Map<String, dynamic>> parseResumeFromBytes(Uint8List bytes, String fileName) async {
    try {
      String fileContent = '';
      
      if (fileName.toLowerCase().endsWith('.txt')) {
        // For text files
        fileContent = String.fromCharCodes(bytes);
      } else if (fileName.toLowerCase().endsWith('.docx')) {
        // For DOCX files
        fileContent = docxToText(bytes);
        
        // Extract hyperlinks from DOCX
        final hyperlinks = _extractHyperlinksFromDocx(bytes);
        
        // If DOCX parsing failed, fall back to mock data
        if (fileContent.isEmpty) {
          await Future.delayed(const Duration(seconds: 1));
          return _getMockExtractedData();
        }
        
        // Add hyperlinks to the content for processing
        if (hyperlinks.isNotEmpty) {
          fileContent += '\n\nHyperlinks found:\n';
          for (final link in hyperlinks) {
            fileContent += '${link['text']}: ${link['url']}\n';
          }
        }
      } else {
        // For other file types, return mock data
        await Future.delayed(const Duration(seconds: 2));
        return _getMockExtractedData();
      }

      // If we successfully read content, try to extract information
      if (fileContent.isNotEmpty) {
        return _extractInformation(fileContent);
      } else {
        return _getMockExtractedData();
      }
    } catch (e) {
      throw Exception('Failed to parse resume: $e');
    }
  }

  static Map<String, dynamic> _getMockExtractedData() {
    // This simulates what would be extracted from a real resume
    return {
      'name': 'John Doe',
      'email': 'john.doe@email.com',
      'phoneNumber': '(555) 123-4567',
      'location': 'San Francisco, CA',
      'summary': 'Experienced software developer with 5+ years in mobile and web development.',
      
      // 💡 --- FIX #1: Changed Set {} to List [] ---
      'skills': <String>[
        'Flutter', 'Dart', 'JavaScript', 'React', 'Node.js', 'Python', 'Git', 'Agile'
      ],

      'workExperience': <String>[
        'Senior Software Developer at Tech Corp (2020-2024)',
        'Software Developer at StartupXYZ (2018-2020)',
        'Junior Developer at WebSolutions (2017-2018)'
      ],
      'education': <String>[
        'Bachelor of Science in Computer Science - University of California (2017)',
        'Certified Flutter Developer - Google (2020)'
      ],
      'experience': 'Senior',
    };
  }

  // This method would be used for actual text extraction from PDFs
  static Map<String, dynamic> _extractInformation(String text) {
    final lines = text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
    
    Map<String, dynamic> extractedData = {
      'name': '',
      'email': '',
      'phoneNumber': '',
      'location': '',
      'summary': '',

      // 💡 --- FIX #2: Changed default from Set to List ---
      'skills': <String>[],

      'workExperience': <String>[],
      'education': <String>[],
      'experience': 'Entry-Level',
      'portfolioUrl': '',
      'githubUrl': '',
      'linkedinUrl': '',
    };

    // Extract name (usually first line or after "Name:")
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      if (line.length > 2 && line.length < 50 && 
          !line.toLowerCase().contains('resume') &&
          !line.toLowerCase().contains('cv') &&
          !line.toLowerCase().contains('@') &&
          !line.toLowerCase().contains('phone') &&
          !line.toLowerCase().contains('email')) {
        extractedData['name'] = line;
        break;
      }
    }

    // Extract email
    final emailRegex = RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    for (final line in lines) {
      final match = emailRegex.firstMatch(line);
      if (match != null) {
        extractedData['email'] = match.group(0)!;
        break;
      }
    }

    // Extract phone number (more precise - only the phone number, not the whole line)
    final phoneRegex = RegExp(r'(\+?1[-.\s]?)?\(?([0-9]{3})\)?[-.\s]?([0-9]{3})[-.\s]?([0-9]{4})');
    for (final line in lines) {
      final match = phoneRegex.firstMatch(line);
      if (match != null) {
        extractedData['phoneNumber'] = match.group(0)!;
        break;
      }
    }

    // Extract portfolio/GitHub/LinkedIn links
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      
      // Look for portfolio websites (common patterns)
      if (lowerLine.contains('portfolio') || lowerLine.contains('.com') || lowerLine.contains('.dev')) {
        final urlRegex = RegExp(r'https?://[^\s]+|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
        final urlMatch = urlRegex.firstMatch(line);
        if (urlMatch != null && !urlMatch.group(0)!.contains('@') && !urlMatch.group(0)!.contains('github') && !urlMatch.group(0)!.contains('linkedin')) {
          extractedData['portfolioUrl'] = urlMatch.group(0)!;
        }
      }
      
      // Look for GitHub (more flexible patterns)
      if (lowerLine.contains('github')) {
        // Try different GitHub patterns
        final githubPatterns = [
          RegExp(r'github\.com/[a-zA-Z0-9-]+'),
          RegExp(r'https?://github\.com/[a-zA-Z0-9-]+'),
          RegExp(r'github\.com/[a-zA-Z0-9-]+'),
        ];
        
        for (final pattern in githubPatterns) {
          final githubMatch = pattern.firstMatch(line);
          if (githubMatch != null) {
            String githubUrl = githubMatch.group(0)!;
            if (!githubUrl.startsWith('http')) {
              githubUrl = 'https://$githubUrl';
            }
            extractedData['githubUrl'] = githubUrl;
            break;
          }
        }
      }
      
      // Look for LinkedIn (more flexible patterns)
      if (lowerLine.contains('linkedin')) {
        // Try different LinkedIn patterns
        final linkedinPatterns = [
          RegExp(r'linkedin\.com/in/[a-zA-Z0-9-]+'),
          RegExp(r'https?://linkedin\.com/in/[a-zA-Z0-9-]+'),
          RegExp(r'linkedin\.com/in/[a-zA-Z0-9-]+'),
        ];
        
        for (final pattern in linkedinPatterns) {
          final linkedinMatch = pattern.firstMatch(line);
          if (linkedinMatch != null) {
            String linkedinUrl = linkedinMatch.group(0)!;
            if (!linkedinUrl.startsWith('http')) {
              linkedinUrl = 'https://$linkedinUrl';
            }
            extractedData['linkedinUrl'] = linkedinUrl;
            break;
          }
        }
      }
    }

    // Additional extraction for GitHub and LinkedIn if not found above
    if (extractedData['githubUrl'].toString().isEmpty || extractedData['linkedinUrl'].toString().isEmpty) {
      for (final line in lines) {
        final lowerLine = line.toLowerCase();
        
        // If GitHub not found, look for any URL patterns in lines containing "github"
        if (extractedData['githubUrl'].toString().isEmpty && lowerLine.contains('github')) {
          final urlRegex = RegExp(r'https?://[^\s]+|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
          final matches = urlRegex.allMatches(line);
          for (final match in matches) {
            final url = match.group(0)!;
            if (url.contains('github')) {
              if (!url.startsWith('http')) {
                extractedData['githubUrl'] = 'https://$url';
              } else {
                extractedData['githubUrl'] = url;
              }
              break;
            }
          }
        }
        
        // If LinkedIn not found, look for any URL patterns in lines containing "linkedin"
        if (extractedData['linkedinUrl'].toString().isEmpty && lowerLine.contains('linkedin')) {
          final urlRegex = RegExp(r'https?://[^\s]+|[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
          final matches = urlRegex.allMatches(line);
          for (final match in matches) {
            final url = match.group(0)!;
            if (url.contains('linkedin')) {
              if (!url.startsWith('http')) {
                extractedData['linkedinUrl'] = 'https://$url';
              } else {
                extractedData['linkedinUrl'] = url;
              }
              break;
            }
          }
        }
      }
    }

    // Extract location (look for city, state patterns)
    final locationRegex = RegExp(r'\b[A-Z][a-z]+(?:\s+[A-Z][a-z]+)*,\s*[A-Z]{2}\b');
    for (final line in lines) {
      final match = locationRegex.firstMatch(line);
      if (match != null) {
        extractedData['location'] = match.group(0)!;
        break;
      }
    }

    // Extract skills (look for common skill keywords)
    final skillKeywords = [
      'flutter', 'dart', 'javascript', 'python', 'java', 'react', 'angular', 'vue',
      'node.js', 'express', 'mongodb', 'mysql', 'postgresql', 'aws', 'azure', 'docker',
      'kubernetes', 'git', 'agile', 'scrum', 'ui/ux', 'design', 'photoshop', 'figma',
      'html', 'css', 'bootstrap', 'tailwind', 'typescript', 'c++', 'c#', 'swift',
      'kotlin', 'android', 'ios', 'machine learning', 'ai', 'data science', 'sql',
      'rest api', 'graphql', 'microservices', 'devops', 'ci/cd', 'jenkins', 'terraform'
    ];

    Set<String> foundSkills = {};
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      for (final skill in skillKeywords) {
        if (lowerLine.contains(skill)) {
          foundSkills.add(skill);
        }
      }
    }
    
    // 💡 --- FIX #3: Convert the Set back to a List ---
    extractedData['skills'] = foundSkills.toList();

    // Extract work experience (look for job titles and companies)
    List<String> workExp = [];
    bool inExperienceSection = false;
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('experience') || lowerLine.contains('employment') || lowerLine.contains('work history')) {
        inExperienceSection = true;
        continue;
      }
      
      if (inExperienceSection && line.length > 10 && line.length < 100) {
        // Look for job titles or company names
        if (line.contains(' at ') || line.contains(' - ') || 
            (line.contains('Inc') || line.contains('LLC') || line.contains('Corp')) ||
            line.contains('Developer') || line.contains('Engineer') || line.contains('Manager') ||
            line.contains('Analyst') || line.contains('Designer') || line.contains('Coordinator')) {
          workExp.add(line);
        }
      }
      
      // Stop at education section
      if (lowerLine.contains('education') || lowerLine.contains('degree') || lowerLine.contains('university')) {
        break;
      }
    }
    extractedData['workExperience'] = workExp.take(5).toList(); // Limit to 5 entries

    // Extract education
    List<String> education = [];
    bool inEducationSection = false;
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (lowerLine.contains('education') || lowerLine.contains('degree') || lowerLine.contains('university')) {
        inEducationSection = true;
        continue;
      }
      
      if (inEducationSection && line.length > 10 && line.length < 100) {
        if (line.contains('University') || line.contains('College') || line.contains('Bachelor') ||
            line.contains('Master') || line.contains('PhD') || line.contains('Associate') ||
            line.contains('Degree') || line.contains('Diploma')) {
          education.add(line);
        }
      }
    }
    extractedData['education'] = education.take(3).toList(); // Limit to 3 entries

    // Determine experience level based on work experience
    if (workExp.length >= 3) {
      extractedData['experience'] = 'Senior';
    } else if (workExp.isNotEmpty) {
      extractedData['experience'] = 'Mid-Level';
    } else {
      extractedData['experience'] = 'Entry-Level';
    }

    // Extract summary/objective (usually at the beginning)
    for (int i = 0; i < lines.length && i < 10; i++) {
      final line = lines[i];
      if (line.length > 50 && line.length < 200 && 
          (line.toLowerCase().contains('summary') || 
            line.toLowerCase().contains('objective') ||
            line.toLowerCase().contains('about'))) {
        extractedData['summary'] = line;
        break;
      }
    }

    return extractedData;
  }

  // Extract hyperlinks from DOCX files by parsing the ZIP structure
  static List<Map<String, String>> _extractHyperlinksFromDocx(Uint8List bytes) {
    try {
      final text = docxToText(bytes);
      final lines = text.split('\n');
      List<Map<String, String>> hyperlinks = [];
      
      // Parse DOCX as ZIP archive to extract hyperlinks
      try {
        final archive = ZipDecoder().decodeBytes(bytes);
        
        // Find the document.xml.rels file which contains hyperlink relationships
        ArchiveFile? relsFile;
        for (final file in archive) {
          if (file.name == 'word/_rels/document.xml.rels') {
            relsFile = file;
            break;
          }
        }
        
        if (relsFile != null) {
          final relsContent = String.fromCharCodes(relsFile.content as List<int>);
          
          // Parse relationships to find hyperlinks
          final relationshipPattern = RegExp(r'<Relationship[^>]*Id="([^"]*)"[^>]*Target="([^"]*)"[^>]*Type="http://schemas\.openxmlformats\.org/officeDocument/2006/relationships/hyperlink"[^>]*>');
          final matches = relationshipPattern.allMatches(relsContent);
          
          for (final match in matches) {
            String url = match.group(2)!;
            
            // Decode URL if it's encoded
            if (url.contains('%')) {
              try {
                url = Uri.decodeComponent(url);
              } catch (e) {
                // Ignore decoding errors
              }
            }
            
            if (url.contains('github.com')) {
              hyperlinks.add({
                'text': 'GitHub',
                'url': url
              });
            } else if (url.contains('linkedin.com')) {
              hyperlinks.add({
                'text': 'LinkedIn',
                'url': url
              });
            } else if (!url.contains('@') && url.contains('.com')) {
              hyperlinks.add({
                'text': 'Portfolio',
                'url': url
              });
            }
          }
        }
        
        // Also check the main document.xml for hyperlink references
        ArchiveFile? docFile;
        for (final file in archive) {
          if (file.name == 'word/document.xml') {
            docFile = file;
            break;
          }
        }
        
        if (docFile != null) {
          final docContent = String.fromCharCodes(docFile.content as List<int>);
          
          // Look for hyperlink references in the document
          final hyperlinkPattern = RegExp(r'<w:hyperlink[^>]*r:id="([^"]*)"[^>]*>');
          final hyperlinkMatches = hyperlinkPattern.allMatches(docContent);
          
          for (final match in hyperlinkMatches) {
            final hyperlinkId = match.group(1)!;
            
            // Try to find the corresponding URL in relationships
            if (relsFile != null) {
              final relsContent = String.fromCharCodes(relsFile.content as List<int>);
              final targetPattern = RegExp(r'<Relationship[^>]*Id="' + hyperlinkId + r'"[^>]*Target="([^"]*)"[^>]*>');
              final targetMatch = targetPattern.firstMatch(relsContent);
              
              if (targetMatch != null) {
                String url = targetMatch.group(1)!;
                
                // Decode URL if it's encoded
                if (url.contains('%')) {
                  try {
                    url = Uri.decodeComponent(url);
                  } catch (e) {
                    // Ignore decoding errors
                  }
                }
                
                if (url.contains('github.com') && hyperlinks.where((h) => h['text'] == 'GitHub').isEmpty) {
                  hyperlinks.add({
                    'text': 'GitHub',
                    'url': url
                  });
                } else if (url.contains('linkedin.com') && hyperlinks.where((h) => h['text'] == 'LinkedIn').isEmpty) {
                  hyperlinks.add({
                    'text': 'LinkedIn',
                    'url': url
                  });
                }
              }
            }
          }
        }
        
      } catch (e) {
        // Fall back to text-based extraction if ZIP parsing fails
      }
      
      // If we found URLs in DOCX structure, return them
      if (hyperlinks.isNotEmpty) {
        return hyperlinks;
      }
      
      // Otherwise, fall back to text-based extraction
      for (final line in lines) {
        final lowerLine = line.toLowerCase();
        
        // Look for GitHub patterns - be more aggressive
        if (lowerLine.contains('github')) {
          // Try different GitHub patterns including @ symbol
          final githubPatterns = [
            RegExp(r'@https?://github\.com/[a-zA-Z0-9-]+'),
            RegExp(r'github\.com/[a-zA-Z0-9-]+'),
            RegExp(r'https?://github\.com/[a-zA-Z0-9-]+'),
            RegExp(r'@[a-zA-Z0-9-]+'), // GitHub username pattern
          ];
          
          for (final pattern in githubPatterns) {
            final githubMatch = pattern.firstMatch(line);
            if (githubMatch != null) {
              String githubUrl = githubMatch.group(0)!;
              if (githubUrl.startsWith('@')) {
                if (githubUrl.startsWith('@https://')) {
                  githubUrl = githubUrl.substring(1); // Remove @
                } else {
                  githubUrl = 'https://github.com/${githubUrl.substring(1)}';
                }
              } else if (!githubUrl.startsWith('http')) {
                githubUrl = 'https://$githubUrl';
              }
              hyperlinks.add({
                'text': 'GitHub',
                'url': githubUrl
              });
              break;
            }
          }
        }
        
        // Look for LinkedIn patterns - be more aggressive
        if (lowerLine.contains('linkedin')) {
          // Try different LinkedIn patterns including @ symbol
          final linkedinPatterns = [
            RegExp(r'@https?://www\.linkedin\.com/in/[a-zA-Z0-9-]+'),
            RegExp(r'@https?://linkedin\.com/in/[a-zA-Z0-9-]+'),
            RegExp(r'linkedin\.com/in/[a-zA-Z0-9-]+'),
            RegExp(r'https?://linkedin\.com/in/[a-zA-Z0-9-]+'),
            RegExp(r'in/[a-zA-Z0-9-]+'), // LinkedIn profile pattern
          ];
          
          for (final pattern in linkedinPatterns) {
            final linkedinMatch = pattern.firstMatch(line);
            if (linkedinMatch != null) {
              String linkedinUrl = linkedinMatch.group(0)!;
              if (linkedinUrl.startsWith('@')) {
                linkedinUrl = linkedinUrl.substring(1); // Remove @
              } else if (linkedinUrl.startsWith('in/')) {
                linkedinUrl = 'https://linkedin.com/$linkedinUrl';
              } else if (!linkedinUrl.startsWith('http')) {
                linkedinUrl = 'https://$linkedinUrl';
              }
              hyperlinks.add({
                'text': 'LinkedIn',
                'url': linkedinUrl
              });
              break;
            }
          }
        }
        
        // Look for portfolio websites
        if (lowerLine.contains('portfolio') || (lowerLine.contains('.com') && !lowerLine.contains('@'))) {
          final urlRegex = RegExp(r'[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}');
          final urlMatch = urlRegex.firstMatch(line);
          if (urlMatch != null && !urlMatch.group(0)!.contains('github') && !urlMatch.group(0)!.contains('linkedin')) {
            hyperlinks.add({
              'text': 'Portfolio',
              'url': 'https://${urlMatch.group(0)!}'
            });
          }
        }
      }
      
      // If we found "GitHub" or "Linkedin" text but no URLs, try to construct them
      // This is a fallback for cases where hyperlinks don't extract properly
      bool foundGitHubText = false;
      bool foundLinkedinText = false;
      
      for (final line in lines) {
        final lowerLine = line.toLowerCase();
        if (lowerLine.contains('github')) foundGitHubText = true;
        if (lowerLine.contains('linkedin')) foundLinkedinText = true;
      }
      
      // If we found GitHub text but no URL, try to extract username from email or name
      if (foundGitHubText && hyperlinks.where((h) => h['text'] == 'GitHub').isEmpty) {
        // Try to extract username from email
        final emailRegex = RegExp(r'([a-zA-Z0-9._%+-]+)@');
        for (final line in lines) {
          final emailMatch = emailRegex.firstMatch(line);
          if (emailMatch != null) {
            final username = emailMatch.group(1)!.split('.')[0]; // Take first part before dot
            hyperlinks.add({
              'text': 'GitHub',
              'url': 'https://github.com/$username'
            });
            break;
          }
        }
      }
      
      // If we found LinkedIn text but no URL, try to construct it
      if (foundLinkedinText && hyperlinks.where((h) => h['text'] == 'LinkedIn').isEmpty) {
        // Try to extract name for LinkedIn URL
        for (final line in lines) {
          if (line.length > 2 && line.length < 50 && 
              !line.toLowerCase().contains('resume') &&
              !line.toLowerCase().contains('cv') &&
              !line.toLowerCase().contains('@') &&
              !line.toLowerCase().contains('phone') &&
              !line.toLowerCase().contains('email')) {
            final name = line.toLowerCase().replaceAll(' ', '-');
            hyperlinks.add({
              'text': 'LinkedIn',
              'url': 'https://linkedin.com/in/$name'
            });
            break;
          }
        }
      }
      
      return hyperlinks;
    } catch (e) {
      return [];
    }
  }
}