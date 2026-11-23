# Development image for Velomine: the same pinned versions as flake.nix, without Nix.
# .NET and Node come from devcontainer features (devcontainer.json); Docker too.
# Debian 12: the last Debian with JDK 17, which flake.nix and CI pin (Debian 13 only ships 21).
FROM mcr.microsoft.com/devcontainers/base:2.2.7-debian12

# Flutter's own command-line needs, JDK 17 (Gradle 9 / AGP 9, the OpenAPI generator) and helpers.
# No browser: use `just up`, or `flutter run -d web-server` and open the forwarded port on your machine.
RUN apt-get update && apt-get install -y --no-install-recommends \
      openjdk-17-jdk-headless unzip zip xz-utils curl git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# The Docker daemon inside the container (Docker-in-Docker, for just up and Testcontainers) uses Docker's
# own nftables firewall backend: iptables fails on hosts without the legacy tables, such as CachyOS.
RUN mkdir -p /etc/docker && echo '{ "firewall-backend": "nftables" }' > /etc/docker/daemon.json

# just, the entry point for everyday commands.
ARG JUST_VERSION=1.59.0
RUN curl -fsSL "https://github.com/casey/just/releases/download/${JUST_VERSION}/just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz" \
      | tar -xz -C /usr/local/bin just

# Same Flutter release and checksum as flake.nix and app/Dockerfile. Bump all three together.
ARG FLUTTER_VERSION=3.50.0
ARG FLUTTER_SHA256=6ea2d806fd57269ae783e6788e2a81fc26eaad782f1e0d0ff38623bb765ff9f5
RUN curl -fsSL -o /tmp/flutter.tar.xz "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && echo "${FLUTTER_SHA256}  /tmp/flutter.tar.xz" | sha256sum -c - \
    && tar -xJf /tmp/flutter.tar.xz -C /opt && rm /tmp/flutter.tar.xz \
    && chown -R vscode:vscode /opt/flutter

# Android SDK: the versions flake.nix asks for (Flutter 3.50's Gradle plugin: compileSdk 36, NDK 28.2).
# Platform 35 is for the jni package. No emulator and no system image: use a phone over Wi-Fi (`just phone`).
ARG ANDROID_CMDLINE_TOOLS=13114758
ARG ANDROID_CMDLINE_TOOLS_SHA256=7ec965280a073311c339e571cd5de778b9975026cfcbe79f2b1cdcb1e15317ee
ENV ANDROID_HOME=/opt/android-sdk
RUN curl -fsSL -o /tmp/clt.zip "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS}_latest.zip" \
    && echo "${ANDROID_CMDLINE_TOOLS_SHA256}  /tmp/clt.zip" | sha256sum -c - \
    && mkdir -p "$ANDROID_HOME/cmdline-tools" && unzip -q /tmp/clt.zip -d "$ANDROID_HOME/cmdline-tools" \
    && mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" && rm /tmp/clt.zip \
    && yes | "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" --licenses > /dev/null \
    && "$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager" \
         "platform-tools" "platforms;android-35" "platforms;android-36" "build-tools;36.0.0" \
         "ndk;28.2.13676358" "cmake;3.22.1" \
    && chown -R vscode:vscode "$ANDROID_HOME"

# Scaleway CLI (`scw`), Sentry CLI and CodeGraph: the releases flake.nix pins, as checksummed release binaries.
ARG SCW_VERSION=2.62.0
ARG SCW_SHA256=7638c385c1a43a5d9022a63791769fd464e14314032a51411726f062f3053e67
RUN curl -fsSL -o /usr/local/bin/scw "https://github.com/scaleway/scaleway-cli/releases/download/v${SCW_VERSION}/scaleway-cli_${SCW_VERSION}_linux_amd64" \
    && echo "${SCW_SHA256}  /usr/local/bin/scw" | sha256sum -c - && chmod +x /usr/local/bin/scw

ARG SENTRY_CLI_VERSION=2.58.2
ARG SENTRY_CLI_SHA256=61b1c19345694ce31ac663e9875194d45f4f317f2b9134269605f810132df88b
RUN curl -fsSL -o /usr/local/bin/sentry-cli "https://github.com/getsentry/sentry-cli/releases/download/${SENTRY_CLI_VERSION}/sentry-cli-Linux-x86_64" \
    && echo "${SENTRY_CLI_SHA256}  /usr/local/bin/sentry-cli" | sha256sum -c - && chmod +x /usr/local/bin/sentry-cli

# CodeGraph ships its own Node, so it does not depend on the Node feature.
ARG CODEGRAPH_VERSION=1.6.2
ARG CODEGRAPH_SHA256=ef0af416092128fb1ccc723786000b7edf4a6971fe604acd08bf966e4f37b828
RUN curl -fsSL -o /tmp/codegraph.tar.gz "https://github.com/colbymchenry/codegraph/releases/download/v${CODEGRAPH_VERSION}/codegraph-linux-x64.tar.gz" \
    && echo "${CODEGRAPH_SHA256}  /tmp/codegraph.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/codegraph.tar.gz -C /opt && mv /opt/codegraph-linux-x64 /opt/codegraph && rm /tmp/codegraph.tar.gz
ENV PATH="/opt/codegraph/bin:${PATH}"

# The two MCP wrappers the agents start (`sentry-mcp`, `scw-mcp`): the same as `sentryMcp` and `scalewayMcp` in flake.nix.
COPY --chmod=755 wrappers/sentry-mcp wrappers/scw-mcp /usr/local/bin/
