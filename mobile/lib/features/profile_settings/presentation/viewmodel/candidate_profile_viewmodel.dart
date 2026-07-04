import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../../../core/error/api_exception.dart';
import '../../data/dtos/profile_input.dart';
import '../../data/dtos/sub_resource_inputs.dart';
import '../../domain/entities/candidate_profile.dart';
import '../../domain/profile_enums.dart';
import '../profile_providers.dart';

class JobPosition {
  final String id;
  final String position;
  final String company;
  final String startYear;
  final String endYear; // If empty or null, means "Present"

  JobPosition({
    required this.id,
    required this.position,
    required this.company,
    required this.startYear,
    required this.endYear,
  });

  JobPosition copyWith({
    String? position,
    String? company,
    String? startYear,
    String? endYear,
  }) {
    return JobPosition(
      id: id,
      position: position ?? this.position,
      company: company ?? this.company,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
    );
  }
}

class Certification {
  final String id;
  final String title;
  final String organization;
  final String year;

  Certification({
    required this.id,
    required this.title,
    required this.organization,
    required this.year,
  });

  Certification copyWith({String? title, String? organization, String? year}) {
    return Certification(
      id: id,
      title: title ?? this.title,
      organization: organization ?? this.organization,
      year: year ?? this.year,
    );
  }
}

class Education {
  final String id;
  final String degree;
  final String university;
  final String startYear;
  final String endYear;

  Education({
    required this.id,
    required this.degree,
    required this.university,
    required this.startYear,
    required this.endYear,
  });

  Education copyWith({
    String? degree,
    String? university,
    String? startYear,
    String? endYear,
  }) {
    return Education(
      id: id,
      degree: degree ?? this.degree,
      university: university ?? this.university,
      startYear: startYear ?? this.startYear,
      endYear: endYear ?? this.endYear,
    );
  }
}

class LookingFor {
  final String jobPosition;
  final String workplaceType;
  final String jobType;
  final String targetLocation;

  LookingFor({
    required this.jobPosition,
    required this.workplaceType,
    required this.jobType,
    required this.targetLocation,
  });

  LookingFor copyWith({
    String? jobPosition,
    String? workplaceType,
    String? jobType,
    String? targetLocation,
  }) {
    return LookingFor(
      jobPosition: jobPosition ?? this.jobPosition,
      workplaceType: workplaceType ?? this.workplaceType,
      jobType: jobType ?? this.jobType,
      targetLocation: targetLocation ?? this.targetLocation,
    );
  }
}

class PortfolioItem {
  final String id;
  final String title;
  final String imagePath;

  PortfolioItem({
    required this.id,
    required this.title,
    required this.imagePath,
  });

