{
  description = "Velomine dev environment (CachyOS + Nix)";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          android_sdk.accept_license = true;
        };
      };

      # Same Flutter release and checksum as the Dockerfile. nixpkgs' flutter347 is 3.47.4
      # (Dart 3.13.3), but app/pubspec.yaml needs Dart ^3.13.7. Bump both files together.
      flutterVersion = "3.47.9";
      flutterTarball = pkgs.fetchurl {
        url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${flutterVersion}-stable.tar.xz";
        sha256 = "25ed8c3c29d51a7353f2a944310b478af8214920639524b19c50a19e6c044c5a";
      };

      # Versions Flutter 3.47's Gradle plugin asks for (compileSdk 36, NDK 28.2).
      android = pkgs.androidenv.composeAndroidPackages {
        platformVersions = [ "36" ];
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
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          # server
          dotnet
          pkgs.postgresql_17   # psql only; same major version as the postgres:17 container

          # app
          android.androidsdk
          pkgs.jdk17           # Gradle 9 / AGP 9 need Java 17+; also runs the OpenAPI generator JAR

          # Claude Code tooling required by CLAUDE.md
          pkgs.nodejs          # ponytail's hooks
          pkgs.codegraph

          # Flutter's own command-line needs, plus helpers
          pkgs.git pkgs.curl pkgs.unzip pkgs.zip pkgs.xz pkgs.which
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
          export GRADLE_USER_HOME="$DEV/gradle"
          export ANDROID_USER_HOME="$DEV/android"
          export ANDROID_AVD_HOME="$DEV/android/avd"
          export Velomine__FilesPath="$DEV/files"

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
