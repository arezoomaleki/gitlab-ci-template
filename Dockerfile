# Stage 1: Build
FROM [REPOSITORY_URL]/dotnet/sdk:8.0 AS build-env
ARG PROJECT=[PROJECT_NAME]
ENV PROJECT_ENV=$PROJECT
WORKDIR /app


# Copy only the necessary files for restore (optimizing cache use)
COPY nuget.config ./
COPY ./$PROJECT_ENV/*.csproj ./
RUN dotnet restore



# Copy the rest of the application files
COPY ./$PROJECT_ENV/* ./
RUN dotnet publish -c Release -o out


# Stage 2: Runtime
FROM [REPOSITORY_URL]/dotnet/aspnet:8.0
ARG PROJECT=[PROJECT_NAME]
ENV PROJECT_ENV=$PROJECT TZ=[TIMEZONE]
WORKDIR /app
COPY --from=build-env /app/out ./

# Minimize the number of layers and optimize for cache use
RUN apt-get update && \
    apt-get install -y libunwind8 ca-certificates && \
    update-ca-certificates --fresh 2>/dev/null || true && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ > /etc/timezone

ENTRYPOINT dotnet "$PROJECT_ENV".dll
