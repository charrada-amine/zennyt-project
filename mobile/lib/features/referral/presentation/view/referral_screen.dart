import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/features/referral/domain/entities/referral.dart';
import 'package:zennyt/features/referral/presentation/providers/referral_providers.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

/// Parrainage (maquettes 115/117) : lien à partager + liste des filleuls avec
/// leur statut (invité / en cours D-xx / recruté).
class ReferralScreen extends ConsumerWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralsAsync = ref.watch(referralsProvider);
    final linkAsync = ref.watch(referralLinkProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FBFF),
      appBar: CustomAppBar(
        title: 'Referral',
        onBack: () => context.pop(),
        trailingAction: _RoundAction(
          icon: HugeIcons.strokeRoundedUserAdd01,
          tooltip: 'Invite',
          onTap: () => _showInviteDialog(context, ref),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(referralsProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            linkAsync.when(
              loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
              error: (_, _) => const SizedBox.shrink(),
              data: (link) => _LinkCard(link: link),
            ),
            const SizedBox(height: 22),
            referralsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text('Could not load your referrals.', style: TextStyle(color: Color(0xFFE53935))),
                ),
              ),
              data: (referrals) => referrals.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'No referrals yet.\nInvite a friend to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF8A90A2), height: 1.5),
                        ),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your referrals (${referrals.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
                        ),
                        const SizedBox(height: 12),
                        ...referrals.map((r) => _ReferralTile(referral: r)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInviteDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite a friend'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Friend\'s e-mail', hintText: 'name@example.com'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Send invite'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty || !context.mounted) return;
    try {
      await ref.read(referralsProvider.notifier).invite(email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation sent!'), backgroundColor: Color(0xFF2AC052)),
        );
      }
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFE53935)),
        );
      }
    }
  }
}

class _LinkCard extends StatelessWidget {
  final ReferralLink link;
  const _LinkCard({required this.link});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6ECF7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earn ${link.bonusCurrency} ${link.bonusAmount} per recruited friend',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E1B4B)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Share your link. The bonus is paid once your friend is hired and their '
            'probation period is validated.',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE6ECF7)),
            ),
            child: Text(
              link.url,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link.url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied!'), backgroundColor: Color(0xFF2AC052)),
                    );
                  },
                  icon: const AppIcon(HugeIcons.strokeRoundedCopy01, size: 16),
                  label: const Text('Copy link'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: colors.primary),
                  onPressed: () => _share(context, link.url),
                  icon: const AppIcon(HugeIcons.strokeRoundedShare08, size: 16),
                  label: const Text('Share'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context, String url) async {
    // No share_plus dependency: offer e-mail / SMS via url_launcher + copy.
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const AppIcon(HugeIcons.strokeRoundedCopy01),
              title: const Text('Copy link'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const AppIcon(HugeIcons.strokeRoundedMail01),
              title: const Text('E-mail'),
              onTap: () async {
                Navigator.pop(ctx);
                await _launch(context, 'mailto:?subject=Join%20Zennyt&body=$url');
              },
            ),
            ListTile(
              leading: const AppIcon(HugeIcons.strokeRoundedMessage02),
              title: const Text('Messages'),
              onTap: () async {
                Navigator.pop(ctx);
                await _launch(context, 'sms:?&body=$url');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      await Clipboard.setData(ClipboardData(text: url));
    }
  }
}

class _ReferralTile extends StatelessWidget {
  final Referral referral;
  const _ReferralTile({required this.referral});

  @override
  Widget build(BuildContext context) {
    final status = referral.status;
    final (color, badge) = switch (status) {
      ReferralStatus.hired => (const Color(0xFF22C55E), 'Hired'),
      ReferralStatus.registered => (
          const Color(0xFFF59E0B),
          referral.daysRemaining != null ? 'In progress D-${referral.daysRemaining}' : 'In progress',
        ),
      ReferralStatus.cancelled => (const Color(0xFF94A3B8), 'Cancelled'),
      ReferralStatus.invited => (const Color(0xFF3B82F6), 'Invited'),
    };
    final initial = referral.displayName.trim().isEmpty
        ? '?'
        : referral.displayName.trim()[0].toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6ECF7)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFEEF2FF),
            backgroundImage: (referral.inviteeAvatarUrl != null && referral.inviteeAvatarUrl!.isNotEmpty)
                ? NetworkImage(referral.inviteeAvatarUrl!)
                : null,
            child: (referral.inviteeAvatarUrl == null || referral.inviteeAvatarUrl!.isEmpty)
                ? Text(initial, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF11428D)))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeAgo(referral.createdAt),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime? at) {
    if (at == null) return '';
    final diff = DateTime.now().difference(at);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

class _RoundAction extends StatelessWidget {
  final AppIconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundAction({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: kAppBarButtonDecoration(),
          child: AppIcon(icon, color: const Color(0xFF21438A), size: 20),
        ),
      ),
    );
  }
}
