package com.zennyt.recruitment.application;

import com.zennyt.recruitment.application.port.FitScoreCalculatorPort;
import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase;
import com.zennyt.recruitment.application.usecase.RecomputeFitScoresUseCase.Pair;
import com.zennyt.recruitment.domain.model.*;
import com.zennyt.recruitment.domain.repository.*;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.vo.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

/**
 * Garde-fou central du batch-loading : le chemin par lot doit produire
 * <b>exactement</b> les mêmes scores que le chemin unitaire.
 *
 * <p>C'est ce qui autorise à laisser les 3 déclencheurs existants (partie jouée,
 * offre publiée, test soumis) sur {@code recompute()} sans risque de divergence
 * avec le balayage de rattrapage, qui lui passe par {@code recomputeBatch()}.
 *
 * <p>Les deux chemins sont alimentés par <b>le même jeu de données</b> : les
 * méthodes unitaires et les méthodes par lot des repositories sont stubbées
 * depuis les mêmes objets, sinon le test ne prouverait rien.
 */
class RecomputeFitScoresUseCaseBatchTest {

    private static final UUID CANDIDATE_COMPLET = UUID.randomUUID();   // jeux + test + score existant
    private static final UUID CANDIDATE_VIERGE = UUID.randomUUID();    // aucune donnée
    private static final UUID RECRUTEUR_AVEC_INFO = UUID.randomUUID();
    private static final UUID RECRUTEUR_SANS_INFO = UUID.randomUUID();
    private static final UUID POSITION_ID = UUID.randomUUID();
    private static final UUID SCORE_EXISTANT_ID = UUID.randomUUID();

    /** Offre reliée au référentiel : le profil métier se résout. */
    private final JobOffer offreResolue = offer(UUID.randomUUID(), RECRUTEUR_AVEC_INFO, POSITION_ID);
    /** Offre sans métier : profil non résolu (branche {@code roleProfile == null}). */
    private final JobOffer offreNonResolue = offer(UUID.randomUUID(), RECRUTEUR_SANS_INFO, null);

    private static final JobRoleProfile PONDERATION = new JobRoleProfile(
        JobProfileType.TECHNIQUE, ExperienceLevel.SENIOR, 35, 65, 65, 30, 20, 30, 15, 5,
        TypeEvaluationHard.QCM, false, java.time.Instant.now());

    private final List<SoftSkillsProjection> modules = List.of(
        SoftSkillsProjection.create(CANDIDATE_COMPLET, "MOVE_FAST", 80, Instant.now()),
        SoftSkillsProjection.create(CANDIDATE_COMPLET, "PLANIFIK", 60, Instant.now()));

    private FitScoreRepository fitScores;
    private SoftSkillsProjectionRepository softSkills;
    private RecruitmentActorRepository actors;
    private TestResultRepository testResults;
    private JobRoleProfileResolver roleProfileResolver;
    private RecomputeFitScoresUseCase useCase;

    /**
     * Calculateur volontairement sensible à <b>chacune</b> des entrées préchargées :
     * si le chemin par lot en associait une seule à la mauvaise paire, le score
     * changerait et le test échouerait.
     */
    private static final FitScoreCalculatorPort CALCULATOR = inputs -> {
        int soft = (int) Math.round(inputs.softSkills().values().stream()
            .mapToDouble(Double::doubleValue).average().orElse(0));
        int hard = inputs.hardSkillScore() == null ? 0 : inputs.hardSkillScore();
        int profil = inputs.roleProfile() == null ? 0 : 7;
        int societe = inputs.companyDescription() == null ? 0 : 3;
        return new FitScoreCalculatorPort.FitScoreResult(
            Math.min(100, soft / 2 + hard / 4 + profil + societe), Math.min(100, soft));
    };