  PortfolioItem copyWith({String? id, String? title, String? imagePath}) {
    return PortfolioItem(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}

class CandidateProfileState {
  final String name;
  final String role;
  final String location;
  final String? avatarUrl;
  final bool isResumeAiVisible;
  final bool isSoftSkillsVisible;
  final int softSkillsScore;
  final LookingFor lookingFor;
  final List<String> skills;
  final String yearsOfExperience;
  final List<JobPosition> jobPositions;
  final List<Certification> certifications;
  final List<Education> education;
  final String aboutMe;
  final bool openToWorkInternationally;
  final String availableDate; // 'Immediately' or a date string
  final List<PortfolioItem> portfolioItems;

  /// Async/caching metadata.
  final bool isLoading;
  final String? errorMessage;

  /// Whether a professional profile already exists on the backend (drives
  /// POST vs PUT on save).
  final bool profileExists;

  CandidateProfileState({
    required this.name,
    required this.role,
    required this.location,
    this.avatarUrl,
    required this.isResumeAiVisible,
    this.isSoftSkillsVisible = true,
    required this.softSkillsScore,
    required this.lookingFor,
    required this.skills,
    required this.yearsOfExperience,
    required this.jobPositions,
    required this.certifications,
    required this.education,
    required this.aboutMe,
    this.openToWorkInternationally = true,
    this.availableDate = 'Immediately',
    this.portfolioItems = const [],
    this.isLoading = false,
    this.errorMessage,
    this.profileExists = false,
  });

  CandidateProfileState copyWith({
    String? name,
    String? role,
    String? location,
    String? avatarUrl,
    bool? isResumeAiVisible,
    bool? isSoftSkillsVisible,
    int? softSkillsScore,
    LookingFor? lookingFor,
    List<String>? skills,
    String? yearsOfExperience,
    List<JobPosition>? jobPositions,
    List<Certification>? certifications,
    List<Education>? education,
    String? aboutMe,
    bool? openToWorkInternationally,
    String? availableDate,
    List<PortfolioItem>? portfolioItems,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? profileExists,
  }) {
    return CandidateProfileState(
      name: name ?? this.name,
      role: role ?? this.role,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isResumeAiVisible: isResumeAiVisible ?? this.isResumeAiVisible,
      isSoftSkillsVisible: isSoftSkillsVisible ?? this.isSoftSkillsVisible,
      softSkillsScore: softSkillsScore ?? this.softSkillsScore,
      lookingFor: lookingFor ?? this.lookingFor,
      skills: skills ?? this.skills,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      jobPositions: jobPositions ?? this.jobPositions,
      certifications: certifications ?? this.certifications,
      education: education ?? this.education,
      aboutMe: aboutMe ?? this.aboutMe,
      openToWorkInternationally:
          openToWorkInternationally ?? this.openToWorkInternationally,
      availableDate: availableDate ?? this.availableDate,
      portfolioItems: portfolioItems ?? this.portfolioItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      profileExists: profileExists ?? this.profileExists,
    );
  }
}

class CandidateProfileViewModel extends Notifier<CandidateProfileState> {
  /// Bumped on every load so a stale in-flight request can't overwrite a newer
  /// result (e.g. after a quick refresh).
  int _loadToken = 0;

  @override
  CandidateProfileState build() {
    // Re-run (and reload) only when the displayed identity actually changes
    // (login/logout, avatar/name/location edit). Routine `/auth/me`
    // revalidations return an equal record, so the cached profile is kept.
    final identity = ref.watch(
      authControllerProvider.select((a) {
        final u = a.value;
        return (u?.id, u?.fullName, u?.profileImageUrl, u?.city, u?.country);
      }),
    );

    final user = ref.read(authControllerProvider).value;
    Future.microtask(_load);
    return _initialFor(user, loading: identity.$1 != null);
  }

  // ── Loading ──────────────────────────────────────────────────────────────

  Future<void> _load() async {
    final user = ref.read(authControllerProvider).value;
    if (user == null) return; // signed out: nothing to fetch

    final token = ++_loadToken;
    try {
      final profile = await ref.read(profileRepositoryProvider).getMyProfile();
      if (token != _loadToken) return; // superseded by a newer load
      state = _merge(user, profile);
    } on ApiException catch (e) {
      if (token != _loadToken) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Explicit reload (pull-to-refresh / retry).
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    await _load();
  }

  // ── Saving (looking-for / profile core fields) ─────────────────────────────

  /// Persists the "Looking for" + availability edits via POST/PUT /profiles/me.
  /// Updates the cache in place on success; throws [ApiException] on failure.
  Future<void> saveLookingFor({
    required String role,
    required LookingFor lookingFor,
    required bool openToWorkInternationally,
    required String availableDate,
  }) async {
    final merged = state.copyWith(
      role: role,
      lookingFor: lookingFor,
      openToWorkInternationally: openToWorkInternationally,
      availableDate: availableDate,
      clearError: true,
    );

    final saved = await ref
        .read(profileRepositoryProvider)
        .saveProfile(_buildInput(merged), exists: merged.profileExists);

    final user = ref.read(authControllerProvider).value;
    _loadToken++; // invalidate any in-flight load
    state = _merge(user, saved);
  }

  /// Persists the "About me" text via POST/PUT /profiles/me.
  /// Throws [ApiException] on failure so the caller can show an error.
  Future<void> saveAboutMe(String text) async {
    final merged = state.copyWith(aboutMe: text, clearError: true);

    final saved = await ref
        .read(profileRepositoryProvider)
        .saveProfile(_buildInput(merged), exists: merged.profileExists);

    final user = ref.read(authControllerProvider).value;
    _loadToken++;
    state = _merge(user, saved);
  }

  // ── Sub-resource persistence (Skills, Positions, Certifications, Education) ──

  void toggleResumeAiVisibility(bool isVisible) {
    state = state.copyWith(isResumeAiVisible: isVisible);
  }

  // ── Job Positions ──────────────────────────────────────────────────────

  Future<void> addJobPosition(JobPosition position) async {
    // Optimistic update
    state = state.copyWith(jobPositions: [...state.jobPositions, position]);
    try {
      final input = PositionInput(
        title: position.position,
        companyName: position.company,
        startDate: _toStartOfYear(position.startYear),
        endDate: position.endYear.isEmpty
            ? null
            : _toStartOfYear(position.endYear),
        current: position.endYear.isEmpty,
      );
      await ref.read(profileRepositoryProvider).addPosition(input);
      await refresh();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      // Rollback
      state = state.copyWith(
        jobPositions: state.jobPositions
            .where((p) => p.id != position.id)
            .toList(),
      );
    }
  }

  Future<void> updateJobPosition(JobPosition updatedPosition) async {
    final oldList = state.jobPositions;
    state = state.copyWith(
      jobPositions: oldList
          .map((p) => p.id == updatedPosition.id ? updatedPosition : p)
          .toList(),
    );
    try {
      final input = PositionInput(
        title: updatedPosition.position,
        companyName: updatedPosition.company,
        startDate: _toStartOfYear(updatedPosition.startYear),
        endDate: updatedPosition.endYear.isEmpty
            ? null
            : _toStartOfYear(updatedPosition.endYear),
        current: updatedPosition.endYear.isEmpty,
      );
      await ref
          .read(profileRepositoryProvider)
          .updatePosition(updatedPosition.id, input);
      await refresh();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message, jobPositions: oldList);
    }
  }

  Future<void> removeJobPosition(String id) async {
    final oldList = state.jobPositions;
    state = state.copyWith(
      jobPositions: oldList.where((p) => p.id != id).toList(),
    );
    try {
      await ref.read(profileRepositoryProvider).deletePosition(id);
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message, jobPositions: oldList);
    }
  }

  // ── Certifications ─────────────────────────────────────────────────────

  Future<void> addCertification(Certification certification) async {
    state = state.copyWith(
      certifications: [...state.certifications, certification],
    );
    try {
      final input = CertificationInput(
        title: certification.title,
        issuer: certification.organization,
        completionDate: _toStartOfYear(certification.year),
      );
      await ref.read(profileRepositoryProvider).addCertification(input);
      await refresh();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      state = state.copyWith(
        certifications: state.certifications
            .where((c) => c.id != certification.id)
            .toList(),
      );
    }
  }

  Future<void> updateCertification(Certification updatedCertification) async {
    final oldList = state.certifications;
    state = state.copyWith(
      certifications: oldList
          .map(
            (c) => c.id == updatedCertification.id ? updatedCertification : c,
          )
          .toList(),
    );
    try {
      final input = CertificationInput(
        title: updatedCertification.title,
        issuer: updatedCertification.organization,
        completionDate: _toStartOfYear(updatedCertification.year),
      );
      await ref
          .read(profileRepositoryProvider)
          .updateCertification(updatedCertification.id, input);
      await refresh();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message, certifications: oldList);
    }
  }

