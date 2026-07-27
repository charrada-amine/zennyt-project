import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lottie/lottie.dart';
import '../providers/internet_provider.dart';
import '../../features/home/presentation/providers/home_providers.dart';

final showNoInternetOverlayProvider = StateProvider<bool>((ref) => false);

class NoConnectionOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const NoConnectionOverlay({required this.child, super.key});

  @override
  ConsumerState<NoConnectionOverlay> createState() => _NoConnectionOverlayState();
}

class _NoConnectionOverlayState extends ConsumerState<NoConnectionOverlay> {
  void _reloadData() {
    final isNowConnected = ref.read(internetProvider);
    if (isNowConnected) {
      ref.read(showNoInternetOverlayProvider.notifier).state = false;
      ref.invalidate(postsProvider);
      ref.invalidate(currentUserProvider);
      ref.invalidate(userPostPreferencesProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(keepAliveSyncProvider);

    final showOverlay = ref.watch(showNoInternetOverlayProvider);

    ref.listen<bool>(internetProvider, (previous, next) {
      final wasConnected = previous ?? true;

      if (!wasConnected && next) {
        ref.read(showNoInternetOverlayProvider.notifier).state = false;
        _reloadData();
      }
    });

    return Stack(
      children: [
        widget.child,
        if (showOverlay)
          Positioned.fill(
            child: Material(
              color: const Color(0x5D000000),
              child: SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white70,
                          size: 28,
                        ),
                        onPressed: () {
                          ref.read(showNoInternetOverlayProvider.notifier).state = false;
                        },
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 180,
                              height: 180,
                              child: Lottie.asset('assets/connectivity/no_internet.json'),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Aucune connexion Internet',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Veuillez vérifier votre connexion.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white70),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
