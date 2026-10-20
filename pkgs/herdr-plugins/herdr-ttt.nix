{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  buildGoModule,
  coreutils,
  gnugrep,
  gnused,
}: let
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "eugenioenko";
    repo = "ttt";
    rev = "v${version}";
    hash = "sha256-ousuIOWk3TRvPB3cilTXHhhAia0Hn+MUykr7uotA7f8=";
  };

  ttt = buildGoModule {
    pname = "ttt";
    inherit version src;
    vendorHash = "sha256-DUyYhsMzjyhW2vtMRkSUKVBvcgJYZi5iUNVKw48l3+Q=";

    subPackages = ["cmd/ttt"];
    ldflags = ["-s" "-w" "-X main.version=${version}"];

    preCheck = ''
      export HOME=$(mktemp -d)
    '';

    meta.mainProgram = "ttt";
  };
in
  mkHerdrPlugin {
    pname = "herdr-ttt";
    inherit version src;
    pluginRoot = "herdr-plugin";

    # The [[build]] hook installs ttt with curl | sh when it isn't on PATH;
    # put Nix's there instead.
    wrapCommands = ["sh"];
    runtimeInputs = [coreutils gnugrep gnused ttt];

    postInstall = ''
      rm $out/scripts/install.sh
      cp ${src}/LICENSE $out/
    '';

    passthru = {inherit ttt;};

    meta = {
      homepage = "https://github.com/eugenioenko/ttt";
      license = lib.licenses.mit;
    };
  }
