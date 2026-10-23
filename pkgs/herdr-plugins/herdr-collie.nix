{
  lib,
  stdenvNoCC,
  mkHerdrPlugin,
  fetchFromGitHub,
  fetchBunDeps,
  bash,
  bun,
  coreutils,
  nodejs,
}: let
  version = "1.23.3";

  src = fetchFromGitHub {
    owner = "AltanS";
    repo = "collie";
    rev = "v${version}";
    hash = "sha256-nt7NJMTHBoraOBJH33zXFBu1GzkKuiHDvCIjZz6S6i8=";
  };

  node-modules = fetchBunDeps {
    pname = "herdr-collie";
    inherit version src;
    hash = "sha256-tAj7dHtBl1JGUg+9IammsZuezhjE3fLmf4yULu6XX7c=";
  };

  web-node-modules = fetchBunDeps {
    pname = "herdr-collie-web";
    inherit version src;
    root = "web";
    hash = "sha256-5KMvEoJpU2/feYPfSgfiPOdnFmc/0a97h9pFDivHvaU=";
  };

  # Upstream's [[build]] step compiles bin/collie and the web UI with
  # `collie build`, which `herdr plugin link` doesn't run and which would
  # `bun install` from the network; do its two build steps here.
  build = stdenvNoCC.mkDerivation {
    pname = "herdr-collie-build";
    inherit version src;

    nativeBuildInputs = [bun nodejs];

    postPatch = ''
      cp -r ${node-modules}/node_modules node_modules
      cp -r ${web-node-modules}/node_modules web/node_modules
      chmod -R u+w node_modules web/node_modules
      patchShebangs node_modules web/node_modules
    '';

    buildPhase = ''
      runHook preBuild
      export HOME=$(mktemp -d)
      bun build --compile --target=bun cli/main.ts --outfile bin/collie
      (cd web && bun run build)
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp bin/collie $out/collie
      cp -r web/dist $out/web
      runHook postInstall
    '';

    # The compiled binary is bun with the bundle appended; stripping or
    # patching it would cut the bundle off.
    dontFixup = true;
  };
in
  mkHerdrPlugin {
    pname = "herdr-collie";
    inherit version src;

    runtimeInputs = [bash coreutils];

    # No settingsFile: its config is several TOML files (keys, commands,
    # launchers, theme, ...) rather than one.

    # bin/collie is copied, not linked: collie finds its checkout (web/dist,
    # the manifest) two directories above the binary's real path.
    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name scripts ! -name bridge ! -name cli ! -name systemd \
        ! -name '*.toml.example' ! -name package.json ! -name LICENSE ! -name TRADEMARKS.md \
        ! -name README.md \
        -exec rm -rf {} +
      find $out/scripts -mindepth 1 -name '*.test.sh' -delete
      find $out/bridge $out/cli -name '*.test.ts' -delete

      install -Dm755 ${build}/collie $out/bin/collie
      mkdir -p $out/web
      cp -r ${build}/web $out/web/dist
    '';

    dontFixup = true;

    passthru = {inherit build node-modules web-node-modules;};

    meta = {
      homepage = "https://github.com/AltanS/collie";
      changelog = "https://github.com/AltanS/collie/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
