import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:zennyt/core/error/api_exception.dart';
import 'package:zennyt/core/router/app_routes.dart';
import 'package:zennyt/shared/widgets/custom_app_bar.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';
import 'package:zennyt/features/jobs/domain/entities/job_position.dart';
import 'package:zennyt/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:zennyt/features/jobs/presentation/providers/jobs_provider.dart';
import 'package:zennyt/features/jobs/presentation/widgets/employment_type_bottom_sheet.dart';
import 'package:zennyt/features/jobs/presentation/widgets/job_form_field.dart';
import 'description_page.dart';
import 'widgets/job_inline_edit_dialog.dart';
import 'widgets/job_international_checkbox.dart';
import 'widgets/job_location_dialog.dart';
import 'widgets/job_salary_dialog.dart';
import 'widgets/job_submit_button.dart';
import 'widgets/job_workplace_dialog.dart';

/// Assistant de création/édition d'offre — porté depuis REC-04
/// (mobile/zennyt), branché sur le backend intégré (`POST /job-offers`).
class CreateJobOfferPage extends ConsumerStatefulWidget {
  final JobOffer? existingJob;
  const CreateJobOfferPage({super.key, this.existingJob});

  @override
  ConsumerState<CreateJobOfferPage> createState() => _CreateJobOfferPageState();
}

class _CreateJobOfferPageState extends ConsumerState<CreateJobOfferPage> {
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _salaryMinCtrl = TextEditingController();
  final _salaryMaxCtrl = TextEditingController();
  final _fieldCtrl = TextEditingController();
  final _companyInfoCtrl = TextEditingController();

  String _descAboutJob = '';
  String _descResponsibilities = '';
  String _descMinQual = '';
  String _descPrefQual = '';
  String _descWhatWeOffer = '';
  String _descHowToApply = '';

  ContractType _contractType = ContractType.fullTime;
  WorkplaceType _workplaceType = WorkplaceType.onSite;
  ExperienceLevel _experienceLevel = ExperienceLevel.junior;

  bool _remote = false;
  bool _openToInternational = false;
  bool _isLoading = false;
  bool _contractTypeChosen = false;
  bool _workplaceTypeChosen = false;

  String? _selectedAssessmentId;
  String? _selectedAssessmentTitle;

  /// F06 — sans métier, le serveur refuse la création : la formule Fit Score n'a
  /// aucune pondération à appliquer. Le champ était câblé mais aucun écran ne le
  /// renseignait, donc toute création échouait.
  /// Seul l'id est conservé : le libellé et le profil métier se relisent dans le
  /// référentiel. En reprise d'édition, le serveur ne renvoie que l'id — dupliquer
  /// l'état obligerait à gérer un cas « id connu, libellé inconnu ».
  String? _selectedJobPositionId;

