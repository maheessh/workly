// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/workly_logo.dart';
import 'profile_screen.dart';
import 'job_swipe_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  // Accent colors and urls
  static const Color maroon = Color(0xFFB3363D); // base maroon (can be used)
  static const Color fadedText = Color(0xFF6E6E6E);

  static const String googleIconUrl =
      "https://developers.google.com/identity/images/g-logo.png";

  // Animation controllers
  late final AnimationController _appearController;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;

  @override
  void initState() {
    super.initState();

    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _appearController, curve: Curves.easeOut));
    _titleFade = CurvedAnimation(parent: _appearController, curve: Curves.easeOut);

    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.20), end: Offset.zero).animate(
        CurvedAnimation(parent: _appearController, curve: Curves.easeOutQuint));
    _cardFade = CurvedAnimation(parent: _appearController, curve: Curves.easeOutQuint);

    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _appearController.forward();
    });
  }

  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  // --- Authentication logic (kept identical) ---
  Future<void> _signInWithGoogle(BuildContext context) async {
    final ap = Provider.of<AuthProvider>(context, listen: false);
    final success = await ap.signInWithGoogle();

    if (!context.mounted) return;

    if (success) {
      // small delay to show animation
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!context.mounted) return;
        final user = ap.currentUser;
        if (user == null) return;
        if (user.phoneNumber.isNotEmpty && user.location.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const JobSwipeScreen()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          );
        }
      });
    } else if (ap.errorMessage != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ap.errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  void _signInAsGuest() {
    Provider.of<AuthProvider>(context, listen: false).signInAsGuest();
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder for breakpoints so the UI adapts responsively
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isMobile = width < 600;
          final isTablet = width >= 600 && width < 1000;
          final isDesktop = width >= 1000;

          // horizontal padding adjusts with screen size
          final horizontalPadding = isMobile ? 20.0 : (isTablet ? 36.0 : 96.0);

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 28.0),
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 56),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: logo + menu (logo is our full-wordmark widget)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Workly full wordmark logo (animated inside its own widget)
                        const WorklyLogo(size: 44),
                        Icon(Icons.menu_rounded, size: isMobile ? 24 : 28, color: Colors.black87),
                      ],
                    ),

                    SizedBox(height: isMobile ? 22 : 36),

                    // Title (animated)
                    SlideTransition(
                      position: _titleSlide,
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: _buildTitle(isMobile, isTablet),
                      ),
                    ),

                    SizedBox(height: isMobile ? 20 : 36),

                    // Card center area - on large screens center the card horizontally
                    Center(
                      child: SlideTransition(
                        position: _cardSlide,
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isDesktop ? 560 : (isTablet ? 520 : double.infinity),
                            ),
                            child: _buildCard(context, isMobile),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Footer
                    _buildFooter(isMobile),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

Widget _buildTitle(bool isMobile, bool isTablet) {
  final double baseSize = isMobile ? 42 : (isTablet ? 52 : 64);
  final bool isDesktop = !isMobile && !isTablet;

  return Column(
    crossAxisAlignment:
        isDesktop ? CrossAxisAlignment.center : CrossAxisAlignment.start,
    children: [
      Text(
        'YOUR JOB',
        textAlign: isDesktop ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontSize: baseSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
      ),
      Text(
        'MATCH',
        textAlign: isDesktop ? TextAlign.center : TextAlign.start,
        style: TextStyle(
          fontSize: baseSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'AI has carefully looked at what you want\nand found the best jobs that match you.',
        textAlign: TextAlign.start, // or keep centered — your choice
        style: TextStyle(
          fontSize: 15,
          color: fadedText,
          height: 1.45,
        ),
      ),
    ],
  );
}


  Widget _buildCard(BuildContext context, bool isMobile) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    // card padding and radius adapt to screen size
    final double cardPadding = isMobile ? 16 : 20;
    final double borderRadius = isMobile ? 18 : 24;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // header row inside card
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(color: maroon, shape: BoxShape.circle),
                child: const Center(child: Icon(Icons.search, color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('AI - Powered', style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Find jobs personalized for you', style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              Icon(Icons.more_vert, size: 20, color: Colors.grey[400]),
            ],
          ),

          const SizedBox(height: 14),

          // chips wrap (will wrap to next line on smaller widths)
          Wrap(spacing: 8, runSpacing: 8, children: [
            _smallChip('Remote'),
            _smallChip('Senior'),
            _smallChip('\$160k - \$220k'),
          ]),

          const SizedBox(height: 18),

          // Divider visual
          Divider(color: Colors.grey[200], height: 1.5),

          const SizedBox(height: 18),

          // Buttons: Google (primary) then Guest (outlined)
          // Buttons use full width and scale neatly on all sizes
          _googleSignButton(context, isLoading),
          const SizedBox(height: 12),
          _guestButton(context, isLoading),
        ],
      ),
    );
  }

  Widget _smallChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  Widget _googleSignButton(BuildContext context, bool loading) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : () => _signInWithGoogle(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB3363D), // maroon base
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image.network fallback
                  
                  const SizedBox(width: 12),
                  const Text(
                    'Sign in with Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  )
                ],
              ),
      ),
    );
  }

  Widget _guestButton(BuildContext context, bool loading) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: loading ? null : _signInAsGuest,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        child: const Text(
          'Continue as Guest',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(top: isMobile ? 14 : 20, bottom: isMobile ? 6 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(onPressed: () {}, child: const Text('Terms', style: TextStyle(color: fadedText))),
          const Text('•', style: TextStyle(color: fadedText)),
          TextButton(onPressed: () {}, child: const Text('Privacy', style: TextStyle(color: fadedText))),
        ],
      ),
    );
  }
}
