{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  bash,
  coreutils,
  git,
}: let
  version = "1.18.0";

  src = fetchFromGitHub {
    owner = "smarzban";
    repo = "herdr-file-viewer";
    rev = "v${version}";
    hash = "sha256-rG15Aq6QVPqE5ndlQwUjMUVlbtdTKKSHdzpOPskd+ss=";
  };

  # Upstream downloads the release binary into target/release/ from a [[build]]
  # hook, which `herdr plugin link` doesn't run; build it from source instead.
  herdr-file-viewer-bin = rustPlatform.buildRustPackage {
    pname = "herdr-file-viewer-bin";
    inherit version src;
    cargoHash = "sha256-H079OdrezPEIplQ3rZqRA0usYzE0omCu6Lc/ebqyc6o=";

    nativeCheckInputs = [git];
    # Some tests run the launcher scripts, whose `/usr/bin/env` shebang the
    # sandbox can't resolve.
    preCheck = ''
      export HOME=$(mktemp -d)
      patchShebangs scripts
    '';

    nativeBuildInputs = [makeWrapper];
    # The glow style is looked up in an assets/ directory above the executable.
    # Git status comes from git; suffixed so the user's own git still wins. The
    # optional renderers (glow, delta, bat) and the editor stay the user's.
    postInstall = ''
      install -Dm644 assets/markdown-style.json $out/assets/markdown-style.json
      wrapProgram $out/bin/herdr-file-viewer --suffix PATH : ${lib.makeBinPath [git]}
    '';

    meta.mainProgram = "herdr-file-viewer";
  };
in
  mkHerdrPlugin {
    pname = "herdr-file-viewer";
    inherit version src;

    runtimeInputs = [bash coreutils];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name scripts ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +
      rm -f $out/scripts/*.ps1 $out/scripts/fetch-or-build.sh $out/scripts/install-renderers.sh

      mkdir -p $out/target/release
      ln -s ${lib.getExe herdr-file-viewer-bin} $out/target/release/herdr-file-viewer
    '';

    passthru = {inherit herdr-file-viewer-bin;};

    meta = {
      homepage = "https://github.com/smarzban/herdr-file-viewer";
      changelog = "https://github.com/smarzban/herdr-file-viewer/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
