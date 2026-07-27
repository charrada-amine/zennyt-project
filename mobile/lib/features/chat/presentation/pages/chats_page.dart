import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/chat_providers.dart';
import '../../../../core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../widgets/chat_list_item.dart';
import '../../../../shared/widgets/platform_app_bar.dart';
import '../../../../shared/widgets/platform_scaffold.dart';

class ChatsPage extends ConsumerWidget {
  const ChatsPage({super.key});

  static const List<String> filterKeys = [
    'filterAll',
    'filterJobOffers',
    'filterProfessionals',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final conversationsAsync = ref.watch(conversationsProvider);
    final selectedFilter = ref.watch(chatFilterProvider);
    final filters = [
      l10n.filterAll,
      l10n.filterJobOffers,
      l10n.filterProfessionals,
    ];

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: Text(
          l10n.allChats,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        showBack: true,
      ),
      backgroundColor: AppColors.panelBackground,
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(120, 120, 128, 0.06),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Transform.translate(
              offset: const Offset(-30, 0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 12, right: 16),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(filters.length, (i) {
                    final isSelected = selectedFilter == i;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: i == filters.length - 1 ? 0 : 8,
                      ),
                      child: GestureDetector(
                        onTap: () =>
                            ref.read(chatFilterProvider.notifier).state = i,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.chipSelected
                                : AppColors.chipUnselected,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            filters[i],
                            style: TextStyle(
                              color: isSelected ? context.colors.cardSurface : context.colors.textPrimary,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 8.0,
                ),
                child: conversationsAsync.when(
                  data: (conversations) {
                    final filtered = selectedFilter == 0
                        ? conversations
                        : selectedFilter == 1
                            ? conversations.where((c) => c.isHiringContact).toList()
                            : conversations.where((c) => !c.isHiringContact).toList();

                    if (filtered.isEmpty) {
                      return Center(child: Text(l10n.noChats));
                    }

                    return ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 20,
                        endIndent: 20,
                        color: AppColors.itemDivider,
                      ),
                      itemBuilder: (context, index) {
                        final conversation = filtered[index];
                        return ChatListItem(
                          conversation: conversation,
                          onTap: () {
                            context.push('/chats/${conversation.id}', extra: conversation);
                          },
                        );
                      },
                    );
                  },
                  loading: () => Center(
                    child: AppConstants.isCupertino
                        ? const CupertinoActivityIndicator()
                        : const CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(child: Text('Erreur: $error')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
