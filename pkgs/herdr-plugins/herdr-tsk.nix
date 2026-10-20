{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  bash,
  coreutils,
  git,
}: let
  version = "0.12.0";

  src = fetchFromGitHub {
    owner = "smarzban";
    repo = "tsk";
    rev = "v${version}";
    hash = "sha256-6EHPIfipl43FnHOxODVQklujQcI9ck9jwxPQyZ1GP+s=";
  };

  # Upstream's [[build]] step runs `cargo build --release`, which
  # `herdr plugin link` doesn't run; build it here instead.
  herdr-tsk-bin = rustPlatform.buildRustPackage {
    pname = "herdr-tsk-bin";
    inherit version src;
    cargoHash = "sha256-Ul27R/iL0mewUjcDadw/RJSlwgJAEEnH0vJ4fqjr588=";

    nativeCheckInputs = [git];
    # Writes a fake brew and execs it while other tests fork, which races into
    # ETXTBSY on a busy builder.
    checkFlags = ["--skip=update_directs_a_homebrew_binary_to_brew_without_a_path_lookup"];
    preCheck = ''
      export HOME=$(mktemp -d)
    '';

    nativeBuildInputs = [makeWrapper];
    # Reads the repository's identity with git; suffixed so the user's own git
    # still wins.
    postInstall = ''
      wrapProgram $out/bin/tsk --suffix PATH : ${lib.makeBinPath [git]}
    '';

    meta.mainProgram = "tsk";
  };
in
  mkHerdrPlugin {
    pname = "herdr-tsk";
    inherit version src;

    runtimeInputs = [bash coreutils];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name scripts ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +
      find $out/scripts -mindepth 1 ! -name 'open-*.sh' -delete

      mkdir -p $out/target/release
      ln -s ${lib.getExe herdr-tsk-bin} $out/target/release/tsk
    '';

    passthru = {inherit herdr-tsk-bin;};

    meta = {
      homepage = "https://github.com/smarzban/tsk";
      changelog = "https://github.com/smarzban/tsk/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
