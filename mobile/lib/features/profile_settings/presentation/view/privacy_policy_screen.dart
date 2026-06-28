import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.backButtonBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.backButtonBorder, width: 1),
                    ),
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Progress Careers',
                            style: AppTypography.titleLarge.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Corporate Privacy Policy',
                            style: AppTypography.titleLarge.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Last Updated: [30/02/2026]',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version: Corporate International Edition',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    
                    _buildSection(
                      colors,
                      '1. DATA CONTROLLER',
                      'Progress Careers operates through affiliated entities established in:\n'
                      '- France (Paris)\n'
                      '- United States (Delaware)\n'
                      '- United Arab Emirates (Dubai)\n'
                      'The relevant entity acting as Data Controller depends on the user\'s location and the contractual relationship established.\n'
                      'For all privacy-related matters: privacy@progresscareers.com',
                    ),
                    
                    _buildSection(
                      colors,
                      '2. SCOPE OF APPLICATION',
                      'This Privacy Policy applies to Candidates, Students, Recruiters, Employers, Ambassadors, and Website Visitors.\n'
                      'It covers all personal data processed through:\n'
                      '- The recruitment platform\n'
                      '- Psychometric (soft skills) games\n'
                      '- Technical (hard skills) assessments\n'
                      '- Artificial intelligence systems\n'
                      '- Video interviews\n'
                      '- Social networking features\n'
                      '- Payment and escrow services',
                    ),
                    
                    _buildSection(
                      colors,
                      '3. CATEGORIES OF PERSONAL DATA',
                      'A. Identification Data: name, email, phone number, address, CV data, employment history.\n'
                      'B. Assessment Data: psychometric results, behavioral metrics, technical test scores.\n'
                      'C. Biometric & Monitoring Data: webcam images, screenshots, keystroke dynamics, behavioral interaction patterns.\n'
                      'D. AI-Generated Data: automated scoring, profiling indicators, compatibility analysis.\n'
                      'E. Financial Data: escrow payments, interview credits, ambassador bonuses, IBAN/payment details.\n'
                      'F. Technical Data: IP address, device identifiers, cookies, log data.',
                    ),

                    _buildSection(
                      colors,
                      '4. LEGAL BASES FOR PROCESSING (GDPR USERS)',
                      'Processing is based on:\n'
                      '- Performance of a contract\n'
                      '- Legitimate interests (security, fraud prevention, platform integrity)\n'
                      '- Legal obligations\n'
                      '- Explicit consent (for biometric monitoring and cookies where required)',
                    ),

                    _buildSection(
                      colors,
                      '5. PURPOSES OF PROCESSING',
                      'Personal data is processed to:\n'
                      '- Provide recruitment and matching services\n'
                      '- Conduct psychometric and technical assessments\n'
                      '- Prevent fraud and identity misuse\n'
                      '- Generate AI-based analytical reports\n'
                      '- Process financial transactions\n'
                      '- Ensure compliance with applicable laws',
                    ),

                    _buildSection(
                      colors,
                      '6. ARTIFICIAL INTELLIGENCE & PROFILING',
                      'Progress Careers uses AI systems to analyze performance data and generate decision-support summaries.\n'
                      'AI does not replace human hiring decisions.\n'
                      'Users in the European Union have the right to:\n'
                      '- Request meaningful information about the logic involved\n'
                      '- Request human intervention\n'
                      '- Object to automated profiling where legally applicable',
                    ),

                    _buildSection(
                      colors,
                      '7. BIOMETRIC & MONITORING DISCLOSURE',
                      'To preserve assessment integrity, monitoring technologies may collect webcam images, screenshots, and keystroke dynamics.\n'
                      'Such data is processed solely for fraud detection and identity verification.\n'
                      'Where required by law, explicit consent is obtained prior to activation.\n'
                      'Biometric-related data is minimized, securely stored, and retained only as long as necessary for fraud prevention purposes.',
                    ),

                    _buildSection(
                      colors,
                      '8. INTERNATIONAL DATA TRANSFERS',
                      'Given the multinational structure (France, USA, UAE), personal data may be transferred internationally.\n'
                      'For EU users, transfers outside the European Economic Area rely on:\n'
                      '- Standard Contractual Clauses (SCCs)\n'
                      '- Adequacy decisions (where applicable)\n'
                      '- Appropriate technical and organizational safeguards',
                    ),

                    _buildSection(
                      colors,
                      '9. DATA RETENTION POLICY',
                      '- Account data: retained during active relationship.\n'
                      '- Assessment data: retained for recruitment duration and compliance obligations.\n'
                      '- Security logs: retained for a limited period for fraud prevention.\n'
                      '- Financial records: retained as required by accounting and tax laws.\n'
                      'Inactive accounts may be deleted after a defined inactivity period (24–36 months).',
                    ),

                    _buildSection(
                      colors,
                      '10. DATA SUBJECT RIGHTS',
                      'EU (GDPR): access, rectification, erasure, restriction, portability, objection.\n'
                      'California (CCPA/CPRA): right to know, delete, opt-out of sale (no sale of data occurs).\n'
                      'UAE: rights under UAE Federal Data Protection Law.\n'
                      'Requests may be submitted to privacy@progresscareers.com',
                    ),

                    _buildSection(
                      colors,
                      '11. DATA SHARING & PROCESSORS',
                      'Personal data may be shared with:\n'
                      '- Recruiters and employers (for recruitment purposes only)\n'
                      '- Payment processors and escrow providers\n'
                      '- Hosting and cloud service providers\n'
                      '- Analytics providers\n'
                      '- Authorities where legally required\n'
                      'All processors are contractually bound to confidentiality and data protection obligations.',
                    ),

                    _buildSection(
                      colors,
                      '12. SECURITY MEASURES',
                      'We implement industry-standard security measures including:\n'
                      '- Encryption in transit (SSL/TLS)\n'
                      '- Secure cloud hosting environments\n'
                      '- Role-based access controls\n'
                      '- Continuous monitoring and fraud detection systems\n'
                      '- Escrow-based payment protection',
                    ),

                    _buildSection(
                      colors,
                      '13. CHILDREN & MINORS',
                      'If users under 18 access the Platform, parental or legal guardian consent may be required in accordance with applicable law.',
                    ),

                    _buildSection(
                      colors,
                      '14. COOKIE POLICY REFERENCE',
                      'Cookies and similar technologies are used for authentication, analytics, performance, and security.\n'
                      'A separate Cookie Policy provides detailed information and consent mechanisms.',
                    ),

                    _buildSection(
                      colors,
                      '15. DATA PROTECTION IMPACT ASSESSMENT (DPIA)',
                      'Given the use of psychometric profiling, AI processing, and monitoring technologies,\n'
                      'Progress Careers conducts periodic Data Protection Impact Assessments to evaluate risks and implement mitigation measures.',
                    ),

                    _buildSection(
                      colors,
                      '16. POLICY UPDATES',
                      'This Privacy Policy may be updated periodically to reflect legal, technical, or operational changes.\n'
                      'Users will be notified via platform notice, dashboard alert, or email when significant changes occur.',
                    ),
                    
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(AppColorScheme colors, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
