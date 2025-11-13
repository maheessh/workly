// lib/screens/job_swipe_screen.dart
import 'package:flutter/material.dart';
import 'package:job_tinder/services/saved_jobs_service.dart';
import 'package:provider/provider.dart';
import 'package:job_tinder/screens/saved_job_screen.dart';
import 'package:job_tinder/themes/app_theme.dart';
import 'dart:math';

import '../models/job_model.dart';
import '../models/user_model.dart'; // <-- ADD THIS
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import 'profile_screen.dart';
import 'job_detail_screen.dart';
import '../widgets/job_card.dart';

class JobSwipeScreen extends StatefulWidget {
  const JobSwipeScreen({super.key});

  @override
  State<JobSwipeScreen> createState() => _JobSwipeScreenState();
}

class _JobSwipeScreenState extends State<JobSwipeScreen> {
  final List<JobModel> _savedJobs = [];
  int _cardIndex = 0;

  // --- Animation State (No changes here) ---
  Offset _cardOffset = Offset.zero;
  final ValueNotifier<SwipeDirection> _swipeDirection =
      ValueNotifier(SwipeDirection.none);
  bool _isSwiping = false;
  final Duration _animationDuration = const Duration(milliseconds: 300);
  // ---

  @override
  void initState() {
    super.initState();
    _loadSavedJobs();

    // Fetch the list of jobs from Google Sheets
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().fetchJobs();
    });
  }

  // --- Utility/State Methods (No changes to _loadSavedJobs or _saveJobs) ---
  Future<void> _loadSavedJobs() async {
    final savedJobs = await SavedJobsService.loadSwipedJobs();
    setState(() {
      _savedJobs.addAll(savedJobs);
    });
  }

  Future<void> _saveJobs() async {
    await SavedJobsService.saveSwipedJobs(_savedJobs);
  }
  // ---

  // 🔴 REMOVED: The old `calculateMatchScore` function is gone.
  // int calculateMatchScore(JobModel job) { ... }

  // --- Pan/Drag Handlers (No changes here) ---
  void _onPanUpdate(DragUpdateDetails details) {
    if (_isSwiping) return;
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
      setState(() {
        _cardOffset = Offset.zero;
        _swipeDirection.value = SwipeDirection.none;
      });
    }
  }
  // ---

  // --- Animation Methods (No changes here) ---
  void _advanceCard() {
    setState(() {
      _cardOffset = Offset.zero;
      _swipeDirection.value = SwipeDirection.none;
      _cardIndex++;
      _isSwiping = false;
    });
  }

  void _animateAndSave() {
    final jobProvider = context.read<JobProvider>();
    if (_isSwiping || _cardIndex >= jobProvider.jobs.length) return;

    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      _isSwiping = true;
      _cardOffset = Offset(screenWidth * 1.5, 0);
      _swipeDirection.value = SwipeDirection.right;
    });

    Future.delayed(_animationDuration, () {
      _savedJobs.add(jobProvider.jobs[_cardIndex]);
      _saveJobs();
      _advanceCard();

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
    final jobProvider = context.read<JobProvider>();
    if (_isSwiping || _cardIndex >= jobProvider.jobs.length) return;

    final screenWidth = MediaQuery.of(context).size.width;
    setState(() {
      _isSwiping = true;
      _cardOffset = Offset(-screenWidth * 1.5, 0);
      _swipeDirection.value = SwipeDirection.left;
    });

    Future.delayed(_animationDuration, () {
      _advanceCard();

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
  // ---

  // --- Navigation Methods (No changes here) ---
  void _showJobDetails(JobModel job) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => JobDetailScreen(job: job)),
    );
  }

  void _goToSavedJobs() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => SavedJobsScreen(savedJobs: _savedJobs)),
    );
  }

  void _goToProfile() {
    Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()))
        .then((_) {
      setState(() {});
    });
  }
  // ---

  @override
  Widget build(BuildContext context) {
    // Watch the provider for job list *and* score updates
    final jobProvider = context.watch<JobProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Jobs'),
        leading: IconButton(
          icon: const Icon(Icons.person_outline, color: AppTheme.subTextColor),
          onPressed: _goToProfile,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border,
                color: AppTheme.subTextColor, size: 28),
            onPressed: _goToSavedJobs,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(jobProvider),
    );
  }

  // This widget now builds based on the job list provider state
  Widget _buildBody(JobProvider provider) {
    switch (provider.state) {
      case NotifierState.initial:
      case NotifierState.loading:
        return const Center(child: CircularProgressIndicator());
      case NotifierState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Failed to load jobs:\n${provider.errorMessage}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.red),
            ),
          ),
        );
      case NotifierState.loaded:
        // Data is loaded, show the swipe cards
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            children: [
              Expanded(
                child: provider.jobs.isEmpty
                    ? const Center(
                        child: Text("No jobs found."),
                      )
                    : _cardIndex >= provider.jobs.length
                        ? const Center(
                            child: Text(
                              "That's all for now!\nCheck back later.",
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 20, color: Colors.grey),
                            ),
                          )
                        : buildCardStack(provider.jobs), // Pass jobs list
              ),
              if (_cardIndex < provider.jobs.length) buildActionButtons(),
            ],
          ),
        );
    }
  }

  /// This is the core logic.
  /// It now gets the score from the provider and triggers API calls.
  Widget buildCardStack(List<JobModel> availableJobs) {
    // We also need the user to send to Gemini
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Stack(
      alignment: Alignment.center,
      children: List.generate(
        min(2, availableJobs.length - _cardIndex),
        (index) {
          final jobIndex = _cardIndex + index;
          final isTopCard = index == 0;
          final card = availableJobs[jobIndex];
          
          // --- NEW SCORE LOGIC ---
          // 1. Get the score data from the provider's cache
          final key = card.title + card.company;
          final scoreData = context.watch<JobProvider>().jobMatchScores[key];

          int score = 0; // Default score

          if (scoreData == null) {
            // 2. If score isn't in cache, and we have a user,
            //    and it's one of the top two cards, fetch it.
            if (user != null && (isTopCard || index == 1)) {
              // Use read() to "fire and forget" the API call
              // The provider will notify when the score is ready
              context.read<JobProvider>().fetchMatchScore(user: user, job: card);
            }
          } else {
            // 3. If we have data, use it.
            //    Default to 0 if score is negative (e.g., our -1 loading state)
            score = (scoreData['score'] as int?) ?? 0;
            if (score < 0) score = 0;
          }
          // --- END NEW SCORE LOGIC ---

          // --- Animation logic (No changes) ---
          final dragAmount = _cardOffset.dx.abs();
          double scale = isTopCard ? 1.0 : max(0.9, 1.0 - (dragAmount / 1000));
          double top = isTopCard ? 0 : 10;
          if (!isTopCard) {
            top -= (dragAmount / 40);
          }
          final transform = Matrix4.identity()
            ..translate(_cardOffset.dx)
            ..rotateZ(_cardOffset.dx / (MediaQuery.of(context).size.width * 0.8));

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
                  duration: _isSwiping
                      ? _animationDuration
                      : (_cardOffset == Offset.zero
                          ? _animationDuration
                          : Duration.zero),
                  curve: Curves.easeOut,
                  child: ValueListenableBuilder<SwipeDirection>(
                    valueListenable: _swipeDirection,
                    builder: (context, direction, _) {
                      return JobCard(
                        job: card,
                        score: score, // <-- Pass the new score
                        swipeDirection:
                            isTopCard ? direction : SwipeDirection.none,
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ).reversed.toList(),
    );
  }

  // Action buttons (No changes needed)
  Widget buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: 'reject_btn',
            onPressed: _animateAndReject,
            backgroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.close, color: Colors.red, size: 36),
          ),
          FloatingActionButton(
            heroTag: 'save_btn',
            onPressed: _animateAndSave,
            backgroundColor: Colors.white,
            elevation: 4,
            child: const Icon(Icons.bookmark,
                color: AppTheme.secondaryColor, size: 36),
          ),
        ],
      ),
    );
  }
}