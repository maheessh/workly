class UserModel {
  String name;
  String email;
  String experience;
  Set<String> skills;
  String resumeFileName;

  UserModel({
    this.name = '',
    this.email = '',
    this.experience = 'Entry-Level',
    Set<String>? skills,
    this.resumeFileName = '',
  }) : this.skills = skills ?? <String>{}; // Fixed: Initializes a new mutable set
}