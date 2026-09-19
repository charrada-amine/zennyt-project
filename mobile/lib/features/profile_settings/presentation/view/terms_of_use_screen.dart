import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../auth/presentation/auth_providers.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Terms of Use & Conditions (design screens 120, 274-275).
///
/// Content is fetched from `GET /legal/terms-of-use`; the in-app transcription
/// stays as an offline fallback (see `docs/SCREENS_1TO1_PLAN.md`).
class TermsOfUseScreen extends ConsumerWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final async = ref.watch(legalDocumentProvider('terms-of-use'));
    final sections = async.maybeWhen(
      data: (document) => document.sections.map((s) => (s.heading, s.body)).toList(),
      orElse: () => _sections,
    );
    final lastUpdated = async.maybeWhen(
      data: (document) => document.lastUpdated,
      orElse: () => 'September 10, 2025',
    );

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
                      icon: AppIcon(
                        HugeIcons.strokeRoundedArrowLeft01,
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
                    Text(
                      'Terms of Use & Conditions',
                      style: AppTypography.titleLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last Updated: $lastUpdated',
                      style: AppTypography.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    for (final s in sections) _buildSection(colors, s.$1, s.$2),
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

const List<(String, String)> _sections = [
  (
    '1. Legal Notice',
    '- Company Name: Zennyt, Inc.\n'
        '- Registered Office: [Insert Address]\n'
        '- Incorporation & Tax ID: [Insert State of Incorporation, EIN]\n'
        '- Contact: [Insert legal contact email]\n'
        '- Hosting Provider: [Insert hosting provider name & address, if required]',
  ),
  (
    '2. Introduction',
    'Zennyt provides recruitment, assessment, and networking solutions. '
        'By creating an account, completing assessments, or using the Platform, candidates '
        'and students ("you," "your") agree to these Terms of Use & Conditions.',
  ),
  (
    '3. Candidate Obligations',
    '- Provide accurate and truthful information.\n'
        '- Use the Platform only for lawful purposes.\n'
        '- Do not engage in fraudulent activity, impersonation, or misuse of the Platform.',
  ),
  (
    '4. Social Network Features',
    'Zennyt also provides social networking functionalities, including but not '
        'limited to user walls, posts, comments, likes, and follower connections.\n'
        '- Users are solely responsible for the content they publish and agree not to post '
        'unlawful, defamatory, discriminatory, offensive, or misleading material.\n'
        '- Users remain the owners of their content but grant Zennyt a '
        'non-exclusive, worldwide, royalty-free license to display, host, and distribute such '
        'content within the Platform solely for the purpose of operating and improving the services.\n'
        '- Zennyt reserves the right to moderate, remove, or restrict access to any '
        'content or account that violates these Terms or applicable law.',
  ),
  (
    '5. Video Interview Services',
    '- Candidates may be invited to video interviews through the Platform.\n'
        '- The Platform provides only the technical infrastructure and is not responsible for '
        'the content or outcome of interviews.\n'
        '- Sharing personal contact details with recruiters outside the Platform in order to '
        'bypass official processes is prohibited.',
  ),
  (
    '6. Psychometric Assessments',
    'Zennyt provides psychometric games (soft skills) and technical skill tests '
        '(hard skills) designed to comply with recognized psychological and scientific standards '
        '(APA) and aligned with the Americans with Disabilities Act (ADA). These tools are '
        'recruitment-focused and not intended for clinical diagnosis.',
  ),
  (
    '7. Fraud Prevention & Monitoring',
    '- To ensure the integrity of assessments, Zennyt may collect anti-fraud data, '
        'including but not limited to screenshots, webcam images, keystroke dynamics, and '
        'behavioral patterns during the tests.\n'
        '- These measures are used solely to detect impersonation, cheating, or identity fraud.\n'
        '- By using the Platform, candidates consent to this monitoring and acknowledge that '
        'fraudulent behavior may result in account suspension or disqualification.',
  ),
  (
    '8. Artificial Intelligence and Automated Processing',
    'Zennyt uses artificial intelligence (AI) to process results from psychometric '
        'games (soft skills) and technical skill tests (hard skills) completed by candidates.\n'
        '- The AI system analyzes raw performance data and generates a summary report '
        'highlighting key skills, behavioral indicators, and potential areas of strength.\n'
        '- These AI-generated summaries are intended solely as decision-support tools for '
        'recruiters and do not replace human judgment.\n'
        '- Recruiters remain fully responsible for final hiring decisions, and candidates '
        'acknowledge that their data may be automatically analyzed as part of the recruitment '
        'process when using the Platform.',
  ),
  (
    '9. Accessibility Commitment',
    'Zennyt is committed to accessibility and strives to conform to the WCAG 2.1 '
        'Level AA and ADA requirements. While reasonable efforts are made, full accessibility '
        'of all content cannot be guaranteed.',
  ),
  (
    '10. Cookies & Data Collection',
    '- The Platform uses cookies and similar technologies to improve user experience, analyze '
        'usage patterns, and provide personalized services.\n'
        '- By using the Platform, you consent to our use of cookies in accordance with our '
        'Privacy Policy.\n'
        '- Candidates may manage or disable cookies through their browser settings, but this '
        'may limit certain features of the Platform.',
  ),
  (
    '11. Privacy and Data Retention',
    '- Candidates may request access, correction, or deletion of their personal data.\n'
        '- Data is retained only for recruitment and HR purposes and in compliance with '
        'applicable law.\n'
        '- Zennyt complies with applicable data protection regulations, including but '
        'not limited to the General Data Protection Regulation (GDPR) for users located in the '
        'European Union and relevant state privacy laws in the United States (such as the '
        'CCPA/CPRA in California).\n'
        'Zennyt is authorized to collect candidates\' and students\' contact details, as '
        'well as the results of their behavioral (soft skills) and technical (hard skills) '
        'assessments. Such data may be processed, analyzed, and made available to third-party '
        'companies exclusively for the purposes of recruitment, human resources management, and '
        'professional matching.',
  ),
  (
    '12. Ambassador Program and Compensation',
    'Definition\n'
        'The Ambassador Program allows any candidate registered on the Zennyt platform '
        '(hereinafter the "Ambassador") to invite new candidates to join the platform '
        '(hereinafter the "Affiliates").\n\n'
        'Nature of the Program\n'
        'For the avoidance of doubt, the Ambassador Program is a single-level referral program '
        'only and shall not be considered, construed, or operated as a multi-level marketing '
        '(MLM) or pyramid scheme.\n\n'
        'Compensation Principle\n'
        'The Ambassador shall receive a bonus of eight hundred US dollars (USD 800) for each '
        'effective recruitment of one of their Affiliates, provided that Zennyt has '
        'effectively collected the commission owed by the client company in connection with said '
        'recruitment.\n\n'
        'Validity of Recruitment\n'
        'A recruitment shall only be deemed valid upon the completion of a three (3) month '
        'probationary or guarantee period following the Affiliate\'s hiring date by the client '
        'company. Only after this probationary period is successfully completed will the '
        'Ambassador\'s bonus become payable. In the event that the employment contract is '
        'terminated during this period (resignation, dismissal, non-compliance of the profile, or '
        'any other cause), no bonus shall be due to the Ambassador.\n\n'
        'Eligibility Conditions\n'
        '- The bonus shall only be granted for Affiliates directly invited by the Ambassador '
        'through the referral tools provided by the platform (personalized link, unique code, etc.).\n'
        '- The bonus shall only be due if the invited Affiliate is recruited by a client company '
        'via the Zennyt platform and such recruitment is validated pursuant to the '
        'rules above.\n'
        '- The bonus shall only be payable once Zennyt has fully collected the '
        'corresponding commission.\n\n'
        'Payment Terms\n'
        '- Bonuses earned shall be accumulated in the Ambassador\'s personal account and may be '
        'consulted at any time through the tracking dashboard.\n'
        '- Payment of bonuses shall be made by Zennyt within a maximum period of '
        'thirty (30) days following the validation of the recruitment (after the probationary '
        'period) and the collection of the corresponding commissions.\n'
        '- Payments shall be made to the bank account (IBAN/RIB) or credit card information '
        'provided by the Ambassador, or by any other method of payment accepted by the Platform.\n'
        '- The Ambassador acknowledges and agrees that they are solely responsible for reporting '
        'and paying any taxes or social contributions arising from the bonuses received under the '
        'Ambassador Program. Zennyt shall in no event be held liable in this respect.\n\n'
        'Limitations and Verification\n'
        'Zennyt reserves the right to verify the authenticity of invitations and '
        'invited profiles to prevent fraud, misuse, or fictitious registrations. Any attempt at '
        'manipulation, fraud, or misuse contrary to these conditions shall result in the '
        'immediate suspension of the Ambassador\'s account and the cancellation of bonuses in '
        'progress.\n\n'
        'Amendments\n'
        'Zennyt reserves the right to modify, at any time, the amount of the bonus, the '
        'payment conditions, or the technical modalities of the Ambassador Program, subject to '
        'informing users through any appropriate means (website, e-mail, personal dashboard).',
  ),
  (
    '13. Candidate Conduct',
    '- Candidates agree to use the Platform fairly and respectfully.\n'
        '- Any attempt to assist recruiters in bypassing the Platform\'s processes may result in '
        'suspension or termination of the candidate\'s account.',
  ),
  (
    '14. Limitation of Liability',
    '- The Platform is provided "as is".\n'
        '- Zennyt provides tools and services to support recruitment processes but does '
        'not act as an employer or employment agency, and makes no guarantee of securing '
        'employment opportunities.\n'
        '- Liability is limited to the extent permitted by law.',
  ),
  (
    '15. Termination & Suspension',
    'Zennyt reserves the right to suspend or terminate candidate accounts in case of '
        'fraud, violation of these Terms, or abusive behavior.',
  ),
  (
    '16. Force Majeure',
    'Zennyt shall not be liable for delays or failures due to circumstances beyond '
        'reasonable control (e.g., natural disasters, outages, cyberattacks, government '
        'restrictions).',
  ),
  (
    '17. Governing Law & Dispute Resolution',
    '- These Terms are governed by the laws of the State of Delaware, United States.\n'
        '- Disputes shall be resolved by binding arbitration in Delaware, in accordance with the '
        'rules of the American Arbitration Association (AAA).\n'
        '- Candidates waive the right to participate in class actions.',
  ),
];
