import 'dart:ui';
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
    final visibleSkills = job.requiredSkills.take(4).toList();
    final other = job.requiredSkills.length - visibleSkills.length;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black12.withOpacity(.08),
              blurRadius: 25,
              offset: const Offset(0, 12))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // ---------------------------
            //          TOP IMAGE
            // ---------------------------
            Container(
  height: 320,
  width: double.infinity,
  decoration: const BoxDecoration(
    image: DecorationImage(
      image: AssetImage("background.jpg"),
      fit: BoxFit.cover,
    ),
  ),
  child: Stack(
    children: [
      // Blur
      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: Colors.black.withOpacity(0.35)),
        ),
      ),
    ],
  ),
),


            // ---------------------------
            //    TOP LEFT BADGE
            // ---------------------------
            Positioned(
              top: 20,
              left: 20,
              child: _glassBadge(job.experienceLevel),
            ),

            // -------------------------------
            //     BOTTOM INFO OVERLAY
            // -------------------------------
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _bottomOverlay(job, visibleSkills, other),
            ),

            // -------------------------------
            //     SWIPE OVERLAYS
            // -------------------------------
            if (swipeDirection != SwipeDirection.none)
              Positioned.fill(
                child: _swipeStamp(),
              ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Glass Badge
  // ----------------------------------------------------------
  Widget _glassBadge(String level) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.work_outline, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                level,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Bottom white card area (job details)
  // ----------------------------------------------------------
  Widget _bottomOverlay(
      JobModel job, List<String> visibleSkills, int otherCount) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job Title
          Text(
            job.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 6),

          // Company + Location + Match score
          Row(
            children: [
              Text(
                job.company,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.location_on_rounded,
                  size: 16, color: Colors.grey),
              Text(
                job.location,
                style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              _matchScore(),
            ],
          ),

          const SizedBox(height: 16),

          // Skill chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final skill in visibleSkills) _skillChip(skill),
              if (otherCount > 0) _skillChip("+$otherCount more"),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // Skill Chips
  // ----------------------------------------------------------
  Widget _skillChip(String skill) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        skill,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Match Score Pill
  // ----------------------------------------------------------
  Widget _matchScore() {
    final color = getScoreColor(score);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        "$score% Match",
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color,
          fontSize: 13,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // Swipe stamp (NOPE / SAVE)
  // ----------------------------------------------------------
  Widget _swipeStamp() {
    final isSave = swipeDirection == SwipeDirection.right;

    return Center(
      child: Transform.rotate(
        angle: isSave ? -0.3 : 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSave ? AppTheme.secondaryColor : Colors.red,
              width: 4,
            ),
          ),
          child: Text(
            isSave ? "SAVE" : "NOPE",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: isSave ? AppTheme.secondaryColor : Colors.red,
            ),
          ),
        ),
      ),
    );
  }
}
