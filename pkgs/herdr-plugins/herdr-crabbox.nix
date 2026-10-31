{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  buildGoModule,
  makeWrapper,
  coreutils,
  git,
  openssh,
  procps,
  rsync,
  writeShellScript,
}: let
  version = "0.80.0";

  src = fetchFromGitHub {
    owner = "openclaw";
    repo = "crabbox";
    rev = "v${version}";
    hash = "sha256-2+GbJyHEBy11M0e0WVCRm32Dj8UGEXKA0o0etdZgDyA=";
  };

  # A CLI-only build, like `go install`: the release's offline runtime pack is
  # left out, so runtimes are fetched when a box first needs them.
  crabbox = buildGoModule {
    pname = "crabbox";
    inherit version src;
    vendorHash = "sha256-L72L2kd6/ISvOr8b4pv1dlurrCAB0bl9vp8RxqUliW4=";

    subPackages = ["cmd/crabbox"];
    env.CGO_ENABLED = 0;
    ldflags = ["-s" "-w" "-X github.com/openclaw/crabbox/internal/cli.version=${version}"];

    # The suite shells out to git, docker and live providers.
    doCheck = false;

    nativeBuildInputs = [makeWrapper];
    # Syncs work trees with git, rsync and ssh; suffixed so the user's own
    # tools (and ssh config) still win.
    postInstall = ''
      wrapProgram $out/bin/crabbox \
        --suffix PATH : ${lib.makeBinPath [coreutils git openssh procps rsync]}
    '';

    meta.mainProgram = "crabbox";
  };

  # What the [[build]] hook would write after finding crabbox on PATH.
  shim = writeShellScript "crabbox-shim.sh" ''
    exec ${lib.getExe crabbox} "$@"
  '';
in
  mkHerdrPlugin {
    pname = "herdr-crabbox";
    inherit version src;
    pluginRoot = "plugins/herdr";

    wrapCommands = ["sh"];
    runtimeInputs = [coreutils];

    postInstall = ''
      rm $out/build.sh $out/.gitignore
      ln -s ${shim} $out/crabbox-shim.sh
      cp ${src}/LICENSE $out/
    '';

    passthru = {inherit crabbox;};

    meta = {
      homepage = "https://github.com/openclaw/crabbox";
      changelog = "https://github.com/openclaw/crabbox/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
