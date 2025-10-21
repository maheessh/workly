import 'package:flutter/material.dart';


class JobModel {
  final String title;
  final String company;
  final String location;
  final String experienceLevel;
  final Set<String> requiredSkills;
  final String description;
  final IconData companyLogo; 

  JobModel({
    required this.title,
    required this.company,
    required this.location,
    required this.experienceLevel,
    required this.requiredSkills,
    required this.description,
    required this.companyLogo,
  });
}