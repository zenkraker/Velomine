# check=skip=FromPlatformFlagConstDisallowed
# (The web stage below is pinned to linux/amd64 on purpose; see the comment there.)
# Web app: Flutter's official release, pinned by version and checksum, on the same Microsoft image as the server build.
# The Flutter release only exists for Linux x64. Its output is plain web files, so on an Apple Silicon host this one
# stage runs emulated and the server image is still built and run natively.
FROM --platform=linux/amd64 mcr.microsoft.com/dotnet/sdk:10.0 AS web
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
RUN flutter pub get --enforce-lockfile
COPY app/lib lib
COPY app/web web
# Bundle the rendering engine instead of fetching it from Google's CDN: no third-party calls, and it works offline.
RUN flutter build web --release --no-web-resources-cdn

# Build stage: restore from lock files first so the layer is cached until packages change.
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY Directory.Build.props Directory.Packages.props ./
COPY src/Velomine.Server/Velomine.Server.csproj src/Velomine.Server/packages.lock.json src/Velomine.Server/
RUN dotnet restore src/Velomine.Server/Velomine.Server.csproj --locked-mode
COPY src/Velomine.Server src/Velomine.Server
RUN dotnet publish src/Velomine.Server/Velomine.Server.csproj -c Release -o /app --no-restore

FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app
COPY --from=build /app .
COPY --from=web /src/app/build/web ./wwwroot
# The aspnet image ships a non-root "app" user; files live on a volume it can write to.
RUN mkdir -p /data/files /data/keys && chown app /data/files /data/keys
USER app
ENV ASPNETCORE_HTTP_PORTS=8080 \
    Velomine__FilesPath=/data/files
EXPOSE 8080
ENTRYPOINT ["dotnet", "Velomine.Server.dll"]
