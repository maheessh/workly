import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:job_tinder/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:job_tinder/themes/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/job_provider.dart'; 
import 'screens/auth_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/job_swipe_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const WorklyApp());
}

class WorklyApp extends StatelessWidget {
  const WorklyApp({super.key});

  @override
  Widget build(BuildContext context) {
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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // --- 1. Store the provider here ---
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // --- 2. Assign it here ---
      _authProvider = Provider.of<AuthProvider>(context, listen: false);
      _authProvider?.addListener(_onAuthStateChanged);
    });
  }
  
  void _onAuthStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }
  
  @override
  void dispose() {
    // --- 3. Use the stored variable ---
    // This is safe because it's not looking up the context.
    _authProvider?.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        
        if (authProvider.isLoading && !authProvider.hasUser) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (authProvider.hasUser) {
          if (authProvider.currentUser?.phoneNumber.isNotEmpty == true && 
                authProvider.currentUser?.location.isNotEmpty == true) {
            return JobSwipeScreen(key: ValueKey('jobswipe_${authProvider.currentUser?.userId}'));
          } else {
            return ProfileScreen(key: ValueKey('profile_${authProvider.currentUser?.userId}'));
          }
        }

        return const AuthScreen();
      },
    );
  }
}