import 'package:flutter/material.dart';
import 'package:job_tinder/themes/app_theme.dart';

import '../models/user_model.dart';
import 'job_swipe_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel? user; // Can be null (creating) or provided (editing)
  const ProfileScreen({super.key, this.user});

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

  bool get _isEditing => widget.user != null;

  @override
  void initState() {
    super.initState();
    // Use existing user data if editing, or create a new model if signing up
    _user = widget.user ?? UserModel();
    _nameController = TextEditingController(text: _user.name);
    _emailController = TextEditingController(text: _user.email);
  }

  @override
  void dispose() {
    _skillsController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _addSkill() {
    if (_skillsController.text.trim().isNotEmpty) {
      setState(() {
        _user.skills.add(_skillsController.text.trim());
        _skillsController.clear();
      });
    }
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Update user model from controllers
      _user.name = _nameController.text;
      _user.email = _emailController.text;
      
      if (_isEditing) {
        // If editing, just pop the screen
        Navigator.pop(context);
      } else {
        // If creating, push replacement to the swipe screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => JobSwipeScreen(user: _user)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profile' : 'Create Your Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _user.experience,
                decoration: const InputDecoration(labelText: 'Experience Level'),
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
                      decoration: const InputDecoration(labelText: 'Add a Skill (e.g., Flutter)'),
                      onFieldSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor, size: 36),
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
                    label: Text(skill, style: const TextStyle(color: Colors.white)),
                    onDeleted: () => setState(() => _user.skills.remove(skill)),
                    backgroundColor: AppTheme.primaryColor,
                    deleteIconColor: Colors.white70,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: Text(_user.resumeFileName.isEmpty ? 'Upload Resume' : _user.resumeFileName),
                onPressed: () {
                  setState(() => _user.resumeFileName = 'my_resume_2024.pdf');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock resume uploaded!')),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _saveProfile,
                child: Text(_isEditing ? 'Save Profile' : 'Start Swiping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}