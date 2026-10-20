{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  coreutils,
  findutils,
  git,
  gnused,
  procps,
  util-linux,
}: let
  version = "1.2.5";

  src = fetchFromGitHub {
    owner = "eliasstravik";
    repo = "herdr-projects";
    rev = "v${version}";
    hash = "sha256-D4+czTCOQU3X/s2hXB+NBHh5Kxbb334WHYNVoezDLzs=";
  };

  # bin/run.sh downloads the release binary from a [[build]] hook, which
  # `herdr plugin link` doesn't run; build it from source instead.
  herdr-projects-bin = rustPlatform.buildRustPackage {
    pname = "herdr-projects-bin";
    inherit version src;
    cargoHash = "sha256-a99jbTisfskYHIPHzBDhiOHnAl+NYRKq+fQ3QR6N6ss=";

    # Upstream points the linker at its own mold wrapper; Nix's cc wrapper
    # links fine on its own.
    postPatch = ''
      rm .cargo/config.toml
    '';

    cargoBuildFlags = ["--bin" "herdr-projects"];

    # The suite drives real agent CLIs, terminals and network listeners.
    doCheck = false;

    nativeBuildInputs = [makeWrapper];
    # Worktrees come from git, and process and lock handling from ps, flock and
    # mkfifo; suffixed so the user's own tools still win. Agent CLIs, gh and
    # ssh stay the user's.
    postInstall = ''
      wrapProgram $out/bin/herdr-projects \
        --suffix PATH : ${lib.makeBinPath [coreutils git procps util-linux]}
    '';

    meta.mainProgram = "herdr-projects";
  };
in
  mkHerdrPlugin {
    pname = "herdr-projects";
    inherit version src;

    # bin/run.sh runs target/release/herdr-projects once it finds it no older
    # than the sources, which aren't installed.
    wrapCommands = ["sh"];
    runtimeInputs = [coreutils findutils gnused];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name bin ! -name assets ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +

      mkdir -p $out/target/release
      ln -s ${lib.getExe herdr-projects-bin} $out/target/release/herdr-projects
    '';

    passthru = {inherit herdr-projects-bin;};

    meta = {
      homepage = "https://github.com/eliasstravik/herdr-projects";
      license = lib.licenses.mit;
    };
  }
