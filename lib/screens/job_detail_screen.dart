import 'package:flutter/material.dart';
import 'package:job_tinder/themes/app_theme.dart';
import 'package:job_tinder/providers/auth_provider.dart'; // <-- ADDED
import 'package:job_tinder/providers/job_provider.dart'; // <-- ADDED
import 'package:provider/provider.dart'; // <-- ADDED
import 'package:url_launcher/url_launcher.dart';
import '../models/job_model.dart';

// 1. CONVERT TO STATEFUL WIDGET
class JobDetailScreen extends StatefulWidget {
  final JobModel job;
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  // 2. ADD INITSTATE TO FETCH SCORE IF NEEDED
  @override
  void initState() {
    super.initState();
    // Check if the score is already in the provider.
    // If not, fetch it. This is useful if the user
    // comes from a "saved jobs" list.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final jobProvider = context.read<JobProvider>();
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.currentUser;
      
      final key = widget.job.title + widget.job.company;
      final scoreData = jobProvider.jobMatchScores[key];

      // If we don't have a user, or score is loading/fetched, do nothing
      if (user == null || scoreData != null) {
        return;
      }
      
      // We have no data for this job, so let's fetch it.
      jobProvider.fetchMatchScore(user: user, job: widget.job);
    });
  }

  /// Launches the provided URL string in an external browser.
  Future<void> _launchURL(BuildContext context, String urlString) async {
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

  @override
  Widget build(BuildContext context) {
    // 3. GET THE JOBPROVIDER TO READ THE SCORE DATA
    final jobProvider = context.watch<JobProvider>();
    final key = widget.job.title + widget.job.company;
    final scoreData = jobProvider.jobMatchScores[key];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
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
                      null, // Use child for skills
                      child: Wrap(
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

                    // --- 4. ADD THE NEW AI SUGGESTIONS SECTION ---
                    _buildAiSuggestions(context, scoreData),
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

  // 5. NEW WIDGET TO BUILD THE AI SECTION
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

    // Get the data (with defaults just in case)
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
          ],
        ),
      ),
    );
  }

  // Helper for the suggestion row
  Widget _buildSuggestionRow(IconData icon, String text, Color color) {
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