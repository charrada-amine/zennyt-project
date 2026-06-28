import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/utils/responsive.dart';
import '../viewmodel/candidate_profile_viewmodel.dart';

class SharePostScreen extends ConsumerStatefulWidget {
  const SharePostScreen({super.key});

  @override
  ConsumerState<SharePostScreen> createState() => _SharePostScreenState();
}

class _SharePostScreenState extends ConsumerState<SharePostScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late AnimationController _menuController;
  late Animation<double> _rotationAnim;
  late Animation<double> _scaleAnim;

  bool _isMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _rotationAnim = Tween<double>(begin: 0, end: 0.125).animate(
      CurvedAnimation(parent: _menuController, curve: Curves.easeOut),
    );

    _scaleAnim = CurvedAnimation(parent: _menuController, curve: Curves.easeOutBack);

    _textController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _menuController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
      if (_isMenuOpen) {
        _menuController.forward();
      } else {
        _menuController.reverse();
      }
    });
  }

  void _submitPost() {
    final title = _textController.text.trim();
    if (title.isEmpty) return;

    final newItem = PortfolioItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      imagePath: 'assets/images/exemple_post.png',
    );

    ref.read(candidateProfileProvider.notifier).addPortfolioItem(newItem);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canPost = _textController.text.trim().isNotEmpty;
    final hPadding = Responsive.horizontalPadding(context);

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: AppSpacing.lg),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(Icons.close, size: 28, color: colors.textPrimary),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Avatar
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.border),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/exemple_post.png'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Privacy Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: colors.scaffoldBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.public, size: 14, color: colors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Public',
                              style: AppTypography.bodySmall.copyWith(
                                color: colors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, size: 16, color: colors.textSecondary),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Post Button
                      ElevatedButton(
                        onPressed: canPost ? _submitPost : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canPost ? colors.primary : colors.dividerThick,
                          foregroundColor: canPost ? Colors.white : colors.textSecondary,
                          elevation: 0,
                          minimumSize: const Size(80, 40), // Override infinite width from theme
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(
                          'Post',
                          style: AppTypography.labelLarge.copyWith(
                            color: canPost ? Colors.white : colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Divider(height: 1, color: colors.border),

                // Text Area
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: AppSpacing.lg),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      autofocus: true,
                      style: AppTypography.bodyLarge.copyWith(
                        color: colors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'New Project',
                        hintStyle: AppTypography.bodyLarge.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Animated Attachment Menu Options
            if (_isMenuOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  onTap: _toggleMenu,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                left: hPadding,
                bottom: 80, // Positioned above the '+' button
                child: ScaleTransition(
                  scale: _scaleAnim,
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildAttachmentOption(
                        colors: colors,
                        icon: Icons.image_outlined,
                        label: 'Media',
                        onTap: () {
                          _toggleMenu();
                          // Placeholder logic for selecting media
                        },
                      ),
                      const SizedBox(width: AppSpacing.xl),
                      _buildAttachmentOption(
                        colors: colors,
                        icon: Icons.description_outlined,
                        label: 'Document',
                        onTap: () {
                          _toggleMenu();
                          // Placeholder logic for selecting document
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // '+' Button Toolbar
            Positioned(
              left: hPadding,
              bottom: 20,
              child: RotationTransition(
                turns: _rotationAnim,
                child: IconButton(
                  onPressed: _toggleMenu,
                  icon: Icon(Icons.add, size: 32, color: colors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required AppColorScheme colors,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.scaffoldBg,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.shadowColor.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: colors.primary),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
