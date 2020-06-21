FROM java:8

COPY jenkins-deploy-example/target/*.jar /app.jar

VOLUME ["/logs"]

CMD ["--server.port=8081"]

EXPOSE 8081

ENTRYPOINT ["java", "-jar", "/app.jar"]
