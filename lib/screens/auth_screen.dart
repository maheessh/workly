import 'package:flutter/material.dart';
import 'package:job_tinder/themes/app_theme.dart';
import '../widgets/workly_logo.dart'; // Import new logo
import 'profile_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const WorklyLogo(size: 50),
              const SizedBox(height: 20),
              Text(
                'Discover Your Next Role',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Swipe right on opportunities that excite you. We learn what you like.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const Spacer(flex: 1),
              Icon(Icons.swipe, size: 100, color: AppTheme.primaryColor.withOpacity(0.2)),
              const Spacer(flex: 2),
              ElevatedButton.icon(
                icon: const Icon(Icons.login), // Replace with Google icon
                label: const Text('Sign in with Google'),
                onPressed: () => _navigateToProfile(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.textColor,
                  elevation: 2,
                  shadowColor: Colors.grey.withOpacity(0.2),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text('Get Started'),
                onPressed: () => _navigateToProfile(context),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}