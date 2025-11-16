import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
// --- NEW ---
import 'dart:ui'; // For ImageFilter.blur, though we'll use a simpler glass effect

import 'package:job_tinder/services/gemini_matching_score.dart';
import 'package:job_tinder/themes/app_theme.dart';
import 'package:job_tinder/providers/auth_provider.dart';
import 'package:job_tinder/providers/job_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_model.dart';

class JobDetailScreen extends StatefulWidget {
  final JobModel job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _isGeneratingLetter = false;
  String? _coverLetter;

  // --- NEW: Define the primary red theme color ---
  static const Color _primaryRed = Color(0xFF690F13); // Hex for (105, 15, 19)

  @override
  void initState() {
    super.initState();
    // Your existing initState logic (no changes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobProvider = context.read<JobProvider>();
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;

      final key = widget.job.title + widget.job.company;
      final scoreData = jobProvider.jobMatchScores[key];

      if (user == null || scoreData != null) {
        return;
      }

      jobProvider.fetchMatchScore(user: user, job: widget.job);
    });
  }

  /// Launches the provided URL string in an external browser.
  Future<void> _launchURL(BuildContext context, String urlString) async {
    // (No changes)
    final Uri url = Uri.parse(urlString);
    if (urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No application link provided.')),
      );
      return;
    }
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $urlString')),
      );
    }
  }

  /// Generates a cover letter using the Gemini service.
  Future<void> _generateCoverLetter() async {
    // (No changes)
    setState(() {
      _isGeneratingLetter = true;
      _coverLetter = null; // Clear old one if any
    });

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      setState(() => _isGeneratingLetter = false);
      return;
    }

    try {
      final generatedText = await GeminiMatchingService.generateCoverLetter(
        user: user,
        job: widget.job,
      );
      setState(() {
        _coverLetter = generatedText;
        _isGeneratingLetter = false;
      });
    } catch (e) {
      setState(() {
        _coverLetter = "An error occurred. Please try again.";
        _isGeneratingLetter = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final key = widget.job.title + widget.job.company;
    final scoreData = jobProvider.jobMatchScores[key];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            // --- MODIFIED: Use the defined red color ---
            backgroundColor: _primaryRed,
            elevation: 2,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              centerTitle: false,
              title: Text(
                widget.job.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  shadows: [
                    Shadow(blurRadius: 2, color: Colors.black38, offset: Offset(0, 1))
                  ],
                ),
              ),
              collapseMode: CollapseMode.parallax,
              stretchModes: const [StretchMode.zoomBackground],
              background: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('background.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 40, bottom: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: Icon(widget.job.companyLogo,
                                size: 32, 
                                // --- MODIFIED: Use red for logo icon ---
                                color: _primaryRed),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.job.company,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 2, color: Colors.black54, offset: Offset(0, 1))
                              ],
                            ),
                          ),
                          Text(
                            widget.job.location,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                              shadows: const [
                                Shadow(blurRadius: 2, color: Colors.black38, offset: Offset(0, 1))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                _buildSectionCard(
                  'Experience Level',
                  child: Text(
                    widget.job.experienceLevel,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black87,
                          height: 1.5,
                        ),
                  ),
                ),
                
                // --- MODIFIED: Use new _buildSkillsCard ---
                _buildSkillsCard(
                  'Required Skills',
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0, // Added spacing for better layout
                    children: widget.job.requiredSkills.isEmpty
                        ? [
                            Text(
                              'No specific skills listed.',
                              // --- MODIFIED: Light text for dark card ---
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                            )
                          ]
                        : widget.job.requiredSkills.map((skill) {
                            // --- MODIFIED: Use new glass chip ---
                            return _buildGlassChip(skill);
                          }).toList(),
                  ),
                ),
                
                _buildSectionCard(
                  'Job Description',
                  child: Text(
                    widget.job.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.black87,
                          height: 1.5,
                        ),
                  ),
                ),

                // AI Suggestions section
                _buildAiSuggestions(context, scoreData),

                // Cover Letter section
                if (_isGeneratingLetter || _coverLetter != null)
                  _buildCoverLetterSection(),

                const SizedBox(height: 120),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildApplyButton(context),
    );
  }

  // --- NEW: Helper for the glassmorphism chip ---
  Widget _buildGlassChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // Semi-transparent white
        borderRadius: BorderRadius.circular(16),
        border: Border.all(width: 1, color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white, // White text
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // --- NEW: Helper for the red skills card ---
  Widget _buildSkillsCard(String title, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryRed, // RED BACKGROUND
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2), // Darker shadow
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white, // WHITE TITLE
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ));
  }

  // --- This is the standard white card ---
  Widget _buildSectionCard(String title, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // --- MODIFIED: AI Suggestions with nicer UI ---
  Widget _buildAiSuggestions(
      BuildContext context, Map<String, dynamic>? scoreData) {
    Widget content;

    if (scoreData == null || scoreData['score'] == -1) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: CircularProgressIndicator(color: _primaryRed),
        ),
      );
    } else {
      final positive = scoreData['positiveMatchReason'] ?? 'N/A';
      final negative = scoreData['negativeMatchReason'] ?? 'N/A';
      final resume = scoreData['resumeSuggestion'] ?? 'N/A';
      final coverLetter = scoreData['coverLetterSuggestion'] ?? 'N/A';

      content = Container(
        padding: const EdgeInsets.all(16), // More padding
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sub-heading
            Text(
              'Match Analysis',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            _buildSuggestionRow(
              Icons.check_circle_outline, // New Icon
              positive,
              Colors.green.shade700,
            ),
            _buildSuggestionRow(
              Icons.warning_amber_outlined, // New Icon
              negative,
              Colors.orange.shade800,
            ),
            const Divider(height: 32),
            // Sub-heading
            Text(
              'Actionable Advice',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            _buildSuggestionRow(
              Icons.article_outlined, // New Icon
              resume,
              _primaryRed, // Use red theme
            ),
            _buildSuggestionRow(
              Icons.mail_outline, // New Icon
              coverLetter,
              _primaryRed, // Use red theme
            ),
            const Divider(height: 32),
            if (!_isGeneratingLetter)
              Center(
                // --- MODIFIED: Button style ---
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryRed,
                    side: BorderSide(color: _primaryRed.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _generateCoverLetter,
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text('Generate Cover Letter'),
                ),
              ),
          ],
        ),
      );
    }

    return _buildSectionCard('AI Suggestions', child: content);
  }

  // --- MODIFIED: Uses _buildSectionCard ---
  Widget _buildCoverLetterSection() {
    Widget content;

    if (_isGeneratingLetter) {
      content = const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              CircularProgressIndicator(color: _primaryRed),
              SizedBox(height: 12),
              Text('Generating your letter...'),
            ],
          ),
        ),
      );
    } else if (_coverLetter != null) {
      content = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _coverLetter!,
              style: TextStyle(
                  fontSize: 15, color: Colors.grey.shade800, height: 1.5),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: _primaryRed),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _coverLetter!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Cover letter copied to clipboard!')),
                  );
                },
                icon: const Icon(Icons.copy, size: 18),
                label: const Text('Copy to Clipboard'),
              ),
            ),
          ],
        ),
      );
    } else {
      content = const SizedBox.shrink();
    }
    
    return _buildSectionCard('Generated Cover Letter', child: content);
  }

  // Helper for the suggestion row
  Widget _buildSuggestionRow(IconData icon, String text, Color color) {
    // (No changes)
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // --- MODIFIED: Apply button with gradient ---
  Widget _buildApplyButton(BuildContext context) {
    // Lighter red for the gradient
    final Color lighterRed = const Color(0xFFA01A20); 

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12, // Respects safe area
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      // --- NEW: Container for gradient ---
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [lighterRed, _primaryRed], // Red gradient
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.transparent, // Transparent bg
            shadowColor: Colors.transparent, // No shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: () => _launchURL(context, widget.job.applylink),
          child: const Text(
            'Apply Now',
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: Colors.white, // Ensure text is white
            ),
          ),
        ),
      ),
    );
  }
}