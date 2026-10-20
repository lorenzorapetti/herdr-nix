{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  bash,
  coreutils,
}: let
  version = "0.3.1";

  src = fetchFromGitHub {
    owner = "aemrebarut";
    repo = "herdr-dagr";
    rev = "v${version}";
    hash = "sha256-Xuo9fklI6Xda3jykFIrF+Ag0CVKqOtdG6v1+LZTLSr0=";
  };

  # Upstream downloads the release binary into bin/ from a [[build]] hook,
  # which `herdr plugin link` doesn't run; build it from source instead.
  herdr-dagr-bin = rustPlatform.buildRustPackage {
    pname = "herdr-dagr-bin";
    inherit version src;
    cargoHash = "sha256-s322rAgZQktgowcnmgDhAh7dek/GKlvDwCk5NaU7VJw=";

    meta.mainProgram = "dagr";
  };
in
  mkHerdrPlugin {
    pname = "herdr-dagr";
    inherit version src;

    # The pane runs `/bin/sh -c 'exec …/bin/dagr view'`, which needs nothing.
    runtimeInputs = [bash coreutils];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name scripts ! -name skills ! -name LICENSE-MIT \
        ! -name LICENSE-APACHE ! -name README.md \
        -exec rm -rf {} +
      find $out/scripts -mindepth 1 ! -name open-dagr.sh -delete

      mkdir -p $out/bin
      ln -s ${lib.getExe herdr-dagr-bin} $out/bin/dagr
    '';

    passthru = {inherit herdr-dagr-bin;};

    meta = {
      homepage = "https://github.com/aemrebarut/herdr-dagr";
      license = with lib.licenses; [mit asl20];
    };
  }
