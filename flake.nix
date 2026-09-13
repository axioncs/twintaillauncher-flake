{
  description = "Nix flake for TwintailLauncher – A multi-platform launcher for your anime games";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        inherit (pkgs) lib;

        # Version + hashes live in version.json so the update bot only
        # needs to touch one small, easy-to-parse file, never flake.nix
        # itself.
        versionInfo = builtins.fromJSON (builtins.readFile ./version.json);
        inherit (versionInfo) version;

        archSuffix =
          if system == "x86_64-linux" then "amd64"
          else if system == "aarch64-linux" then "arm64"
          else throw "unsupported system: ${system}";

        debHash = versionInfo.hashes.${archSuffix};

        runtimeDeps = with pkgs; [
          gtk3
          glib
          cairo
          pango
          gdk-pixbuf
          harfbuzz
          webkitgtk_4_1
          libsoup_3
          openssl
          vulkan-loader
          glib-networking
          libayatana-appindicator
        ];

        bashEnvScript = pkgs.writeText "twintaillauncher-bash-env" ''
          unset GIO_EXTRA_MODULES
          unset BASH_ENV
        '';

        unwrapped = pkgs.stdenv.mkDerivation {
          pname = "twintaillauncher-bin";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://github.com/TwintailTeam/TwintailLauncher/releases/download/ttl-v${version}/twintaillauncher_${version}_${archSuffix}.deb";
            hash = debHash;
          };

          nativeBuildInputs = with pkgs; [
            autoPatchelfHook
            dpkg
          ];

          buildInputs = runtimeDeps ++ (with pkgs; [ stdenv.cc.cc.lib ]);

          unpackPhase = ''
            dpkg-deb -x $src .
          '';

          installPhase = ''
            runHook preInstall

            install -Dm755 usr/bin/twintaillauncher -t "$out/bin"

            install -Dm755 usr/lib/twintaillauncher/resources/hpatchz -t "$out/lib/twintaillauncher/resources"
            install -Dm755 usr/lib/twintaillauncher/resources/reaper -t "$out/lib/twintaillauncher/resources"
            if [ -f usr/lib/twintaillauncher/resources/hkrpg_patch.dll ]; then
              install -Dm644 usr/lib/twintaillauncher/resources/hkrpg_patch.dll -t "$out/lib/twintaillauncher/resources"
            fi

            install -Dm644 usr/share/applications/twintaillauncher.desktop -t "$out/share/applications"

            for size in 32x32 128x128; do
              if [ -f "usr/share/icons/hicolor/$size/apps/twintaillauncher.png" ]; then
                install -Dm644 "usr/share/icons/hicolor/$size/apps/twintaillauncher.png" \
                  "$out/share/icons/hicolor/$size/apps/twintaillauncher.png"
              fi
            done
            if [ -f "usr/share/icons/hicolor/256x256@2/apps/twintaillauncher.png" ]; then
              install -Dm644 "usr/share/icons/hicolor/256x256@2/apps/twintaillauncher.png" \
                "$out/share/icons/hicolor/256x256@2/apps/twintaillauncher.png"
            fi

            runHook postInstall
          '';

          postFixup = ''
            mv $out/bin/twintaillauncher $out/bin/.twintaillauncher-launcher
            cat > $out/bin/twintaillauncher << 'WRAPPER'
#!/bin/sh
data="''${XDG_DATA_HOME:-$HOME/.local/share}/twintaillauncher"
chmod -f u+w "$data/hpatchz" "$data/hpatchz.exe" 2>/dev/null || true
exec "$(dirname "$0")/.twintaillauncher-launcher" "$@"
WRAPPER
            chmod +x $out/bin/twintaillauncher
          '';

          meta = {
            description = "A multi-platform launcher for your anime games (pre-built binary)";
            homepage = "https://github.com/TwintailTeam/TwintailLauncher";
            license = lib.licenses.gpl3Only;
            platforms = [ "x86_64-linux" "aarch64-linux" ];
            mainProgram = "twintaillauncher";
          };
        };
      in
      {
        packages.default = pkgs.buildFHSEnv {
          name = "twintaillauncher";
          targetPkgs =
            _:
            runtimeDeps
            ++ (with pkgs; [
              coreutils
              bash
            ])
            ++ lib.optionals (system == "x86_64-linux") (with pkgs; [
              pkgsi686Linux.glibc
              pkgsi686Linux.gcc-unwrapped.lib
            ]);
          profile = ''
            export GIO_EXTRA_MODULES=/usr/lib64/gio/modules
            export SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
            export BASH_ENV=${bashEnvScript}
          '';
          runScript = "${unwrapped}/bin/twintaillauncher";
          extraInstallCommands = ''
            mkdir -p $out/share
            ln -s ${unwrapped}/share/applications $out/share/applications 2>/dev/null || true
            ln -s ${unwrapped}/share/icons $out/share/icons 2>/dev/null || true
          '';
          meta = unwrapped.meta;
        };
      }
    );
}
