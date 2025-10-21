import 'package:flutter/material.dart';
import '../models/job_model.dart';

final List<JobModel> mockJobs = [
  JobModel(
    title: 'Flutter Developer',
    company: 'Innovate Solutions',
    location: 'Remote',
    experienceLevel: 'Mid-Level',
    requiredSkills: {'Flutter', 'Dart', 'Firebase', 'REST APIs'},
    description: 'Join our team to build beautiful cross-platform applications. You will be responsible for developing new user-facing features, building reusable components and front-end libraries for future use, and optimizing components for maximum performance across a vast array of web-capable devices.',
    companyLogo: Icons.phone_android,
  ),
  JobModel(
    title: 'Frontend Engineer',
    company: 'Creative Web Ltd.',
    location: 'San Francisco, CA',
    experienceLevel: 'Senior',
    requiredSkills: {'React', 'JavaScript', 'TypeScript', 'CSS', 'HTML5'},
    description: 'Lead the development of our user-facing features. We are looking for a seasoned engineer who is passionate about UI/UX and has a strong understanding of web fundamentals. You will mentor junior developers and drive technical decision-making.',
    companyLogo: Icons.web,
  ),
  JobModel(
    title: 'Product Manager',
    company: 'Future Tech',
    location: 'New York, NY',
    experienceLevel: 'Senior',
    requiredSkills: {'Agile', 'Roadmapping', 'JIRA', 'User Research'},
    description: 'Define product vision, strategy, and roadmap. You will work closely with engineering, design, and marketing to guide products from conception to launch. This role requires a strong analytical background and excellent communication skills.',
    companyLogo: Icons.business,
  ),
  JobModel(
    title: 'UI/UX Designer',
    company: 'DesignFirst',
    location: 'Remote',
    experienceLevel: 'Mid-Level',
    requiredSkills: {'Figma', 'Adobe XD', 'Prototyping', 'User Testing'},
    description: 'Create engaging and user-friendly interfaces. We need a designer who can translate complex requirements into intuitive and beautiful designs. You will be part of the entire product lifecycle, from research to high-fidelity mockups.',
    companyLogo: Icons.design_services,
  ),
];