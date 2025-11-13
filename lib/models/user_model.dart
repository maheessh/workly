// lib/models/user_model.dart

class UserModel {
  String userId; // Unique identifier for the user
  String name;
  String email;
  String experience;
  Set<String> skills;
  String resumeFileName;
  String resumeFilePath;
  String phoneNumber;
  String location;
  String summary;
  List<String> workExperience;
  List<String> education;
  String portfolioUrl;
  String githubUrl;
  String linkedinUrl;
  bool isGuest; // Whether this is a guest user
  String? authProvider; // 'google', 'email', etc.
  String? photoUrl; // Profile photo URL from Google

  UserModel({
    this.userId = '',
    this.name = '',
    this.email = '',
    this.experience = 'Entry-Level',
    Set<String>? skills,
    this.resumeFileName = '',
    this.resumeFilePath = '',
    this.phoneNumber = '',
    this.location = '',
    this.summary = '',
    List<String>? workExperience,
    List<String>? education,
    this.portfolioUrl = '',
    this.githubUrl = '',
    this.linkedinUrl = '',
    this.isGuest = false,
    this.authProvider,
    this.photoUrl,
  })  : skills = skills ?? <String>{},
        workExperience = workExperience ?? <String>[],
        education = education ?? <String>[];

  // =======================================================================
  // ==  MODIFIED METHOD: Converts a Map to a UserModel (Now Safer)       ==
  // =======================================================================
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      experience: json['experience'] ?? 'Entry-Level',
      
      // == MODIFICATION: This is safer. ==
      // It filters out any nulls *inside* the list (e.g., [null, "Flutter"])
      skills: (json['skills'] as List? ?? [])
          .whereType<String>() // Filters out nulls
          .toSet(),
      
      resumeFileName: json['resumeFileName'] ?? '',
      resumeFilePath: json['resumeFilePath'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      location: json['location'] ?? '',
      summary: json['summary'] ?? '',
      
      // == MODIFICATION: This is safer. ==
      workExperience: (json['workExperience'] as List? ?? [])
          .whereType<String>()
          .toList(),
          
      // == MODIFICATION: This is safer. ==
      education: (json['education'] as List? ?? [])
          .whereType<String>()
          .toList(),
      
      portfolioUrl: json['portfolioUrl'] ?? '',
      githubUrl: json['githubUrl'] ?? '',
      linkedinUrl: json['linkedinUrl'] ?? '',
      
      isGuest: json['isGuest'] ?? false,
      
      authProvider: json['authProvider'],
      photoUrl: json['photoUrl'],
    );
  }

  // =======================================================================
  // ==  METHOD: Converts a UserModel to a Map (for JSON/Firebase)        ==
  // =======================================================================
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'experience': experience,
      'skills': skills.toList(), // Convert Set to List for JSON
      'resumeFileName': resumeFileName,
      'resumeFilePath': resumeFilePath,
      'phoneNumber': phoneNumber,
      'location': location,
      'summary': summary,
      'workExperience': workExperience,
      'education': education,
      'portfolioUrl': portfolioUrl,
      'githubUrl': githubUrl,
      'linkedinUrl': linkedinUrl,
      'isGuest': isGuest,
      'authProvider': authProvider,
      'photoUrl': photoUrl,
    };
  }

  // =======================================================================
  // ==  NEW METHOD: Creates a copy of the user model                   ==
  // =======================================================================
  /// Creates a safe copy of the UserModel.
  /// This is used in the ProfileScreen to avoid changing the
  /// main user object in the AuthProvider by mistake.
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
      // Create new collections to avoid sharing references
      skills: skills ?? Set<String>.from(this.skills),
      resumeFileName: resumeFileName ?? this.resumeFileName,
      resumeFilePath: resumeFilePath ?? this.resumeFilePath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      summary: summary ?? this.summary,
      workExperience: workExperience ?? List<String>.from(this.workExperience),
      education: education ?? List<String>.from(this.education),
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      isGuest: isGuest ?? this.isGuest,
      authProvider: authProvider ?? this.authProvider,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}