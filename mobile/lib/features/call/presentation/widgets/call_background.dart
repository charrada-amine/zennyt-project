import 'package:flutter/material.dart';
import 'package:zennyt/core/theme/app_colors.dart';

class CallBackground extends StatelessWidget {
  final String contactName;
  final bool remoteHasVideo;

  const CallBackground({
    super.key,
    required this.contactName,
    required this.remoteHasVideo,
  });



  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.transparent,

        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.gray200,
                child: Text(
                  contactName
                      .split(' ')
                      .map((p) => p.isNotEmpty ? p[0] : '')
                      .take(2)
                      .join(),
                  style: const TextStyle(
                    color: AppColors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 32,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(contactName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                remoteHasVideo ? 'Video Call' : 'Audio Call',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
