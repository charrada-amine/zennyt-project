import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/core/theme/theme.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';
import 'package:zennyt/features/jobs/domain/entities/job_position.dart';
import 'package:zennyt/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:zennyt/shared/icons/app_icons.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';
import 'package:zennyt/shared/widgets/app_spinner.dart';

/// Création / édition d'une offre (`POST /job-offers`, `PUT /job-offers/{id}`).
///
/// Un seul formulaire en sections numérotées, tout en saisie directe (plus de
/// cascade de boîtes de dialogue) : le poste, le contrat, le lieu, le salaire, la
/// description et le test hard skills. Les champs obligatoires sont vérifiés à la
/// frappe après la première tentative d'envoi, et « Post » défile jusqu'à la
/// première erreur au lieu d'un simple snackbar.
class CreateJobOfferPage extends ConsumerStatefulWidget {
  final JobOffer? existingJob;
  const CreateJobOfferPage({super.key, this.existingJob});

  @override
  ConsumerState<CreateJobOfferPage> createState() => _CreateJobOfferPageState();
}

/// Longueur minimale de « About the job » : en dessous, l'offre ne dit rien.
const int kMinAboutJobLength = 40;

class _CreateJobOfferPageState extends ConsumerState<CreateJobOfferPage> {
  final _formKey = GlobalKey<FormState>();

  final _title = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _salaryMin = TextEditingController();
  final _salaryMax = TextEditingController();
  final _about = TextEditingController();
  final _responsibilities = TextEditingController();
  final _minQualifications = TextEditingController();
  final _prefQualifications = TextEditingController();
  final _whatWeOffer = TextEditingController();
  final _howToApply = TextEditingController();

  // Champs sans saisie dans ce formulaire mais conservés en édition.
  String _companyName = '';
  String _fieldOfWork = '';
  String _companyInfo = '';

  ContractType _contractType = ContractType.fullTime;
  WorkplaceType _workplaceType = WorkplaceType.onSite;
  ExperienceLevel _experienceLevel = ExperienceLevel.junior;
  String _salaryCurrency = 'TND';
  SalaryPeriod _salaryPeriod = SalaryPeriod.monthly;
  bool _openToInternational = false;

  /// F06 — sans métier du référentiel, le serveur refuse l'offre (aucune
  /// pondération Fit Score à appliquer). Seul l'id est gardé : libellé et profil
  /// se relisent dans le référentiel.
  String? _jobPositionId;
  bool _positionMissing = false;

  String? _assessmentId;
  String? _assessmentTitle;

  bool _submitted = false;
  bool _loading = false;

  final _positionKey = GlobalKey();

  bool get _isEdit => widget.existingJob != null;

  @override
  void initState() {
    super.initState();
    final job = widget.existingJob;
    if (job != null) {
      _title.text = job.title;
      _city.text = job.city;
      _country.text = job.country;
      if (job.salaryMin > 0) _salaryMin.text = job.salaryMin.toStringAsFixed(0);
      if (job.salaryMax > 0) _salaryMax.text = job.salaryMax.toStringAsFixed(0);
      _about.text = job.description;
      _responsibilities.text = job.responsibilities;
      _minQualifications.text = job.minimumQualifications;
      _prefQualifications.text = job.preferredQualifications;
      _whatWeOffer.text = job.whatWeOffer;
      _howToApply.text = job.howToApply;
      _companyName = job.companyName;
      _fieldOfWork = job.fieldOfWork;
      _companyInfo = job.companyInfo;
      _contractType = job.contractType;
      _workplaceType = job.workplaceType;
      _experienceLevel = job.experienceLevel;
      _salaryCurrency = kSalaryCurrencies.contains(job.salaryCurrency)
          ? job.salaryCurrency
          : 'TND';
      _salaryPeriod = job.salaryPeriod;
      _openToInternational = job.openToInternational;
      _jobPositionId = job.jobPositionId;
      _assessmentId = job.assessmentId;
    }
    for (final c in _controllers) {
      c.addListener(_refresh);
    }
  }

