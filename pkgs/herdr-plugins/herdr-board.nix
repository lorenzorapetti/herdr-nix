{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  bash,
  coreutils,
  git,
  procps,
}: let
  version = "0.19.1";

  src = fetchFromGitHub {
    owner = "nelsonPires5";
    repo = "herdr-board";
    rev = "v${version}";
    hash = "sha256-uJUyHprpt8tregwcQR/PUj+mky0g1v1nmfq7r20tTDs=";
  };

  # Upstream's [[build]] steps compile `board` into target/release/ and copy it
  # to ~/.local/bin for agents to call, neither of which `herdr plugin link`
  # runs; build it here, and add `passthru.herdr-board-bin` to your packages
  # for the CLI.
  herdr-board-bin = rustPlatform.buildRustPackage {
    pname = "herdr-board-bin";
    inherit version src;
    cargoHash = "sha256-rfPWa3oNB0jCCmOW++xOaebJyRrVGohwwDyrQmPtw0s=";

    cargoBuildFlags = ["--package" "board-cli"];

    nativeCheckInputs = [git procps];
    # The core and daemon suites drive fake agent CLIs on tight deadlines that
    # time out in the sandbox; test the CLI that gets installed.
    cargoTestFlags = ["--package" "board-cli"];
    preCheck = ''
      export HOME=$(mktemp -d)
    '';

    nativeBuildInputs = [makeWrapper];
    # Creates worktrees with git; suffixed so the user's own git still wins.
    postInstall = ''
      wrapProgram $out/bin/board --suffix PATH : ${lib.makeBinPath [git]}
    '';

    meta.mainProgram = "board";
  };
in
  mkHerdrPlugin {
    pname = "herdr-board";
    inherit version src;

    runtimeInputs = [bash coreutils];

    # No settingsFile: config.toml lives in ~/.config/herdr-board, not
    # $HERDR_PLUGIN_CONFIG_DIR.

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name scripts ! -name skill ! -name README.md \
        -exec rm -rf {} +
      find $out/scripts -mindepth 1 ! -name open-board.sh -exec rm -rf {} +

      mkdir -p $out/target/release
      ln -s ${lib.getExe herdr-board-bin} $out/target/release/board
    '';

    passthru = {inherit herdr-board-bin;};

    meta = {
      homepage = "https://github.com/nelsonPires5/herdr-board";
      changelog = "https://github.com/nelsonPires5/herdr-board/blob/v${version}/CHANGELOG.md";
      # No LICENSE file; Cargo.toml declares MIT.
      license = lib.licenses.mit;
    };
  }
