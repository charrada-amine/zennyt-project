import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import 'package:zennyt/core/constants.dart';
import '../../../../shared/widgets/initials_avatar.dart';

class ProfileRow extends StatelessWidget {
  const ProfileRow({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const InitialsAvatar(
            url:
                "https://plus.unsplash.com/premium_photo-1738449261730-2bc6a8ab40b5?q=80&w=1632&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D",
            size: 60,
          ),
          const SizedBox(width: 20),
          AppConstants.isCupertino
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => context.push('/create-post'),
                  child: Text(
                    l10n.newProject,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryGrey,
                      fontFamily: 'inter',
                      fontStyle: FontStyle.normal,
                      fontWeight: AppWeights.regular,
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () => context.push('/create-post'),
                  child: Text(
                    l10n.newProject,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.primaryGrey,
                      fontFamily: 'inter',
                      fontStyle: FontStyle.normal,
                      fontWeight: AppWeights.regular,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
