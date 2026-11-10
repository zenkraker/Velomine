# syntax=docker/dockerfile:1.7
# check=skip=FromPlatformFlagConstDisallowed
# (The web stage below is pinned to linux/amd64 on purpose; see the comment there.)
# Web app: Flutter's official release, pinned by version and checksum, on the same Microsoft image as the server build.
# The Flutter release only exists for Linux x64. Its output is plain web files, so on an Apple Silicon host this one
# stage runs emulated and the server image is still built and run natively.
FROM --platform=linux/amd64 mcr.microsoft.com/dotnet/sdk:10.0@sha256:212fe4cb74627d5adf9817a4088906ae3edff1bd853bb27565d4b46731efe61e AS web
ARG FLUTTER_VERSION=3.47.9
ARG FLUTTER_SHA256=25ed8c3c29d51a7353f2a944310b478af8214920639524b19c50a19e6c044c5a
RUN apt-get update && apt-get install -y --no-install-recommends curl git unzip xz-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL -o /tmp/flutter.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/flutter.tar.xz -C /opt && rm /tmp/flutter.tar.xz \
    && git config --global --add safe.directory /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}" FLUTTER_SUPPRESS_ANALYTICS=true CI=true
RUN flutter config --no-analytics && flutter precache --web
WORKDIR /src/app
COPY app/pubspec.yaml app/pubspec.lock ./
COPY app/packages packages
RUN --mount=type=cache,target=/root/.pub-cache flutter pub get --enforce-lockfile
COPY app/lib lib
COPY app/web web
# The cache mount below is not a layer: .dart_tool/package_config.json points into
# /root/.pub-cache, so the build step must mount the same cache or imports fail.
RUN --mount=type=cache,target=/root/.pub-cache flutter build web --release --no-web-resources-cdn \
    && find build/web -name '*.map' -delete

# Build stage: restore from lock files first so the layer is cached until packages change.
FROM mcr.microsoft.com/dotnet/sdk:10.0@sha256:212fe4cb74627d5adf9817a4088906ae3edff1bd853bb27565d4b46731efe61e AS build
WORKDIR /src
COPY Directory.Build.props Directory.Packages.props ./
COPY src/Velomine.Server/Velomine.Server.csproj src/Velomine.Server/packages.lock.json src/Velomine.Server/
RUN --mount=type=cache,target=/root/.nuget/packages dotnet restore src/Velomine.Server/Velomine.Server.csproj --locked-mode
COPY src/Velomine.Server src/Velomine.Server
RUN --mount=type=cache,target=/root/.nuget/packages dotnet publish src/Velomine.Server/Velomine.Server.csproj \
    -c Release -p:ContinuousIntegrationBuild=true -p:UseAppHost=false -o /app --no-restore

# Alpine runtime: smaller than the Debian image, with the ICU data and time
# zones the app needs for Italian/English formatting and member time zones.
FROM mcr.microsoft.com/dotnet/aspnet:10.0-alpine@sha256:486297ae006e95ee2ee3112a2c03e3d26e41fbbc64b7a29e28e7a18cc36b12bb AS runtime
ARG VERSION=0.0.0
ARG REVISION=unknown
WORKDIR /app
COPY --from=build /app .
COPY --from=web /src/app/build/web ./wwwroot
RUN apk add --no-cache icu-libs icu-data-full tzdata ca-certificates \
    && mkdir -p /data/files /data/keys \
    && chown app:app /data/files /data/keys
LABEL org.opencontainers.image.title="Velomine" \
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
