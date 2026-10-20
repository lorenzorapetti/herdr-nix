{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  buildNpmPackage,
  rustPlatform,
  nodejs,
}: let
  version = "0.17.7";

  src = fetchFromGitHub {
    owner = "osolmaz";
    repo = "pi-workflows";
    rev = "v${version}";
    hash = "sha256-qgl31mqUqNopbX3JBC4IvOZwdZ/WtXbrpZwGfP1ARyU=";
  };

  # The viewer loads the compiled client resolver from dist/, which the git
  # checkout `herdr plugin link` points at doesn't have.
  dist = buildNpmPackage {
    pname = "pi-workflows-dist";
    inherit version src;
    npmDepsHash = "sha256-bdTWF/aBFRnRsukXNX8+rNGKwLS6GfkNCDnCOi2gpPU=";

    # The native better-sqlite3 build is for the Pi extension, not the viewer.
    npmFlags = ["--ignore-scripts"];

    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  };

  # The `piw` terminal client the pane runs, found on PATH.
  piw = rustPlatform.buildRustPackage {
    pname = "piw";
    inherit version src;
    sourceRoot = "${src.name}/tui";
    cargoHash = "sha256-jKxbExog9fGk+nS2Z6zQeetrU81eVyAY9g3bMebwIko=";

    meta.mainProgram = "piw";
  };
in
  mkHerdrPlugin {
    pname = "herdr-pi-workflows";
    inherit version src;

    wrapCommands = ["node"];
    runtimeInputs = [nodejs piw];

    # package.json is where the viewer reads the piw version it expects.
    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name package.json ! -name plugins ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +
      ln -s ${dist} $out/dist
    '';

    passthru = {inherit dist piw;};

    meta = {
      homepage = "https://github.com/osolmaz/pi-workflows";
      license = lib.licenses.mit;
    };
  }
