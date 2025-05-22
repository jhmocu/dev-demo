FROM openjdk:17-jdk

WORKDIR /app

COPY app.jar app.jar

EXPOSE 80

ENTRYPOINT ["java", "-jar", "app.jar"]