  List<TextEditingController> get _controllers => [
    _title,
    _city,
    _country,
    _salaryMin,
    _salaryMax,
    _about,
    _responsibilities,
    _minQualifications,
    _prefQualifications,
    _whatWeOffer,
    _howToApply,
  ];

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  // ───────────────────────────── validation ─────────────────────────────

  static String? _required(String? v, String what) =>
      (v == null || v.trim().isEmpty) ? '$what is required' : null;

  String? _validateTitle(String? v) {
    final error = _required(v, 'Job title');
    if (error != null) return error;
    if (v!.trim().length < 3) return 'Job title is too short';
    return null;
  }

  double? _amount(TextEditingController c) =>
      c.text.trim().isEmpty ? null : double.tryParse(c.text.trim());

  String? _validateSalaryMax(String? _) {
    final min = _amount(_salaryMin);
    final max = _amount(_salaryMax);
    if (max != null && min == null) return 'Add a minimum first';
    if (min != null && max != null && max < min) return 'Must be ≥ the minimum';
    return null;
  }

  String? _validateAbout(String? v) {
    final error = _required(v, 'A job description');
    if (error != null) return error;
    final left = kMinAboutJobLength - v!.trim().length;
    return left > 0 ? 'Add at least $left more characters' : null;
  }

  /// Sections complètes, pour la barre d'envoi (le salaire et le test sont
  /// optionnels : ils ne bloquent pas).
  int get _completedSections {
    var done = 0;
    if (_validateTitle(_title.text) == null && _jobPositionId != null) done++;
    done++; // contrat & lieu de travail : toujours une valeur par défaut
    if (_city.text.trim().isNotEmpty && _country.text.trim().isNotEmpty) done++;
    if (_validateAbout(_about.text) == null) done++;
    return done;
  }

  static const int _requiredSections = 4;

  // ───────────────────────────── actions ─────────────────────────────

