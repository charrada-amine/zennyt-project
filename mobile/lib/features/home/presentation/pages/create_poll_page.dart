// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zennyt/core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../providers/poll_provider.dart';

class CreatePollPage extends ConsumerStatefulWidget {
  const CreatePollPage({super.key});

  @override
  ConsumerState<CreatePollPage> createState() => _CreatePollPageState();
}

class _CreatePollPageState extends ConsumerState<CreatePollPage> {
  late TextEditingController _questionController;
  late List<TextEditingController> _optionControllers;
  String _selectedTimeframe = '3 days';

  final List<String> _timeframeOptions = [
    '1 day',
    '3 days',
    '7 days',
    '14 days',
  ];

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController();
    _optionControllers = [
      TextEditingController(),
      TextEditingController(),
    ];
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canAdd {
    if (_questionController.text.trim().isEmpty) return false;
    final filled =
        _optionControllers.where((c) => c.text.trim().isNotEmpty).length;
    return filled >= 2;
  }

  void _addOption() {
    if (_optionControllers.length < 6) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  void _submit() {
    final notifier = ref.read(pollCreationProvider.notifier);
    notifier.setQuestion(_questionController.text);
    for (int i = 0; i < _optionControllers.length; i++) {
      notifier.updateOption(i, _optionControllers[i].text);
    }
    notifier.setTimeframe(_selectedTimeframe);

    final state = ref.read(pollCreationProvider);
    if (state.isValid) {
      context.pop(state.toPoll());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.panelBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.yourQuestion,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _questionController,
                      onChanged: (_) => setState(() {}),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.typeTheQuestion,
                        hintStyle: TextStyle(
                          color: context.colors.textMuted,
                          fontSize: 15,
                        ),
                        filled: true,
                        fillColor: AppColors.surfaceLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colors.border,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: context.colors.border,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.iconColor,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ..._optionControllers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final controller = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  l10n.optionIndex(index + 1),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const Spacer(),
                                if (_optionControllers.length > 2)
                                  GestureDetector(
                                    onTap: () => _removeOption(index),
                                    child: Icon(
                                      AppConstants.isCupertino
                                          ? CupertinoIcons.xmark_circle_fill
                                          : Icons.cancel,
                                      color: context.colors.textMuted,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: controller,
                              onChanged: (_) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: l10n.addAnOption,
                                hintStyle: TextStyle(
                                  color: context.colors.textMuted,
                                  fontSize: 15,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: context.colors.divider,
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: context.colors.divider,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.iconColor,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_optionControllers.length < 6)
                      GestureDetector(
                        onTap: _addOption,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.iconColor.withOpacity(0.3),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add,
                                color: AppColors.iconColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.addAnOption,
                                style: const TextStyle(
                                  color: AppColors.iconColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.timeframe,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.colors.border,
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTimeframe,
                          isExpanded: true,
                          icon: Icon(
                            AppConstants.isCupertino
                                ? CupertinoIcons.chevron_down
                                : Icons.expand_more,
                            color: AppColors.iconColor,
                          ),
                          items: _timeframeOptions.map((tf) {
                            return DropdownMenuItem(
                              value: tf,
                              child: Text(
                                tf,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textDark,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedTimeframe = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.pollDisclaimer,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textMuted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.panelBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.itemDivider, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(
              AppConstants.isCupertino ? CupertinoIcons.xmark : Icons.close,
              color: context.colors.textPrimary,
              size: 28,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                l10n.poll,
                style:const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _canAdd ? _submit : null,
            child: Text(
              l10n.add,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _canAdd ? AppColors.iconColor : context.colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
