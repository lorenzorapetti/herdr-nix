{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
}: let
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "yuk1ty";
    repo = "herdr-spreader";
    rev = "v${version}";
    hash = "sha256-nPuL1MUsMpgJYi0rPPBUdffp/SrI7T1fDkQBBVq/QZY=";
  };

  # Upstream's [[build]] step runs `cargo build --release`, which
  # `herdr plugin link` doesn't run; build it here instead.
  herdr-spreader-bin = rustPlatform.buildRustPackage {
    pname = "herdr-spreader-bin";
    inherit version src;
    cargoHash = "sha256-44CbUeR1OBm9oGUf+xTMPKCebTGcvrrDA6ZjskWm8Ug=";

    meta.mainProgram = "herdr-spreader";
  };
in
  mkHerdrPlugin {
    pname = "herdr-spreader";
    inherit version src;

    # Every entry point runs ./target/release/herdr-spreader directly.
    wrapCommands = [];

    settingsFile = "config.yaml";

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name examples ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +

      mkdir -p $out/target/release
      ln -s ${lib.getExe herdr-spreader-bin} $out/target/release/herdr-spreader
    '';

    passthru = {inherit herdr-spreader-bin;};

    meta = {
      homepage = "https://github.com/yuk1ty/herdr-spreader";
      changelog = "https://github.com/yuk1ty/herdr-spreader/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
