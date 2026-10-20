{
  lib,
  stdenvNoCC,
  mkHerdrPlugin,
  fetchFromGitHub,
  fetchBunDeps,
  bun,
  coreutils,
  gnused,
  nodejs,
}: let
  version = "0.4.12";

  src = fetchFromGitHub {
    owner = "devswha";
    repo = "herdr-web-ui";
    rev = "v${version}";
    hash = "sha256-TwmeSDag7iSGGmR1aTylNY4y3Dbfbk0FYr/dxMFl89A=";
  };

  build-node-modules = fetchBunDeps {
    pname = "herdr-web-ui-build";
    inherit version src;
    hash = "sha256-2tvSvtfXvYsBeIOUy/KGRz3m+EjY0v8do/A6NHq84p4=";
  };

  # Upstream's [[build]] steps run `bun install` and build the web client into
  # dist/, which `herdr plugin link` doesn't run; do both here.
  dist = stdenvNoCC.mkDerivation {
    pname = "herdr-web-ui-dist";
    inherit version src;

    nativeBuildInputs = [bun nodejs];

    buildPhase = ''
      runHook preBuild
      export HOME=$(mktemp -d)
      cp -r ${build-node-modules}/node_modules node_modules
      chmod -R u+w node_modules
      patchShebangs node_modules
      bun --bun vite build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  };

  node-modules = fetchBunDeps {
    pname = "herdr-web-ui";
    inherit version src;
    hash = "sha256-PqOAR5WEzWKYlbNdkb3YXO7HvE0KUwc4ItkaitPu1tc=";
    installFlags = ["--production"];
  };
in
  mkHerdrPlugin {
    pname = "herdr-web-ui";
    inherit version src;

    # The server runs on Bun; its terminal sidecar runs node-pty under Node.
    wrapCommands = ["sh"];
    runtimeInputs = [bun coreutils gnused nodejs];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name package.json ! -name server ! -name shared \
        ! -name scripts ! -name public ! -name LICENSE ! -name THIRD_PARTY_NOTICES.md \
        ! -name README.md \
        -exec rm -rf {} +
      rm -f $out/scripts/*.ps1
      ln -s ${dist} $out/dist
      ln -s ${node-modules}/node_modules $out/node_modules
    '';

    passthru = {inherit dist node-modules;};

    meta = {
      homepage = "https://github.com/devswha/herdr-web-ui";
      changelog = "https://github.com/devswha/herdr-web-ui/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
