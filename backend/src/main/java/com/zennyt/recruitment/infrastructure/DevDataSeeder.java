package com.zennyt.recruitment.infrastructure;

import com.zennyt.recruitment.domain.model.Assessment;
import com.zennyt.recruitment.domain.model.AssessmentQuestion;
import com.zennyt.recruitment.domain.model.FitScore;
import com.zennyt.recruitment.domain.model.JobOffer;
import com.zennyt.recruitment.domain.model.SoftSkillsProjection;
import com.zennyt.recruitment.domain.repository.AssessmentRepository;
import com.zennyt.recruitment.domain.repository.FitScoreRepository;
import com.zennyt.recruitment.domain.repository.JobOfferRepository;
import com.zennyt.recruitment.domain.repository.SoftSkillsProjectionRepository;
import com.zennyt.recruitment.domain.vo.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * Jeu de données de démo — profil {@code dev} uniquement.
 *
 * <p>Insère, au démarrage et de façon idempotente, des données cohérentes pour
 * tester l'API via Bruno/Swagger sans tout créer à la main : 3 offres ACTIVE
 * appartenant au recruteur de démo, une évaluation, et un fit score.
 *
 * <p>Les UUID sont <b>fixes</b> pour que la collection Bruno puisse les référencer
 * directement (voir {@code tooling/bruno/environments/Local.bru}).
 */
@Component
@Profile("dev")
public class DevDataSeeder implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DevDataSeeder.class);

    // ───────────── Identités de démo (mêmes valeurs que la collection Bruno) ─────────────
    public static final UUID RECRUITER = UUID.fromString("11111111-1111-1111-1111-111111111111");
    public static final UUID RECRUITER_2 = UUID.fromString("33333333-3333-3333-3333-333333333333");
    public static final UUID CANDIDATE = UUID.fromString("22222222-2222-2222-2222-222222222222");

    // ───────────── Entités de démo à UUID fixe ─────────────
    private static final UUID OFFER_1 = UUID.fromString("a0000000-0000-0000-0000-000000000001");
    private static final UUID OFFER_2 = UUID.fromString("a0000000-0000-0000-0000-000000000002");
    private static final UUID OFFER_3 = UUID.fromString("a0000000-0000-0000-0000-000000000003");
    private static final UUID ASSESSMENT_1 = UUID.fromString("b0000000-0000-0000-0000-000000000001");

    private final JobOfferRepository jobOfferRepository;
    private final AssessmentRepository assessmentRepository;
    private final FitScoreRepository fitScoreRepository;
    private final SoftSkillsProjectionRepository softSkillsRepository;

    public DevDataSeeder(JobOfferRepository jobOfferRepository,
                         AssessmentRepository assessmentRepository,
                         FitScoreRepository fitScoreRepository,
                         SoftSkillsProjectionRepository softSkillsRepository) {
        this.jobOfferRepository = jobOfferRepository;
        this.assessmentRepository = assessmentRepository;
        this.fitScoreRepository = fitScoreRepository;
        this.softSkillsRepository = softSkillsRepository;
    }

    @Override
    public void run(String... args) {
        // Idempotent : si le recruteur de démo a déjà des offres, on ne reseed pas.
        if (!jobOfferRepository.findByRecruiterId(RECRUITER, null, null, 0, 1).isEmpty()) {
            log.info("[DevDataSeeder] Données de démo déjà présentes — seeding ignoré.");
            return;
        }

        // L'offre 1 est liée à l'évaluation de démo (assessmentId non null).
        JobOffer offer1 = activeOffer(OFFER_1, "Senior Backend Engineer",
            "Conception et développement de microservices Java/Spring.",
            ContractType.FULL_TIME, WorkplaceType.REMOTE, ExperienceLevel.MID, "Tunis");
        offer1.assignAssessment(ASSESSMENT_1);
        jobOfferRepository.save(offer1);
        jobOfferRepository.save(activeOffer(OFFER_2, "UX/UI Designer",
            "Conception d'interfaces mobiles et design system.",
            ContractType.FULL_TIME, WorkplaceType.HYBRID, ExperienceLevel.JUNIOR, "Paris"));
        // L'offre 3 appartient au 2e recruteur (Youssef) : support des tests négatifs
        // Bruno 51/54 (offre étrangère → 403), comme le seed REC-04 d'origine.
        jobOfferRepository.save(activeOffer(OFFER_3, RECRUITER_2, "Engineering Manager",
            "Encadrement d'une squad produit de 6 personnes.",
            ContractType.FULL_TIME, WorkplaceType.ON_SITE, ExperienceLevel.EXECUTIVE, "Lyon"));

        assessmentRepository.save(Assessment.rehydrate(ASSESSMENT_1, RECRUITER,
            "Test technique back-end", 600, 2, null, null,
            List.of(
                new AssessmentQuestion(
                    "Quel outil est un système de contrôle de version ?",
                    List.of("Docker", "Git", "Jenkins", "Node.js"), 1),
                new AssessmentQuestion(
                    "Quel langage tourne sur la JVM ?",
                    List.of("Java", "Python", "Ruby", "Go"), 0)),
            Instant.now(), Instant.now()));

        fitScoreRepository.save(FitScore.rehydrate(
            UUID.fromString("c0000000-0000-0000-0000-000000000001"),
            CANDIDATE, OFFER_1, 87, 82, 91, null, 100, Instant.now()));

        // Projections soft skills des candidats de démo : sans elles, aucune paire
        // candidat×offre n'existe pour le recalcul des fit scores (les projections
        // réelles arrivent via les événements du module Games).
        softSkillsRepository.save(SoftSkillsProjection.create(CANDIDATE, "MOVE_FAST", 85, Instant.now()));
        softSkillsRepository.save(SoftSkillsProjection.create(
            UUID.fromString("44444444-4444-4444-4444-444444444444"), "MOVE_FAST", 58, Instant.now()));
        softSkillsRepository.save(SoftSkillsProjection.create(
            UUID.fromString("55555555-5555-5555-5555-555555555555"), "MOVE_FAST", 74, Instant.now()));

        log.info("""
            [DevDataSeeder] Données de démo insérées :
              Recruteur : {}
              Candidat  : {}
              Offres ACTIVE : {}, {}, {}
              Évaluation : {}
            """, RECRUITER, CANDIDATE, OFFER_1, OFFER_2, OFFER_3, ASSESSMENT_1);
    }

    /** Construit une offre directement en statut ACTIVE (visible dans le feed candidat). */
    private JobOffer activeOffer(UUID id, String title, String description,
                                 ContractType contract, WorkplaceType workplace,
                                 ExperienceLevel level, String city) {
        return activeOffer(id, RECRUITER, title, description, contract, workplace, level, city);
    }

    private JobOffer activeOffer(UUID id, UUID recruiterId, String title, String description,
                                 ContractType contract, WorkplaceType workplace,
                                 ExperienceLevel level, String city) {
        Instant now = Instant.now();
        return JobOffer.rehydrate(
            id, recruiterId, null, title,
            new Location(city, "TN"), 40000.0, 70000.0,
            contract, workplace, level,
            description,
            "Responsabilités à définir.", "Bac+5 ou équivalent.", "Expérience en équipe agile.",
            "Package compétitif, télétravail, formation.", "Postulez via l'application.",
            null, null, false, JobOfferStatus.ACTIVE, now, now);
    }
}
