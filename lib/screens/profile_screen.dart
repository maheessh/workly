// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:job_tinder/themes/app_theme.dart';

import '../models/user_model.dart';
import '../services/file_upload_service.dart';
import '../services/user_storage_service.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'job_swipe_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late UserModel _user;
  final _skillsController = TextEditingController();
  final List<String> _experienceLevels = ['Entry-Level', 'Mid-Level', 'Senior'];

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _summaryController;
  late TextEditingController _portfolioController;
  late TextEditingController _githubController;
  late TextEditingController _linkedinController;

  bool _isUploadingResume = false;

  @override
  void initState() {
    super.initState();
    // Get user from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // Use copyWith to avoid modifying the provider's state directly
    _user = authProvider.currentUser?.copyWith() ?? UserModel();

    _nameController = TextEditingController(text: _user.name);
    _emailController = TextEditingController(text: _user.email);
    _phoneController = TextEditingController(text: _user.phoneNumber);
    _locationController = TextEditingController(text: _user.location);
    _summaryController = TextEditingController(text: _user.summary);
    _portfolioController = TextEditingController(text: _user.portfolioUrl);
    _githubController = TextEditingController(text: _user.githubUrl);
    _linkedinController = TextEditingController(text: _user.linkedinUrl);
  }

  @override
  void dispose() {
    _skillsController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _summaryController.dispose();
    _portfolioController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  // == ✨ NICE FEATURE: Smarter skill adding (prevents duplicates) ==
  void _addSkill() {
    final skillText = _skillsController.text.trim();
    if (skillText.isNotEmpty) {
      if (_user.skills.contains(skillText)) {
        // Show a snackbar if the skill already exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$skillText" is already in your skills list.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        setState(() {
          _user.skills.add(skillText);
          _skillsController.clear();
        });
      }
    }
  }

  // =======================================================================
  // ==  FIXED METHOD: This now correctly updates all fields              ==
  // =======================================================================
  Future<void> _uploadResume() async {
    if (_isUploadingResume) return;

    setState(() {
      _isUploadingResume = true;
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Uploading and parsing resume...'),
            ],
          ),
        ),
      );

      // Pick and parse file (works on all platforms including web)
      final extractedData = await FileUploadService.pickAndParseResumeFile();

      if (extractedData != null) {
        // 1. Create a safe model from the parsed data.
        final parsedModel = UserModel.fromJson(extractedData);

        // 2. Update user model with extracted data
        setState(() {
          // Get file name from the extracted data map
          String fileName = extractedData['fileName'] ?? '';
          String fileExt = extractedData['fileExtension'] ?? 'pdf';
          if (fileName.isEmpty) {
            fileName = 'resume_uploaded.$fileExt';
          }

          _user.resumeFilePath =
              'uploaded_resume_${DateTime.now().millisecondsSinceEpoch}';
          _user.resumeFileName = fileName;

          // =================================================================
          // ==  THE FIX: Removed all `_user.name.isEmpty` checks           ==
          // =================================================================
          // Now, it *always* updates the field if the parser found data.

          if (parsedModel.name.isNotEmpty) {
            _user.name = parsedModel.name;
            _nameController.text = _user.name;
          }
          if (parsedModel.email.isNotEmpty) {
            _user.email = parsedModel.email;
            _emailController.text = _user.email;
          }
          if (parsedModel.phoneNumber.isNotEmpty) {
            _user.phoneNumber = parsedModel.phoneNumber;
            _phoneController.text = _user.phoneNumber;
          }
          if (parsedModel.location.isNotEmpty) {
            _user.location = parsedModel.location;
            _locationController.text = _user.location;
          }
          if (parsedModel.summary.isNotEmpty) {
            _user.summary = parsedModel.summary;
            _summaryController.text = _user.summary;
          }
          if (parsedModel.portfolioUrl.isNotEmpty) {
            _user.portfolioUrl = parsedModel.portfolioUrl;
            _portfolioController.text = _user.portfolioUrl;
          }
          if (parsedModel.githubUrl.isNotEmpty) {
            _user.githubUrl = parsedModel.githubUrl;
            _githubController.text = _user.githubUrl;
          }
          if (parsedModel.linkedinUrl.isNotEmpty) {
            _user.linkedinUrl = parsedModel.linkedinUrl;
            _linkedinController.text = _user.linkedinUrl;
          }

          // Add extracted skills
          _user.skills.addAll(parsedModel.skills);

          // Update experience level
          if (parsedModel.experience.isNotEmpty) {
             _user.experience = parsedModel.experience;
          }

          // Add work experience and education
          if (parsedModel.workExperience.isNotEmpty) {
             _user.workExperience = parsedModel.workExperience;
          }
          if (parsedModel.education.isNotEmpty) {
             _user.education = parsedModel.education;
          }
        });

        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Resume uploaded successfully! Extracted ${parsedModel.skills.length} skills.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Close loading dialog
        if (mounted) Navigator.of(context).pop();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No file selected'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // This error message will now be more informative
            content: Text('Error processing resume: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingResume = false;
      });
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Update user model from controllers
      _user.name = _nameController.text;
      _user.email = _emailController.text;
      _user.phoneNumber = _phoneController.text;
      _user.location = _locationController.text;
      _user.summary = _summaryController.text;
      _user.portfolioUrl = _portfolioController.text;
      _user.githubUrl = _githubController.text;
      _user.linkedinUrl = _linkedinController.text;

      // Update the user in AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateLocalUser(_user);

      // Navigate to job swipe screen
      if (mounted) { // ⬅️ Add 'mounted' check
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const JobSwipeScreen()),
        );
      }
    }
  }

  // == ✨ NICE FEATURE: Helper widget for section headers ==
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            _user.isGuest ? 'Create Your Profile' : 'Complete Your Profile'),
        actions: [
          if (!_user.isGuest)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();

                // Navigate back to auth screen after sign out
                if (mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                    (route) => false,
                  );
                }
              },
              tooltip: 'Sign Out',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Guest user notice
              if (_user.isGuest)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Guest Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Your progress won\'t be saved. Sign in to save your profile and job preferences.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // == ✨ NICE FEATURE: Profile Picture Avatar ==
              if (_user.photoUrl != null && _user.photoUrl!.isNotEmpty)
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(_user.photoUrl!),
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              
              // == ✨ NICE FEATURE: Section Headers for clarity ==
              _buildSectionHeader('Basic Information'),
              
              TextFormField(
                controller: _nameController,
                // == ✨ NICE FEATURE: Required field indicator ==
                decoration: const InputDecoration(labelText: 'Full Name *'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email *'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration:
                    const InputDecoration(labelText: 'Location (City, State)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _summaryController,
                decoration:
                    const InputDecoration(labelText: 'Professional Summary'),
                maxLines: 3,
              ),

              // == ✨ NICE FEATURE: Section Headers for clarity ==
              _buildSectionHeader('Professional Links'),
              
              TextFormField(
                controller: _portfolioController,
                decoration:
                    const InputDecoration(labelText: 'Portfolio Website'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _githubController,
                decoration: const InputDecoration(labelText: 'GitHub Profile'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkedinController,
                decoration: const InputDecoration(labelText: 'LinkedIn Profile'),
                keyboardType: TextInputType.url,
              ),

              // == ✨ NICE FEATURE: Section Headers for clarity ==
              _buildSectionHeader('Experience & Skills'),

              DropdownButtonFormField<String>(
                value: _user.experience.isEmpty || !_experienceLevels.contains(_user.experience)
                    ? 'Entry-Level'
                    : _user.experience,
                decoration:
                    const InputDecoration(labelText: 'Experience Level'),
                items: _experienceLevels.map((level) {
                  return DropdownMenuItem(value: level, child: Text(level));
                }).toList(),
                onChanged: (value) => setState(() => _user.experience = value!),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillsController,
                      decoration: const InputDecoration(
                          labelText: 'Add a Skill (e.g., Flutter)'),
                      onFieldSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle,
                        color: AppTheme.primaryColor, size: 36),
                    onPressed: _addSkill,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _user.skills.map((skill) {
                  return Chip(
                    label:
                        Text(skill, style: const TextStyle(color: Colors.white)),
                    onDeleted: () => setState(() => _user.skills.remove(skill)),
                    backgroundColor: AppTheme.primaryColor,
                    deleteIconColor: Colors.white70,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              
              // == ✨ NICE FEATURE: Better resume button state ==
              OutlinedButton.icon(
                icon: _isUploadingResume
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _user.resumeFileName.isNotEmpty
                        // Show checkmark if resume is uploaded
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.upload_file),
                label: Text(_user.resumeFileName.isEmpty
                    ? 'Upload Resume (PDF/DOCX/TXT)'
                    : 'Resume: ${_user.resumeFileName}'),
                onPressed: _isUploadingResume ? null : _uploadResume,
              ),
              
              // Display extracted work experience
              if (_user.workExperience.isNotEmpty) ...[
                _buildSectionHeader('Work Experience (from resume)'),
                ...(_user.workExperience.map((exp) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $exp',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ))),
              ],

              // Display extracted education
              if (_user.education.isNotEmpty) ...[
                _buildSectionHeader('Education (from resume)'),
                ...(_user.education.map((edu) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $edu',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ))),
              ],

              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)
                ),
                onPressed: _saveProfile,
                child: Text(_user.phoneNumber.isNotEmpty &&
                        _user.location.isNotEmpty
                    ? 'Update Profile & Continue Swiping'
                    : (_user.isGuest
                        ? 'Start Swiping as Guest'
                        : 'Start Swiping')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// == ✨ NICE FEATURE: Added a copyWith method to your UserModel ==
// This is not in this file, but you should add it to your `user_model.dart`
// It prevents bugs where you accidentally change the provider's state.

/*
  // Add this method inside your UserModel class in `user_model.dart`
  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? experience,
    Set<String>? skills,
    String? resumeFileName,
    String? resumeFilePath,
    String? phoneNumber,
    String? location,
    String? summary,
    List<String>? workExperience,
    List<String>? education,
    String? portfolioUrl,
    String? githubUrl,
    String? linkedinUrl,
    bool? isGuest,
    String? authProvider,
    String? photoUrl,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      experience: experience ?? this.experience,
      skills: skills ?? this.skills,
      resumeFileName: resumeFileName ?? this.resumeFileName,
      resumeFilePath: resumeFilePath ?? this.resumeFilePath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      summary: summary ?? this.summary,
      workExperience: workExperience ?? this.workExperience,
      education: education ?? this.education,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      isGuest: isGuest ?? this.isGuest,
      authProvider: authProvider ?? this.authProvider,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
*/