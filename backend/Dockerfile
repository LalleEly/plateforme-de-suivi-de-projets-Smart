# ── Etape de build ──────────────────────────────────────
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY .mvn/ .mvn/
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw dependency:go-offline -B
COPY src ./src
RUN ./mvnw clean package -DskipTests -B

# ── Etape d'execution ────────────────────────────────────
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
# Render (et la plupart des PaaS) injectent le port a ecouter via $PORT ;
# server.port dans application.yml lit deja cette variable.
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
