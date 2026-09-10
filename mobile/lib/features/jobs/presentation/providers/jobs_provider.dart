import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zennyt/core/network/dio_client.dart';
import 'package:zennyt/features/jobs/data/jobs_repository_impl.dart';
import 'package:zennyt/features/jobs/domain/entities/assessment.dart';
import 'package:zennyt/features/jobs/domain/entities/job.dart';
import 'package:zennyt/features/jobs/domain/repositories/jobs_repository.dart';
import 'package:zennyt/features/jobs/domain/entities/job_position.dart';
/// Source unique du repository Jobs (backend intégré).
final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  return JobsRepositoryImpl(ref.watch(dioProvider));
});

class JobOffersNotifier extends AsyncNotifier<List<JobOffer>> {
  @override
  Future<List<JobOffer>> build() {
    return ref.read(jobsRepositoryProvider).getJobOffers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(jobsRepositoryProvider).getJobOffers());
  }

  /// F24 (FITSCORE_REMEDIATION.md §3 index F24): `assessmentId` isn't part of
  /// the create payload (backend-enforced, see [JobsRepositoryImpl.createJobOffer])
  /// — returns the created job so callers that captured an assessment
  /// selection in the same form can immediately follow up with
  /// [assignAssessment].
  Future<JobOffer> createJob(CreateJobOfferParams params) async {
    final newJob = await ref.read(jobsRepositoryProvider).createJobOffer(params);
    final current = state.value ?? [];
    state = AsyncData([newJob, ...current]);
    return newJob;
  }

  Future<void> updateJob(UpdateJobOfferParams params) async {
    final updated = await ref.read(jobsRepositoryProvider).updateJobOffer(params);
    final current = state.value ?? [];
    state = AsyncData(current.map((j) => j.id == updated.id ? updated : j).toList());
  }

  Future<void> deleteJob(String id) async {
    await ref.read(jobsRepositoryProvider).deleteJobOffer(id);
    final current = state.value ?? [];
    state = AsyncData(current.where((j) => j.id != id).toList());
  }

  Future<void> assignAssessment(AssignAssessmentParams params) async {
    final updated = await ref.read(jobsRepositoryProvider).assignAssessmentToJob(
          jobId: params.jobId,
          assessmentId: params.assessmentId,
        );
    final current = state.value ?? [];
    state = AsyncData(current.map((j) => j.id == updated.id ? updated : j).toList());
  }
}

final jobOffersProvider = AsyncNotifierProvider<JobOffersNotifier, List<JobOffer>>(
  JobOffersNotifier.new,
);

final jobOfferDetailProvider = FutureProvider.family<JobOffer, String>((ref, id) {
  return ref.read(jobsRepositoryProvider).getJobOfferById(id);
});

class AssessmentsNotifier extends AsyncNotifier<List<Assessment>> {
  @override
  Future<List<Assessment>> build() {
    return ref.read(jobsRepositoryProvider).getAssessments();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(jobsRepositoryProvider).getAssessments());
  }

  Future<Assessment?> createAssessment(CreateAssessmentParams params) async {
    final newAssessment = await ref.read(jobsRepositoryProvider).createAssessment(params);
    final current = state.value ?? [];
    state = AsyncData([...current, newAssessment]);
    return newAssessment;
  }

  /// Génération IA — pas encore disponible sur le backend intégré
  /// (voir GenerateAssessmentAiParams) ; l'appel lève une ApiException 404.
  Future<Assessment?> generateAssessmentAi(GenerateAssessmentAiParams params) async {
    final newAssessment = await ref.read(jobsRepositoryProvider).generateAssessmentAi(params);
    final current = state.value ?? [];
    state = AsyncData([...current, newAssessment]);
    return newAssessment;
  }

  Future<void> updateAssessment(UpdateAssessmentParams params) async {
    final updated = await ref.read(jobsRepositoryProvider).updateAssessment(params);
    final current = state.value ?? [];
    state = AsyncData(current.map((a) => a.id == updated.id ? updated : a).toList());
  }

  Future<void> deleteAssessment(String id) async {
    await ref.read(jobsRepositoryProvider).deleteAssessment(id);
    final current = state.value ?? [];
    state = AsyncData(current.where((a) => a.id != id).toList());
  }
}

/// F06 — le catalogue des métiers, pour le sélecteur du formulaire de création.
/// Chargé une fois par session : le référentiel est fixe (142 lignes approuvées).
final jobPositionsProvider = FutureProvider<List<JobPosition>>((ref) {
  return ref.read(jobsRepositoryProvider).getJobPositions();
});

/// F30 — les 24 lignes de pondération (6 profils × 4 niveaux). L'endpoint existait
/// depuis le début, au contrat, avec son javadoc annonçant servir au préremplissage
/// du formulaire — et personne ne l'appelait.
final jobRoleProfilesProvider = FutureProvider<List<JobRoleProfile>>((ref) {
  return ref.read(jobsRepositoryProvider).getJobRoleProfiles();
});

final assessmentsProvider = AsyncNotifierProvider<AssessmentsNotifier, List<Assessment>>(
  AssessmentsNotifier.new,
);

final assessmentDetailProvider = FutureProvider.family<Assessment, String>((ref, id) {
  return ref.read(jobsRepositoryProvider).getAssessmentById(id);
});
