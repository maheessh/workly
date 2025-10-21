import 'package:flutter/material.dart';
import 'package:job_tinder/screens/saved_job_screen.dart';
import 'package:job_tinder/themes/app_theme.dart';
import 'dart:math';

import '../models/job_model.dart';
import '../models/user_model.dart';
import '../data/mock_data.dart';
import 'profile_screen.dart';
import 'job_detail_screen.dart';
import '../widgets/job_card.dart';

class JobSwipeScreen extends StatefulWidget {
  final UserModel user;
  const JobSwipeScreen({super.key, required this.user});

  @override
  State<JobSwipeScreen> createState() => _JobSwipeScreenState();
}

class _JobSwipeScreenState extends State<JobSwipeScreen> {
  final List<JobModel> _savedJobs = [];
  late List<JobModel> _availableJobs;
  int _cardIndex = 0;

  // --- Animation State ---
  Offset _cardOffset = Offset.zero;
  final ValueNotifier<SwipeDirection> _swipeDirection = ValueNotifier(SwipeDirection.none);
  bool _isSwiping = false; // Prevents multiple swipes
  final Duration _animationDuration = const Duration(milliseconds: 300);
  // ---

  @override
  void initState() {
    super.initState();
    _availableJobs = List.from(mockJobs);
  }

  int calculateMatchScore(JobModel job) {
    int score = 0;
    int commonSkills = widget.user.skills.intersection(job.requiredSkills).length;
    if (job.requiredSkills.isNotEmpty) {
      score += (60 * (commonSkills / job.requiredSkills.length)).round();
    }
    if (widget.user.experience == job.experienceLevel) score += 40;
    return min(100, score);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isSwiping) return; // Don't allow drag while animating
    setState(() {
      _cardOffset += details.delta;
      if (_cardOffset.dx > 10) {
        _swipeDirection.value = SwipeDirection.right;
      } else if (_cardOffset.dx < -10) {
        _swipeDirection.value = SwipeDirection.left;
      } else {
        _swipeDirection.value = SwipeDirection.none;
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isSwiping) return;

    if (_cardOffset.dx.abs() > 150) {
      if (_cardOffset.dx > 0) {
        _animateAndSave();
      } else {
        _animateAndReject();
      }
    } else {
      // Animate back to center
      setState(() {
        _cardOffset = Offset.zero;
        _swipeDirection.value = SwipeDirection.none;
      });
    }
  }
  
  void _advanceCard() {
    // This is called AFTER the animation completes
    setState(() {
      _cardOffset = Offset.zero; // Reset position for the new card
      _swipeDirection.value = SwipeDirection.none;
      _cardIndex++;
      _isSwiping = false; // Allow new interactions
    });
  }

  void _animateAndSave() {
    if (_isSwiping || _cardIndex >= _availableJobs.length) return;

    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      _isSwiping = true;
      _cardOffset = Offset(screenWidth * 1.5, 0); // Animate off-screen right
      _swipeDirection.value = SwipeDirection.right;
    });

    // Wait for animation to finish
    Future.delayed(_animationDuration, () {
      _savedJobs.add(_availableJobs[_cardIndex]);
      _advanceCard(); // Move to next card
      
      // Show Notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job saved to your list!'),
            backgroundColor: AppTheme.secondaryColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _animateAndReject() {
    if (_isSwiping || _cardIndex >= _availableJobs.length) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      _isSwiping = true;
      _cardOffset = Offset(-screenWidth * 1.5, 0); // Animate off-screen left
      _swipeDirection.value = SwipeDirection.left;
    });
    
    // Wait for animation to finish
    Future.delayed(_animationDuration, () {
      _advanceCard(); // Move to next card

      // Show Notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Job skipped.'),
            backgroundColor: AppTheme.subTextColor,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showJobDetails(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
    );
  }

  void _goToSavedJobs() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SavedJobsScreen(savedJobs: _savedJobs)),
    );
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen(user: widget.user))
    ).then((_) {
      setState(() {}); 
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Jobs'),
        leading: IconButton(
          icon: const Icon(Icons.person_outline, color: AppTheme.subTextColor),
          onPressed: _goToProfile,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: AppTheme.subTextColor, size: 28),
            onPressed: _goToSavedJobs,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            Expanded(
              child: _cardIndex >= _availableJobs.length
                  ? const Center(
                      child: Text(
                        "That's all for now!\nCheck back later.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, color: Colors.grey)
                      )
                    )
                  : buildCardStack(),
            ),
            if (_cardIndex < _availableJobs.length) buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget buildCardStack() {
    // We only build 2 cards: the top one and the one beneath it.
    return Stack(
      alignment: Alignment.center,
      children: List.generate(
        min(2, _availableJobs.length - _cardIndex),
        (index) {
          final jobIndex = _cardIndex + index;
          final isTopCard = index == 0;
          final card = _availableJobs[jobIndex];
          final score = calculateMatchScore(card);
          
          // Animation for the card underneath
          final dragAmount = _cardOffset.dx.abs();
          double scale = isTopCard ? 1.0 : max(0.9, 1.0 - (dragAmount / 1000));
          double top = isTopCard ? 0 : 10;
          
          if (!isTopCard) {
              top -= (dragAmount / 40);
          }

          // Card's rotation and translation transform
          final transform = Matrix4.identity()
            ..translate(_cardOffset.dx)
            ..rotateZ(_cardOffset.dx / (MediaQuery.of(context).size.width * 0.8));
          
          // Use AnimatedContainer for smooth transitions
          return AnimatedPositioned(
            duration: _animationDuration,
            top: top,
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                onPanUpdate: isTopCard ? _onPanUpdate : null,
                onPanEnd: isTopCard ? _onPanEnd : null,
                onTap: isTopCard ? () => _showJobDetails(card) : null,
                child: AnimatedContainer(
                  transform: isTopCard ? transform : Matrix4.identity(),
                  // This duration handles the swipe/snap-back animation
                  duration: _isSwiping 
                      ? _animationDuration // Animate swipe away
                      : (_cardOffset == Offset.zero ? _animationDuration : Duration.zero), // Animate snap back, but not drag
                  curve: Curves.easeOut,
                  child: ValueListenableBuilder<SwipeDirection>(
                    valueListenable: _swipeDirection,
                    builder: (context, direction, _) {
                        return JobCard(
                          job: card,
                          score: score,
                          swipeDirection: isTopCard ? direction : SwipeDirection.none
                        );
                    }
                  ),
                ),
              ),
            ),
          );
        },
      ).reversed.toList(),
    );
  }

  Widget buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: 'reject_btn',
            onPressed: _animateAndReject, // Use animated method
            backgroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.close, color: Colors.red, size: 36),
          ),
          FloatingActionButton(
            heroTag: 'save_btn',
            onPressed: _animateAndSave, // Use animated method
            backgroundColor: Colors.white,
            elevation: 4,
            // UPDATED: Changed icon to bookmark for clarity
            child: const Icon(Icons.bookmark, color: AppTheme.secondaryColor, size: 36),
          ),
        ],
      ),
    );
  }
}