{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  coreutils,
  openssh,
  procps,
}: let
  version = "0.4.3";

  src = fetchFromGitHub {
    owner = "nikok6";
    repo = "herdr-mirror";
    rev = "v${version}";
    hash = "sha256-dZIu4TcMkVDrRvnvgRMh7+8PpNaWB/i2/UkH/h0ZRW4=";
  };

  # Upstream downloads the release binary into target/release/ from a [[build]]
  # hook, which `herdr plugin link` doesn't run; build it from source instead.
  herdr-mirror-bin = rustPlatform.buildRustPackage {
    pname = "herdr-mirror-bin";
    inherit version src;
    cargoHash = "sha256-mXQ0oVf+GVDYcUVdovQFKAM/Bc2hWgcms6h8S/ebnFE=";

    # The proxy-command tests spawn a real ssh.
    nativeCheckInputs = [openssh];
    preCheck = ''
      export HOME=$(mktemp -d)
    '';

    nativeBuildInputs = [makeWrapper];
    # Reaches remotes with ssh and inspects processes with ps and cat;
    # suffixed so the user's own ssh (and its config) still wins.
    postInstall = ''
      wrapProgram $out/bin/herdr-mirror --suffix PATH : ${lib.makeBinPath [coreutils openssh procps]}
    '';

    meta.mainProgram = "herdr-mirror";
  };
in
  mkHerdrPlugin {
    pname = "herdr-mirror";
    inherit version src;

    # Every entry point runs ./target/release/herdr-mirror directly.
    wrapCommands = [];

    settingsFile = "hosts.toml";

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +

      mkdir -p $out/target/release
      ln -s ${lib.getExe herdr-mirror-bin} $out/target/release/herdr-mirror
    '';

    passthru = {inherit herdr-mirror-bin;};

    meta = {
      homepage = "https://github.com/nikok6/herdr-mirror";
      license = lib.licenses.mit;
    };
  }
