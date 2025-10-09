FROM maven:3.8.5-openjdk-11 AS build
WORKDIR /app

COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src

RUN mvn clean package -DskipTests



FROM openjdk:11-jre-slim
WORKDIR /app

COPY --from=build /app/target/*.jar app.jar

ENV DB_HOST=10.25.10.194
ENV DB_USERNAME=obo
ENV DB_PASSWORD=obo123

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]