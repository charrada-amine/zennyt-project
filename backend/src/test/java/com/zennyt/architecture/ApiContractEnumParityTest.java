package com.zennyt.architecture;

import com.zennyt.recruitment.domain.vo.ContractType;
import com.zennyt.recruitment.domain.vo.ExperienceLevel;
import com.zennyt.recruitment.domain.vo.JobProfileType;
import com.zennyt.recruitment.domain.vo.TypeEvaluationHard;
import com.zennyt.recruitment.domain.vo.WorkplaceType;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le contrat OpenAPI et les enums Java doivent déclarer exactement les mêmes valeurs.
 *
 * <p>Né du renommage des niveaux d'expérience (tâche F31) : {@code experienceLevel}
 * a changé de valeurs, et rien n'aurait signalé un oubli côté contrat. Un écart y est
 * particulièrement traître, parce qu'il ne casse pas au démarrage — il produit un
 * <b>400 à l'exécution</b> sur une valeur pourtant valide côté serveur, ou pire, laisse
 * passer une valeur que le serveur interprète autrement.
 *
 * <p>Les contextes {@code identity}, {@code engagement} et {@code analytics} n'utilisent
 * aucun de ces enums, et aucun événement sortant de {@code recruitment} ne les transporte
 * (vérifié le 2026-08-06) : le contrat HTTP est donc le seul point de contact à protéger.
 */
class ApiContractEnumParityTest {

    private static final Path CONTRACT = Path.of("..", "contracts", "recruitment.openapi.yaml");

    @Test
    @DisplayName("ExperienceLevel — l'échelle du CdC est la même dans le code et au contrat")
    void experienceLevelParity() throws IOException {
        assertContractEnumMatches("ExperienceLevel", ExperienceLevel.values());

        // Verrouille aussi l'ORDRE : la pondération dépend du rang de la bande, pas
        // seulement de son nom. C'est exactement ce que V29 avait déplacé sans le voir.
        assertThat(Arrays.stream(ExperienceLevel.values()).map(Enum::name).toList())
            .containsExactly("JUNIOR", "SENIOR", "LEAD", "MANAGER");
    }

    @Test
    @DisplayName("Les autres enums métier du contrat restent alignés")
    void autresEnumsParity() throws IOException {
        assertContractEnumMatches("JobProfileType", JobProfileType.values());
        assertContractEnumMatches("TypeEvaluationHard", TypeEvaluationHard.values());
        assertContractEnumMatches("ContractType", ContractType.values());
        assertContractEnumMatches("WorkplaceType", WorkplaceType.values());
    }

    private void assertContractEnumMatches(String schemaName, Enum<?>[] javaValues) throws IOException {
        List<String> attendu = Arrays.stream(javaValues).map(Enum::name).sorted().toList();
        assertThat(contractEnumValues(schemaName))
            .as("enum %s : le contrat OpenAPI et l'enum Java doivent declarer les memes valeurs", schemaName)
            .containsExactlyElementsOf(attendu);
    }

    /** Lit {@code enum: [A, B, C]} sous le schéma nommé, quel que soit le reste du bloc. */
    private List<String> contractEnumValues(String schemaName) throws IOException {
        String yaml = Files.readString(CONTRACT);
        Matcher schema = Pattern.compile(
                "^ {4}" + Pattern.quote(schemaName) + ":\\s*$(.*?)(?=^ {4}\\w)",
                Pattern.MULTILINE | Pattern.DOTALL)
            .matcher(yaml);
        assertThat(schema.find())
            .as("le schema %s doit exister dans recruitment.openapi.yaml", schemaName)
            .isTrue();

        Matcher values = Pattern.compile("enum:\\s*\\[([^\\]]+)]").matcher(schema.group(1));
        assertThat(values.find())
            .as("le schema %s doit declarer une liste enum", schemaName)
            .isTrue();

        return Arrays.stream(values.group(1).split(","))
            .map(String::trim)
            .sorted()
            .toList();
    }
}
