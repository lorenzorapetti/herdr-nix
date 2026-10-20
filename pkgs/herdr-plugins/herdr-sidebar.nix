{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  bash,
  coreutils,
  curl,
  git,
  python3,
}: let
  version = "0.15.1";

  src = fetchFromGitHub {
    owner = "alexarthurs";
    repo = "herdr-sidebar";
    rev = "v${version}";
    hash = "sha256-6lHSzGKzh6ef6rQXy43BHZgIMhBC4YVs3tDTqW0pRzU=";
  };

  # Upstream downloads the release binaries into target/release/ from a
  # [[build]] hook, which `herdr plugin link` doesn't run; build them from
  # source instead.
  herdr-sidebar-bin = rustPlatform.buildRustPackage {
    pname = "herdr-sidebar-bin";
    inherit version src;
    sourceRoot = "${src.name}/plugins/herdr-sidebar";
    cargoHash = "sha256-5WgmUlLzuBAiQeIx8tgfCT3UDMuH18BQT/+nGL1uKpw=";

    nativeCheckInputs = [git];
    preCheck = ''
      export HOME=$(mktemp -d)
    '';

    nativeBuildInputs = [makeWrapper];
    # Git status comes from git, and the update check from curl; suffixed so
    # the user's own tools still win. Fonts, glow and the opener stay the
    # user's.
    postInstall = ''
      for bin in $out/bin/*; do
        wrapProgram $bin --suffix PATH : ${lib.makeBinPath [curl git]}
      done
    '';

    meta.mainProgram = "herdr-sidebar";
  };
in
  mkHerdrPlugin {
    pname = "herdr-sidebar";
    inherit version src;
    pluginRoot = "plugins/herdr-sidebar";

    # The redeploy action pipes `herdr workspace list` into python3.
    runtimeInputs = [bash coreutils python3];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name scripts ! -name README.md \
        -exec rm -rf {} +
      find $out/scripts -mindepth 1 ! -name redeploy.sh -delete
      cp ${src}/LICENSE $out/

      mkdir -p $out/target/release
      ln -s ${lib.getExe herdr-sidebar-bin} $out/target/release/herdr-sidebar
    '';

    passthru = {inherit herdr-sidebar-bin;};

    meta = {
      homepage = "https://github.com/alexarthurs/herdr-sidebar";
      license = lib.licenses.mit;
    };
  }
