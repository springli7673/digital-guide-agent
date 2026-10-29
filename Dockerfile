# 应用镜像（可选）。依赖用 docker-compose.yml 单独起。
#
#   docker build -t digital-guide-agent .
#   docker run --rm -p 8080:8080 \
#     -e DEEPSEEK_API_KEY=sk-xxx \
#     -e SPRING_DATASOURCE_URL='jdbc:postgresql://host.docker.internal:5432/digital_guide?stringtype=unspecified' \
#     -e AI_EMBEDDING_BASEURL=http://host.docker.internal:11434 \
#     digital-guide-agent
#
# 注意 host.docker.internal：容器里的 127.0.0.1 是容器自己，连不到宿主的 pg/ollama。

FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# 先只拷 pom 拉依赖，改代码时能命中缓存
COPY backend/pom.xml ./
RUN mvn -B -q dependency:go-offline

COPY backend/src ./src
RUN mvn -B -q -DskipTests package

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app/app.jar"]
