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

class HelpCenterPage extends ConsumerWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            const SizedBox(height: 20),
            Expanded(
              child: helpChatsAsync.when(
                data: (chats) => ListView.separated(
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
