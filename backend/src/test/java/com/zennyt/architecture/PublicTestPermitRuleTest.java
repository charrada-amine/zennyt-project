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
 */
class PublicTestPermitRuleTest {

    @Test
    void globalSecurityPermitsPublicTestGet() throws IOException {
        Path config = Path.of("src/main/java/com/zennyt/shared/infrastructure/config/SecurityConfig.java");
        if (!Files.exists(config)) {
            config = Path.of("backend/src/main/java/com/zennyt/shared/infrastructure/config/SecurityConfig.java");
        }
        assertThat(config).exists();

        String source = Files.readString(config).replaceAll("\\s+", " ");
        assertThat(source)
            .as("GET /api/v1/tests/** must stay in the permitAll list")
            .contains(".requestMatchers(HttpMethod.GET, \"/api/v1/tests/**\").permitAll()");
    }
}
