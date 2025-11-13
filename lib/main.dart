import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:job_tinder/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:job_tinder/themes/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/job_provider.dart'; // <-- 1. ADD THIS IMPORT
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/job_swipe_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const WorklyApp());
}

class WorklyApp extends StatelessWidget {
  const WorklyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. UPDATED: Use MultiProvider to provide both services
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (context) => AuthProvider()),
        ChangeNotifierProvider<JobProvider>(create: (context) => JobProvider()),
      ],
      child: MaterialApp(
        title: 'Workly',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// ==========================================================
// == NO CHANGES NEEDED for AuthWrapper or _AuthWrapperState ==
// ==========================================================
// Your existing logic for routing is perfect and doesn't
// need to be modified.

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Listen to auth changes and force rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.addListener(_onAuthStateChanged);
    });
  }
  
  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  void dispose() {
    // Check if AuthProvider is still available to avoid errors on hot reload
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.removeListener(_onAuthStateChanged);
    } catch (e) {
      // Provider is already disposed, no need to remove listener
      print('AuthWrapper dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        
        // Show loading screen while checking auth state
        if (authProvider.isLoading && !authProvider.hasUser) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is signed in (Google or guest), check if profile is complete
        if (authProvider.hasUser) {
          
          // If profile is complete, go directly to job swipe screen
          if (authProvider.currentUser?.phoneNumber.isNotEmpty == true && 
                authProvider.currentUser?.location.isNotEmpty == true) {
            return JobSwipeScreen(key: ValueKey('jobswipe_${authProvider.currentUser?.userId}'));
          } else {
            // Profile not complete, go to profile screen
            return ProfileScreen(key: ValueKey('profile_${authProvider.currentUser?.userId}'));
          }
        }

        // Otherwise, show auth screen
        return const AuthScreen();
      },
    );
  }
}