{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  fetchBunDeps,
  bun,
  procps,
}: let
  version = "0.6.4";

  src = fetchFromGitHub {
    owner = "iurysza";
    repo = "herdr-tab-smart-rename";
    rev = "v${version}";
    hash = "sha256-y8FXMPFWGbPv7dDAE0TfBwbpyD9RHkoKLb7ueCxSn0M=";
  };

  # Upstream's [[build]] step runs `bun install --production`, which
  # `herdr plugin link` doesn't run; install the dependencies here instead.
  node-modules = fetchBunDeps {
    pname = "herdr-tab-smart-rename";
    inherit version src;
    hash = "sha256-V52N97KBlMtinmqhB6oyFeQ1TtcrRll1p2oiwKmwg/A=";
    installFlags = ["--production"];
  };
in
  mkHerdrPlugin {
    pname = "herdr-tab-smart-rename";
    inherit version src;

    # The model CLIs it can name tabs with (pi, opencode) are the user's.
    wrapCommands = ["bun"];
    runtimeInputs = [bun procps];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name package.json ! -name bun.lock ! -name src \
        ! -name provider.env.example ! -name README.md \
        -exec rm -rf {} +
      ln -s ${node-modules}/node_modules $out/node_modules
    '';

    passthru = {inherit node-modules;};

    # Upstream ships no license.
    meta = {
      homepage = "https://github.com/iurysza/herdr-tab-smart-rename";
      changelog = "https://github.com/iurysza/herdr-tab-smart-rename/blob/v${version}/CHANGELOG.md";
    };
  }
