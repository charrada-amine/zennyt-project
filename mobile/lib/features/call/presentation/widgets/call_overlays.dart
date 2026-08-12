import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';

import '../../../../core/constants.dart';
import '../../../../shared/widgets/important_alert.dart';
import '../providers/call_ui_providers.dart';

class CallInfoButton extends ConsumerWidget {
  const CallInfoButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      right: 16,
      child: GestureDetector(
        onTap: () => ref.read(showAlertProvider.notifier).state = true,
        child: const CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white24,
          child: Icon(Icons.info_outline, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class CallAlertOverlay extends ConsumerWidget {
  const CallAlertOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 16,
      right: 16,
      child: ImportantAlert(
        onClose: () => ref.read(showAlertProvider.notifier).state = false,
      ),
    );
  }
}


class CallVirtualBackgroundPanel extends ConsumerWidget {

  final void Function({
    required VirtualBgType type,
    String? imagePath,
  }) onApplyVirtualBackground;

  const CallVirtualBackgroundPanel({
    super.key,
    required this.onApplyVirtualBackground,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(virtualBackgroundTypeProvider);
    final selectedImageIdx = ref.watch(selectedImageIndexProvider);

    return Positioned(
      bottom: 220,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xEE1E1E24),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BgButton(
                  icon: Icons.block,
                  label: "Aucun",
                  isActive: active == VirtualBgType.none,
                  onTap: () {
                    ref.read(virtualBackgroundTypeProvider.notifier).state =
                        VirtualBgType.none;
                    onApplyVirtualBackground(type: VirtualBgType.none);
                  },
                ),
                _BgButton(
                  icon: Icons.blur_on,
                  label: "Flou",
                  isActive: active == VirtualBgType.blur,
                  onTap: () {
                    ref.read(virtualBackgroundTypeProvider.notifier).state =
                        VirtualBgType.blur;
                    onApplyVirtualBackground(type: VirtualBgType.blur);
                  },
                ),
                _BgButton(
                  icon: Icons.image_outlined,
                  label: "Image",
                  isActive: active == VirtualBgType.image,
                  onTap: () {
                    ref.read(virtualBackgroundTypeProvider.notifier).state =
                        VirtualBgType.image;
                    onApplyVirtualBackground(
                      type: VirtualBgType.image,
                      imagePath: availableBgImages[selectedImageIdx],
                    );
                  },
                ),
              ],
            ),

            // Options secondaires conditionnelles (Images)
            if (active == VirtualBgType.image) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Divider(color: Colors.white24, height: 1),
              ),
              SizedBox(
                height: 54,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: availableBgImages.length,
                  itemBuilder: (context, index) {
                    final isSelected = selectedImageIdx == index;

                    return GestureDetector(
                      onTap: () {
                        ref.read(selectedImageIndexProvider.notifier).state = index;
                        onApplyVirtualBackground(
                          type: VirtualBgType.image,
                          imagePath: availableBgImages[index],
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF818CF8)
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          backgroundImage: AssetImage(availableBgImages[index]),
                          child: !isSelected
                              ? null
                              : const Icon(Icons.check, color: Colors.white, size: 20),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () =>
                  ref.read(showVirtualBgPanelProvider.notifier).state = false,
              child: Text(
                l10n.closeLabel,
                style: const TextStyle(
                  color: Color(0xFF818CF8),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BgButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _BgButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isActive
                  ? Border.all(color: Colors.purpleAccent, width: 2)
                  : null,
            ),
            child: CircleAvatar(
              backgroundColor: context.colors.placeholderBg,
              child: Icon(icon, color: context.colors.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(fontSize: 12, color: context.colors.textMuted)),
        ],
      ),
    );
  }
}
