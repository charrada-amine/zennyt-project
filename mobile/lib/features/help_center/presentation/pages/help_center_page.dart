// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../../../../core/constants.dart';
import '../../../../shared/widgets/platform_app_bar.dart';
import '../../../../shared/widgets/platform_scaffold.dart';
import '../widgets/help_chat_item.dart';
import '../providers/help_center_providers.dart';

class HelpCenterPage extends ConsumerStatefulWidget {
  const HelpCenterPage({super.key});

  @override
  ConsumerState<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends ConsumerState<HelpCenterPage> {
  bool _opening = false;

  /// Ouvre une conversation puis y entre. Rien ne permettait de le faire : la liste ne
  /// pouvait que rester vide.
  Future<void> _openConversation() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final chat = await ref.read(helpCenterActionsProvider).openChat();
      if (!mounted) return;
      context.push('/help-center/${chat.id}', extra: chat);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("La conversation n'a pas pu etre ouverte.")),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final helpChatsAsync = ref.watch(helpChatsProvider);
    final l10n = AppLocalizations.of(context);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Column(
          children: [
            Text(
              l10n.helpCenter,
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'inter',
                fontWeight: AppWeights.semiBold,
                color: AppColors.chipSelected,
              ),
            ),
            Text(
              l10n.customerService,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'inter',
                fontWeight: AppWeights.regular,
                color: AppColors.subtitleColor,
              ),
            ),
          ],
        ),
        showBack: true,
        onLeadingPressed: () => context.pop(),
      ),
      backgroundColor: AppColors.panelBackground,
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _opening ? null : _openConversation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.chipSelected,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _opening
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.add_comment_outlined, size: 20),
                  label: const Text('Contacter le support'),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: helpChatsAsync.when(
                data: (chats) => chats.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            "Aucune conversation pour l'instant.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.subtitleColor),
                          ),
                        ),
                      )
                    : ListView.separated(
                  itemCount: chats.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 0.5,
                    indent: 20,
                    endIndent: 20,
                    color: AppColors.itemDivider,
                  ),
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return HelpChatItem(
                      chat: chat,
                      onTap: () {
                        context.push('/help-center/${chat.id}', extra: chat);
                      },
                    );
                  },
                ),
                loading: () => Center(
                  child: AppConstants.isCupertino
                      ? const CupertinoActivityIndicator()
                      : const CircularProgressIndicator(),
                ),
                error: (error, _) => Center(child: Text('Erreur: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
