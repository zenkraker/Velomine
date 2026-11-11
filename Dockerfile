# syntax=docker/dockerfile:1.7
# The server image: the .NET API and the background services, and no front-end. The web app and the presentation site
# are in the web image (app/Dockerfile), which forwards /api, /health and /openapi here.

# Build stage: restore from lock files first so the layer is cached until packages change.
FROM mcr.microsoft.com/dotnet/sdk:10.0@sha256:212fe4cb74627d5adf9817a4088906ae3edff1bd853bb27565d4b46731efe61e AS build
WORKDIR /src
COPY Directory.Build.props Directory.Packages.props ./
COPY src/Velomine.Server/Velomine.Server.csproj src/Velomine.Server/packages.lock.json src/Velomine.Server/
# Packages stay in the layer, not in a cache mount: CI restores layers from its cache but not cache mounts, so a cached
# restore with an empty mount would leave the publish below without its packages.
RUN dotnet restore src/Velomine.Server/Velomine.Server.csproj --locked-mode
COPY src/Velomine.Server src/Velomine.Server
# VERSION and REVISION reach the assembly, so GET /api/v1/server, logs and Sentry report the running build (BuildInfo.cs).
# Declared here, after the restore, so a new commit does not invalidate the restored packages.
ARG VERSION=0.0.0
ARG REVISION=
RUN dotnet publish src/Velomine.Server/Velomine.Server.csproj \
    -c Release -p:ContinuousIntegrationBuild=true -p:UseAppHost=false \
    -p:Version="${VERSION}" -p:SourceRevisionId="${REVISION}" -o /app --no-restore

# Alpine runtime: smaller than the Debian image, with the ICU data and time
# zones the app needs for Italian/English formatting and member time zones.
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine@sha256:486297ae006e95ee2ee3112a2c03e3d26e41fbbc64b7a29e28e7a18cc36b12bb AS runtime
ARG VERSION=0.0.0
ARG REVISION=unknown
WORKDIR /app
COPY --from=build /app .
RUN apk add --no-cache icu-libs icu-data-full tzdata ca-certificates \
    && mkdir -p /data/files /data/keys \
    && chown app:app /data/files /data/keys
LABEL org.opencontainers.image.title="Velomine server" \
      org.opencontainers.image.description="Cycling club training platform" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.source="https://github.com/zenkraker/Velomine"
USER app
ENV ASPNETCORE_HTTP_PORTS=8080 \
    Velomine__FilesPath=/data/files \
    Velomine__DataProtection__KeysPath=/data/keys \
    TZ=UTC \
    DOTNET_gcServer=0 \
    DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
STOPSIGNAL SIGTERM
EXPOSE 8080
ENTRYPOINT ["dotnet", "Velomine.Server.dll"]
