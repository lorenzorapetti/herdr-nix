{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  git,
}: let
  version = "0.3.6";

  src = fetchFromGitHub {
    owner = "thanhdat77";
    repo = "herdr-navigator";
    rev = "v${version}";
    hash = "sha256-+xtBu4m2YenFH+W3Sv7atDvcsgChS5mKXgVgKomM768=";
  };

  # Upstream's [[build]] step runs `cargo build --release`, which
  # `herdr plugin link` doesn't run; build it here instead.
  herdr-navigator-bin = rustPlatform.buildRustPackage {
    pname = "herdr-navigator-bin";
    inherit version src;
    cargoHash = "sha256-1fvQ8hyarP1WQwqIRvqKCkttwAMj3wGieue91/VNll8=";

    nativeCheckInputs = [git];
    preCheck = ''
      export HOME=$(mktemp -d)
    '';

    nativeBuildInputs = [makeWrapper];
    # Lists worktrees with git; suffixed so the user's own git still wins.
    # zoxide, an optional source, stays the user's.
    postInstall = ''
      wrapProgram $out/bin/herdr-navigator --suffix PATH : ${lib.makeBinPath [git]}
    '';

    meta.mainProgram = "herdr-navigator";
  };
in
  mkHerdrPlugin {
    pname = "herdr-navigator";
    inherit version src;

    # Every entry point runs ./target/release/herdr-navigator directly.
    wrapCommands = [];

    settingsFile = "config.toml";

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name examples ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +

      mkdir -p $out/target/release
      ln -s ${lib.getExe herdr-navigator-bin} $out/target/release/herdr-navigator
    '';

    passthru = {inherit herdr-navigator-bin;};

    meta = {
      homepage = "https://github.com/thanhdat77/herdr-navigator";
      changelog = "https://github.com/thanhdat77/herdr-navigator/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
