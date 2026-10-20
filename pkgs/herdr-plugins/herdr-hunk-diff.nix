{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  buildNpmPackage,
  git,
  hunk,
  nodejs,
}: let
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "jhochenbaum";
    repo = "herdr-hunk-diff";
    rev = "v${version}";
    hash = "sha256-aDsq1BKmaYl50HfqJywFZZxpVfmKGs1JHJyoMiRSnIM=";
  };

  # Upstream's [[build]] steps install the npm dependencies and compile dist/,
  # which `herdr plugin link` doesn't run; do both here.
  build = buildNpmPackage {
    pname = "herdr-hunk-diff-build";
    inherit version src;
    npmDepsHash = "sha256-Gf1s4r43CPQaj+LgFJH3z82J2cYsIgZWUEVVJx8sJks=";

    doCheck = true;
    nativeCheckInputs = [git];
    checkPhase = ''
      runHook preCheck
      export HOME=$(mktemp -d)
      # The Windows pane test runs the prebuilt hunk from npm, which needs a
      # dynamic loader the sandbox lacks.
      node_modules/.bin/vitest run --exclude tests/windows-pane.test.ts
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      # By default it runs the prebuilt hunk binary from hunkdiff's per-platform
      # npm packages; run Nix's instead. Patched after the tests, which check
      # that default. Setting hunk.bin still picks another.
      substituteInPlace dist/herdr.js \
        --replace-fail 'return { bin: cfg.hunk.bin, prefix: [] };' \
          'return { bin: cfg.hunk.bin, prefix: [] }; return { bin: "${lib.getExe hunk}", prefix: [] };'
      npm prune --omit=dev --omit=optional --offline --ignore-scripts
      mkdir -p $out
      cp -r dist node_modules $out/
      runHook postInstall
    '';
  };
in
  mkHerdrPlugin {
    pname = "herdr-hunk-diff";
    inherit version src;

    wrapCommands = ["node" "sh"];
    runtimeInputs = [git nodejs];

    settingsFile = "config.toml";

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name package.json ! -name skills ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +
      ln -s ${build}/dist $out/dist
      ln -s ${build}/node_modules $out/node_modules
    '';

    passthru = {inherit build;};

    meta = {
      homepage = "https://github.com/jhochenbaum/herdr-hunk-diff";
      license = lib.licenses.mit;
    };
  }
