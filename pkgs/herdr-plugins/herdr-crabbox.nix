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
  version = "0.84.0";

  src = fetchFromGitHub {
    owner = "openclaw";
    repo = "crabbox";
    rev = "v${version}";
    hash = "sha256-QUw42t+OkfxgLl+a6hLNDMteH+gXu9tft8fiQVkRtMc=";
  };

  # A CLI-only build, like `go install`: the release's offline runtime pack is
  # left out, so runtimes are fetched when a box first needs them.
  crabbox = buildGoModule {
    pname = "crabbox";
    inherit version src;
    vendorHash = "sha256-5U2nA7u8XntQSr7Iye40SYe8mJ7IbvR2f2BYbD272kY=";

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
