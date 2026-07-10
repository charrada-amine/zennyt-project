import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../shared/widgets/zennyt_loader.dart';
import '../providers/cv_autofill_providers.dart';

class CvProcessingScreen extends ConsumerStatefulWidget {
  final String? filePath;
  final String? imagePaths; // Comma-separated if multiple
  final String? url;

  const CvProcessingScreen({super.key, this.filePath, this.imagePaths, this.url});

  @override
  ConsumerState<CvProcessingScreen> createState() => _CvProcessingScreenState();
}

class _CvProcessingScreenState extends ConsumerState<CvProcessingScreen> {
  double _progress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _startProgressTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProcessing();
    });
  }

  void _startProgressTimer() {
    // Fake progress: increment by 1% every 400ms, capping at 95%
    // This allows it to stretch over ~38 seconds naturally.
    _progressTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (mounted && _progress < 0.95) {
        setState(() {
          _progress += 0.01;
        });
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _startProcessing() async {
    // Assuming English for now, ideally would get from current locale
    const languageCode = 'en'; 

    final viewModel = ref.read(cvAutofillViewModelProvider.notifier);
    
    if (widget.url != null) {
      await viewModel.processRemoteFile(widget.url!, languageCode);
    } else if (widget.filePath != null) {
      await viewModel.processLocalFile(widget.filePath!, languageCode);
    } else if (widget.imagePaths != null) {
      final paths = widget.imagePaths!.split(',').where((p) => p.isNotEmpty).toList();
      await viewModel.processCameraImages(paths, languageCode);
    }

    _progressTimer?.cancel();
    if (mounted) {
      setState(() {
        _progress = 1.0;
      });
    }
    
    await Future.delayed(const Duration(milliseconds: 400));

    if (mounted) {
      final state = ref.read(cvAutofillViewModelProvider);
      if (state.error != null) {
        // Show error and pop
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${state.error}')),
        );
        context.pop();
      } else if (state.data != null) {
        if (state.data!.isValidCv == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('The provided document does not appear to be a valid CV.')),
          );
          context.pop();
        } else {
          // Navigate to review screen
          context.pushReplacement(AppRoutes.cvReview);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ZennytLoader(size: 80),
            const SizedBox(height: 48),
            Text(
              'Analyzing your CV...',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Extracting skills, experience, and education.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              '${(_progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
