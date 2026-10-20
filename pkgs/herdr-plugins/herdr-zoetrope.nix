{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  bash,
  coreutils,
  gawk,
  gnugrep,
  gnused,
  jq,
  procps,
}: let
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "furkankly";
    repo = "zoetrope";
    rev = "v${version}";
    hash = "sha256-jfzbgtZNIbDyHpXqP5QxF9o71zdYKEbY862NIaPHujo=";
  };

  zoetrope = rustPlatform.buildRustPackage {
    pname = "zoetrope";
    inherit version src;
    cargoHash = "sha256-6k+f07IusOyTudHsiOsBQGg00gd6NGP7nJU51inlfxU=";

    # Finds none of the Codex fixture's files when run from the Nix sandbox.
    checkFlags = ["--skip=provider::tests::open_finds_every_file_of_a_fixture_session"];
    preCheck = ''
      export HOME=$(mktemp -d)
    '';

    meta.mainProgram = "zoe";
  };
in
  mkHerdrPlugin {
    pname = "herdr-zoetrope";
    inherit version src;
    pluginRoot = "herdr-plugin";

    # The scripts expect `zoe` on PATH; the [[build]] hook only checks for it.
    runtimeInputs = [bash coreutils gawk gnugrep gnused jq procps zoetrope];

    postInstall = ''
      rm $out/herdr/ensure-zoe.sh
      cp ${src}/LICENSE $out/
    '';

    passthru = {inherit zoetrope;};

    meta = {
      homepage = "https://github.com/furkankly/zoetrope";
      changelog = "https://github.com/furkankly/zoetrope/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
