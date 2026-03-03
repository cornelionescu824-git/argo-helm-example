FROM --platform=linux/amd64 eclipse-temurin:8-jre-alpine
WORKDIR /app

COPY target/simple-api-1.0.0.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
