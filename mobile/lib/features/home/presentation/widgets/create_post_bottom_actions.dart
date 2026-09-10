import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:zennyt/core/constants.dart';
import '../../../../core/theme/app_color_scheme.dart';

class CreatePostBottomActions extends StatelessWidget {
  final VoidCallback onAddTap;
  final VoidCallback onMediaTap;
  final double bottomInset;

  const CreatePostBottomActions({
    super.key,
    required this.onAddTap,
    required this.onMediaTap,
    required this.bottomInset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Row(
        children: [
          GestureDetector(
            onTap: onMediaTap,
            child: FaIcon(
              FontAwesomeIcons.image,
              color: context.colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {},
            child: FaIcon(
              FontAwesomeIcons.trophy,
              color: context.colors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: onAddTap,
            child: Icon(
              Icons.add,
              color: context.colors.primary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
