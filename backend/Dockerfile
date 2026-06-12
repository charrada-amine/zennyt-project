# syntax=docker/dockerfile:1.7
# ─────────────────────────────────────────────────────────────
# Stage 1 — Build (Maven + JDK 21)
# ─────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /workspace

# Copier d'abord les descripteurs Maven pour profiter du cache de couches :
# tant que pom.xml ne change pas, les dépendances ne sont pas re-téléchargées.
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN --mount=type=cache,target=/root/.m2 ./mvnw dependency:go-offline -B

# Copier le code source et compiler
COPY src/ src/
RUN --mount=type=cache,target=/root/.m2 ./mvnw clean package -DskipTests -B \
    && java -Djarmode=layertools -jar target/*.jar extract --destination target/extracted

# ─────────────────────────────────────────────────────────────
# Stage 2 — Runtime (JRE seul, image minimale)
# ─────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

# Utilisateur non-root pour la sécurité
RUN addgroup -S spring && adduser -S spring -G spring -u 1000
USER spring:spring

# Copier les couches Spring Boot séparément (meilleur cache au redéploiement)
ARG EXTRACTED=/workspace/target/extracted
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
