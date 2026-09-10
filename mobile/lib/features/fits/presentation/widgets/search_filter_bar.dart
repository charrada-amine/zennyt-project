import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_text_field.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key, this.onChanged});
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => AppTextField(
    hint: 'Search',
    prefixIcon: Icons.search_rounded,
    onChanged: onChanged,
    textInputAction: TextInputAction.search,
  );
}
