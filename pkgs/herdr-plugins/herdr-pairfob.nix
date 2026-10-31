{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  buildGoModule,
  coreutils,
}: let
  version = "1.4.9";

  src = fetchFromGitHub {
    owner = "arronKler";
    repo = "pairfob";
    rev = "v${version}";
    hash = "sha256-ZHvtcAwg6Xzcjl09Bi/77gYcHc13GowNeBFAm7Rj3Xg=";
  };

  pairfob = buildGoModule {
    pname = "pairfob";
    inherit version src;
    vendorHash = "sha256-qPDL6eIfLhgvbA4eSYYzOUOTNzXDpa5yu+NcEoovXpQ=";

    subPackages = ["cmd/pairfob"];
    ldflags = ["-s" "-w" "-X main.version=${version}"];

    # The install-script tests cover the release downloader this replaces, and
    # the machine-link and WebRTC ones need the network.
    checkFlags = ["-skip=^(TestInstall|TestMachineLink|TestWebRTC|TestCancellingAMachineLink|TestClosingAMachineOffer)"];
    preCheck = ''
      export HOME=$(mktemp -d)
    '';

    meta.mainProgram = "pairfob";
  };
in
  mkHerdrPlugin {
    pname = "herdr-pairfob";
    inherit version src;

    # The scripts look for `pairfob` on PATH and otherwise download a release
    # into ~/.local/bin. `pairfob service install` points the background
    # service at this store path, so rerun it after an upgrade.
    wrapCommands = ["sh"];
    runtimeInputs = [coreutils pairfob];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name plugin ! -name LICENSE ! -name NOTICE ! -name README.md \
        -exec rm -rf {} +
      rm $out/plugin/herdr/*.ts
    '';

    passthru = {inherit pairfob;};

    meta = {
      homepage = "https://github.com/arronKler/pairfob";
      license = lib.licenses.asl20;
    };
  }
