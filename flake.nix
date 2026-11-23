{
  description = "Velomine dev environment (CachyOS + Nix)";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      # x86_64 Linux only: the Claude Code manifest and extension hashes below are linux-x64.
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          # Only the unfree packages the shell and `vscode` use, so a new one never slips in
          # unnoticed. androidenv names each Android part twice (`android-sdk-ndk` and `ndk`).
          allowUnfreePredicate =
            pkg:
            let
              name = nixpkgs.lib.getName pkg;
            in
            builtins.elem name [
              "claude-code"
              "vscode"
              "vscode-extension-anthropic-claude-code"
              "vscode-extension-ms-dotnettools-csdevkit"
              "build-tools"
              "cmake"
              "cmdline-tools"
              "emulator"
              "ndk"
              "platforms"
              "platform-tools"
              "tools"
            ]
            || nixpkgs.lib.hasPrefix "android-sdk-" name
            || nixpkgs.lib.hasPrefix "system-image-" name;
          android_sdk.accept_license = true;
        };
      };

      # Same Flutter release and checksum as app/Dockerfile: the official release, not nixpkgs' build, which lags
      # behind the Dart version app/pubspec.yaml needs. Bump both files together.
      flutterVersion = "3.50.0";
      flutterTarball = pkgs.fetchurl {
        url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${flutterVersion}-stable.tar.xz";
        sha256 = "6ea2d806fd57269ae783e6788e2a81fc26eaad782f1e0d0ff38623bb765ff9f5";
      };

      # Versions Flutter 3.50's Gradle plugin asks for (compileSdk 36, NDK 28.2). Platform 35 is for the jni
      # package (dart.dev, used by shared_preferences on Android), which compiles against it.
      # androidenv pulls a system image for every platform; only the emulator's (36, see the
      # justfile) is kept, so the unused API 35 image is never downloaded.
      androidRepo = nixpkgs.lib.importJSON "${pkgs.path}/pkgs/development/mobile/androidenv/repo.json";
      android = pkgs.androidenv.composeAndroidPackages {
        repo = androidRepo // {
          images = nixpkgs.lib.filterAttrs (api: _: api == "36") androidRepo.images;
        };
        platformVersions = [
          "35"
          "36"
        ];
        buildToolsVersions = [ "36.0.0" ];
        includeNDK = true;
        ndkVersions = [ "28.2.13676358" ];
        includeCmake = true;
        cmakeVersions = [ "3.22.1" ];
        includeEmulator = true;
        includeSystemImages = true;
        systemImageTypes = [ "google_apis_playstore" ];
        abiVersions = [ "x86_64" ];
      };
      androidSdk = "${android.androidsdk}/libexec/android-sdk";
      dotnet = pkgs.dotnetCorePackages.sdk_10_0;
      nodejs = pkgs.nodejs_24; # ponytail hooks and sentry-mcp; pinned so an LTS bump is a deliberate change

      # Claude Code from Anthropic's release manifest, ahead of nixpkgs. To update, take the
      # version from https://downloads.claude.ai/claude-code-releases/latest and the
      # linux-x64 checksum from <that URL's folder>/<version>/manifest.zst.json. Drop this
      # override once nixpkgs' claude-code is at least this version.
      claudeCode = pkgs.claude-code.override {
        manifest = {
          version = "2.1.322";
          platforms.linux-x64 = {
            binary = "claude.zst";
            checksum = "9bb7558bd992ca457e6458bf1686572f7a3156b8331dd8443391dbfe590c1eed";
          };
        };
      };

      # The VS Code extension at the same version as the CLI above (it bundles its own binary).
      # Update both together; the hash is the Marketplace VSIX for linux-x64.
      claudeCodeExtension = pkgs.vscode-extensions.anthropic.claude-code.overrideAttrs (_: {
        inherit (claudeCode) version;
        src = pkgs.vscode-utils.fetchVsixFromVscodeMarketplace {
          name = "claude-code";
          publisher = "anthropic";
          arch = "linux-x64";
          inherit (claudeCode) version;
          hash = "sha256-5y+nUr4ZNdkzOXwYvbqDrj1KZ+x2zeWoQuh+Wh1aHPQ=";
        };
      });

      # Local stdio Sentry MCP for Pi (.pi/mcp.json), read-only skills; Claude Code uses
      # the hosted server in .mcp.json. npx pins the package version; upgrade it deliberately.
      sentryMcpVersion = "0.49.0";
      sentryMcp = pkgs.writeShellApplication {
        name = "sentry-mcp";
        runtimeInputs = [ nodejs ];
        text = ''
          export MCP_SKILLS="''${MCP_SKILLS:-inspect,triage}"
          exec npx --yes @sentry/mcp-server@${sentryMcpVersion} "$@"
        '';
      };

      # Scaleway's own MCP server (built into the Scaleway CLI), read-only by
      # design: only get/list commands, and only the hosting namespaces. It uses
      # the CLI profile named by SCW_PROFILE (default velomine-readonly), which
      # the developer creates with `scw init -p velomine-readonly` from a
      # least-privilege IAM application. Never the account key; never committed.
      scalewayMcp = pkgs.writeShellApplication {
        name = "scw-mcp";
        runtimeInputs = [ pkgs.scaleway-cli ];
        text = ''
          exec scw -p "''${SCW_PROFILE:-velomine-readonly}" mcp server serve \
            read-only=true namespaces=instance,rdb,dns,object,iam,registry,vpc "$@"
        '';
      };

      # VS Code with the project's extensions, using the same Microsoft build as the
      # host package. Run it with `nix run .#vscode`.
      vscode = pkgs.vscode-with-extensions.override {
        vscode = pkgs.vscode;
        vscodeExtensions = [
          claudeCodeExtension
          pkgs.vscode-extensions.dart-code.flutter
          pkgs.vscode-extensions.jnoortheen.nix-ide
          pkgs.vscode-extensions.mkhl.direnv
          pkgs.vscode-extensions.ms-dotnettools.csdevkit
        ];
      };
    in
    {
      formatter.${system} = pkgs.nixfmt;

      packages.${system} = {
        inherit
          vscode
          sentryMcp
          scalewayMcp
          claudeCode
          ;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [
          # server
          dotnet

          # app
          android.androidsdk
          pkgs.jdk17 # Gradle 9 / AGP 9 need Java 17+; CI pins the same (ci.yml); also runs the OpenAPI generator JAR

          # AI coding agents and the tooling they share.
          # Agent plugins are recommended, not pinned here: ponytail
          # (@dietrichgebert/ponytail, configured in .claude/settings.json and
          # .pi/settings.json) and the official Flutter agent plugin
          # (Flutter/Dart skills plus the `dart mcp-server` MCP server used by
          # .mcp.json and .pi/mcp.json). Install them per agent; see
          # docs/development.md.
          claudeCode # the only Claude Code install: no host copy, no self-update
          nodejs # ponytail's Claude Code hooks
          pkgs.codegraph
          pkgs.sentry-cli # releases and debug-symbol uploads
          sentryMcp # local stdio Sentry MCP for Pi
          pkgs.scaleway-cli # scw, for the read-only profile and `scw init`
          scalewayMcp # read-only Scaleway MCP (see above)
          pkgs.pi-coding-agent # Pi in the terminal (`pi`); the same setup as the Pendant extension (.pi/)

          # Flutter's own command-line needs, plus helpers
          pkgs.git
          pkgs.curl
          pkgs.unzip
          pkgs.zip
          pkgs.xz
          pkgs.which
          pkgs.just
          pkgs.nixd
        ];

        ANDROID_HOME = androidSdk;
        ANDROID_SDK_ROOT = androidSdk;
        JAVA_HOME = "${pkgs.jdk17}";
        DOTNET_ROOT = "${dotnet}/share/dotnet";
        DOTNET_CLI_TELEMETRY_OPTOUT = "1";
        DOTNET_NOLOGO = "1";
        FLUTTER_SUPPRESS_ANALYTICS = "true";

        shellHook = ''
          REPO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
          DEV="$REPO/.dev"

          # Caches and data that would otherwise land in your home folder.
          # Everything lives in .dev/ — delete that folder and it is all gone.
          export NUGET_PACKAGES="$DEV/nuget/packages"
          export NUGET_HTTP_CACHE_PATH="$DEV/nuget/http-cache"
          export DOTNET_CLI_HOME="$DEV/dotnet"
          export PUB_CACHE="$DEV/pub-cache"
          export npm_config_cache="$DEV/npm" # npx: sentry-mcp and other agent tools
          export GRADLE_USER_HOME="$DEV/gradle"
          export ANDROID_USER_HOME="$DEV/android"
          export ANDROID_AVD_HOME="$DEV/android/avd"

          # Flutter: unpack the pinned release once. It must be writable, so it can't live in /nix/store.
          FLUTTER_DIR="$DEV/flutter-${flutterVersion}"
          if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
            echo "velomine: unpacking Flutter ${flutterVersion} into .dev/ (first run only)"
            mkdir -p "$FLUTTER_DIR"
            tar -xJf ${flutterTarball} -C "$FLUTTER_DIR" --strip-components=1
          fi
          # Remove Flutter releases left behind by an earlier pin.
          for old in "$DEV"/flutter-*; do
            if [ -d "$old" ] && [ "$old" != "$FLUTTER_DIR" ]; then
              echo "velomine: removing $(basename "$old") from .dev/"
              rm -rf "$old"
            fi
          done
          export FLUTTER_ROOT="$FLUTTER_DIR"
          export PATH="$FLUTTER_DIR/bin:$PUB_CACHE/bin:$PATH"

          # Flutter web debugging uses the browser installed on your host.
          export CHROME_EXECUTABLE="$(command -v chromium || command -v google-chrome-stable || command -v google-chrome || true)"
        '';
      };
    };
}
