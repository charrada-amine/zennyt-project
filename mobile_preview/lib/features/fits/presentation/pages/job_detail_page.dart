import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../applications/data/applications_remote_datasource.dart';
import '../../domain/entities/fit_item.dart';

/// Détail d'une offre. Si [item] est fourni (depuis le deck Fits), l'en-tête et
/// le texte "About" affichent les vraies données ; les sections riches restent
/// représentatives (le backend ne renvoie pas tous les blocs).
class JobDetailPage extends StatefulWidget {
  final FitItem? item;
  const JobDetailPage({super.key, this.item});
  @override
  State<JobDetailPage> createState() => _JobDetailPageState();
}

/// État de la candidature à l'offre — pilote le bouton d'action en bas.
enum JobAction { start, continueAssessment, contact }

class _JobDetailPageState extends State<JobDetailPage> {
  bool _company = false; // false = Description, true = Company
  JobAction _action = JobAction.start;

  // Données réelles si l'offre est passée par la route, sinon valeurs maquette.
  String get _role =>
      (widget.item?.role.isNotEmpty ?? false) ? widget.item!.role : 'UI/UX Designer';
  String get _companyName =>
      (widget.item?.name.isNotEmpty ?? false) ? widget.item!.name : 'Google inc';
  String get _location => (widget.item?.location.isNotEmpty ?? false)
      ? widget.item!.location
      : 'California, USA';
  String? get _salary => widget.item?.salary;
  String? get _chip =>
      (widget.item != null && widget.item!.tags.isNotEmpty) ? widget.item!.tags.first : 'Contract';
  String get _about => (widget.item?.about?.isNotEmpty ?? false)
      ? widget.item!.about!
      : "At Google, we're on a mission to organize the world's information "
          "and make it universally accessible and useful. As a UI/UX Designer, "
          "you'll play a critical role in shaping the future of our products.";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: () => context.pop()),
        title: const Text('Job Detail',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        actions: [
          // Aperçu : bascule l'état (en vrai, déduit de la candidature/match).
          PopupMenuButton<JobAction>(
            icon: const Icon(Icons.more_vert, color: AppTheme.muted),
            onSelected: (a) => setState(() => _action = a),
            itemBuilder: (_) => const [
              PopupMenuItem(value: JobAction.start, child: Text('État : Start assessment')),
              PopupMenuItem(
                  value: JobAction.continueAssessment,
                  child: Text('État : Continue assessment')),
              PopupMenuItem(value: JobAction.contact, child: Text('État : Contact recruiter')),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: _actionButton(),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _header(),
          const SizedBox(height: 16),
          _tabs(),
          const SizedBox(height: 16),
          if (!_company) ..._description() else ..._companyInfo(),
        ],
      ),
    );
  }

  /// Soumet la candidature (POST /applications, best-effort) puis ouvre le test
  /// en passant l'id de l'offre et, si présent, l'id du test rattaché.
  Future<void> _applyAndStartAssessment() async {
    final item = widget.item;
    if (item != null) {
      try {
        final created = await sl<ApplicationsRemoteDataSource>().submit(item.id);
        if (mounted && created) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Candidature envoyée ✅')));
        }
      } catch (_) {
        // Non bloquant : on poursuit vers le test même si l'appel échoue.
      }
    }
    if (!mounted) return;
    context.push('/assessment', extra: <String, String?>{
      'assessmentId':
          (item != null && item.assessmentIds.isNotEmpty) ? item.assessmentIds.first : null,
      'jobOfferId': item?.id,
    });
  }

  Widget _actionButton() {
    final blue = FilledButton.styleFrom(
        backgroundColor: AppTheme.brandBlue,
        padding: const EdgeInsets.symmetric(vertical: 14));
    switch (_action) {
      case JobAction.start:
        return FilledButton(
          style: blue,
          onPressed: _applyAndStartAssessment,
          child: const Text('Start assessment'),
        );
      case JobAction.continueAssessment:
        return FilledButton(
          style: blue,
          onPressed: _applyAndStartAssessment,
          child: const Text('Continue assessment'),
        );
      case JobAction.contact:
        return FilledButton.icon(
          style: blue,
          onPressed: () => context.push('/chats'),
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Contact the recruiter'),
        );
    }
  }

  Widget _header() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: const Color(0xFFF1F3F8),
                borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Text('G',
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: AppTheme.brandBlue)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_role,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy)),
                Text(_companyName, style: const TextStyle(color: AppTheme.muted)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.muted),
          const SizedBox(width: 4),
          Text(_location, style: const TextStyle(color: AppTheme.muted)),
          const Spacer(),
          const Icon(Icons.group_outlined, size: 15, color: AppTheme.muted),
          const SizedBox(width: 4),
          const Text('30 Applicants', style: TextStyle(color: AppTheme.muted)),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.payments_outlined, size: 15, color: AppTheme.brandPink),
          const SizedBox(width: 4),
          Text(_salary ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
          const Spacer(),
          if (_chip != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F4),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(_chip!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF5F6275))),
            ),
        ]),
        const SizedBox(height: 14),
        const Text('Hiring Contact',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        const SizedBox(height: 8),
        const Row(children: [
          CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=31')),
          SizedBox(width: 8),
          Text('Kristin Watson',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.navy)),
        ]),
      ],
    );
  }

  Widget _tabs() {
    Widget pill(String label, bool isCompany) {
      final active = _company == isCompany;
      return GestureDetector(
        onTap: () => setState(() => _company = isCompany),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AppTheme.brandPink : const Color(0xFFFBE9F0),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppTheme.brandPink)),
        ),
      );
    }

    return Row(children: [
      pill('Description', false),
      const SizedBox(width: 10),
      pill('Company', true),
    ]);
  }

  List<Widget> _description() => [
        _section('About the Job', _about),
        _bullets('Responsibilities', const [
          'Translate user needs and business goals into compelling interface designs.',
          'Create wireframes, storyboards, user flows and prototypes.',
          'Conduct user testing and analyze feedback to refine designs.',
        ]),
        _bullets('Minimum Qualifications', const [
          "Bachelor's degree in Design, HCI, Computer Science or equivalent.",
          '3+ years of experience in UX/UI design for digital products.',
          'Proficiency in Figma, Sketch, Adobe XD.',
        ]),
        _bullets('Preferred Qualifications', const [
          'Knowledge of front-end development (HTML/CSS/JS).',
          'Familiarity with accessibility standards (WCAG).',
        ]),
        _bullets('What We Offer', const [
          'Competitive compensation and equity packages.',
          'Comprehensive health and wellness benefits.',
          'Hybrid work flexibility and world-class campuses.',
        ]),
      ];

  List<Widget> _companyInfo() => [
        _section('Who we are ?',
            'Google is a global technology company dedicated to organizing '
            'information and making it universally accessible — products used '
            'by billions, with a strong focus on usability and human experience.'),
        _section('Mission & Vision',
            'Create intuitive, inclusive and impactful digital experiences that '
            'solve real human problems at scale.'),
        _section('Culture & work environment',
            'Cross-functional, highly collaborative teams. The culture values '
            'curiosity, experimentation, feedback and continuous learning.'),
      ];

  Widget _section(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 15)),
            const SizedBox(height: 6),
            Text(body,
                style: const TextStyle(color: Color(0xFF555A6B), height: 1.45)),
          ],
        ),
      );

  Widget _bullets(String title, List<String> items) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 15)),
            const SizedBox(height: 6),
            for (final it in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  ', style: TextStyle(color: Color(0xFF555A6B))),
                    Expanded(
                      child: Text(it,
                          style: const TextStyle(
                              color: Color(0xFF555A6B), height: 1.4)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
}
