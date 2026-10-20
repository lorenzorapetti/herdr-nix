{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
  makeWrapper,
  git,
  procps,
}: let
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "ChmaraX";
    repo = "herdr-nvim";
    rev = "v${version}";
    hash = "sha256-EghtchK820sWZmq67qdHhKSWkLnG2CqLza/dmUqNNi0=";
  };

  # Upstream downloads the release binary into bin/ from a [[build]] hook,
  # which `herdr plugin link` doesn't run; build it from source instead.
  herdr-nvim-bin = rustPlatform.buildRustPackage {
    pname = "herdr-nvim-bin";
    inherit version src;
    cargoHash = "sha256-ncnRRclRvbHWHcx9UTCoFvZILRw7kUf+Ub7N1ZjQ0IA=";

    nativeCheckInputs = [git procps];
    preCheck = ''
      export HOME=$(mktemp -d)
      # The file picker's end-to-end test searches this repository as a git
      # checkout.
      git init -q
      git add -A
      git -c user.name=nix -c user.email=nix@localhost commit -qm source
    '';

    nativeBuildInputs = [makeWrapper];
    # Finds its daemons with ps and pgrep and the repository with git;
    # suffixed so the user's own tools still win. Neovim itself is the user's.
    postInstall = ''
      wrapProgram $out/bin/herdr-nvim --suffix PATH : ${lib.makeBinPath [git procps]}
    '';

    meta.mainProgram = "herdr-nvim";
  };
in
  mkHerdrPlugin {
    pname = "herdr-nvim";
    inherit version src;

    # Every entry point runs bin/herdr-nvim directly.
    wrapCommands = [];

    # No settingsFile: config.toml lives in ~/.config/herdr-nvim, not
    # $HERDR_PLUGIN_CONFIG_DIR.

    # lua/ and plugin/ are the Neovim half the daemon loads.
    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name lua ! -name plugin ! -name doc \
        ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +

      mkdir -p $out/bin
      ln -s ${lib.getExe herdr-nvim-bin} $out/bin/herdr-nvim
    '';

    passthru = {inherit herdr-nvim-bin;};

    meta = {
      homepage = "https://github.com/ChmaraX/herdr-nvim";
      changelog = "https://github.com/ChmaraX/herdr-nvim/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