    @BeforeEach
    void setUp() {
        fitScores = mock(FitScoreRepository.class);
        softSkills = mock(SoftSkillsProjectionRepository.class);
        actors = mock(RecruitmentActorRepository.class);
        testResults = mock(TestResultRepository.class);
        roleProfileResolver = mock(JobRoleProfileResolver.class);
        JobOfferRepository offers = mock(JobOfferRepository.class);

        RecruitmentActor avecInfo = actor(RECRUTEUR_AVEC_INFO, "Entreprise produit");
        RecruitmentActor sansInfo = actor(RECRUTEUR_SANS_INFO, null);
        TestResult resultat = testResult(CANDIDATE_COMPLET, offreResolue.id(), 72);
        FitScore existant = FitScore.calculated(SCORE_EXISTANT_ID, CANDIDATE_COMPLET,
            offreResolue.id(), 10, 10, null, 100, Instant.now());

        // ---- chemin unitaire ----
        when(softSkills.findByCandidateId(CANDIDATE_COMPLET)).thenReturn(modules);
        when(softSkills.findByCandidateId(CANDIDATE_VIERGE)).thenReturn(List.of());
        when(actors.findById(RECRUTEUR_AVEC_INFO)).thenReturn(Optional.of(avecInfo));
        when(actors.findById(RECRUTEUR_SANS_INFO)).thenReturn(Optional.of(sansInfo));
        when(roleProfileResolver.resolve(offreResolue)).thenReturn(PONDERATION);
        when(roleProfileResolver.resolve(offreNonResolue)).thenReturn(null);
        when(testResults.findByCandidateIdAndJobOfferId(any(), any())).thenReturn(Optional.empty());
        when(testResults.findByCandidateIdAndJobOfferId(CANDIDATE_COMPLET, offreResolue.id()))
            .thenReturn(Optional.of(resultat));
        when(fitScores.findByCandidateIdAndJobOfferId(any(), any())).thenReturn(Optional.empty());
        when(fitScores.findByCandidateIdAndJobOfferId(CANDIDATE_COMPLET, offreResolue.id()))
            .thenReturn(Optional.of(existant));
        when(fitScores.save(any())).thenAnswer(invocation -> invocation.getArgument(0));

        // ---- chemin par lot : MÊMES données, méthodes en masse ----
        when(softSkills.findByCandidateIds(any())).thenReturn(modules);
        when(actors.findByIds(any())).thenReturn(List.of(avecInfo, sansInfo));
        when(roleProfileResolver.resolveAll(any())).thenReturn(Map.of(offreResolue.id(), PONDERATION));
        when(testResults.findByCandidateIdsAndJobOfferIds(any(), any())).thenReturn(List.of(resultat));
        when(fitScores.findByCandidateIdsAndJobOfferIds(any(), any())).thenReturn(List.of(existant));
        when(fitScores.saveAll(any())).thenAnswer(invocation ->
            ((List<?>) invocation.getArgument(0)).size());

        useCase = new RecomputeFitScoresUseCase(CALCULATOR, fitScores, offers, softSkills, actors,
            roleProfileResolver, testResults);
    }

    private List<Pair> toutesLesPaires() {
        return List.of(
            new Pair(CANDIDATE_COMPLET, offreResolue),     // jeux + test + score existant + profil + société
            new Pair(CANDIDATE_COMPLET, offreNonResolue),  // profil non résolu, pas de société
            new Pair(CANDIDATE_VIERGE, offreResolue),      // aucun soft skill, aucun test
            new Pair(CANDIDATE_VIERGE, offreNonResolue));  // tout absent
    }

    @Test
    void cheminParLotProduitExactementLesMemesScoresQueLeCheminUnitaire() {
        List<Pair> paires = toutesLesPaires();

        Map<String, FitScore> unitaires = paires.stream()
            .map(pair -> useCase.recompute(pair.candidateId(), pair.offer()))
            .collect(Collectors.toMap(f -> f.candidateId() + "|" + f.jobOfferId(), Function.identity()));

        List<FitScore> parLot = useCase.recomputeBatch(paires);

        assertThat(parLot).hasSameSizeAs(paires);
        for (FitScore lot : parLot) {
            FitScore unitaire = unitaires.get(lot.candidateId() + "|" + lot.jobOfferId());
            assertThat(unitaire).as("paire manquante côté unitaire").isNotNull();
            // computedAt exclu volontairement : Instant.now() diffère entre les deux exécutions.
            assertThat(lot.score()).as("score").isEqualTo(unitaire.score());
            assertThat(lot.softSkillScore()).as("softSkillScore").isEqualTo(unitaire.softSkillScore());
            assertThat(lot.hardSkillScore()).as("hardSkillScore").isEqualTo(unitaire.hardSkillScore());
            assertThat(lot.coverageRatio()).as("coverageRatio").isEqualTo(unitaire.coverageRatio());
            // id exclu ici : un score neuf reçoit un UUID aléatoire, donc forcément différent
            // entre deux exécutions. La seule garantie qui compte — la réutilisation de l'id
            // d'un score existant — est vérifiée par le test dédié ci-dessous.
        }
    }

