import 'package:flutter/material.dart';
import 'package:job_tinder/models/swipe_direction.dart';
import 'package:job_tinder/themes/app_theme.dart';
import '../models/job_model.dart';

class JobCard extends StatelessWidget {
  final JobModel job;
  final int score;
  final SwipeDirection swipeDirection;

  const JobCard({
    super.key,
    required this.job,
    required this.score,
    this.swipeDirection = SwipeDirection.none,
  });

  Color getScoreColor(int score) {
    if (score >= 75) return AppTheme.secondaryColor;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final visibleSkills = job.requiredSkills.take(5).toList();
    final otherSkillsCount = job.requiredSkills.length - visibleSkills.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.07),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company logo + name
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                      child: Icon(
                        job.companyLogo,
                        color: AppTheme.primaryColor,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        job.company,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Job Title
                Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Location + match score
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.location,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: getScoreColor(score).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        "$score% Match",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: getScoreColor(score),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Skill tags limited
                Wrap(
                  spacing: 8,
                  runSpacing: -6,
                  children: [
                    for (var skill in visibleSkills)
                      Chip(
                        label: Text(skill,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                        backgroundColor:
                            AppTheme.primaryColor.withOpacity(0.08),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (otherSkillsCount > 0)
                      Chip(
                        label: Text("+$otherSkillsCount more",
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        backgroundColor: Colors.grey.shade200,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),

                const SizedBox(height: 18), // maintains spacing safely

              ],
            ),
          ),

          // Swipe overlays
          if (swipeDirection != SwipeDirection.none)
            Positioned.fill(
              child: Center(
                child: Transform.rotate(
                  angle: swipeDirection == SwipeDirection.right
                      ? -0.3
                      : 0.3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: swipeDirection == SwipeDirection.right
                            ? AppTheme.secondaryColor
                            : Colors.red,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      swipeDirection == SwipeDirection.right
                          ? "SAVE"
                          : "NOPE",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: swipeDirection == SwipeDirection.right
                            ? AppTheme.secondaryColor
                            : Colors.red,
                      ),
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
