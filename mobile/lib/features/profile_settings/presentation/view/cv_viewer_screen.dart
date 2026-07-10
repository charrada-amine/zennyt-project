import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';

/// Full-screen in-app PDF viewer with download option.
///
/// Uses `pdfrx` to render the PDF from a network URL directly inside the app.
class CvViewerScreen extends StatefulWidget {
  const CvViewerScreen({super.key, required this.cvUrl});

  final String cvUrl;

  @override
  State<CvViewerScreen> createState() => _CvViewerScreenState();
}

class _CvViewerScreenState extends State<CvViewerScreen> {
  final PdfViewerController _controller = PdfViewerController();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorScheme>()!;

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: colors.cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_rounded, color: colors.textPrimary),
        ),
        title: Text(
          'My CV',
          style: AppTypography.bodyLarge.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          // Download / Open externally
          IconButton(
            onPressed: () async {
              try {
                final url = Uri.parse(widget.cvUrl);
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Could not download CV'),
                      backgroundColor: colors.error,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
              }
            },
            icon: Icon(
              Icons.download_rounded,
              color: colors.primary,
            ),
            tooltip: 'Download CV',
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: colors.divider,
          ),
        ),
      ),
      body: Stack(
        children: [
          // PDF viewer
          PdfViewer.uri(
            Uri.parse(widget.cvUrl),
            controller: _controller,
            params: PdfViewerParams(
              loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: colors.primary,
                          value: totalBytes != null && totalBytes > 0
                              ? bytesDownloaded / totalBytes
                              : null,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Loading CV...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      if (totalBytes != null && totalBytes > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${(bytesDownloaded / 1024).toStringAsFixed(0)} / ${(totalBytes / 1024).toStringAsFixed(0)} KB',
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              errorBannerBuilder: (context, error, stackTrace, documentRef) {
                // Error callback
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: colors.error.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.picture_as_pdf_rounded,
                            color: colors.error,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Unable to Preview',
                          style: AppTypography.bodyLarge.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'This file could not be rendered in-app.\nTry downloading it instead.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final url = Uri.parse(widget.cvUrl);
                              await launchUrl(
                                url,
                                mode: LaunchMode.externalApplication,
                              );
                            } catch (_) {}
                          },
                          icon: const Icon(Icons.download_rounded, size: 20),
                          label: const Text('Download CV'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
