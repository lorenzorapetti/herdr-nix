{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  gh,
  git,
}: let
  version = "0.5.1";

  src = fetchFromGitHub {
    owner = "osolmaz";
    repo = "ghzinga";
    rev = "v${version}";
    hash = "sha256-spQFJyim32rJ0eY5uAhOM5UJKgWDdyvbV9nkRPQloZ0=";
  };

  ghzinga = rustPlatform.buildRustPackage {
    pname = "ghzinga";
    inherit version src;
    cargoHash = "sha256-BovekIK4DmvgG1aR3dhdBGMQVDxZ7lcLiUegFkVm3j0=";

    nativeCheckInputs = [git];
    preCheck = ''
      export HOME=$(mktemp -d)
      patchShebangs plugins/herdr/test
    '';

    nativeBuildInputs = [makeWrapper];
    # Fetches issues and PRs through gh, which reads the user's own login;
    # suffixed so the user's own gh and git still win.
    postInstall = ''
      for bin in $out/bin/*; do
        wrapProgram $bin --suffix PATH : ${lib.makeBinPath [gh git]}
      done
    '';

    meta.mainProgram = "gzg";
  };
in
  mkHerdrPlugin {
    pname = "herdr-ghzinga";
    inherit version src;
    pluginRoot = "plugins/herdr";

    # The manifest expects `gzg` on PATH.
    wrapCommands = ["gzg"];
    runtimeInputs = [ghzinga];

    postInstall = ''
      rm -rf $out/test
    '';

    passthru = {inherit ghzinga;};

    meta = {
      homepage = "https://github.com/osolmaz/ghzinga";
      license = lib.licenses.mit;
    };
  }
