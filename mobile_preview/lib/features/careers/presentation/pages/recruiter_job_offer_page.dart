import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/recruiter_job_offer.dart';

/// Détail d'une offre côté recruteur : carte stats (candidats / réussite),
/// onglets Description / Company. Tap sur la carte → scores des candidats.
class RecruiterJobOfferPage extends StatefulWidget {
  final RecruiterJobOffer offer;
  const RecruiterJobOfferPage({super.key, required this.offer});
  @override
  State<RecruiterJobOfferPage> createState() => _RecruiterJobOfferPageState();
}

class _RecruiterJobOfferPageState extends State<RecruiterJobOfferPage> {
  bool _company = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.offer;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.chevron_left), onPressed: () => context.pop()),
        title: const Text('Job Offer',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statCard(o),
          const SizedBox(height: 16),
          _tabs(),
          const SizedBox(height: 16),
          if (!_company) ..._description() else ..._companyInfo(),
        ],
      ),
    );
  }

  Widget _statCard(RecruiterJobOffer o) {
    return GestureDetector(
      onTap: () => context.push('/recruiter/scores', extra: o),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppTheme.brandBlue, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(8)),
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
                    Text(o.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700)),
                    Text(o.company,
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.white70),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _stat('Candidates', '${o.candidates}')),
              const SizedBox(width: 12),
              Expanded(child: _stat('Success rate', '${o.successRate}%')),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(o.location,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              const Icon(Icons.payments_outlined, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(o.salary,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ]),
            const SizedBox(height: 8),
            const Text('Tap to see candidate scores',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
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
        _section('About the Job',
            "At Google, we're on a mission to organize the world's information and "
            "make it universally accessible and useful. As a ${widget.offer.title}, "
            "you'll play a critical role in shaping the future of our products."),
        _bullets('Responsibilities', const [
          'Translate user needs and business goals into scalable solutions.',
          'Collaborate with cross-functional teams.',
          'Conduct testing and analyze feedback to iterate.',
        ]),
      ];

  List<Widget> _companyInfo() => [
        _section('Who we are ?',
            'Google is a global technology company dedicated to organizing '
            'information and making it universally accessible.'),
      ];

  Widget _section(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 15)),
            const Spacer(),
            const Icon(Icons.edit_outlined, size: 16, color: AppTheme.muted),
          ]),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: Color(0xFF555A6B), height: 1.45)),
        ]),
      );

  Widget _bullets(String title, List<String> items) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppTheme.navy, fontSize: 15)),
            const Spacer(),
            const Icon(Icons.edit_outlined, size: 16, color: AppTheme.muted),
          ]),
          const SizedBox(height: 6),
          for (final it in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('•  ', style: TextStyle(color: Color(0xFF555A6B))),
                Expanded(
                    child: Text(it,
                        style: const TextStyle(color: Color(0xFF555A6B), height: 1.4))),
              ]),
            ),
        ]),
      );
}