  bool get _isEditMode => widget.existingJob != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_onTitleChanged);
    final job = widget.existingJob;
    if (job != null) {
      _titleCtrl.text = job.title;
      _companyCtrl.text = job.companyName;
      _cityCtrl.text = job.city;
      _countryCtrl.text = job.country;
      _salaryMinCtrl.text = job.salaryMin.toStringAsFixed(0);
      _salaryMaxCtrl.text = job.salaryMax.toStringAsFixed(0);
      _fieldCtrl.text = job.fieldOfWork;
      _companyInfoCtrl.text = job.companyInfo;
      _contractType = job.contractType;
      _workplaceType = job.workplaceType;
      _experienceLevel = job.experienceLevel;
      _selectedJobPositionId = job.jobPositionId;
      _remote = job.remote;
      _openToInternational = job.openToInternational;
      _selectedAssessmentId = job.assessmentId;
      _descAboutJob = job.description;
      _descResponsibilities = job.responsibilities;
      _descMinQual = job.minimumQualifications;
      _descPrefQual = job.preferredQualifications;
      _descWhatWeOffer = job.whatWeOffer;
      _descHowToApply = job.howToApply;
      _contractTypeChosen = true;
      _workplaceTypeChosen = true;
    }
  }

  void _onTitleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onTitleChanged);
    for (final c in [
      _titleCtrl, _companyCtrl, _cityCtrl, _countryCtrl,
      _salaryMinCtrl, _salaryMaxCtrl, _fieldCtrl, _companyInfoCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _locationDisplay {
    final city = _cityCtrl.text.trim();
    final country = _countryCtrl.text.trim();
    if (city.isNotEmpty && country.isNotEmpty) return '$city, $country';
    if (city.isNotEmpty) return city;
    if (country.isNotEmpty) return country;
    return '';
  }

  String _getSalaryDisplay() {
    final min = _salaryMinCtrl.text.trim();
    final max = _salaryMaxCtrl.text.trim();
    if (min.isNotEmpty && max.isNotEmpty) return '\$$min – \$$max /Mo';
    if (min.isNotEmpty) return '\$$min /Mo';
    return '';
  }

  bool get _hasDescription => _descAboutJob.isNotEmpty || _descResponsibilities.isNotEmpty;

  Future<void> _openEmploymentTypeSheet() async {
    final result = await EmploymentTypeBottomSheet.show(context, selected: _contractType);
    if (result != null && mounted) {
      setState(() {
        _contractType = result;
        _contractTypeChosen = true;
      });
    }
  }

  Future<void> _openWorkplaceDialog() async {
    final result = await showJobWorkplaceDialog(context);
    if (result != null && mounted) {
      setState(() {
        _workplaceType = result;
        _workplaceTypeChosen = true;
      });
    }
  }

  Future<void> _openLocationDialog() async {
    await showJobLocationDialog(
      context,
      cityCtrl: _cityCtrl,
      countryCtrl: _countryCtrl,
      onSaved: () => setState(() {}),
    );
  }

  Future<void> _openSalaryDialog() async {
    await showJobSalaryDialog(
      context,
      minCtrl: _salaryMinCtrl,
      maxCtrl: _salaryMaxCtrl,
      onSaved: () => setState(() {}),
    );
  }

  Future<void> _openDescriptionPage() async {
    final result = await Navigator.of(context).push<DescriptionData>(
      MaterialPageRoute(
        builder: (_) => DescriptionPage(
          initial: DescriptionData(
            aboutTheJob: _descAboutJob,
            responsibilities: _descResponsibilities,
            minimumQualifications: _descMinQual,
            preferredQualifications: _descPrefQual,
            whatWeOffer: _descWhatWeOffer,
            howToApply: _descHowToApply,
          ),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _descAboutJob = result.aboutTheJob;
        _descResponsibilities = result.responsibilities;
        _descMinQual = result.minimumQualifications;
        _descPrefQual = result.preferredQualifications;
        _descWhatWeOffer = result.whatWeOffer;
        _descHowToApply = result.howToApply;
      });
    }
  }

  Future<void> _openAssessmentPage() async {
    final result = await context.pushNamed<Map<String, String>>(
      AppRoutes.nSelectAssessment,
      extra: _selectedAssessmentId,
    );
    if (result != null && mounted) {
      setState(() {
        _selectedAssessmentId = result['id'];
        _selectedAssessmentTitle = result['title'];
      });
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job position is required')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (_isEditMode) {
        final jobId = widget.existingJob!.id;
        await ref.read(jobOffersProvider.notifier).updateJob(
              UpdateJobOfferParams(
                id: jobId,
                title: _titleCtrl.text.trim(),
                companyName: _companyCtrl.text.trim(),
                city: _cityCtrl.text.trim(),
                country: _countryCtrl.text.trim(),
                remote: _remote,
                salaryMin: double.tryParse(_salaryMinCtrl.text) ?? 0,
                salaryMax: double.tryParse(_salaryMaxCtrl.text) ?? 0,
                contractType: _contractType,
                workplaceType: _workplaceType,
                experienceLevel: _experienceLevel,
                fieldOfWork: _fieldCtrl.text.trim(),
                description: _descAboutJob,
                responsibilities: _descResponsibilities,
                minimumQualifications: _descMinQual,
                preferredQualifications: _descPrefQual,
                whatWeOffer: _descWhatWeOffer,
                howToApply: _descHowToApply,
                companyInfo: _companyInfoCtrl.text.trim(),
                assessmentId: _selectedAssessmentId,
                openToInternational: _openToInternational,
              ),
            );
        ref.invalidate(jobOfferDetailProvider(jobId));
      } else {
        // F23/F24 (FITSCORE_REMEDIATION.md §3): assessmentId isn't part of the
        // create payload (backend-enforced — see JobsRepositoryImpl.createJobOffer).
        // Assignment is a separate PATCH, chained here so picking an assessment
        // during creation still works from the user's point of view.
        final newJob = await ref.read(jobOffersProvider.notifier).createJob(
              CreateJobOfferParams(
                title: _titleCtrl.text.trim(),
                companyName: _companyCtrl.text.trim(),
                city: _cityCtrl.text.trim(),
                country: _countryCtrl.text.trim(),
                remote: _remote,
                salaryMin: double.tryParse(_salaryMinCtrl.text) ?? 0,
                salaryMax: double.tryParse(_salaryMaxCtrl.text) ?? 0,
                currency: '/Mo',
                contractType: _contractType,
                workplaceType: _workplaceType,
                experienceLevel: _experienceLevel,
                fieldOfWork: _fieldCtrl.text.trim(),
                description: _descAboutJob,
                responsibilities: _descResponsibilities,
                minimumQualifications: _descMinQual,
                preferredQualifications: _descPrefQual,
                whatWeOffer: _descWhatWeOffer,
                howToApply: _descHowToApply,
                companyInfo: _companyInfoCtrl.text.trim(),
                assessmentId: _selectedAssessmentId,
                jobPositionId: _selectedJobPositionId,
                openToInternational: _openToInternational,
              ),
            );
        if (_selectedAssessmentId != null) {
          await ref.read(jobOffersProvider.notifier).assignAssessment(
                AssignAssessmentParams(
                  jobId: newJob.id,
                  assessmentId: _selectedAssessmentId,
                ),
              );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode ? 'Job updated!' : 'Job posted!'),
            backgroundColor: const Color(0xFF2AC052),
          ),
        );
        context.pop();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFE53935)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: _isEditMode ? 'Edit Job Offer' : 'Add a job offer',
        onBack: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            JobFormField(
              label: 'Job position',
              value: _titleCtrl.text.isEmpty ? null : _titleCtrl.text,
              showPen: true,
              onTap: () => showJobInlineEditDialog(
                context,
                label: 'Job position',
                controller: _titleCtrl,
                hint: 'e.g. Senior Flutter Developer',
              ),
            ),
            const SizedBox(height: 16),
            JobFormField(
              label: 'Métier (référentiel)',
              value: _selectedPosition()?.label,
              onTap: _openJobPositionDialog,
            ),
            const SizedBox(height: 16),
            JobFormField(
              label: 'Niveau hiérarchique',
              value: _selectedPosition()?.levelLabel(_experienceLevel) ??
                  _experienceLevel.label,
              onTap: _openExperienceLevelDialog,
            ),
            _buildWeightingPreview(),
            const SizedBox(height: 16),
            JobFormField(
              label: 'Type of workplace',
              value: _workplaceTypeChosen ? _workplaceType.label : null,
              onTap: _openWorkplaceDialog,
            ),
            const SizedBox(height: 16),
            JobFormField(
              label: 'Location',
              value: _locationDisplay.isEmpty ? null : _locationDisplay,
              onTap: _openLocationDialog,
            ),
            const SizedBox(height: 16),
            JobFormField(
              label: 'Employment type',
              value: _contractTypeChosen ? _contractType.label : null,
              onTap: _openEmploymentTypeSheet,
            ),
            const SizedBox(height: 16),
            JobFormField(
              label: 'Salary',
              value: _getSalaryDisplay().isEmpty ? null : _getSalaryDisplay(),
              onTap: _openSalaryDialog,
            ),
            const SizedBox(height: 16),
            JobFormField(
              label: 'Description',
              value: _hasDescription ? 'Description added' : null,
              onTap: _openDescriptionPage,
            ),
            const SizedBox(height: 16),
            JobFormField(
              label: 'Hard skills test',
              value: _selectedAssessmentTitle,
              onTap: _openAssessmentPage,
            ),
            const SizedBox(height: 24),
            JobInternationalCheckbox(
              value: _openToInternational,
              label: 'Open to international',
              onChanged: (v) => setState(() => _openToInternational = v),
            ),
            const SizedBox(height: 16),
            JobSubmitButton(
              isLoading: _isLoading,
              isEditMode: _isEditMode,
              labelPost: 'Post',
              labelSave: 'Save Changes',
              onPressed: _submit,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// F06 — sélection du métier dans le référentiel. Le serveur n'accepte que des
  /// métiers approuvés : un métier proposé mais pas encore validé par un admin n'a
  /// pas de profil, donc pas de pondération, donc l'offre resterait sans Fit Score.
  Future<void> _openJobPositionDialog() async {
    final positions = await ref.read(jobPositionsProvider.future);
    if (!mounted) return;

    final selected = await showDialog<JobPosition>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Métier'),
        children: [
          SizedBox(
            width: double.maxFinite,
            height: 420,
            child: ListView.builder(
              itemCount: positions.length,
              itemBuilder: (context, i) {
                final position = positions[i];
                return ListTile(
                  title: Text(position.name),
                  subtitle: position.sector == null
                      ? const Text('Métier transverse')
                      : Text(position.sector!),
                  selected: position.id == _selectedJobPositionId,
                  onTap: () => Navigator.pop(context, position),
                );
              },
            ),
          ),
        ],
      ),
    );

    if (selected == null) return;
    setState(() => _selectedJobPositionId = selected.id);
  }

  /// Le référentiel est déjà en cache après le premier chargement ; tant qu'il ne
  /// l'est pas, le champ reste vide plutôt que d'afficher un id brut.
  JobPosition? _selectedPosition() {
    if (_selectedJobPositionId == null) return null;
    final positions = ref.watch(jobPositionsProvider).asData?.value;
    if (positions == null) return null;
    final match = positions.where((p) => p.id == _selectedJobPositionId);
    return match.isEmpty ? null : match.first;
  }

  /// Le niveau n'avait aucun sélecteur : toute offre partait en JUNIOR. C'est pourtant
  /// lui qui décide du partage soft/hard — sur un métier Technique, 35 % de hard en
  /// Junior contre 65 % en Senior.
  Future<void> _openExperienceLevelDialog() async {
    final position = _selectedPosition();
    final selected = await showDialog<ExperienceLevel>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Niveau hiérarchique'),
        children: ExperienceLevel.values
            .map((level) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, level),
                  child: Text(position?.levelLabel(level) ?? level.label),
                ))
            .toList(),
      ),
    );
    if (selected == null) return;
    setState(() => _experienceLevel = selected);
  }

  /// F30 — montre au recruteur ce que son choix implique réellement. Lecture seule :
  /// les niveaux d'héritage entreprise et offre sont reportés (décision D-E), il n'y a
  /// donc rien à ajuster ici — seulement à rendre visible une pondération qui, sinon,
  /// s'applique sans que personne ne la voie.
  Widget _buildWeightingPreview() {
    final profileType = _selectedPosition()?.profileType;
    if (profileType == null) return const SizedBox.shrink();

    final profiles = ref.watch(jobRoleProfilesProvider);
    return profiles.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (all) {
        final match = all
            .where((p) => p.profileType == profileType && p.level == _experienceLevel)
            .toList();
        if (match.isEmpty) return const SizedBox.shrink();
        final profile = match.first;

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pondération appliquée · ${profile.profileType}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 6),
                Text('Soft skills ${profile.softWeight} %  ·  Hard skills ${profile.hardWeight} %',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                ...profile.moduleWeights.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text('${m.key} — ${m.value} %',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    )),
                if (!profile.calibrated) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Pondération v1, pas encore validée en atelier RH.',
                    style: TextStyle(
                        fontSize: 11, color: Color(0xFFC2620A), fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
