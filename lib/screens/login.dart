import 'package:flutter/material.dart';
import 'profile_screen.dart'; 
import 'package:job_tinder/themes/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Define the colors from your new design
  static const Color primaryRed = Color(0xFFD90429);
  static const Color darkInputColor = Color(0xFF1C1C1E);
  static const Color lightGrayText = Color(0xFF8A8A8E);

  // Controllers for text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Mock navigation to profile
  void _navigateToProfile(BuildContext context) {
    /*
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    */
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        // The back button is automatically added by Navigator.push
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Start By Setting Up Your Account!',
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome to Job Today! Let\'s get started by setting up your account.',
                style: textTheme.bodyMedium?.copyWith(
                  color: lightGrayText,
                ),
              ),
              const SizedBox(height: 32),
              
              // --- Email Field ---
              _buildTextFieldLabel('Email'),
              _buildTextField(
                controller: _emailController,
                hintText: 'tim.jennings@example.com',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // --- Password Field ---
              _buildTextFieldLabel('Password'),
              _buildTextField(
                controller: _passwordController,
                hintText: '••••••••••',
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement forgot password
                  },
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: primaryRed, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- Log In Button ---
              ElevatedButton(
                onPressed: () => _navigateToProfile(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryRed,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Log in', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 24),

              // --- "Not Hiring" Text ---
              Center(
                child: Text(
                  "I'm not hiring, I'm looking for a job",
                  style: TextStyle(color: lightGrayText, fontSize: 14),
                ),
              ),
              const SizedBox(height: 32),

              // --- "Or sign in with" Divider ---
              _buildDivider(),
              const SizedBox(height: 32),

              // --- Social Logins ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(Icons.email_outlined),
                  const SizedBox(width: 20),
                  // TODO: Replace with Google icon asset
                  _buildSocialButton(Icons.g_mobiledata, isGoogle: true),
                  const SizedBox(width: 20),
                  // TODO: Replace with Facebook icon asset
                  _buildSocialButton(Icons.facebook),
                ],
              ),
              const SizedBox(height: 40),

              // --- Terms of Service ---
              Center(
                child: Text(
                  'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: lightGrayText, fontSize: 12),
                ),
              ),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildTextFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor: darkInputColor,
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFF545458)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(child: Container(height: 1, color: darkInputColor)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Or sing in with',
            style: TextStyle(color: lightGrayText, fontSize: 14),
          ),
        ),
        Expanded(child: Container(height: 1, color: darkInputColor)),
      ],
    );
  }

  Widget _buildSocialButton(IconData icon, {bool isGoogle = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: darkInputColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: isGoogle ? 32 : 24, // Make Google 'G' stand out if it's text
      ),
    );
  }
}