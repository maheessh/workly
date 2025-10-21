import 'package:flutter/material.dart';
import 'package:job_tinder/themes/app_theme.dart';
import '../models/job_model.dart';

enum SwipeDirection { none, left, right }

class JobCard extends StatelessWidget {
  final JobModel job;
  final int score;
  final SwipeDirection swipeDirection;

  const JobCard({super.key, required this.job, required this.score, this.swipeDirection = SwipeDirection.none});
  
  Color getScoreColor(int score) {
    if (score >= 75) return AppTheme.secondaryColor;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      width: size.width * 0.9,
      height: size.height * 0.65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade100,
                      child: Icon(job.companyLogo, size: 32, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.title, style: Theme.of(context).textTheme.titleLarge, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(job.company, style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(job.location, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Divider(height: 32),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: job.requiredSkills.map((skill) {
                    return Chip(
                      label: Text(skill),
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      labelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      side: BorderSide.none,
                    );
                  }).toList(),
                ),
                const Spacer(),
                Row(
                  children: [
                     Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: getScoreColor(score).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$score% Match',
                        style: TextStyle(color: getScoreColor(score), fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.info_outline, color: Colors.grey, size: 20),
                    const SizedBox(width: 4),
                    Text("Tap for details", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey))
                  ],
                ),
              ],
            ),
          ),
          // Swipe indicator overlay
          if (swipeDirection != SwipeDirection.none)
            Center(
              child: Transform.rotate(
                angle: swipeDirection == SwipeDirection.right ? -0.3 : 0.3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: swipeDirection == SwipeDirection.right ? AppTheme.secondaryColor : Colors.red, width: 4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    // UPDATED: Changed text to "SAVE"
                    swipeDirection == SwipeDirection.right ? 'SAVE' : 'NOPE',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: swipeDirection == SwipeDirection.right ? AppTheme.secondaryColor : Colors.red,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}