import 'package:flutter/material.dart';

import 'widgets/legal_screen_layout.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const sections = [
    LegalSectionData(
      title: 'Information We Collect',
      body:
          'Smart BaitGuard collects monitoring station statuses, bait level data, device activity logs, and system alert histories to provide telemetry and real-time AI rodent detection alerts. No personal end-user facility mappings are used beyond required technical parameters.',
    ),
    LegalSectionData(
      title: 'How We Use Your Data',
      body:
          'Aggregated device status datasets are evaluated to automatically optimize bait alerts and improve predictive rodent activity mapping. We never sell your facility hardware tracking metrics to any external third-party data broker services.',
    ),
    LegalSectionData(
      title: 'Data Storage & Security',
      body:
          'All monitoring information is encrypted during remote transmission using standard transport layer protocols. Historical logs are archived strictly on cloud instances matching enterprise secure access controls and corporate policies.',
    ),
    LegalSectionData(
      title: 'Your Rights',
      body:
          'As a registered viewer or manager on our enterprise tenant, you hold the right to request comprehensive platform logs, download tracking charts, or request complete profile updates via the system administrator portal.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const LegalScreenLayout(
      title: 'Privacy Policy',
      subtitle: 'Last updated: January 2026',
      sections: sections,
    );
  }
}
