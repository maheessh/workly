import 'package:flutter/material.dart';
import 'package:job_tinder/themes/app_theme.dart';
import '../models/job_model.dart';
import 'job_detail_screen.dart'; // Import detail screen

class SavedJobsScreen extends StatelessWidget {
  final List<JobModel> savedJobs;
  const SavedJobsScreen({super.key, required this.savedJobs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs'),
      ),
      body: savedJobs.isEmpty
          ? const Center(
              child: Text(
                "You haven't saved any jobs yet.",
                style: TextStyle(fontSize: 18, color: Colors.grey)
              )
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: savedJobs.length,
              itemBuilder: (context, index) {
                final job = savedJobs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(job.companyLogo)),
                    title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${job.company} - ${job.location}'),
                    trailing: const Icon(Icons.bookmark, color: AppTheme.primaryColor),
                    onTap: () {
                      // NEW: Tap to see details
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}