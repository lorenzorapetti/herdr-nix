{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  buildGoModule,
  makeWrapper,
  git,
}: let
  version = "0.1.24";

  src = fetchFromGitHub {
    owner = "cloudmanic";
    repo = "herdr-plus";
    rev = "v${version}";
    hash = "sha256-2NnPlZSPBoZa22A02q/FQLm1a7+FH/tCzALZSpP5rkQ=";
  };

  # Upstream's [[build]] step runs `go build` or downloads a release binary into
  # bin/, which `herdr plugin link` doesn't run; build it here instead.
  herdr-plus-bin = buildGoModule {
    pname = "herdr-plus-bin";
    inherit version src;
    vendorHash = "sha256-im2gPhLarMf1w/8rhxbOe9EhUdvseffukT9tqU4EEXI=";

    ldflags = ["-s" "-w"];

    nativeCheckInputs = [git];

    nativeBuildInputs = [makeWrapper];
    # git detects whether a project directory is a repo; suffixed so the user's
    # own git still wins.
    postInstall = ''
      wrapProgram $out/bin/herdr-plus --suffix PATH : ${lib.makeBinPath [git]}
    '';

    meta.mainProgram = "herdr-plus";
  };
in
  mkHerdrPlugin {
    pname = "herdr-plus";
    inherit version src;

    # Every entry point runs ./bin/herdr-plus directly.
    wrapCommands = [];

    settingsFile = "config.toml";

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name examples ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +

      mkdir -p $out/bin
      ln -s ${lib.getExe herdr-plus-bin} $out/bin/herdr-plus
    '';

    passthru = {inherit herdr-plus-bin;};

    meta = {
      homepage = "https://github.com/cloudmanic/herdr-plus";
      license = lib.licenses.mit;
    };
  }
