import 'package:flutter/material.dart';

import 'package:zennyt/shared/widgets/custom_app_bar.dart';
class DescriptionData {
  final String aboutTheJob;
  final String responsibilities;
  final String minimumQualifications;
  final String preferredQualifications;
  final String whatWeOffer;
  final String howToApply;

  const DescriptionData({
    this.aboutTheJob = '',
    this.responsibilities = '',
    this.minimumQualifications = '',
    this.preferredQualifications = '',
    this.whatWeOffer = '',
    this.howToApply = '',
  });
}

class DescriptionPage extends StatefulWidget {
  final DescriptionData initial;
  const DescriptionPage({super.key, required this.initial});

  @override
  State<DescriptionPage> createState() => _DescriptionPageState();
}

class _DescriptionPageState extends State<DescriptionPage> {
  late final TextEditingController _aboutCtrl;
  late final TextEditingController _responsibilitiesCtrl;
  late final TextEditingController _minQualCtrl;
  late final TextEditingController _prefQualCtrl;
  late final TextEditingController _whatWeOfferCtrl;
  late final TextEditingController _howToApplyCtrl;

  @override
  void initState() {
    super.initState();
    _aboutCtrl = TextEditingController(text: widget.initial.aboutTheJob);
    _responsibilitiesCtrl = TextEditingController(text: widget.initial.responsibilities);
    _minQualCtrl = TextEditingController(text: widget.initial.minimumQualifications);
    _prefQualCtrl = TextEditingController(text: widget.initial.preferredQualifications);
    _whatWeOfferCtrl = TextEditingController(text: widget.initial.whatWeOffer);
    _howToApplyCtrl = TextEditingController(text: widget.initial.howToApply);
  }

  @override
  void dispose() {
    for (final c in [
      _aboutCtrl, _responsibilitiesCtrl, _minQualCtrl,
      _prefQualCtrl, _whatWeOfferCtrl, _howToApplyCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(DescriptionData(
      aboutTheJob: _aboutCtrl.text.trim(),
      responsibilities: _responsibilitiesCtrl.text.trim(),
      minimumQualifications: _minQualCtrl.text.trim(),
      preferredQualifications: _prefQualCtrl.text.trim(),
      whatWeOffer: _whatWeOfferCtrl.text.trim(),
      howToApply: _howToApplyCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Description',
        onBack: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DescriptionSection(title: 'About the job', controller: _aboutCtrl),
            const SizedBox(height: 24),
            _DescriptionSection(title: 'Responsibilities', controller: _responsibilitiesCtrl),
            const SizedBox(height: 24),
            _DescriptionSection(title: 'Minimum Qualifications', controller: _minQualCtrl),
            const SizedBox(height: 24),
            _DescriptionSection(title: 'Preferred Qualifications', controller: _prefQualCtrl),
            const SizedBox(height: 24),
            _DescriptionSection(title: 'What we offer', controller: _whatWeOfferCtrl),
            const SizedBox(height: 24),
            _DescriptionSection(title: 'How to apply', controller: _howToApplyCtrl),
            const SizedBox(height: 48),
            Center(
              child: OutlinedButton(
                onPressed: _save,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF21438A), width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, color: Color(0xFF21438A), fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _DescriptionSection extends StatelessWidget {
  final String title;
  final TextEditingController controller;

  const _DescriptionSection({required this.title, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF171725),
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5F7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: Color(0xFF171725)),
            decoration: const InputDecoration(
              hintText: 'Click to add content',
              hintStyle: TextStyle(color: Color(0xFF9292A0)),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}
