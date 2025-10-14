import 'package:flutter/material.dart';
import 'dart:math';

// Main function to run the app
void main() {
  runApp(const JobTinderApp());
}

// --- DATA MODELS ---

// Model for user data
class UserModel {
  String name;
  String email;
  String experience; // e.g., "Entry-Level", "Mid-Level", "Senior"
  Set<String> skills;
  String resumeFileName;

  UserModel({
    this.name = '',
    this.email = '',
    this.experience = 'Entry-Level',
    this.skills = const {},
    this.resumeFileName = '',
  });
}

// Model for job data
class JobModel {
  final String title;
  final String company;
  final String location;
  final String experienceLevel;
  final Set<String> requiredSkills;
  final String description;

  JobModel({
    required this.title,
    required this.company,
    required this.location,
    required this.experienceLevel,
    required this.requiredSkills,
    required this.description,
  });
}

// --- MOCK DATA ---
// In a real app, this would come from an API connected to your Excel sheet.
final List<JobModel> mockJobs = [
  JobModel(
    title: 'Flutter Developer',
    company: 'Innovate Solutions',
    location: 'Remote',
    experienceLevel: 'Mid-Level',
    requiredSkills: {'Flutter', 'Dart', 'Firebase', 'REST APIs'},
    description: 'Join our innovative team to build beautiful and functional cross-platform applications using Flutter.',
  ),
  JobModel(
    title: 'Frontend Engineer',
    company: 'Creative Web Ltd.',
    location: 'San Francisco, CA',
    experienceLevel: 'Senior',
    requiredSkills: {'React', 'JavaScript', 'CSS', 'HTML', 'TypeScript'},
    description: 'Lead the development of our user-facing features and build reusable code and libraries for future use.',
  ),
  JobModel(
    title: 'Product Manager',
    company: 'Future Tech',
    location: 'New York, NY',
    experienceLevel: 'Senior',
    requiredSkills: {'Agile', 'Product Roadmapping', 'Market Research', 'JIRA'},
    description: 'Define product vision, strategy, and roadmap. Work closely with engineering, marketing, and sales teams.',
  ),
  JobModel(
    title: 'UI/UX Designer',
    company: 'DesignFirst Studios',
    location: 'Remote',
    experienceLevel: 'Mid-Level',
    requiredSkills: {'Figma', 'Adobe XD', 'User Research', 'Prototyping'},
    description: 'Create engaging and user-friendly interfaces for our mobile and web applications.',
  ),
  JobModel(
    title: 'Junior Dart Developer',
    company: 'Startup Hub',
    location: 'Austin, TX',
    experienceLevel: 'Entry-Level',
    requiredSkills: {'Dart', 'Git', 'Problem-Solving'},
    description: 'An exciting opportunity for a recent graduate to kickstart their career in mobile development with Dart.',
  ),
];

// --- MAIN APP WIDGET ---
class JobTinderApp extends StatelessWidget {
  const JobTinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job Tinder',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.deepPurpleAccent),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurpleAccent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const ProfileScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- SCREENS ---

// Screen for user to fill in their details
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _user = UserModel();
  final _skillsController = TextEditingController();

  final List<String> _experienceLevels = ['Entry-Level', 'Mid-Level', 'Senior'];

  void _addSkill() {
    if (_skillsController.text.isNotEmpty) {
      setState(() {
        _user.skills.add(_skillsController.text.trim());
        _skillsController.clear();
      });
    }
  }

