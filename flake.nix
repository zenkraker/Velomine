{
  description = "Velomine dev environment (CachyOS + Nix)";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };

      # Same Flutter release and checksum as app/Dockerfile. nixpkgs' flutter347 is 3.47.4
      # (Dart 3.13.3), but app/pubspec.yaml needs Dart ^3.13.7. Bump both files together.
      flutterVersion = "3.47.9";
      flutterTarball = pkgs.fetchurl {
        url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${flutterVersion}-stable.tar.xz";
        sha256 = "25ed8c3c29d51a7353f2a944310b478af8214920639524b19c50a19e6c044c5a";
      };

      # Versions Flutter 3.47's Gradle plugin asks for (compileSdk 36, NDK 28.2). Platform 35 is for the jni
      # package (dart.dev, used by shared_preferences on Android), which compiles against it.
      android = pkgs.androidenv.composeAndroidPackages {
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

      # nixpkgs' opencode 2.2.5 pins a stale node_modules hash, so override it until
      # nixpkgs catches up. Remove this once `nix shell nixpkgs#opencode` builds.
      opencode = pkgs.opencode.overrideAttrs (old: {
        node_modules = old.node_modules.overrideAttrs (_: {
          outputHash = "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
        });
      });

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
      claudeCodeExtension = pkgs.vscode-extensions.anthropic.claude-code.overrideAttrs (_: rec {
        version = claudeCode.version;
        src = pkgs.vscode-utils.fetchVsixFromVscodeMarketplace {
          name = "claude-code";
          publisher = "anthropic";
          arch = "linux-x64";
          inherit version;
          hash = "sha256-5y+nUr4ZNdkzOXwYvbqDrj1KZ+x2zeWoQuh+Wh1aHPQ=";
        };
      });

      # TEMPORARY: OpenCode 2 rejects the hosted Sentry MCP OAuth with a 401
      # (https://github.com/anomalyco/opencode/issues/56195). Remove this local
      # stdio wrapper and point opencode.json back at https://mcp.sentry.dev/mcp
      # once the fix ships. npx pins the package version; upgrade it deliberately.
      sentryMcpVersion = "0.49.0";
      sentryMcp = pkgs.writeShellApplication {
        name = "sentry-mcp";
        runtimeInputs = [ pkgs.nodejs ];
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

      # OpenCode V2 is not in nixpkgs' extension set yet.
      opencodeV2Extension = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "opencode-v2";
          publisher = "sst-dev";
          version = "0.1.1";
          sha256 = "sha256-11a8JaishNyy6XkTeh6s36efdt1tSNYclOdkglx8x30=";
        }
      ];

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
        ]
        ++ opencodeV2Extension;
      };
    in
    {
      formatter.${system} = pkgs.nixfmt;

      packages.${system} = {
        inherit
          opencode
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
          pkgs.jdk17 # Gradle 9 / AGP 9 need Java 17+; also runs the OpenAPI generator JAR

          # AI coding agents and the tooling they share.
          # Agent plugins are recommended, not pinned here: ponytail
          # (@dietrichgebert/ponytail, configured in opencode.json and
          # .claude/settings.json) and the official Flutter agent plugin
          # (Flutter/Dart skills plus the `dart mcp-server` MCP server used by
          # .mcp.json and opencode.json). Install them per agent; see
          # docs/development.md.
          claudeCode # the only Claude Code install: no host copy, no self-update
          pkgs.nodejs # ponytail's Claude Code hooks
          pkgs.codegraph
          pkgs.sentry-cli # releases and debug-symbol uploads
          sentryMcp # local stdio Sentry MCP (hosted OAuth is broken in OpenCode 2)
          pkgs.scaleway-cli # scw, for the read-only profile and `scw init`
          scalewayMcp # read-only Scaleway MCP (see above)
          opencode # local override (see above); alternative to Claude Code

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
          export FLUTTER_ROOT="$FLUTTER_DIR"
          export PATH="$FLUTTER_DIR/bin:$PUB_CACHE/bin:$PATH"

          # Flutter web debugging uses the browser installed on your host.
          export CHROME_EXECUTABLE="$(command -v chromium || command -v google-chrome-stable || command -v google-chrome || true)"

          (cd "$REPO" && dotnet tool restore > /dev/null 2>&1) || true
        '';
      };
    };
}
