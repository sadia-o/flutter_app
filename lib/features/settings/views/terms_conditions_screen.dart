import 'package:flutter/material.dart';

import 'widgets/legal_screen_layout.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const sections = [
    LegalSectionData(
      title: 'Acceptance of Terms',
      body:
          'By accessing or logging into the Smart BaitGuard corporate application, you signify your complete agreement to be legally bound by these terms. If you do not accept these policies, you are not authorized to check BaitGuard system statuses.',
    ),
    LegalSectionData(
      title: 'Use of Service',
      body:
          'Services must be accessed strictly in coordination with authentic authorized facility hardware monitoring kits. End-users are strictly prohibited from generating fake BaitGuard sensor data or falsifying AI detection reports.',
    ),
    LegalSectionData(
      title: 'User Responsibilities',
      body:
          'Managers and viewers remain individually responsible for retaining strict password secrecy, managing correct push alert priorities, and physically updating low bait or offline monitoring units upon receiving automated system telemetry alerts.',
    ),
    LegalSectionData(
      title: 'Limitation of Liability',
      body:
          'Smart BaitGuard operates as an auxiliary assistance utility to support overall facility sanitization regimes. Under no conditions shall we be liable for unforeseen product loss, storage contaminations, or missed physical rodent intrusions.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const LegalScreenLayout(
      title: 'Terms & Conditions',
      subtitle: 'Last updated: January 2026',
      sections: sections,
    );
  }
}
