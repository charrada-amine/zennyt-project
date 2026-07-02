package com.zennyt.architecture;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.library.Architectures;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

/**
 * Tests d'architecture — transforment les règles DDD en garanties automatiques.
 *
 * <p>Ces tests échouent à la CI si quelqu'un viole l'isolation des bounded
 * contexts ou les dépendances de l'architecture hexagonale. C'est ce qui
 * empêche le monolithe modulaire de dégénérer en "big ball of mud" et garde
 * le découpage futur en microservices peu coûteux.
 */
class ArchitectureTest {

    private static JavaClasses classes;

    @BeforeAll
    static void importClasses() {
        classes = new ClassFileImporter()
            .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
            .importPackages("com.zennyt");
    }

    /**
     * Règle d'or : un bounded context ne dépend pas du DOMAINE d'un autre.
     * Seule exception tolérée : écouter les Domain Events publiés (package event),
     * ce qui reste un couplage par contrat d'événement, pas par modèle interne.
     */
    @Test
    void boundedContextsDoNotDependOnEachOthersInternals() {
        for (String ctx : new String[]{"identity", "recruitment", "engagement", "analytics", "games"}) {
            noClasses()
                .that().resideInAPackage("..%s..".formatted(ctx))
                .should().dependOnClassesThat()
                .resideInAnyPackage(otherContextInternals(ctx))
                .because("Les contextes communiquent par Domain Events, jamais par appel direct au modèle interne")
                .check(classes);
        }
    }

    /**
     * Architecture hexagonale : le domaine ne dépend ni de l'application,
     * ni de l'infrastructure, ni du web. Il est au centre.
     */
    @Test
    void domainDoesNotDependOnOuterLayers() {
        Architectures.layeredArchitecture()
            .consideringOnlyDependenciesInLayers()
            .layer("Domain").definedBy("..domain..")
            .layer("Application").definedBy("..application..")
            .layer("Infrastructure").definedBy("..infrastructure..")
            .layer("Api").definedBy("..api..")
            .whereLayer("Api").mayNotBeAccessedByAnyLayer()
            .whereLayer("Infrastructure").mayOnlyBeAccessedByLayers("Api")
            .whereLayer("Application").mayOnlyBeAccessedByLayers("Api", "Infrastructure")
            .whereLayer("Domain").mayOnlyBeAccessedByLayers("Application", "Infrastructure", "Api")
            .check(classes);
    }

    /** Le domaine ne doit pas dépendre de Spring (pureté du modèle métier). */
    @Test
    void domainIsFrameworkAgnostic() {
        noClasses()
            .that().resideInAPackage("..domain..")
            .should().dependOnClassesThat().resideInAnyPackage(
                "org.springframework..", "jakarta.persistence..")
            .because("Le domaine doit rester du Java pur, testable sans framework")
            .check(classes);
    }

    /** Construit la liste des packages internes des AUTRES contextes (hors event). */
    private static String[] otherContextInternals(String current) {
        String[] all = {"identity", "recruitment", "engagement", "analytics", "games"};
        return java.util.Arrays.stream(all)
            .filter(c -> !c.equals(current))
            // on autorise ..<ctx>.domain.event.. (écoute d'événements) mais pas le reste du domaine/app
            .flatMap(c -> java.util.stream.Stream.of(
                "..%s.domain.model..".formatted(c),
                "..%s.domain.repository..".formatted(c),
                "..%s.domain.service..".formatted(c),
                "..%s.application..".formatted(c),
                "..%s.infrastructure..".formatted(c)))
            .toArray(String[]::new);
    }
}