  void _findJobs() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobSwipeScreen(user: _user),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Your Profile'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                onSaved: (value) => _user.name = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter a valid email' : null,
                onSaved: (value) => _user.email = value!,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _user.experience,
                decoration: const InputDecoration(labelText: 'Experience Level'),
                items: _experienceLevels.map((level) {
                  return DropdownMenuItem(value: level, child: Text(level));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _user.experience = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skillsController,
                      decoration: const InputDecoration(labelText: 'Add a Skill (e.g., Flutter)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.deepPurpleAccent, size: 30),
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
                    label: Text(skill),
                    onDeleted: () {
                      setState(() {
                        _user.skills.remove(skill);
                      });
                    },
                    backgroundColor: Colors.deepPurple.withOpacity(0.3),
                    deleteIconColor: Colors.white70,
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: Text(_user.resumeFileName.isEmpty ? 'Upload Resume' : _user.resumeFileName),
                onPressed: () {
                  // Mock resume upload
                  setState(() {
                    _user.resumeFileName = 'my_resume_2024.pdf';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mock resume uploaded!')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _findJobs,
                child: const Text('Save & Find Jobs'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Screen for swiping through job cards
class JobSwipeScreen extends StatefulWidget {
  final UserModel user;
  const JobSwipeScreen({super.key, required this.user});

  @override
  State<JobSwipeScreen> createState() => _JobSwipeScreenState();
}

class _JobSwipeScreenState extends State<JobSwipeScreen> {
  final List<JobModel> _appliedJobs = [];
  late List<JobModel> _availableJobs;
  
  // State for swipe animation
  Offset _cardOffset = Offset.zero;
  bool _isDragging = false;
  
  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the jobs list
    _availableJobs = List.from(mockJobs);
  }

  // --- MATCHING ALGORITHM ---
  int calculateMatchScore(JobModel job) {
    int score = 0;
    
    // 1. Skill match (most important) - 60 points
    int commonSkills = widget.user.skills.intersection(job.requiredSkills).length;
    if (job.requiredSkills.isNotEmpty) {
      score += (60 * (commonSkills / job.requiredSkills.length)).round();
    }
    
    // 2. Experience level match - 40 points
    if (widget.user.experience == job.experienceLevel) {
      score += 40;
    } else if (widget.user.experience == 'Senior' && job.experienceLevel == 'Mid-Level') {
      score += 20; // Senior can do Mid-Level
    } else if (widget.user.experience == 'Mid-Level' && job.experienceLevel == 'Entry-Level') {
      score += 20; // Mid-Level can do Entry-Level
    }
    
    return min(100, score); // Cap score at 100
  }
  
  void _onPanStart(DragStartDetails details) {
      setState(() {
        _isDragging = true;
      });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _cardOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_cardOffset.dx.abs() > 120) {
      // Swiped far enough
      if (_cardOffset.dx > 0) {
        _apply();
      } else {
        _reject();
      }
    } else {
      // Snap back to center
      setState(() {
        _cardOffset = Offset.zero;
        _isDragging = false;
      });
    }
  }

  void _apply() {
      if (_availableJobs.isNotEmpty) {
        setState(() {
          final job = _availableJobs.removeAt(0);
          _appliedJobs.add(job);
          _resetCard();
        });
      }
  }
  
  void _reject() {
      if (_availableJobs.isNotEmpty) {
        setState(() {
          _availableJobs.removeAt(0);
          _resetCard();
        });
      }
  }

  void _resetCard() {
    setState(() {
        _cardOffset = Offset.zero;
        _isDragging = false;
    });
  }
  
  Color getScoreColor(int score) {
    if (score >= 75) return Colors.greenAccent;
    if (score >= 50) return Colors.yellowAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Match'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add_check),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AppliedJobsScreen(appliedJobs: _appliedJobs),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _availableJobs.isEmpty
                    ? const Text("That's all the jobs for now!", style: TextStyle(fontSize: 20, color: Colors.white70))
                    : buildCardStack(),
              ),
            ),
             if (_availableJobs.isNotEmpty) buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget buildCardStack() {
    final job = _availableJobs.first;
    final score = calculateMatchScore(job);
    final angle = _cardOffset.dx / 150; // rotation angle
    final transform = Matrix4.identity()
      ..translate(_cardOffset.dx, _cardOffset.dy)
      ..rotateZ(angle);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedContainer(
        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 200),
        transform: transform,
        child: JobCard(job: job, score: score, scoreColor: getScoreColor(score)),
      ),
    );
  }

  Widget buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            heroTag: 'reject_btn',
            onPressed: _reject,
            backgroundColor: Colors.red,
            child: const Icon(Icons.close, color: Colors.white),
          ),
          FloatingActionButton(
            heroTag: 'apply_btn',
            onPressed: _apply,
            backgroundColor: Colors.green,
            child: const Icon(Icons.check, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

// Screen to display jobs the user has applied for
class AppliedJobsScreen extends StatelessWidget {
  final List<JobModel> appliedJobs;
  const AppliedJobsScreen({super.key, required this.appliedJobs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Applied Jobs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: appliedJobs.isEmpty
          ? const Center(
              child: Text("You haven't applied to any jobs yet.", style: TextStyle(color: Colors.white70)),
            )
          : ListView.builder(
              itemCount: appliedJobs.length,
              itemBuilder: (context, index) {
                final job = appliedJobs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${job.company} - ${job.location}'),
                    trailing: const Icon(Icons.check_circle, color: Colors.greenAccent),
                  ),
                );
              },
            ),
    );
  }
}

// --- WIDGETS ---

// Widget for displaying a single job card
class JobCard extends StatelessWidget {
  final JobModel job;
  final int score;
  final Color scoreColor;

  const JobCard({super.key, required this.job, required this.score, required this.scoreColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Expanded(
                   child: Text(
                    job.title,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                                   ),
                 ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     color: scoreColor.withOpacity(0.2),
                     borderRadius: BorderRadius.circular(20),
                     border: Border.all(color: scoreColor)
                   ),
                   child: Text('$score% Match', style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold)),
                 ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${job.company} • ${job.location}',
              style: const TextStyle(fontSize: 18, color: Colors.white70),
            ),
            const Divider(height: 32, color: Colors.white24),
            Text(
              'Experience: ${job.experienceLevel}',
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Top Skills Required:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: job.requiredSkills.map((skill) {
                return Chip(
                  label: Text(skill),
                  backgroundColor: Colors.deepPurple.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                );
              }).toList(),
            ),
            const Spacer(),
             Text(
              job.description,
              style: const TextStyle(fontSize: 14, color: Colors.white60),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
