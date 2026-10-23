{
  lib,
  stdenv,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  pkg-config,
  bash,
  coreutils,
  curl,
  git,
  gnused,
  jq,
  onnxruntime,
  openssl,
}: let
  version = "0.31.0";

  src = fetchFromGitHub {
    owner = "nicosuave";
    repo = "memex";
    rev = "v${version}";
    hash = "sha256-qw4q4HQBcy08tJUxpmct22bJZWskfQHdkZOV3ax7OGI=";
  };

  # Upstream downloads the release binary into bin/ from a [[build]] hook,
  # which `herdr plugin link` doesn't run; build it from source the way its own
  # nix/package.nix does.
  memex = rustPlatform.buildRustPackage {
    pname = "memex";
    inherit version src;
    cargoHash = "sha256-WpfoZl5VIBcTY7RMssuOIUu0VYaKq4Kcs0n4m50mvKY=";

    # Link against Nix's ONNX Runtime instead of downloading one.
    buildNoDefaultFeatures = true;
    buildFeatures = ["ort-load-dynamic"];

    nativeBuildInputs = [makeWrapper pkg-config];
    buildInputs = [openssl];

    postInstall = ''
      wrapProgram $out/bin/memex \
        --set-default ORT_DYLIB_PATH ${onnxruntime}/lib/libonnxruntime${stdenv.hostPlatform.extensions.sharedLibrary}
    '';

    # The tests download embedding models.
    doCheck = false;

    meta.mainProgram = "memex";
  };
in
  mkHerdrPlugin {
    pname = "herdr-memex";
    inherit version src;

    # The pane runs `sh -c 'exec …/herdr/memex-pane.sh'`.
    wrapCommands = ["bash" "sh"];
    runtimeInputs = [bash coreutils curl git gnused jq];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name herdr ! -name skills ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +
      rm $out/herdr/install.sh

      mkdir -p $out/bin
      ln -s ${lib.getExe memex} $out/bin/memex
    '';

    passthru = {inherit memex;};

    meta = {
      homepage = "https://github.com/nicosuave/memex";
      license = lib.licenses.mit;
    };
  }
