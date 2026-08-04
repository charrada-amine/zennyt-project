import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../domain/entities/recruiter_job_offer.dart';
import '../../domain/entities/recruiter_test.dart';
import '../bloc/careers_bloc.dart';

/// Accueil recruteur "Careers" : ses tests + ses offres publiées.
class CareersPage extends StatelessWidget {
  const CareersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.navy,
        elevation: 0.5,
        centerTitle: true,
        title: const Text('Careers',
            style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.navy)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=15')),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 2),
      body: BlocBuilder<CareersBloc, CareersState>(
        builder: (context, state) {
          if (state.status == CareersStatus.loading ||
              state.status == CareersStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == CareersStatus.error) {
            return Center(child: Text(state.message));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              _sectionHeader('Your Tests',
                  trailing: Icons.edit_outlined,
                  onTrailing: () => context.push('/recruiter/my-tests')),
              SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _addTile(context),
                    for (final t in state.tests) _TestChip(test: t),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _sectionHeader('Your Job Offers',
                  trailing: Icons.add,
                  onTrailing: () => context.push('/recruiter/add-offer')),
              for (final o in state.offers)
                _JobOfferRow(
                  offer: o,
                  onTap: () => context.push('/recruiter/job-offer', extra: o),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title, {IconData? trailing, VoidCallback? onTrailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.navy)),
        const Spacer(),
        if (trailing != null)
          InkWell(
            onTap: onTrailing,
            child: Icon(trailing, size: 18, color: AppTheme.brandBlue),
          ),
      ]),
    );
  }

  Widget _addTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => context.push('/recruiter/add-assessment'),
        child: Container(
          width: 64,
          decoration: BoxDecoration(
              color: AppTheme.brandPink,
              borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.add_box_outlined, color: Colors.white),
        ),
      ),
    );
  }
}

class _TestChip extends StatelessWidget {
  final RecruiterTest test;
  const _TestChip({required this.test});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 72,
        decoration: BoxDecoration(
            color: AppTheme.brandBlue, borderRadius: BorderRadius.circular(14)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lightbulb_outline, color: Colors.white, size: 26),
            const SizedBox(height: 6),
            Text(test.name,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _JobOfferRow extends StatelessWidget {
  final RecruiterJobOffer offer;
  final VoidCallback onTap;
  const _JobOfferRow({required this.offer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFECECEF)),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: const Color(0xFFF1F3F8),
                    borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.center,
                child: const Text('G',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppTheme.brandBlue)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(offer.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.navy,
                        fontSize: 15)),
              ),
              Text(offer.salary,
                  style: const TextStyle(
                      color: AppTheme.brandBlue, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 4),
            Text('${offer.company} · ${offer.location}',
                style: const TextStyle(color: AppTheme.muted, fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              Text(offer.postedAgo,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
              const Spacer(),
              for (final t in offer.tags) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F4),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(t,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF5F6275))),
                ),
                const SizedBox(width: 6),
              ],
            ]),
          ],
        ),
      ),
    );
  }
}
