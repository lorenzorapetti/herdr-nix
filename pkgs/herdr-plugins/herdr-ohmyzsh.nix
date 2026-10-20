{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  bash,
  coreutils,
  gnugrep,
  zsh,
}: let
  # No release tags upstream yet.
  src = fetchFromGitHub {
    owner = "robbyrussell";
    repo = "herdr-ohmyzsh";
    rev = "bbc072ada531e6306276900a866a4b44a9b92e74";
    hash = "sha256-75JYRXRfn5dFH88DBQqVRbW5OVL1eq3en0M19NpFKLE=";
  };
in
  mkHerdrPlugin {
    pname = "herdr-ohmyzsh";
    version = (lib.importTOML "${src}/herdr-plugin.toml").version;
    inherit src;

    # The [[build]] hook links this directory into Oh My Zsh's custom plugins,
    # which `herdr plugin link` doesn't run; the "install" action still does it,
    # or point Oh My Zsh at herdr.plugin.zsh yourself.
    wrapCommands = ["zsh"];
    runtimeInputs = [coreutils gnugrep zsh];

    doCheck = true;
    nativeCheckInputs = [bash zsh];
    checkPhase = ''
      runHook preCheck
      export HOME=$(mktemp -d)
      patchShebangs tests
      zsh tests/run.zsh
      runHook postCheck
    '';

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name herdr.plugin.zsh ! -name bin ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +
    '';

    meta = {
      homepage = "https://github.com/robbyrussell/herdr-ohmyzsh";
      license = lib.licenses.mit;
    };
  }
