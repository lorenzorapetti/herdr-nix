{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  bash,
  coreutils,
  git,
  # "full" adds document review with plannotator-tui; "lite" is the terminal
  # annotation tools only. Both register as the same plugin id.
  variant ? "full",
}:
assert lib.assertOneOf "variant" variant ["full" "lite"]; let
  full = variant == "full";

  # The plugin is released from main; only the Rust helper gets tags.
  src = fetchFromGitHub {
    owner = "plannotator";
    repo = "herdr-annotate";
    rev = "c5e565e9bdbb52d152ad15169f38ed8bae31b610";
    hash = "sha256-qh6vQ4e4ehIuY8bIV6H0uScO6AQySCLDYwHkI24csFQ=";
  };

  manifest =
    if full
    then "herdr-plugin.toml"
    else "lite/herdr-plugin.toml";

  pinnedVersion = file: lib.trim (builtins.readFile "${src}/${file}");

  # Upstream downloads both binaries into bin/ from a [[build]] hook, which
  # `herdr plugin link` doesn't run; build them from source instead.
  herdr-annotate-bin = rustPlatform.buildRustPackage {
    pname = "herdr-annotate-bin";
    version = pinnedVersion "herdr-annotate.version";
    inherit src;
    sourceRoot = "${src.name}/rust";
    cargoHash = "sha256-ReKL4pHo6doBn4XBOr0WbEyrEnoDbnz/wo56QEwYqOg=";
    meta.mainProgram = "herdr-annotate";
  };

  plannotator-tui = rustPlatform.buildRustPackage rec {
    pname = "plannotator-tui";
    version = pinnedVersion "plannotator-tui.version";
    src = fetchFromGitHub {
      owner = "plannotator";
      repo = "plannotator-tui";
      rev = "v${version}";
      hash = "sha256-oJ+AMl2G9m/hxFJLwiN6CQ9urhyhK0w6VEcbnpUgQv0=";
    };
    cargoHash = "sha256-EK3iCT+VJQ/1Sjhdt06nc1pUdo0B6tPBjbjSV9jsRKY=";
    cargoBuildFlags = ["--package" "plannotator-tui"];

    # Some tests write annotation records under the user's data dir.
    preCheck = ''
      export HOME=$(mktemp -d)
    '';

    nativeBuildInputs = [makeWrapper];
    # Resolves the repository under review with git; suffixed so the user's own
    # git still wins.
    postInstall = ''
      wrapProgram $out/bin/plannotator-tui --suffix PATH : ${lib.makeBinPath [git]}
    '';

    meta.mainProgram = "plannotator-tui";
  };
in
  mkHerdrPlugin {
    pname = "herdr-annotate-${variant}";
    version = (lib.importTOML "${src}/${manifest}").version;
    inherit src;

    # The full variant's document review pane runs `sh -c 'exec bash …'`.
    wrapCommands = lib.optional full "sh";
    runtimeInputs = [bash coreutils];

    postInstall =
      ''
        rm -rf $out/.github $out/assets $out/docs $out/rust $out/links $out/windows-full \
          $out/skills ${lib.optionalString full "$out/lite"} $out/*.ps1 $out/scripts/test-* $out/scripts/lite-* $out/scripts/*.py \
          $out/scripts/*.ps1 $out/scripts/smoke.sh $out/scripts/stage-local.sh
      ''
      # Lite's manifest lives in lite/ and reaches one directory up for the
      # shared bin/ and scripts/; hoist it to the top level.
      + lib.optionalString (!full) ''
        mv $out/lite/herdr-plugin.toml $out/herdr-plugin.toml
        rm -rf $out/lite $out/plannotator-tui.version $out/scripts/*plannotator-tui*
        substituteInPlace $out/herdr-plugin.toml \
          --replace-fail '"../bin/' '"./bin/' \
          --replace-fail '"../scripts/' '"scripts/'
      ''
      # Stamp the staged binaries with their pinned versions, so the fetch
      # scripts see them as current if herdr ever runs the [[build]] hooks.
      + ''
        mkdir -p $out/bin
        ln -s ${lib.getExe herdr-annotate-bin} $out/bin/herdr-annotate.exe
        printf '%s' ${herdr-annotate-bin.version} > $out/bin/herdr-annotate.version
      ''
      + lib.optionalString full ''
        ln -s ${lib.getExe plannotator-tui} $out/bin/plannotator-tui.exe
        printf '%s' ${plannotator-tui.version} > $out/bin/plannotator-tui.version
      '';

    passthru =
      {inherit herdr-annotate-bin;}
      // lib.optionalAttrs full {inherit plannotator-tui;};

    meta = {
      homepage = "https://github.com/plannotator/herdr-annotate";
      license = lib.licenses.mit;
    };
  }
