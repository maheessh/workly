import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:job_tinder/themes/app_theme.dart';
import '../widgets/workly_logo.dart';
import '../widgets/google_icon.dart';
import '../providers/auth_provider.dart';
import 'profile_screen.dart';
import 'job_swipe_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signInWithGoogle();
    
    if (success && context.mounted) {
      // Force navigation after successful sign-in
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (context.mounted) {
          final user = authProvider.currentUser;
          if (user != null) {
            if (user.phoneNumber.isNotEmpty && user.location.isNotEmpty) {
              // Profile complete - go to job swipe screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const JobSwipeScreen()),
              );
            } else {
              // Profile incomplete - go to profile screen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            }
          }
        }
      });
    } else if (!success && authProvider.errorMessage != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _signInAsGuest(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.signInAsGuest();
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
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return ElevatedButton.icon(
                    icon: authProvider.isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const GoogleIcon(size: 20),
                    label: Text(authProvider.isLoading ? 'Signing in...' : 'Sign in with Google'),
                    onPressed: authProvider.isLoading ? null : () => _signInWithGoogle(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.textColor,
                      elevation: 2,
                      shadowColor: Colors.grey.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _signInAsGuest(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Continue as Guest'),
              ),
              const SizedBox(height: 8),
              Text(
                'Guest users can explore jobs but won\'t save progress',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}