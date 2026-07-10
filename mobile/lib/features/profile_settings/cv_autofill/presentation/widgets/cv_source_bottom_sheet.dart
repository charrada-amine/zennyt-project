import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_selector/file_selector.dart';
import '../../../../../core/router/app_routes.dart';

class CvSourceBottomSheet extends ConsumerWidget {
  final String? cvUrl;
  
  const CvSourceBottomSheet({super.key, this.cvUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Auto Fill Profile',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Select how you want to provide your CV to automatically extract and fill your profile.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
          ),
          const SizedBox(height: 24),
          if (cvUrl == null || cvUrl!.isEmpty)
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Upload Document'),
              subtitle: const Text('PDF, PNG, JPG (Max 5MB)'),
              onTap: () => _pickFile(context),
            ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Scan with Camera'),
            subtitle: const Text('Take photos of your CV pages'),
            onTap: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.cvCameraCapture);
            },
          ),
          if (cvUrl != null && cvUrl!.isNotEmpty) ...[
            ListTile(
              leading: const Icon(Icons.cloud_done_outlined, color: Colors.blue),
              title: const Text('Use Saved CV'),
              subtitle: const Text('Process the CV currently on your profile'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('${AppRoutes.cvProcessing}?url=${Uri.encodeComponent(cvUrl!)}');
              },
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      const XTypeGroup pdfGroup = XTypeGroup(
        label: 'Documents',
        extensions: <String>['pdf', 'png', 'jpg', 'jpeg', 'webp'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[pdfGroup]);

      if (file != null && context.mounted) {
        Navigator.of(context).pop();
        context.push('${AppRoutes.cvProcessing}?filePath=${file.path}');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }
}
