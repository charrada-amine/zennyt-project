import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/selection_list_tile.dart';
import '../../../../core/theme/theme.dart';
import '../viewmodel/profile_setup_viewmodel.dart';

/// Full-screen searchable selection list for the user's field of work.
/// Pops with the selected industry string.
class FieldOfWorkScreen extends ConsumerStatefulWidget {
  const FieldOfWorkScreen({super.key});

  @override
  ConsumerState<FieldOfWorkScreen> createState() => _FieldOfWorkScreenState();
}

class _FieldOfWorkScreenState extends ConsumerState<FieldOfWorkScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.read(fieldOfWorkRepositoryProvider).getFields();
    final selected = ref.watch(
      profileSetupViewModelProvider.select((s) => s.fieldOfWork),
    );
    final filtered = _query.isEmpty
        ? all
        : all
              .where((f) => f.toLowerCase().contains(_query.toLowerCase()))
              .toList();
    final hPadding = Responsive.horizontalPadding(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            const AppBackButton(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                hPadding,
                0,
                hPadding,
                AppSpacing.md,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppStrings.fieldOfWork,
                  style: AppTypography.titleLarge.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                hPadding,
                0,
                hPadding,
                AppSpacing.md,
              ),
              child: TextField(
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search, size: AppSpacing.iconMd),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 0, indent: AppSpacing.screenPaddingH),
                itemBuilder: (context, index) {
                  final field = filtered[index];
                  return SelectionListTile(
                    label: field,
                    selected: field == selected,
                    onTap: () {
                      ref
                          .read(profileSetupViewModelProvider.notifier)
                          .setFieldOfWork(field);
                      context.pop();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
