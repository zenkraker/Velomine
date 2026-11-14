# syntax=docker/dockerfile:1.7
# check=skip=FromPlatformFlagConstDisallowed
# The web image: the Flutter web app and the presentation site, served by nginx, which forwards /api, /health and
# /openapi to the server. Build it from the repository root:  docker build -f app/Dockerfile .
#
# Flutter's official release, pinned by version and checksum (tools/check-versions.sh keeps flake.nix in step). It only
# exists for Linux x64; its output is plain files, so on an Apple Silicon host this stage runs emulated.
FROM --platform=linux/amd64 mcr.microsoft.com/dotnet/sdk:10.0@sha256:212fe4cb74627d5adf9817a4088906ae3edff1bd853bb27565d4b46731efe61e AS build
ARG FLUTTER_VERSION=3.50.0
ARG FLUTTER_SHA256=6ea2d806fd57269ae783e6788e2a81fc26eaad782f1e0d0ff38623bb765ff9f5
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
# Packages stay in the layer, not in a cache mount: CI restores layers from its cache but not cache mounts, so a cached
# `pub get` with an empty mount would leave the build below without its packages.
RUN flutter pub get --enforce-lockfile
COPY app/lib lib
COPY app/assets assets
COPY app/web web
RUN flutter build web --release --no-web-resources-cdn \
    && find build/web -name '*.map' -delete

# The official nginx image, as the unprivileged nginx user, on port 8080. It writes only to /tmp.
FROM nginx:1.30.6-alpine@sha256:583b7f2fce1cdb8da5ad5c39ebd3c33b98b87d493190e548bdee1fa8c619c311 AS runtime
ARG VERSION=0.0.0
ARG REVISION=unknown
COPY app/nginx.conf /etc/nginx/nginx.conf
COPY site /srv/site
COPY --from=build /src/app/build/web /srv/app
# The build this image is, at /version.json, as the server reports its own at /api/v1/server.
RUN printf '{"version":"%s","revision":"%s"}\n' "$VERSION" "$REVISION" > /srv/app/version.json
LABEL org.opencontainers.image.title="Velomine web" \
      org.opencontainers.image.description="Velomine web app and presentation site" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.source="https://github.com/zenkraker/Velomine"
USER nginx
EXPOSE 8080
STOPSIGNAL SIGQUIT
# nginx directly, without the image's entrypoint scripts: they rewrite files the read-only root does not allow.
ENTRYPOINT ["nginx", "-g", "daemon off;"]
