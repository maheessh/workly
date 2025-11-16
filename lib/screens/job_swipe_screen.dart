// lib/screens/job_swipe_screen.dart
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:job_tinder/services/saved_jobs_service.dart';
import 'package:job_tinder/themes/app_theme.dart';
import '../models/swipe_direction.dart';
import '../models/job_model.dart';
import '../providers/auth_provider.dart';
import '../providers/job_provider.dart';
import '../widgets/job_card.dart';
import 'profile_screen.dart';
import 'job_detail_screen.dart';
import 'saved_job_screen.dart';
import 'ai_coach_screen.dart';

class JobSwipeScreen extends StatefulWidget {
  const JobSwipeScreen({super.key});

  @override
  State<JobSwipeScreen> createState() => _JobSwipeScreenState();
}

class _JobSwipeScreenState extends State<JobSwipeScreen>
    with SingleTickerProviderStateMixin {
  final List<JobModel> _savedJobs = [];
  int _cardIndex = 0;
  Offset _cardOffset = Offset.zero;
  final ValueNotifier<SwipeDirection> _swipeDirection =
      ValueNotifier(SwipeDirection.none);
  bool _isSwiping = false;
  final Duration _animationDuration = const Duration(milliseconds: 300);

  // subtle animation for entrance / buttons
  late final AnimationController _buttonsController;
  late final Animation<double> _buttonsScale;

  @override
  void initState() {
    super.initState();
    _loadSavedJobs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JobProvider>().fetchJobs();
    });

    _buttonsController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _buttonsScale = CurvedAnimation(parent: _buttonsController, curve: Curves.easeOutBack);
    _buttonsController.forward();
  }

  @override
  void dispose() {
    _buttonsController.dispose();
    _swipeDirection.dispose();
    super.dispose();
  }

  Future<void> _loadSavedJobs() async {
    final savedJobs = await SavedJobsService.loadSwipedJobs();
    setState(() {
      _savedJobs.addAll(savedJobs);
    });
  }

  Future<void> _saveJobs() async {
    await SavedJobsService.saveSwipedJobs(_savedJobs);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isSwiping) return;
    setState(() {
      _cardOffset += details.delta;
      if (_cardOffset.dx > 12) {
        _swipeDirection.value = SwipeDirection.right;
      } else if (_cardOffset.dx < -12) {
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

  // Navigation helpers
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
    Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
        .then((_) => setState(() {}));
  }

  void _goToAiCoach() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AiCoachScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final jobProvider = context.watch<JobProvider>();
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1000;
    final isDesktop = width >= 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _buildTopTitle(isMobile, isTablet, isDesktop),
        centerTitle: isDesktop,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.person_crop_circle),
          onPressed: _goToProfile,
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.chat_bubble_text_fill,
                color: Color.fromARGB(255, 128, 13, 13), size: 26),
            tooltip: 'AI Coach',
            onPressed: _goToAiCoach,
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.archivebox_fill,
                color: AppTheme.subTextColor, size: 28),
            tooltip: 'Saved Jobs',
            onPressed: _goToSavedJobs,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(jobProvider),
    );
  }

  Widget _buildTopTitle(bool isMobile, bool isTablet, bool isDesktop) {
    // Center title for desktop, left for mobile/tablet
    final titleWidget = Column(
      crossAxisAlignment: isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      
    );
    return titleWidget;
  }

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
        return _loadedBody(provider);
    }
  }

  Widget _loadedBody(JobProvider provider) {
    final jobs = provider.jobs;
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      // area for cards - responsive height limit
      final cardAreaHeight = min(MediaQuery.of(context).size.height * 0.72, 720.0);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Column(
          children: [
            // Card area
            SizedBox(
              height: cardAreaHeight,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: width > 700 ? 560 : width),
                  child: jobs.isEmpty || _cardIndex >= jobs.length
                      ? const Center(child: Text("No jobs found."))
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            // Card stack
                            buildCardStack(jobs),
                          ],
                        ),
                ),
              ),
            ),

            // Action buttons (only when there are more cards)
            if (_cardIndex < (provider.jobs.length))
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 6),
                child: ScaleTransition(
                  scale: _buttonsScale,
                  child: buildActionButtons(),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget buildCardStack(List<JobModel> availableJobs) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // Limit rendered cards to three for performance and visual stack
    final toRender = min(3, availableJobs.length - _cardIndex);

    return Stack(
      alignment: Alignment.center,
      children: List.generate(toRender, (index) {
        final jobIndex = _cardIndex + index;
        final isTopCard = index == 0;
        final cardJob = availableJobs[jobIndex];

        // Score logic (unchanged)
        final key = cardJob.title + cardJob.company;
        final scoreData = context.watch<JobProvider>().jobMatchScores[key];
        int score = 0;
        if (scoreData == null) {
          if (user != null && (isTopCard || index == 1)) {
            context.read<JobProvider>().fetchMatchScore(user: user, job: cardJob);
          }
        } else {
          score = (scoreData['score'] as int?) ?? 0;
          if (score < 0) score = 0;
        }

        // Stacking transform (slight translation & rotation)
        final baseOffset = Offset(0, index * 12.0);
        final slideOffset = isTopCard ? _cardOffset : Offset.zero;
        final totalOffset = baseOffset + slideOffset;
        final rotation = isTopCard
            ? (_cardOffset.dx / (MediaQuery.of(context).size.width * 0.9))
            : (index * -0.03);

        return Positioned(
          top: index * 8.0,
          child: Transform.translate(
            offset: totalOffset,
            child: Transform.rotate(
              angle: rotation,
              child: GestureDetector(
                onPanUpdate: isTopCard ? _onPanUpdate : null,
                onPanEnd: isTopCard ? _onPanEnd : null,
                onTap: isTopCard ? () => _showJobDetails(cardJob) : null,
                child: AnimatedContainer(
                  duration: _animationDuration,
                  curve: Curves.easeOut,
                  width: min(MediaQuery.of(context).size.width, 560),
                  // Wrap the JobCard so it adapts and keeps its rounded look
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Card content (self-contained JobCard)
                      JobCard(
                        job: cardJob,
                        score: score,
                        swipeDirection: isTopCard
                            ? _swipeDirection.value
                            : SwipeDirection.none,
                      ),

                      // Right translucent action icons stacked vertically (mimic heart/star/x)
                      if (isTopCard)
                        Positioned(
                          right: 12,
                          // position above the JobCard's bottom overlay
                          bottom: 110,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _roundIconButton(
                                icon: Icons.close,
                                onTap: _animateAndReject,
                                color: Colors.white.withOpacity(0.95),
                                bg: Colors.black.withOpacity(0.18),
                              ),
                              const SizedBox(height: 12),
                              _roundIconButton(
                                icon: Icons.star_border,
                                onTap: () {
                                  _animateAndSave();
                                },
                                color: Colors.white.withOpacity(0.95),
                                bg: Colors.black.withOpacity(0.18),
                              ),
                              const SizedBox(height: 12),
                              _roundIconButton(
                                icon: Icons.favorite,
                                onTap: _animateAndSave,
                                color: Colors.white.withOpacity(0.95),
                                bg: Colors.black.withOpacity(0.18),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).reversed.toList(),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
    required Color bg,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 48,
        width: 48,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Reject
          FloatingActionButton(
            heroTag: 'reject_btn',
            onPressed: _animateAndReject,
            backgroundColor: Colors.white,
            elevation: 6,
            child: const Icon(Icons.close, color: Colors.red, size: 34),
          ),

          // Info / Details (center)
          FloatingActionButton(
            heroTag: 'info_btn',
            onPressed: () {
              final jobProvider = context.read<JobProvider>();
              if (_cardIndex < jobProvider.jobs.length) {
                _showJobDetails(jobProvider.jobs[_cardIndex]);
              }
            },
            backgroundColor: Colors.white,
            elevation: 6,
            child: const Icon(Icons.info_outline, color: Colors.black87, size: 28),
          ),

          // Save (bookmark)
          FloatingActionButton(
            heroTag: 'save_btn',
            onPressed: _animateAndSave,
            backgroundColor: Colors.white,
            elevation: 6,
            child: const Icon(Icons.bookmark, color: AppTheme.secondaryColor, size: 34),
          ),
        ],
      ),
    );
  }
}
