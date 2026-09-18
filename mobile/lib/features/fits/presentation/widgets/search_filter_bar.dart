import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_text_field.dart';

import 'package:zennyt/shared/icons/app_icons.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key, this.onChanged});
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => AppTextField(
    hint: 'Search',
    prefixIcon: HugeIcons.strokeRoundedSearch01,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
  );
}
