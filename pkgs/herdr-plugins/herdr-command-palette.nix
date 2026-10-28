{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  bash,
  coreutils,
  fzf,
  jq,
}: let
  # No release tags upstream; pin to the merged `fix/surface-failed-action-invokes` commit.
  src = fetchFromGitHub {
    owner = "JanTvrdik";
    repo = "herdr-command-palette";
    rev = "eab940018c2135ac23718efa11e23e9dddcd2a75";
    hash = "sha256-A43Dl365S/5w2wrttV1RnQ1g7YRJmsD3tb5EUUZcQQY=";
  };

  version = (lib.importTOML "${src}/herdr-plugin.toml").version;
in
  mkHerdrPlugin {
    pname = "herdr-command-palette";
    inherit version src;

    # Both entry points run `bash` (open.sh and `bash -c ...`); palette.sh needs
    # fzf + jq, which the herdr server PATH may not have.
    wrapCommands = ["bash"];
    runtimeInputs = [bash coreutils fzf jq];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name open.sh ! -name palette.sh \
        ! -name README.md ! -name LICENSE \
        -exec rm -rf {} +
    '';

    meta = {
      homepage = "https://github.com/JanTvrdik/herdr-command-palette";
      license = lib.licenses.mit;
    };
  }