  Future<void> _pickJobPosition() async {
    final positions = await ref.read(jobPositionsProvider.future);
    if (!mounted) return;
    final selected = await showModalBottomSheet<JobPosition>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _JobPositionPicker(positions: positions, selectedId: _jobPositionId),
    );
    if (selected != null) {
      setState(() {
        _jobPositionId = selected.id;
        _positionMissing = false;
      });
    }
  }

  Future<void> _pickAssessment() async {
    final result = await context.pushNamed<Map<String, String>>(
      AppRoutes.nSelectAssessment,
      extra: _assessmentId,
    );
    if (result != null && mounted) {
      setState(() {
        _assessmentId = result['id'];
        _assessmentTitle = result['title'];
      });
    }
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _submitted = true;
      _positionMissing = _jobPositionId == null;
    });
    final formOk = _formKey.currentState!.validate();
    final positionContext = _positionKey.currentContext;
    if (_positionMissing && positionContext != null) {
      await Scrollable.ensureVisible(
        positionContext,
        duration: const Duration(milliseconds: 300),
        alignment: 0.2,
      );
    }
    if (!formOk || _positionMissing) {
      _scrollToFirstError();
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final min = _amount(_salaryMin) ?? 0;
      final max = _amount(_salaryMax) ?? min;
      if (_isEdit) {
        final jobId = widget.existingJob!.id;
        await ref
            .read(jobOffersProvider.notifier)
            .updateJob(
              UpdateJobOfferParams(
                id: jobId,
                title: _title.text.trim(),
                companyName: _companyName,
                city: _city.text.trim(),
                country: _country.text.trim(),
                remote: _workplaceType == WorkplaceType.remote,
                salaryMin: min,
                salaryMax: max,
                salaryCurrency: _salaryCurrency,
                salaryPeriod: _salaryPeriod,
                contractType: _contractType,
                workplaceType: _workplaceType,
                experienceLevel: _experienceLevel,
                fieldOfWork: _fieldOfWork,
                description: _about.text.trim(),
                responsibilities: _responsibilities.text.trim(),
                minimumQualifications: _minQualifications.text.trim(),
                preferredQualifications: _prefQualifications.text.trim(),
                whatWeOffer: _whatWeOffer.text.trim(),
                howToApply: _howToApply.text.trim(),
                companyInfo: _companyInfo,
                assessmentId: _assessmentId,
                jobPositionId: _jobPositionId,
                openToInternational: _openToInternational,
              ),
            );
        ref.invalidate(jobOfferDetailProvider(jobId));
      } else {
        // F23/F24 : l'évaluation n'est pas dans le payload de création (règle
        // serveur) ; elle est rattachée juste après par un PATCH.
        final created = await ref
            .read(jobOffersProvider.notifier)
            .createJob(
              CreateJobOfferParams(
                title: _title.text.trim(),
                companyName: _companyName,
                city: _city.text.trim(),
                country: _country.text.trim(),
                remote: _workplaceType == WorkplaceType.remote,
                salaryMin: min,
                salaryMax: max,
                salaryCurrency: _salaryCurrency,
                salaryPeriod: _salaryPeriod,
                currency: _salaryPeriod.shortSuffix,
                contractType: _contractType,
                workplaceType: _workplaceType,
                experienceLevel: _experienceLevel,
                fieldOfWork: _fieldOfWork,
                description: _about.text.trim(),
                responsibilities: _responsibilities.text.trim(),
                minimumQualifications: _minQualifications.text.trim(),
                preferredQualifications: _prefQualifications.text.trim(),
                whatWeOffer: _whatWeOffer.text.trim(),
                howToApply: _howToApply.text.trim(),
                companyInfo: _companyInfo,
                assessmentId: _assessmentId,
                jobPositionId: _jobPositionId,
                openToInternational: _openToInternational,
              ),
            );
        if (_assessmentId != null) {
          await ref
              .read(jobOffersProvider.notifier)
              .assignAssessment(
                AssignAssessmentParams(
                  jobId: created.id,
                  assessmentId: _assessmentId,
                ),
              );
        }
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Job offer updated' : 'Job offer posted'),
        ),
      );
      context.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Amène le premier champ en erreur à l'écran (le formulaire est long).
  void _scrollToFirstError() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _formKey.currentContext;
      if (ctx == null) return;
      FormFieldState<dynamic>? first;
      void visit(Element e) {
        if (first != null) return;
        if (e is StatefulElement && e.state is FormFieldState) {
          final state = e.state as FormFieldState;
          if (state.hasError) {
            first = state;
            return;
          }
        }
        e.visitChildElements(visit);
      }

      (ctx as Element).visitChildElements(visit);
      final target = first?.context;
      if (target != null && !_positionMissing) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 300),
          alignment: 0.2,
        );
      }
    });
  }

  JobPosition? _selectedPosition() {
    if (_jobPositionId == null) return null;
    final positions = ref.watch(jobPositionsProvider).asData?.value;
    return positions?.where((p) => p.id == _jobPositionId).firstOrNull;
  }

  // ───────────────────────────── UI ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final position = _selectedPosition();

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: CustomAppBar(
        title: _isEdit ? 'Edit job offer' : 'New job offer',
        onBack: () => context.pop(),
      ),
      bottomNavigationBar: _SubmitBar(
        done: _completedSections,
        total: _requiredSections,
        loading: _loading,
        label: _isEdit ? 'Save changes' : 'Post offer',
        onPressed: _submit,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        // Pas de ListView paresseuse : un champ hors écran serait démonté, donc
        // ignoré par la validation du formulaire.
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Section(
                number: 1,
                title: 'The role',
                subtitle: 'What candidates will see first.',
                children: [
                  _TextInput(
                    key: const ValueKey('job-title'),
                    controller: _title,
                    label: 'Job title',
                    hint: 'e.g. Junior Flutter Developer',
                    icon: HugeIcons.strokeRoundedBriefcase01,
                    validator: _validateTitle,
                    maxLength: 150,
                    capitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 14),
                  KeyedSubtree(
                    key: _positionKey,
                    child: _PickerTile(
                      key: const ValueKey('job-position'),
                      label: 'Job family',
                      value: position?.label,
                      placeholder: 'Choose from the job taxonomy',
                      icon: HugeIcons.strokeRoundedHierarchySquare01,
                      error: _positionMissing
                          ? 'Pick a job family: it drives the Fit Score'
                          : null,
                      onTap: _pickJobPosition,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Seniority'),
                  const SizedBox(height: 8),
                  _ChoiceChips<ExperienceLevel>(
                    values: ExperienceLevel.values,
                    selected: _experienceLevel,
                    label: (l) => position?.levelLabel(l) ?? l.label,
                    onSelected: (l) => setState(() => _experienceLevel = l),
                  ),
                  _WeightingPreview(
                    position: position,
                    level: _experienceLevel,
                  ),
                ],
              ),
              _Section(
                number: 2,
                title: 'Contract & workplace',
                children: [
                  const _FieldLabel('Employment type'),
                  const SizedBox(height: 8),
                  _ChoiceChips<ContractType>(
                    values: ContractType.values,
                    selected: _contractType,
                    label: (c) => c.label,
                    onSelected: (c) => setState(() => _contractType = c),
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Workplace'),
                  const SizedBox(height: 8),
                  _ChoiceChips<WorkplaceType>(
                    values: WorkplaceType.values,
                    selected: _workplaceType,
                    label: (w) => w.label,
                    onSelected: (w) => setState(() => _workplaceType = w),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    key: const ValueKey('job-international'),
                    contentPadding: EdgeInsets.zero,
                    value: _openToInternational,
                    onChanged: (v) => setState(() => _openToInternational = v),
                    title: Text(
                      'Open to international candidates',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      'Candidates from other countries can apply',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
              _Section(
                number: 3,
                title: 'Location',
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TextInput(
                          key: const ValueKey('job-city'),
                          controller: _city,
                          label: 'City',
                          hint: 'Tunis',
                          icon: HugeIcons.strokeRoundedLocation01,
                          validator: (v) => _required(v, 'City'),
                          capitalization: TextCapitalization.words,
                          formatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\d')),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TextInput(
                          key: const ValueKey('job-country'),
                          controller: _country,
                          label: 'Country',
                          hint: 'Tunisia',
                          icon: HugeIcons.strokeRoundedGlobe02,
                          validator: (v) => _required(v, 'Country'),
                          capitalization: TextCapitalization.words,
                          formatters: [
                            FilteringTextInputFormatter.deny(RegExp(r'\d')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _Section(
                number: 4,
                title: 'Salary',
                subtitle:
                    'Optional, but offers with a salary get more applications.',
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _TextInput(
                          key: const ValueKey('job-salary-min'),
                          controller: _salaryMin,
                          label: 'Minimum',
                          hint: '1800',
                          keyboardType: TextInputType.number,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
                          prefix: salaryCurrencySymbol(_salaryCurrency),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TextInput(
                          key: const ValueKey('job-salary-max'),
                          controller: _salaryMax,
                          label: 'Maximum',
                          hint: '2600',
                          keyboardType: TextInputType.number,
                          formatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(8),
                          ],
                          prefix: salaryCurrencySymbol(_salaryCurrency),
                          validator: _validateSalaryMax,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceChips<String>(
                          values: kSalaryCurrencies,
                          selected: _salaryCurrency,
                          label: (c) => c,
                          onSelected: (c) =>
                              setState(() => _salaryCurrency = c),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _ChoiceChips<SalaryPeriod>(
                    values: SalaryPeriod.values,
                    selected: _salaryPeriod,
                    label: (p) => p.label,
                    onSelected: (p) => setState(() => _salaryPeriod = p),
                  ),
                ],
              ),
              _Section(
                number: 5,
                title: 'Description',
                children: [
                  _TextInput(
                    key: const ValueKey('job-about'),
                    controller: _about,
                    label: 'About the job',
                    hint:
                        'The team, the mission, what makes this role interesting…',
                    validator: _validateAbout,
                    minLines: 4,
                    maxLines: 10,
                    maxLength: 3000,
                    capitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  _TextInput(
                    controller: _responsibilities,
                    label: 'Responsibilities',
                    hint: 'One per line',
                    minLines: 3,
                    maxLines: 8,
                    maxLength: 2000,
                    capitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  _TextInput(
                    controller: _minQualifications,
                    label: 'Minimum qualifications',
                    minLines: 2,
                    maxLines: 6,
                    maxLength: 1500,
                    capitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  _TextInput(
                    controller: _prefQualifications,
                    label: 'Preferred qualifications',
                    minLines: 2,
                    maxLines: 6,
                    maxLength: 1500,
                    capitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  _TextInput(
                    controller: _whatWeOffer,
                    label: 'What we offer',
                    minLines: 2,
                    maxLines: 6,
                    maxLength: 1500,
                    capitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  _TextInput(
                    controller: _howToApply,
                    label: 'How to apply',
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 800,
                    capitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
              _Section(
                number: 6,
                title: 'Hard-skills test',
                subtitle:
                    'Optional. Candidates take it once, from the offer page.',
                children: [
                  _PickerTile(
                    key: const ValueKey('job-assessment'),
                    label: 'Test',
                    value:
                        _assessmentTitle ??
                        (_assessmentId != null ? 'Test attached' : null),
                    placeholder: 'No test: choose or create one',
                    icon: HugeIcons.strokeRoundedQuiz01,
                    onTap: _pickAssessment,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────── building blocks ─────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.number,
    required this.title,
    required this.children,
    this.subtitle,
  });

  final int number;
  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Material (et non un Container coloré) : les ListTile/Switch de la section
    // y dessinent leur fond et leurs ondulations.
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: colors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$number',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.titleMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: context.colors.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.validator,
    this.keyboardType,
    this.formatters,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.prefix,
    this.capitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final AppIconData? icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? formatters;
  final int? minLines;
  final int maxLines;
  final int? maxLength;
  final String? prefix;
  final TextCapitalization capitalization;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: colors.border),
    );
    final multiline = maxLines > 1;
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType:
          keyboardType ??
          (multiline ? TextInputType.multiline : TextInputType.text),
      inputFormatters: formatters,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: capitalization,
      textInputAction: multiline
          ? TextInputAction.newline
          : TextInputAction.next,
      style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: multiline,
        errorMaxLines: 2,
        // Le compteur n'apparaît qu'en approchant de la limite.
        counterText:
            maxLength != null && controller.text.length > maxLength! * 0.8
            ? null
            : '',
        filled: true,
        fillColor: colors.inputFill,
        prefixText: prefix == null ? null : '$prefix ',
        prefixIcon: icon == null
            ? null
            : Padding(
                padding: const EdgeInsets.all(12),
                child: AppIcon(icon, color: colors.textSecondary, size: 20),
              ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 44,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: colors.primary, width: 1.6),
        ),
        errorBorder: border.copyWith(
          borderSide: BorderSide(color: colors.error),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    super.key,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
    this.error,
  });

  final String label;
  final String? value;
  final String placeholder;
  final AppIconData icon;
  final VoidCallback onTap;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasValue = value != null && value!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: colors.inputFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: error != null ? colors.error : colors.border,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Row(
                children: [
                  AppIcon(icon, color: colors.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hasValue ? value! : placeholder,
                          style: TextStyle(
                            color: hasValue
                                ? colors.textPrimary
                                : colors.textSecondary,
                            fontWeight: hasValue
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppIcon(
                    HugeIcons.strokeRoundedArrowRight01,
                    color: colors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text(
              error!,
              style: TextStyle(color: colors.error, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _ChoiceChips<T> extends StatelessWidget {
  const _ChoiceChips({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in values)
          ChoiceChip(
            label: Text(label(value)),
            selected: value == selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(value),
            labelStyle: TextStyle(
              color: value == selected ? Colors.white : colors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            selectedColor: colors.primary,
            backgroundColor: colors.inputFill,
            side: BorderSide(
              color: value == selected ? colors.primary : colors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

/// F30 — ce que le choix du métier et du niveau implique pour le Fit Score.
/// Lecture seule : rien à ajuster ici, seulement rendre visible la pondération.
class _WeightingPreview extends ConsumerWidget {
  const _WeightingPreview({required this.position, required this.level});

  final JobPosition? position;
  final ExperienceLevel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileType = position?.profileType;
    if (profileType == null) return const SizedBox.shrink();
    final colors = context.colors;
    final profile = ref
        .watch(jobRoleProfilesProvider)
        .asData
        ?.value
        .where((p) => p.profileType == profileType && p.level == level)
        .firstOrNull;
    if (profile == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                HugeIcons.strokeRoundedAnalytics01,
                color: colors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'How the Fit Score weighs this role',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Row(
              children: [
                Expanded(
                  flex: profile.softWeight.clamp(1, 100),
                  child: Container(height: 8, color: colors.primary),
                ),
                Expanded(
                  flex: profile.hardWeight.clamp(1, 100),
                  child: Container(height: 8, color: const Color(0xFFD12E7D)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Soft skills ${profile.softWeight}%',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                'Hard skills ${profile.hardWeight}%',
                style: const TextStyle(
                  color: Color(0xFFD12E7D),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (!profile.calibrated) ...[
            const SizedBox(height: 8),
            Text(
              'Provisional weights, not yet validated with HR.',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Métier du référentiel : recherche plein texte (nom ou secteur).
class _JobPositionPicker extends StatefulWidget {
  const _JobPositionPicker({required this.positions, required this.selectedId});

  final List<JobPosition> positions;
  final String? selectedId;

  @override
  State<_JobPositionPicker> createState() => _JobPositionPickerState();
}

class _JobPositionPickerState extends State<_JobPositionPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final q = _query.trim().toLowerCase();
    final list = widget.positions
        .where(
          (p) =>
              q.isEmpty ||
              p.name.toLowerCase().contains(q) ||
              (p.sector ?? '').toLowerCase().contains(q),
        )
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scroll) => Material(
        color: colors.cardSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: TextField(
                key: const ValueKey('job-position-search'),
                autofocus: true,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search a job family (e.g. Développeur, Data)',
                  filled: true,
                  fillColor: colors.inputFill,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: AppIcon(
                      HugeIcons.strokeRoundedSearch01,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        'No job family matches “$_query”',
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      controller: scroll,
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final p = list[i];
                        final selected = p.id == widget.selectedId;
                        return ListTile(
                          title: Text(
                            p.name,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            p.sector ?? 'Cross-sector',
                            style: TextStyle(
                              color: colors.textSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                          trailing: selected
                              ? AppIcon(
                                  HugeIcons.strokeRoundedCheckmarkCircle02,
                                  color: colors.primary,
                                  size: 20,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.done,
    required this.total,
    required this.loading,
    required this.label,
    required this.onPressed,
  });

  final int done;
  final int total;
  final bool loading;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.cardSurface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$done of $total required sections',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: done / total,
                        minHeight: 6,
                        backgroundColor: colors.inputFill,
                        color: done == total ? colors.success : colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              FilledButton(
                key: const ValueKey('job-submit'),
                onPressed: loading ? null : onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  minimumSize: const Size(140, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: AppSpinner(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
