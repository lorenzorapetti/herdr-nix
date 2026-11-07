{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  coreutils,
  gnugrep,
  gnused,
}: let
  version = "0.18.2";

  src = fetchFromGitHub {
    owner = "uwuclxdy";
    repo = "clauth";
    rev = "v${version}";
    hash = "sha256-jw4DX8P4cs3RnGzLjGwH/8FjBpwfCGog0EtU0AYNzKM=";
  };

  clauth = rustPlatform.buildRustPackage {
    pname = "clauth";
    inherit version src;
    cargoHash = "sha256-oNrCb6+/1HmVp+dbcyCCO9ibVoshGhDvpOgDdVjAhLE=";

    # Dozens of the oauth and scheduler tests stall for minutes each in the
    # sandbox; the suite didn't finish within half an hour.
    doCheck = false;

    meta.mainProgram = "clauth";
  };
in
  mkHerdrPlugin {
    pname = "herdr-clauth";
    inherit version src;
    pluginRoot = "herdr-plugin";

    # The dashboard pane runs a bare `clauth`, and the scripts call it too.
    wrapCommands = ["clauth" "sh"];
    runtimeInputs = [clauth coreutils gnugrep gnused];

    postInstall = ''
      cp ${src}/LICENSE $out/
    '';

    passthru = {inherit clauth;};

    meta = {
      homepage = "https://github.com/uwuclxdy/clauth";
      license = lib.licenses.mit;
    };
  }
