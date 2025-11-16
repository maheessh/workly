import 'package:flutter/material.dart';
import 'package:job_tinder/themes/app_theme.dart';
import '../models/job_model.dart';
import 'job_detail_screen.dart'; // Import detail screen

class SavedJobsScreen extends StatelessWidget {
  final List<JobModel> savedJobs;
  const SavedJobsScreen({super.key, required this.savedJobs});

  // ------------------------------------------------------------------
  // --- NEW: Helper widget for the styled tags ---
  // ------------------------------------------------------------------
  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // --- NEW: Helper widget for the custom job card UI ---
  // ------------------------------------------------------------------
  Widget _buildJobCard(BuildContext context, JobModel job) {
    return GestureDetector(
      // We wrap with GestureDetector to keep the onTap functionality
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            // Soft shadow like in the image
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use the company name as the "tag"
            _buildTag(job.company, AppTheme.primaryColor),
            const SizedBox(height: 16),
            // Job Title
            Text(
              job.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            // Location (like the time/subtitle in the image)
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    color: Colors.grey[600], size: 16),
                const SizedBox(width: 6),
                Text(
                  job.location,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // --- UPDATED: Main build method ---
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Set a light background color to match the image's aesthetic
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Saved Jobs'),
        // Style the AppBar to be modern (white, no shadow)
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: savedJobs.isEmpty
          ? const Center(
              child: Text(
                "You haven't saved any jobs yet.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              // Add vertical padding to the list itself
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: savedJobs.length,
              itemBuilder: (context, index) {
                final job = savedJobs[index];
                // Use our new custom card widget
                return _buildJobCard(context, job);
              },
            ),
    );
  }
}