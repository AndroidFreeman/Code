# Use an official Gradle image to build the Spring Boot app
FROM gradle:8.6-jdk21 AS build
WORKDIR /app
# Copy the gradle configuration files
COPY build.gradle settings.gradle ./
# Copy the source code
COPY src ./src
# Build the application (skipping tests for faster deployment)
RUN gradle bootJar -x test

# Use a lightweight JRE image for running the app
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
# Copy the built jar from the build stage
COPY --from=build /app/build/libs/*.jar app.jar
# Expose the application port
EXPOSE 8080
# Set active profile to 'prod' to use MariaDB and Redis as configured in application.yml
ENV SPRING_PROFILES_ACTIVE=prod
# Run the application
ENTRYPOINT ["java", "-jar", "app.jar"]