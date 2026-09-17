package com.zennyt.architecture;

import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Le endpoint public {@code GET /api/v1/tests/{token}} est déclaré public au
 * niveau du contrat recruitment (§5.7) et de l'annotation du contrôleur, mais il
 * restait bloqué en 401 par le filtre global — roadmap RECRUITMENT_MODULE.md
 * §15.2. Ce garde-fou verrouille la règle de permit-list pour qu'une régression
 * de SecurityConfig ne referme pas silencieusement le lien public.
 *
 * <p>Le permit est volontairement borné au segment unique {@code /tests/*}
 * (exactement {@code GET /tests/{token}} du contrat) : le double joker
 * {@code /tests/**} ouvrait aussi tout sous-chemin, plus large que le contrat.
 */
class PublicTestPermitRuleTest {

    @Test
    void globalSecurityPermitsPublicTestGet() throws IOException {
        String source = readSecurityConfig();

        assertThat(source)
            .as("GET /api/v1/tests/* (segment unique) doit rester dans la permit-list")
            .contains(".requestMatchers(HttpMethod.GET, \"/api/v1/tests/*\").permitAll()");
    }

    @Test
    void globalSecurityDoesNotPermitTestSubPaths() throws IOException {
        String source = readSecurityConfig();

        assertThat(source)
            .as("Le double joker /api/v1/tests/** est interdit : le contrat n'expose "
                + "que GET /tests/{token}, pas de sous-chemins")
            .doesNotContain("/api/v1/tests/**");
    }

    private static String readSecurityConfig() throws IOException {
        Path config = Path.of("src/main/java/com/zennyt/shared/infrastructure/config/SecurityConfig.java");
        if (!Files.exists(config)) {
            config = Path.of("backend/src/main/java/com/zennyt/shared/infrastructure/config/SecurityConfig.java");
        }
        assertThat(config).exists();
        return Files.readString(config).replaceAll("\\s+", " ");
    }
}
