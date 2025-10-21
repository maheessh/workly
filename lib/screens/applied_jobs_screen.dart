import 'package:flutter/material.dart';
import '../models/job_model.dart';

class AppliedJobsScreen extends StatelessWidget {
  final List<JobModel> appliedJobs;
  const AppliedJobsScreen({super.key, required this.appliedJobs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applied Jobs'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: appliedJobs.isEmpty
          ? const Center(child: Text("You haven't applied to any jobs yet.", style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: appliedJobs.length,
              itemBuilder: (context, index) {
                final job = appliedJobs[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(job.companyLogo)),
                    title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${job.company} - ${job.location}'),
                    trailing: const Icon(Icons.check_circle, color: Colors.green),
                  ),
                );
              },
            ),
    );
  }
}