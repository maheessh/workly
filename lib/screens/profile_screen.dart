// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:job_tinder/themes/app_theme.dart'; // AppTheme isn't used here
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/file_upload_service.dart';
import 'job_swipe_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late UserModel _user;

  final List<String> _experienceOptions = [
    'Entry-Level',
    'Mid-Level',
    'Senior'
  ];

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _summaryController;
  late TextEditingController _portfolioController;
  late TextEditingController _githubController;
  late TextEditingController _linkedinController;
  final TextEditingController _skillsController = TextEditingController();

  bool _isUploadingResume = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _user = authProvider.currentUser?.copyWith() ?? UserModel();

    _nameController = TextEditingController(text: _user.name);
    _emailController = TextEditingController(text: _user.email);
    _phoneController = TextEditingController(text: _user.phoneNumber);
    _locationController = TextEditingController(text: _user.location);
    _summaryController = TextEditingController(text: _user.summary);
    _portfolioController = TextEditingController(text: _user.portfolioUrl);
    _githubController = TextEditingController(text: _user.githubUrl);
    _linkedinController = TextEditingController(text: _user.linkedinUrl);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _summaryController.dispose();
    _portfolioController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _uploadResume() async {
    setState(() => _isUploadingResume = true);

    final extracted = await FileUploadService.pickAndParseResumeFile();

    if (extracted != null) {
      final parsed = UserModel.fromJson(extracted);
      setState(() {
        // File details
        _user.resumeFileName = extracted['fileName'] ?? _user.resumeFileName;
        _user.resumeFilePath =
            extracted['resumeFilePath'] ?? _user.resumeFilePath;

        // Merge scalar fields if present
        if (parsed.name.isNotEmpty) {
          _user.name = parsed.name;
          _nameController.text = parsed.name;
        }
        if (parsed.email.isNotEmpty) {
          _user.email = parsed.email;
          _emailController.text = parsed.email;
        }
        if (parsed.phoneNumber.isNotEmpty) {
          _user.phoneNumber = parsed.phoneNumber;
          _phoneController.text = parsed.phoneNumber;
        }
        if (parsed.location.isNotEmpty) {
          _user.location = parsed.location;
          _locationController.text = parsed.location;
        }
        if (parsed.summary.isNotEmpty) {
          _user.summary = parsed.summary;
          _summaryController.text = parsed.summary;
        }
        if (parsed.portfolioUrl.isNotEmpty) {
          _user.portfolioUrl = parsed.portfolioUrl;
          _portfolioController.text = parsed.portfolioUrl;
        }
        if (parsed.githubUrl.isNotEmpty) {
          _user.githubUrl = parsed.githubUrl;
          _githubController.text = parsed.githubUrl;
        }
        if (parsed.linkedinUrl.isNotEmpty) {
          _user.linkedinUrl = parsed.linkedinUrl;
          _linkedinController.text = parsed.linkedinUrl;
        }
        if (parsed.experience.isNotEmpty) {
          _user.experience = parsed.experience;
        }

        // Collections
        if (parsed.skills.isNotEmpty) {
          // Add only unique skills
          for (var skill in parsed.skills) {
            if (!_user.skills.contains(skill)) {
              _user.skills.add(skill);
            }
          }
        }
        if (parsed.workExperience.isNotEmpty) {
          _user.workExperience = List<String>.from(parsed.workExperience);
        }
        if (parsed.education.isNotEmpty) {
          _user.education = List<String>.from(parsed.education);
        }
      });
    }

    setState(() => _isUploadingResume = false);
  }

  void _addSkill() {
    final skill = _skillsController.text.trim();
    if (skill.isNotEmpty && !_user.skills.contains(skill)) {
      setState(() {
        _user.skills.add(skill);
        _skillsController.clear();
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _user = _user.copyWith(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      location: _locationController.text.trim(),
      summary: _summaryController.text.trim(),
      portfolioUrl: _portfolioController.text.trim(),
      githubUrl: _githubController.text.trim(),
      linkedinUrl: _linkedinController.text.trim(),
      // Note: experience and skills are already updated via setState
    );

    await Provider.of<AuthProvider>(context, listen: false)
        .updateLocalUser(_user);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const JobSwipeScreen()),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(t,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      );

  Widget _card({required Widget child}) => Card(
        elevation: 4,
        margin: const EdgeInsets.only(bottom: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      );

  Widget _buildUploadResumeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isUploadingResume ? null : _uploadResume,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF101018),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
        child: _isUploadingResume
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _user.resumeFileName.isEmpty
                    ? "Upload Resume"
                    : "Uploaded: ${_user.resumeFileName}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(115),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 52, 18, 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xff5e0b15), Color(0xff8a1625)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Text(
            "Complete Your Profile",
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        width: isDesktop ? 380 : width * 0.9,
        child: FloatingActionButton.extended(
          backgroundColor: const Color(0xff8a1625),
          onPressed: _saveProfile,
          label: const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text("Continue",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SlideTransition(
        position: Tween(begin: const Offset(0, .05), end: Offset.zero)
            .animate(CurvedAnimation(
                parent: _animationController, curve: Curves.easeOut)),
        child: Center(
          child: Container(
            width: isDesktop ? width * 0.45 : width,
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_user.isGuest)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(10)),
                        child: const Text(
                            "👤 Guest Mode — profile not stored in cloud",
                            style: TextStyle(fontSize: 13)),
                      ),
                    _sectionTitle("Start with your Resume"),
                    _card(
                      child: Column(
                        children: [
                          _buildUploadResumeButton(),
                          const SizedBox(height: 12),
                          const Text(
                            "Uploading will auto-fill your profile details.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    _sectionTitle("Basic Info"),
                    _card(
                      child: Column(children: [
                        TextFormField(
                          controller: _nameController,
                          decoration:
                              const InputDecoration(labelText: "Full Name *"),
                          validator: (v) =>
                              v!.isEmpty ? "Name required" : null,
                        ),
                        // --- ADDED SPACING ---
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _emailController,
                          decoration:
                              const InputDecoration(labelText: "Email *"),
                          validator: (v) =>
                              !v!.contains("@") ? "Enter valid email" : null,
                        ),
                        // --- ADDED SPACING ---
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration:
                              const InputDecoration(labelText: "Phone Number"),
                        ),
                        // --- ADDED SPACING ---
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _locationController,
                          decoration:
                              const InputDecoration(labelText: "Location"),
                        ),
                      ]),
                    ),

                    _sectionTitle("About You"),
                    _card(
                      child: TextFormField(
                        controller: _summaryController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: "Short Summary (optional)"),
                      ),
                    ),

                    _sectionTitle("Experience Level"),
                    _card(
                      child: DropdownButtonFormField(
                        value: _user.experience.isEmpty
                            ? "Entry-Level"
                            : _experienceOptions.contains(_user.experience)
                                ? _user.experience
                                : "Entry-Level",
                        items: _experienceOptions
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _user.experience = v!),
                      ),
                    ),

                    _sectionTitle("Skills"),
                    _card(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: TextField(
                                  controller: _skillsController,
                                  decoration: const InputDecoration(
                                      labelText: "Add Skill"),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle,
                                    color: Color(0xff8a1625)),
                                onPressed: _addSkill,
                              ),
                            ]),
                            Wrap(
                              spacing: 6,
                              children: _user.skills.map((s) {
                                return Chip(
                                  label: Text(s),
                                  deleteIcon: const Icon(Icons.close,
                                      size: 16, color: Colors.white),
                                  onDeleted: () =>
                                      setState(() => _user.skills.remove(s)),
                                  backgroundColor: const Color(0xff8a1625),
                                  labelStyle:
                                      const TextStyle(color: Colors.white),
                                );
                              }).toList(),
                            )
                          ]),
                    ),

                    _sectionTitle("Links"),
                    _card(
                      child: Column(children: [
                        TextFormField(
                          controller: _portfolioController,
                          decoration:
                              const InputDecoration(labelText: "Portfolio URL"),
                        ),
                        // --- ADDED SPACING ---
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _githubController,
                          decoration:
                              const InputDecoration(labelText: "GitHub URL"),
                        ),
                        // --- ADDED SPACING ---
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _linkedinController,
                          decoration:
                              const InputDecoration(labelText: "LinkedIn URL"),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}