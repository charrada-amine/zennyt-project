import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/api_exception.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../viewmodel/candidate_profile_viewmodel.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late TextEditingController _positionController;
  late TextEditingController _lookingForController;

  String _workplaceType = 'Flexible';
  String _jobType = 'Full time';
  String _targetLocation = 'New York, USA';
  bool _openToWorkInternationally = true;
  String _availableDate = 'Immediately';
  bool _saving = false;

  final List<String> _workplaceOptions = [
    'On-site',
    'Remote',
    'Hybrid',
    'Flexible',
  ];

  final List<String> _jobTypeOptions = [
    'Full time',
    'Part time',
    'Contract',
    'Freelance',
    'Internship',
  ];

  final List<String> _locationOptions = [
    'New York, USA',
    'San Francisco, USA',
    'London, UK',
    'Berlin, Germany',
    'Paris, France',
    'Toronto, Canada',
    'Sydney, Australia',
    'Tokyo, Japan',
    'California, USA',
    'Remote',
  ];

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    final state = ref.read(candidateProfileProvider);
    _positionController = TextEditingController(text: state.role);
    _lookingForController = TextEditingController(text: state.lookingFor.jobPosition);
    _workplaceType = state.lookingFor.workplaceType;
    _jobType = state.lookingFor.jobType;
    _targetLocation = state.lookingFor.targetLocation;
    _openToWorkInternationally = state.openToWorkInternationally;
    _availableDate = state.availableDate;

    // Normalize workplace type casing
    if (!_workplaceOptions.contains(_workplaceType)) {
      for (final opt in _workplaceOptions) {
        if (opt.toLowerCase() == _workplaceType.toLowerCase()) {
          _workplaceType = opt;
          break;
        }
      }
    }

    // Normalize target location casing
    if (!_locationOptions.contains(_targetLocation)) {
      for (final opt in _locationOptions) {
        if (opt.toLowerCase() == _targetLocation.toLowerCase()) {
          _targetLocation = opt;
          break;
        }
      }
    }

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _positionController.dispose();
    _lookingForController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    try {
      await ref.read(candidateProfileProvider.notifier).saveLookingFor(
            role: _positionController.text.trim(),
            lookingFor: LookingFor(
              jobPosition: _lookingForController.text.trim(),
              workplaceType: _workplaceType,
              jobType: _jobType,
              targetLocation: _targetLocation,
            ),
            openToWorkInternationally: _openToWorkInternationally,
            availableDate: _availableDate,
          );
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: context.colors.error,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final colors = context.colors;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: colors.primary,
              onPrimary: Colors.white,
              surface: colors.scaffoldBg,
              onSurface: colors.textPrimary,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _availableDate = DateFormat('MMM d, yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Column(
              children: [
                // ── Top Bar ──
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPadding,
                    vertical: AppSpacing.lg,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.backButtonBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.backButtonBorder, width: 1),
                        ),
                        child: IconButton(
                          onPressed: () => context.pop(),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: colors.backButtonIcon,
                            size: 20,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Edit profile',
                        style: AppTypography.titleLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // ── Form Content ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: hPadding),
                    child: Column(
                      children: [
                        const SizedBox(height: AppSpacing.md),

                        // Position
                        _AnimatedField(
                          delay: 0,
                          child: _buildTextInput(
                            colors: colors,
                            label: 'Position',
                            controller: _positionController,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Looking for
                        _AnimatedField(
                          delay: 1,
                          child: _buildTextInput(
                            colors: colors,
                            label: 'Looking for',
                            controller: _lookingForController,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Type of workplace
                        _AnimatedField(
                          delay: 2,
                          child: _buildDropdownField(
                            colors: colors,
                            label: 'Type of workplace',
                            value: _workplaceType,
                            options: _workplaceOptions,
                            onChanged: (v) => setState(() => _workplaceType = v!),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Type of job
                        _AnimatedField(
                          delay: 3,
                          child: _buildDropdownField(
                            colors: colors,
                            label: 'Type of job',
                            value: _jobType,
                            options: _jobTypeOptions,
                            onChanged: (v) => setState(() => _jobType = v!),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Target job location
                        _AnimatedField(
                          delay: 4,
                          child: _buildDropdownField(
                            colors: colors,
                            label: 'Target job location',
                            value: _targetLocation,
                            options: _locationOptions,
                            onChanged: (v) => setState(() => _targetLocation = v!),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Open to work internationally
                        _AnimatedField(
                          delay: 5,
                          child: _buildToggleField(colors),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Available
                        _AnimatedField(
                          delay: 6,
                          child: _buildAvailableField(colors),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // Submit button
                        _AnimatedField(
                          delay: 7,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                            child: PrimaryButton(
                              label: 'Submit',
                              loading: _saving,
                              onPressed: _submit,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextInput({
    required AppColorScheme colors,
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
              fontSize: 11,
            ),
          ),
          TextField(
            controller: controller,
            style: AppTypography.bodyMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required AppColorScheme colors,
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: colors.textSecondary,
              fontSize: 11,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : options.first,
              isExpanded: true,
              isDense: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.primary,
                size: 22,
              ),
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              dropdownColor: colors.scaffoldBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              items: options.map((opt) {
                return DropdownMenuItem(
                  value: opt,
                  child: Text(opt),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleField(AppColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.border.withValues(alpha: 0.6)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Open to work internationally',
              style: AppTypography.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            height: 28,
            child: Switch.adaptive(
              value: _openToWorkInternationally,
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return null;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.success;
                }
                return colors.border;
              }),
              onChanged: (v) => setState(() => _openToWorkInternationally = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableField(AppColorScheme colors) {
    return InkWell(
      onTap: () {
        _showAvailabilityPicker(colors);
      },
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: colors.scaffoldBg,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: colors.border.withValues(alpha: 0.6)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available',
                    style: AppTypography.bodySmall.copyWith(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _availableDate,
                    style: AppTypography.bodyMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  void _showAvailabilityPicker(AppColorScheme colors) {
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.scaffoldBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'When are you available?',
                  style: AppTypography.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Immediately option
                _AvailabilityOption(
                  label: 'Immediately',
                  isSelected: _availableDate == 'Immediately',
                  colors: colors,
                  onTap: () {
                    setState(() => _availableDate = 'Immediately');
                    Navigator.pop(ctx);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),

                // Pick a date option
                _AvailabilityOption(
                  label: 'Select a specific date',
                  isSelected: _availableDate != 'Immediately',
                  colors: colors,
                  icon: Icons.calendar_month_outlined,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickDate();
                  },
                ),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Staggered animation helper ──

class _AnimatedField extends StatefulWidget {
  const _AnimatedField({required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  State<_AnimatedField> createState() => _AnimatedFieldState();
}

class _AnimatedFieldState extends State<_AnimatedField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 80 * widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

// ── Availability option tile ──

class _AvailabilityOption extends StatelessWidget {
  const _AvailabilityOption({
    required this.label,
    required this.isSelected,
    required this.colors,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final AppColorScheme colors;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? colors.primary.withValues(alpha: 0.08)
          : colors.inputFill,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border.withValues(alpha: 0.4),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: colors.primary, size: 20),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? colors.primary : colors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
