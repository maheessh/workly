import 'package:flutter/material.dart';
import 'package:job_tinder/themes/app_theme.dart';
import '../models/job_model.dart';

class JobDetailScreen extends StatelessWidget {
  final JobModel job;
  const JobDetailScreen({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              centerTitle: false,
              title: Text(
                job.title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
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
                        child: Icon(job.companyLogo, size: 32, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        job.company,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        job.location,
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
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
                      job.experienceLevel,
                    ),
                    _buildDetailSection(
                      context,
                      'Required Skills',
                      null, // Use child for skills
                      child: Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: job.requiredSkills.map((skill) {
                          return Chip(
                            label: Text(skill),
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            labelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    ),
                    _buildDetailSection(
                      context,
                      'Job Description',
                      job.description,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Mock "Apply" button pressed!')),
                        );
                      },
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

  Widget _buildDetailSection(BuildContext context, String title, String? content, {Widget? child}) {
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
          child ?? Text(
            content ?? '',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}