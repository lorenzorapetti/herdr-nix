{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  buildNpmPackage,
  coreutils,
  nodejs,
}: let
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "nidhi-singh02";
    repo = "agent-router";
    rev = "v${version}";
    hash = "sha256-III+GpKwgylQrv3sFjzch4Z1MRluTO+k6Xop/CuASEg=";
  };

  # Upstream's [[build]] steps run `npm ci` and compile the router CLI, which
  # `herdr plugin link` doesn't run; do both here. The scripts run it from
  # packages/router/dist/cli.js.
  build = buildNpmPackage {
    pname = "herdr-agent-router-build";
    inherit version src;
    npmDepsHash = "sha256-rFjQ6OZP7zrVMfxh9iE1kmyM2CFbrgPYmtNVcowLSdc=";

    installPhase = ''
      runHook preInstall
      npm prune --omit=dev --offline
      mkdir -p $out
      cp -r node_modules packages $out/
      runHook postInstall
    '';
  };
in
  mkHerdrPlugin {
    pname = "herdr-agent-router";
    inherit version src;

    # The agent CLIs it routes to (claude, codex, cursor-agent, opencode) are
    # the user's.
    runtimeInputs = [coreutils nodejs];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name herdr-plugin ! -name config.example.json ! -name skills \
        ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +
      ln -s ${build}/packages $out/packages
      ln -s ${build}/node_modules $out/node_modules
    '';

    passthru = {inherit build;};

    meta = {
      homepage = "https://github.com/nidhi-singh02/agent-router";
      changelog = "https://github.com/nidhi-singh02/agent-router/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
