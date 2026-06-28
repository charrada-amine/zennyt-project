# syntax=docker/dockerfile:1.7
# ─────────────────────────────────────────────────────────────
# IMPORTANT : le contexte de build est la RACINE du projet (zennyt-project/),
# car le build Maven lit les contrats OpenAPI dans ../contracts (openapi-generator).
# Construire avec :
#   docker build -f backend/Dockerfile -t zennyt-backend .
# (le « . » final = racine du dépôt, pas le dossier backend/)
# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# Stage 1 — Build (Maven + JDK 21)
# ─────────────────────────────────────────────────────────────
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /workspace

# Les contrats sont requis par openapi-generator (backend/pom.xml référence ../contracts).
COPY contracts/ contracts/

# Descripteur Maven d'abord : tant que pom.xml ne change pas, les dépendances
# restent en cache de couche et ne sont pas re-téléchargées.
COPY backend/pom.xml backend/pom.xml
RUN --mount=type=cache,target=/root/.m2 mvn -f backend/pom.xml dependency:go-offline -B

# Code source puis build. Les tests tournent dans la CI, pas dans l'image.
COPY backend/src backend/src
RUN --mount=type=cache,target=/root/.m2 mvn -f backend/pom.xml clean package -DskipTests -B \
    && java -Djarmode=layertools -jar backend/target/*.jar extract \
       --destination backend/target/extracted

# ─────────────────────────────────────────────────────────────
# Stage 2 — Runtime (JRE seul, image minimale)
# ─────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

# Utilisateur non-root pour la sécurité
RUN addgroup -S spring && adduser -S spring -G spring -u 1000
USER spring:spring

# Copier les couches Spring Boot séparément (meilleur cache au redéploiement)
ARG EXTRACTED=/workspace/backend/target/extracted
COPY --from=build --chown=spring:spring ${EXTRACTED}/dependencies/ ./
COPY --from=build --chown=spring:spring ${EXTRACTED}/spring-boot-loader/ ./
COPY --from=build --chown=spring:spring ${EXTRACTED}/snapshot-dependencies/ ./
COPY --from=build --chown=spring:spring ${EXTRACTED}/application/ ./

# Port exposé (App Service le mappe automatiquement via WEBSITES_PORT)
EXPOSE 8080

# Réglages JVM adaptés aux conteneurs : la JVM lit les limites du conteneur
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+UseG1GC -XX:+ExitOnOutOfMemoryError"

# Endpoint de santé utilisé par App Service (health check) et les smoke tests
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health | grep -q UP || exit 1

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
