{
  lib,
  stdenvNoCC,
  mkHerdrPlugin,
  fetchFromGitHub,
  fetchBunDeps,
  bun,
  nodejs,
}: let
  version = "0.8.9";

  src = fetchFromGitHub {
    owner = "powerfooI";
    repo = "roamgate";
    rev = "v${version}";
    hash = "sha256-HFOq4Dj2bYD4KYqaNwL76/6YqjmDJpYFlVDT0lPr3As=";
  };

  node-modules = fetchBunDeps {
    pname = "roamgate";
    inherit version src;
    hash = "sha256-yH7hSybA51pi1inihpz1x05Nwpxq6GY+kbwpNZ1CGuk=";
  };

  # Upstream downloads the release binary into server/ from a [[build]] hook,
  # which `herdr plugin link` doesn't run; build the web client and compile the
  # server with it embedded, like the release does.
  roamgate = stdenvNoCC.mkDerivation {
    pname = "roamgate";
    inherit version src;

    nativeBuildInputs = [bun nodejs];

    postPatch = ''
      cp -r ${node-modules}/. .
      for dir in node_modules */node_modules; do
        chmod -R u+w $dir
        patchShebangs $dir
      done
    '';

    buildPhase = ''
      runHook preBuild
      export HOME=$(mktemp -d)
      bun run build:web
      (cd server && bun run compile)
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 server/roamgate $out/bin/roamgate
      runHook postInstall
    '';

    # The compiled binary is bun with the bundle appended; stripping or
    # patching it would cut the bundle off.
    dontFixup = true;

    meta.mainProgram = "roamgate";
  };
in
  mkHerdrPlugin {
    pname = "herdr-roamgate";
    inherit version src;

    # Every entry point runs ./server/roamgate directly.
    wrapCommands = [];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name LICENSE ! -name LICENSES ! -name THIRD_PARTY_NOTICES.md \
        ! -name README.md \
        -exec rm -rf {} +

      mkdir -p $out/server
      ln -s ${lib.getExe roamgate} $out/server/roamgate
    '';

    passthru = {inherit roamgate node-modules;};

    meta = {
      homepage = "https://github.com/powerfooI/roamgate";
      license = lib.licenses.mit;
    };
  }