  Future<void> removeCertification(String id) async {
    final oldList = state.certifications;
    state = state.copyWith(
      certifications: oldList.where((c) => c.id != id).toList(),
    );
    try {
      await ref.read(profileRepositoryProvider).deleteCertification(id);
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message, certifications: oldList);
    }
  }

  // ── Education ──────────────────────────────────────────────────────────

  Future<void> addEducation(Education edu) async {
    state = state.copyWith(education: [...state.education, edu]);
    try {
      final input = EducationInput(
        degree: edu.degree,
        school: edu.university,
        startDate: _toStartOfYear(edu.startYear),
        endDate: edu.endYear.isEmpty ? null : _toStartOfYear(edu.endYear),
      );
      await ref.read(profileRepositoryProvider).addEducation(input);
      await refresh();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      state = state.copyWith(
        education: state.education.where((ed) => ed.id != edu.id).toList(),
      );
    }
  }

  Future<void> updateEducation(Education updatedEdu) async {
    final oldList = state.education;
    state = state.copyWith(
      education: oldList
          .map((e) => e.id == updatedEdu.id ? updatedEdu : e)
          .toList(),
    );
    try {
      final input = EducationInput(
        degree: updatedEdu.degree,
        school: updatedEdu.university,
        startDate: _toStartOfYear(updatedEdu.startYear),
        endDate: updatedEdu.endYear.isEmpty
            ? null
            : _toStartOfYear(updatedEdu.endYear),
      );
      await ref
          .read(profileRepositoryProvider)
          .updateEducation(updatedEdu.id, input);
      await refresh();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message, education: oldList);
    }
  }

  Future<void> removeEducation(String id) async {
    final oldList = state.education;
    state = state.copyWith(
      education: oldList.where((e) => e.id != id).toList(),
    );
    try {
      await ref.read(profileRepositoryProvider).deleteEducation(id);
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message, education: oldList);
    }
  }

  // ── Skills ─────────────────────────────────────────────────────────────

  /// Syncs the skill list by diffing the old vs new lists and calling
  /// add/delete on each change. This is called from the TechnicalSkillsModal.
  Future<void> updateSkills(List<String> newSkills) async {
    final oldSkills = state.skills;
    // Optimistic update
    state = state.copyWith(skills: newSkills);

    try {
      final repo = ref.read(profileRepositoryProvider);
      final profile = await repo.getMyProfile();
      final existingSkills = (profile?.skills ?? [])
          .where((s) => s.type == null || s.type == 'TECHNICAL')
          .toList();

      // Skills to add (in new list but not in existing)
      final existingNames = existingSkills.map((s) => s.name).toSet();
      final toAdd = newSkills.where((s) => !existingNames.contains(s)).toList();

      // Skills to delete (in existing but not in new list)
      final newSet = newSkills.toSet();
      final toDelete = existingSkills
          .where((s) => !newSet.contains(s.name))
          .toList();

      for (final name in toAdd) {
        await repo.addSkill(SkillInput(name: name, type: 'TECHNICAL'));
      }
      for (final skill in toDelete) {
        await repo.deleteSkill(skill.id);
      }

      await refresh();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message, skills: oldSkills);
    }
  }

  void updateYearsOfExperience(String newYears) {
    state = state.copyWith(yearsOfExperience: newYears);
  }

  void toggleSoftSkillsVisibility(bool isVisible) {
    state = state.copyWith(isSoftSkillsVisible: isVisible);
  }

  void addPortfolioItem(PortfolioItem item) {
    state = state.copyWith(portfolioItems: [item, ...state.portfolioItems]);
  }

  void removePortfolioItem(String id) {
    state = state.copyWith(
      portfolioItems: state.portfolioItems.where((i) => i.id != id).toList(),
    );
  }

  // ── Mapping helpers ────────────────────────────────────────────────────────

  CandidateProfileState _initialFor(AppUser? user, {required bool loading}) {
    return CandidateProfileState(
      name: user?.fullName.trim() ?? '',
      role: '',
      location: _locationOf(user),
      avatarUrl: user?.profileImageUrl,
      isResumeAiVisible: true,
      softSkillsScore: 0,
      lookingFor: LookingFor(
        jobPosition: '',
        workplaceType: 'Flexible',
        jobType: 'Full time',
        targetLocation: '',
      ),
      skills: const [],
      yearsOfExperience: '',
      jobPositions: const [],
      certifications: const [],
      education: const [],
      aboutMe: '',
      isLoading: loading,
      profileExists: false,
    );
  }

  CandidateProfileState _merge(AppUser? user, CandidateProfile? p) {
    return CandidateProfileState(
      name: user?.fullName.trim() ?? '',
      role: (p?.currentPosition?.isNotEmpty ?? false)
          ? p!.currentPosition!
          : (user?.role.label ?? ''),
      location: _locationOf(user),
      avatarUrl: user?.profileImageUrl,
      isResumeAiVisible: true,
      softSkillsScore: p?.softSkillsScore ?? 0,
      lookingFor: LookingFor(
        jobPosition: p?.lookingFor ?? '',
        workplaceType: ProfileEnums.workplaceFromWire(p?.workplaceType),
        jobType: ProfileEnums.jobTypeFromWire(p?.jobType),
        targetLocation: p?.targetJobLocation ?? '',
      ),
      skills: (p?.skills ?? const [])
          .where((s) => s.type == null || s.type == 'TECHNICAL')
          .map((s) => s.name)
          .where((n) => n.isNotEmpty)
          .toList(),
      yearsOfExperience: p?.yearsOfExperience != null
          ? '${p!.yearsOfExperience} years'
          : '',
      jobPositions: (p?.positions ?? const [])
          .map(
            (pos) => JobPosition(
              id: pos.id,
              position: pos.title,
              company: pos.companyName ?? '',
              startYear: _yearOf(pos.startDate),
              endYear: pos.current ? '' : _yearOf(pos.endDate),
            ),
          )
          .toList(),
      certifications: (p?.certifications ?? const [])
          .map(
            (c) => Certification(
              id: c.id,
              title: c.title,
              organization: c.issuer ?? '',
              year: _yearOf(c.completionDate),
            ),
          )
          .toList(),
      education: (p?.education ?? const [])
          .map(
            (e) => Education(
              id: e.id,
              degree: e.degree,
              university: e.school ?? '',
              startYear: _yearOf(e.startDate),
              endYear: _yearOf(e.endDate),
            ),
          )
          .toList(),
      aboutMe: p?.aboutMe ?? '',
      openToWorkInternationally: p?.openInternationally ?? false,
      availableDate: _availabilityLabel(p),
      isLoading: false,
      profileExists: p != null,
    );
  }

  ProfileInput _buildInput(CandidateProfileState s) {
    final immediately = s.availableDate.trim() == 'Immediately';
    return ProfileInput(
      currentPosition: s.role,
      lookingFor: s.lookingFor.jobPosition,
      workplaceType: ProfileEnums.workplaceToWire(s.lookingFor.workplaceType),
      jobType: ProfileEnums.jobTypeToWire(s.lookingFor.jobType),
      targetJobLocation: s.lookingFor.targetLocation,
      yearsOfExperience: _parseYears(s.yearsOfExperience),
      softSkillsScore: s.softSkillsScore,
      aboutMe: s.aboutMe,
      openInternationally: s.openToWorkInternationally,
      availabilityType: immediately
          ? ProfileEnums.availabilityImmediately
          : ProfileEnums.availabilitySelectDate,
      availabilityDate: immediately ? null : _toIsoDate(s.availableDate),
    );
  }

  static String _locationOf(AppUser? user) {
    if (user == null) return '';
    return [
      user.city,
      user.country,
    ].where((e) => e != null && e.isNotEmpty).join(', ');
  }

  static String _yearOf(String? date) {
    if (date == null || date.length < 4) return '';
    return date.substring(0, 4);
  }

  static String _availabilityLabel(CandidateProfile? p) {
    if (p == null) return 'Immediately';
    if (p.availabilityType == ProfileEnums.availabilitySelectDate &&
        p.availabilityDate != null) {
      final parsed = DateTime.tryParse(p.availabilityDate!);
      if (parsed != null) return DateFormat('MMM d, yyyy').format(parsed);
    }
    return 'Immediately';
  }

  static int? _parseYears(String value) {
    final match = RegExp(r'\d+').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(0)!);
  }

  static String? _toIsoDate(String display) {
    try {
      final parsed = DateFormat('MMM d, yyyy').parseStrict(display);
      return DateFormat('yyyy-MM-dd').format(parsed);
    } catch (_) {
      final iso = DateTime.tryParse(display);
      return iso == null ? null : DateFormat('yyyy-MM-dd').format(iso);
    }
  }

  /// Converts a year string (e.g. "2023") to a date string ("2023-01-01")
  /// that the API expects. Returns null if the year is empty or invalid.
  static String? _toStartOfYear(String year) {
    if (year.trim().isEmpty) return null;
    final parsed = int.tryParse(year.trim());
    if (parsed == null) return null;
    return '$parsed-01-01';
  }
}

final candidateProfileProvider =
    NotifierProvider<CandidateProfileViewModel, CandidateProfileState>(
      CandidateProfileViewModel.new,
    );
