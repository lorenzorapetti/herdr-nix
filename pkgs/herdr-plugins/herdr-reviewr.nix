{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  git,
}: let
  version = "0.47.0";

  src = fetchFromGitHub {
    owner = "persiyanov";
    repo = "herdr-reviewr";
    rev = "v${version}";
    hash = "sha256-pu1q3yFVtTd/MdHx4WgEUzyIRzVbqj/XMIMAbRkmvTU=";
  };

  # Upstream downloads the release binary into bin/ from a [[build]] hook,
  # which `herdr plugin link` doesn't run; build it from source instead.
  herdr-reviewr-bin = rustPlatform.buildRustPackage {
    pname = "herdr-reviewr-bin";
    inherit version src;
    cargoHash = "sha256-3G3ZU0a48mD9ZRwjRoKioWJwnZ8Mt6BT5Q9CdqPxdV0=";

    nativeCheckInputs = [git];
    # Asserts two subprocess runs finish within 5s, which a loaded builder
    # running the other end-to-end tests alongside it can miss.
    checkFlags = ["--skip=a_held_lock_holds_back_only_its_own_workspace"];
    preCheck = ''
      export HOME=$(mktemp -d)
      # The end-to-end tests and a style lint expect a git checkout.
      git init -q
      git add -A
      git -c user.name=nix -c user.email=nix@localhost commit -qm source
    '';

    nativeBuildInputs = [makeWrapper];
    # Diffs come from git; suffixed so the user's own git still wins.
    postInstall = ''
      wrapProgram $out/bin/herdr-reviewr --suffix PATH : ${lib.makeBinPath [git]}
    '';

    meta.mainProgram = "herdr-reviewr";
  };
in
  mkHerdrPlugin {
    pname = "herdr-reviewr";
    inherit version src;

    # Every manifest command runs bin/herdr-reviewr directly.
    wrapCommands = [];

    settingsFile = "config.toml";

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name herdr ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +
      rm -f $out/herdr/*.ps1

      mkdir -p $out/bin
      ln -s ${lib.getExe herdr-reviewr-bin} $out/bin/herdr-reviewr
    '';

    passthru = {inherit herdr-reviewr-bin;};

    meta = {
      homepage = "https://github.com/persiyanov/herdr-reviewr";
      changelog = "https://github.com/persiyanov/herdr-reviewr/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
