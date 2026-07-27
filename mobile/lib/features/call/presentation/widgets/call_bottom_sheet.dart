import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/constants.dart';
import 'package:zennyt/l10n/gen/app_localizations.dart';
import '../providers/call_ui_providers.dart';
import 'call_action_button.dart';
import 'call_control_button.dart';

class CallBottomSheet extends ConsumerWidget {
  final DraggableScrollableController controller;
  final bool isRendering;
  final VoidCallback onEndCall;
  final VoidCallback onSwitchCamera;
  final void Function(bool isMuted) onToggleMute;
  final void Function(bool isCameraOff) onToggleCamera;
  final void Function(bool isSpeakerOn) onToggleSpeaker;

  const CallBottomSheet({
    super.key,
    required this.controller,
    required this.isRendering,
    required this.onEndCall,
    required this.onSwitchCamera,
    required this.onToggleMute,
    required this.onToggleCamera,
    required this.onToggleSpeaker,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isMuted = ref.watch(isMutedProvider);
    final isCameraOff = ref.watch(isCameraOffProvider);
    final isSpeakerOn = ref.watch(isSpeakerOnProvider);

    return DraggableScrollableSheet(
      controller: controller,
      initialChildSize: 0.25,
      minChildSize: 0.12,
      maxChildSize: 0.30,
      builder: (context, scrollController) {
        return Container(
          decoration:BoxDecoration(
            color: AppColors.gray700.withValues(alpha: 0.5),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),


              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CallControlButton(
                      icon:Icon(AppConstants.isCupertino ? CupertinoIcons.dial:Icons.av_timer,color: Colors.white,size: 28,)
                      ,
                      label: l10n.effects,
                      onTap: () => ref
                          .read(showVirtualBgPanelProvider.notifier)
                          .state = !ref.read(showVirtualBgPanelProvider),
                    ),
                    CallControlButton(
                      icon: AppConstants.isCupertino
                          ? (isMuted
                              ?const Icon( CupertinoIcons.mic_fill,color: Colors.white,size: 28)
                              :const Icon(CupertinoIcons.mic_slash_fill,color: Colors.white,size: 28))
                          : (isMuted
                              ?const FaIcon(FontAwesomeIcons.microphone,color: Colors.white,size: 28)
                              :const FaIcon(FontAwesomeIcons.microphoneSlash,color: Colors.white,size: 28)),
                      label: l10n.mute,
                      onTap: () => onToggleMute(isMuted),
                    ),
                    if (!isCameraOff && isRendering)
                      CallControlButton(
                        icon: AppConstants.isCupertino
                            ?const Icon( CupertinoIcons.switch_camera_solid,color:Colors.white,size:28)
                            :const FaIcon(FontAwesomeIcons.cameraRotate,color: Colors.white,size: 28),
                        label: l10n.flip,
                        onTap: onSwitchCamera,
                      ),
                    CallControlButton(
                      icon:const FaIcon(FontAwesomeIcons.xmark,color: Colors.white,size: 32),
                      label: l10n.end,
                      backgroundColor: Colors.red,
                      onTap: onEndCall,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),


              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  CallActionButton(
                    icon: AppConstants.isCupertino
                        ? (isCameraOff
                            ? const Icon(CupertinoIcons.video_camera_solid,color: Colors.white,size: 28)
                            : const FaIcon(FontAwesomeIcons.videoSlash,color: Colors.white,size: 22,))
                        : (isCameraOff
                            ? const FaIcon(FontAwesomeIcons.video,color: Colors.white,size: 22,)
                            : const FaIcon(FontAwesomeIcons.videoSlash,color: Colors.white,size: 22,)),
                    label: isCameraOff ? l10n.videoOn : l10n.cameraOff,
                    onTap: () => onToggleCamera(isCameraOff),
                  ),
                  CallActionButton(
                    icon: AppConstants.isCupertino
                        ? (isSpeakerOn
                            ? const Icon(CupertinoIcons.speaker_1_fill,color: Colors.white,size: 28,)
                            : const Icon(CupertinoIcons.speaker_3_fill,color: Colors.white,size: 28,))
                        : (isSpeakerOn
                            ? const FaIcon(FontAwesomeIcons.volumeLow,color: Colors.white,size: 22,)
                            : const FaIcon(FontAwesomeIcons.volumeHigh,color: Colors.white,size: 22,)),
                    label: isSpeakerOn ? l10n.earpiece : l10n.speaker,
                    onTap: () => onToggleSpeaker(isSpeakerOn),
                  ),
                ],
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
            ],
          ),
        );
      },
    );
  }
}
