{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  coreutils,
  gnugrep,
  jq,
  procps,
  python3,
}: let
  # No release tags upstream yet.
  src = fetchFromGitHub {
    owner = "fkiene";
    repo = "llmtrim-herdr";
    rev = "88ed6fbeab1cfc1224bece3744b207659bc1123b";
    hash = "sha256-k5hHWV+lYLPxoqmiOIyZ/RwwXr3ug5zVwgLockIPC0E=";
  };
in
  mkHerdrPlugin {
    pname = "herdr-llmtrim";
    version = (lib.importTOML "${src}/herdr-plugin.toml").version;
    inherit src;

    # The hooks are run as `bin/<hook>.sh` straight from their `#!/bin/sh`
    # shebang; run them through sh so its wrapper puts their tools on PATH.
    postPatch = ''
      sed -i -E 's#command = \["(bin/[a-z-]+\.sh)"#command = ["sh", "\1"#' herdr-plugin.toml
    '';

    # llmtrim itself, the proxy this drives, is the user's: it installs a CA
    # and rewrites their agents' routing, see its README.
    wrapCommands = ["sh"];
    runtimeInputs = [coreutils gnugrep jq procps python3];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name bin ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +
      rm $out/bin/*.ps1
    '';

    meta = {
      homepage = "https://github.com/fkiene/llmtrim-herdr";
      license = lib.licenses.mpl20;
    };
  }