    @Test
    void leScoreExistantEstReutiliseParLesDeuxChemins() {
        FitScore unitaire = useCase.recompute(CANDIDATE_COMPLET, offreResolue);
        FitScore parLot = useCase.recomputeBatch(List.of(new Pair(CANDIDATE_COMPLET, offreResolue))).get(0);

        assertThat(unitaire.id()).isEqualTo(SCORE_EXISTANT_ID);
        assertThat(parLot.id()).isEqualTo(SCORE_EXISTANT_ID);
    }

    @Test
    void unLotNeLitQuUneFoisParTypeDeDonnee() {
        useCase.recomputeBatch(toutesLesPaires());

        verify(softSkills, times(1)).findByCandidateIds(any());
        verify(actors, times(1)).findByIds(any());
        verify(roleProfileResolver, times(1)).resolveAll(any());
        verify(testResults, times(1)).findByCandidateIdsAndJobOfferIds(any(), any());
        verify(fitScores, times(1)).findByCandidateIdsAndJobOfferIds(any(), any());
        verify(fitScores, times(1)).saveAll(any());

        // Aucun retour au chargement paire par paire, sinon le gain disparaît.
        verify(softSkills, never()).findByCandidateId(any());
        verify(actors, never()).findById(any());
        verify(roleProfileResolver, never()).resolve(any());
        verify(testResults, never()).findByCandidateIdAndJobOfferId(any(), any());
        verify(fitScores, never()).findByCandidateIdAndJobOfferId(any(), any());
        verify(fitScores, never()).save(any());
    }

    @Test
    void uneOffreSansMetierApprouveNEcritAucunScore() {
        // Le calculateur déterministe renvoie null sans pondération résolue : on n'écrit
        // rien plutôt que d'inventer un score. Vérifié sur les DEUX chemins, car un seul
        // des deux qui écrirait recréerait l'incohérence que la suppression du repli
        // Groq visait à supprimer.
        FitScoreCalculatorPort sansPonderation = inputs ->
            inputs.roleProfile() == null ? null : new FitScoreCalculatorPort.FitScoreResult(50, 50);
        var useCaseSansRepli = new RecomputeFitScoresUseCase(sansPonderation, fitScores,
            mock(JobOfferRepository.class), softSkills, actors, roleProfileResolver, testResults);

        assertThat(useCaseSansRepli.recompute(CANDIDATE_VIERGE, offreNonResolue)).isNull();
        verify(fitScores, never()).save(any());

        assertThat(useCaseSansRepli.recomputeBatch(List.of(new Pair(CANDIDATE_VIERGE, offreNonResolue))))
            .isEmpty();
    }

    @Test
    void lotVideNeDeclencheAucuneRequete() {
        assertThat(useCase.recomputeBatch(List.of())).isEmpty();
        verifyNoInteractions(softSkills, actors, testResults, roleProfileResolver);
        verifyNoInteractions(fitScores);
    }

    // ───────────── fixtures ─────────────

    private static JobOffer offer(UUID id, UUID recruiterId, UUID jobPositionId) {
        Instant now = Instant.now();
        return JobOffer.rehydrate(id, recruiterId, null, "Développeur",
            new Location("Tunis", "TN"), 40000.0, 70000.0,
            ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.SENIOR,
            "desc", "resp", "min", "pref", "offer", "apply",
            null, jobPositionId, false, JobOfferStatus.ACTIVE, now, now);
    }

    private static RecruitmentActor actor(UUID id, String companyInfo) {
        return new RecruitmentActor(id, "RECRUITER", true, "Zennyt", null, "Tunis", "TN",
            "Zennyt Inc.", companyInfo, null, null, null, null, null, null, null,
            Instant.now(), UUID.randomUUID());
    }

    private static TestResult testResult(UUID candidateId, UUID jobOfferId, int percentage) {
        Instant now = Instant.now();
        return TestResult.rehydrate(UUID.randomUUID(), jobOfferId, UUID.randomUUID(), candidateId,
            percentage, percentage, percentage >= 60, List.of(), now, now, 120,
            TestResultStatus.COMPLETED);
    }
}
