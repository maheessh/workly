import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- 1. ADD FOR CLIPBOARD
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
  // --- 3. ADD STATE FOR COVER LETTER ---
  bool _isGeneratingLetter = false;
  String? _coverLetter;
  // ---

  @override
  void initState() {
    super.initState();
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
    // (No changes to this function)
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

  // --- 4. ADD METHOD TO GENERATE COVER LETTER ---
  Future<void> _generateCoverLetter() async {
    setState(() {
      _isGeneratingLetter = true;
      _coverLetter = null; // Clear old one if any
    });

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    
    if (user == null) {
      setState(() => _isGeneratingLetter = false);
      return; // Should not happen if user is on this screen
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
  // ---

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final key = widget.job.title + widget.job.company;
    final scoreData = jobProvider.jobMatchScores[key];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // (No changes to SliverAppBar)
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              centerTitle: false,
              title: Text(
                widget.job.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.7)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: Icon(widget.job.companyLogo,
                            size: 32, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.job.company,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.job.location,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8), fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      context,
                      'Experience Level',
                      widget.job.experienceLevel,
                    ),
                    _buildDetailSection(
                      context,
                      'Required Skills',
                      null, 
                      child: Wrap(
                        // (No changes to this Wrap)
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: widget.job.requiredSkills.isEmpty
                            ? [
                                Text(
                                  'No specific skills listed.',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                )
                              ]
                            : widget.job.requiredSkills.map((skill) {
                                return Chip(
                                  label: Text(skill),
                                  backgroundColor:
                                      AppTheme.primaryColor.withOpacity(0.1),
                                  labelStyle: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600),
                                  side: BorderSide.none,
                                );
                              }).toList(),
                      ),
                    ),
                    _buildDetailSection(
                      context,
                      'Job Description',
                      widget.job.description,
                    ),

                    _buildAiSuggestions(context, scoreData),
                    
                    // --- 5. ADD THE NEW COVER LETTER WIDGET ---
                    if (_isGeneratingLetter || _coverLetter != null)
                      _buildCoverLetterSection(),
                    // ---
                    
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () => _launchURL(context, widget.job.applylink),
                      child: const Text('Apply Now'),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSuggestions(
      BuildContext context, Map<String, dynamic>? scoreData) {
    // Show a loading spinner if data is null (not fetched)
    // or score is -1 (our "loading" state)
    if (scoreData == null || scoreData['score'] == -1) {
      return _buildDetailSection(
        context,
        'AI Suggestions',
        null,
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final positive = scoreData['positiveMatchReason'] ?? 'N/A';
    final negative = scoreData['negativeMatchReason'] ?? 'N/A';
    final resume = scoreData['resumeSuggestion'] ?? 'N/A';
    final coverLetter = scoreData['coverLetterSuggestion'] ?? 'N/A';

    return _buildDetailSection(
      context,
      'AI Suggestions',
      null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSuggestionRow(
                Icons.check_circle, positive, Colors.green.shade700),
            _buildSuggestionRow(
                Icons.warning, negative, Colors.orange.shade800),
            const Divider(height: 24),
            _buildSuggestionRow(
                Icons.article, resume, AppTheme.primaryColor),
            _buildSuggestionRow(
                Icons.description, coverLetter, AppTheme.primaryColor),
            
            // --- 6. ADD THE GENERATE BUTTON ---
            const Divider(height: 24),
            if (!_isGeneratingLetter)
              Center(
                child: TextButton.icon(
                  onPressed: _generateCoverLetter,
                  icon: const Icon(Icons.auto_awesome, size: 20),
                  label: const Text('Generate Cover Letter'),
                ),
              ),
            // ---
          ],
        ),
      ),
    );
  }

  // --- 7. ADD WIDGET TO DISPLAY THE COVER LETTER ---
  Widget _buildCoverLetterSection() {
    return _buildDetailSection(
      context,
      'Generated Cover Letter',
      null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isGeneratingLetter)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Generating your letter...'),
                    ],
                  ),
                ),
              )
            else if (_coverLetter != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _coverLetter!,
                    style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _coverLetter!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cover letter copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copy to Clipboard'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
  // ---

  // Helper for the suggestion row
  Widget _buildSuggestionRow(IconData icon, String text, Color color) {
    // (No changes to this function)
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
              style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  // This is your existing helper, no changes needed
  Widget _buildDetailSection(BuildContext context, String title, String? content,
      {Widget? child}) {
    // (No changes to this function)
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          child ??
              Text(
                content ?? '',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
        ],
      ),
    );
  }
}