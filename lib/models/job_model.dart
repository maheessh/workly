// lib/models/job_model.dart
import 'package:flutter/material.dart';

class JobModel {
  final String title;
  final String company;
  final String location;
  final String experienceLevel;
  final Set<String> requiredSkills;
  final String description;
  final IconData companyLogo;
  final String applylink; // <-- 1. ADD THIS

  JobModel({
    required this.title,
    required this.company,
    required this.location,
    required this.experienceLevel,
    required this.requiredSkills,
    required this.description,
    required this.companyLogo,
    required this.applylink, // <-- 2. ADD THIS
  });

  factory JobModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> skillsList = json['requiredSkills'] ?? [];
    final Set<String> skills = skillsList.map((skill) => skill.toString()).toSet();
    final String logoString = json['companyLogo'] ?? 'business';
    final IconData logo = _mapStringToIcon(logoString);

    return JobModel(
      title: json['title'] ?? 'No Title',
      company: json['company'] ?? 'No Company',
      location: json['location'] ?? 'No Location',
      experienceLevel: json['experienceLevel'] ?? 'N/A',
      requiredSkills: skills,
      description: json['description'] ?? 'No Description',
      companyLogo: logo,
      applylink: json['applylink'] ?? '', // <-- 3. ADD THIS
    );
  }

  static IconData _mapStringToIcon(String iconName) {
    switch (iconName) {
      case 'phone_android': return Icons.phone_android;
      case 'web': return Icons.web;
      case 'design_services': return Icons.design_services;
      case 'business': return Icons.business;
      default: return Icons.business;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'company': company,
      'location': location,
      'experienceLevel': experienceLevel,
      'requiredSkills': requiredSkills.toList(),
      'description': description,
      // We don't need to send the link or logo to Gemini
    };
  }
}