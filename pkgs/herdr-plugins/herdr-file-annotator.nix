{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  coreutils,
  git,
}: let
  version = "0.14.0";

  src = fetchFromGitHub {
    owner = "JonasBaeumer";
    repo = "herdr-file-annotator";
    rev = "v${version}";
    hash = "sha256-PjjNOK3t5gCXgN67NprilBYDkqb8uSMUK2+S+Qo7hH0=";
  };

  # Upstream downloads the release binary into bin/ from a [[build]] hook,
  # which `herdr plugin link` doesn't run; build it from source instead.
  herdr-file-annotator-bin = rustPlatform.buildRustPackage {
    pname = "herdr-file-annotator-bin";
    inherit version src;
    cargoHash = "sha256-r8kYclAVyeHlvFR1OptF/2sCDX15O+tQmOsifneon2I=";

    nativeCheckInputs = [git];
    preCheck = ''
      export HOME=$(mktemp -d)
    '';

    nativeBuildInputs = [makeWrapper];
    # Diffs come from git, and mkfifo from coreutils; suffixed so the user's
    # own tools still win.
    postInstall = ''
      wrapProgram $out/bin/herdr-annotator --suffix PATH : ${lib.makeBinPath [coreutils git]}
    '';

    meta.mainProgram = "herdr-annotator";
  };
in
  mkHerdrPlugin {
    pname = "herdr-file-annotator";
    inherit version src;

    # The pane runs `sh -c 'exec …/bin/herdr-annotator pane'`.
    wrapCommands = ["sh"];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +

      mkdir -p $out/bin
      ln -s ${lib.getExe herdr-file-annotator-bin} $out/bin/herdr-annotator
    '';

    passthru = {inherit herdr-file-annotator-bin;};

    meta = {
      homepage = "https://github.com/JonasBaeumer/herdr-file-annotator";
      license = lib.licenses.mit;
    };
  }
