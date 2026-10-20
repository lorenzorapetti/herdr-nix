{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  buildGoModule,
  go_1_27,
}: let
  version = "0.17.4";

  src = fetchFromGitHub {
    owner = "permgps";
    repo = "herdr-telegram-agents";
    rev = "v${version}";
    hash = "sha256-nRTQfx0PWIt30CtBmoVA/I40rgYwvxP4w+8wulqdgJI=";
  };

  # Upstream downloads the release binary into bin/ from a [[build]] hook,
  # which `herdr plugin link` doesn't run; build it from source instead.
  # go.mod asks for a newer patch release than nixpkgs' default Go.
  herdr-telegram-agents-bin = (buildGoModule.override {go = go_1_27;}) {
    pname = "herdr-telegram-agents-bin";
    inherit version src;
    vendorHash = "sha256-BHHQlARGtvZiZ5BQqZYrz4gD3E0Xr/TybAD5LpSvX0M=";

    subPackages = ["cmd/herdr-tg"];
    ldflags = ["-s" "-w" "-X main.version=${version}"];

    preCheck = ''
      export HOME=$(mktemp -d)
    '';

    meta.mainProgram = "herdr-tg";
  };
in
  mkHerdrPlugin {
    pname = "herdr-telegram-agents";
    inherit version src;

    # Every entry point runs bin/herdr-tg directly.
    wrapCommands = [];

    # No settingsFile: the setup action writes config.json, bot token included,
    # which doesn't belong in the Nix store.

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +

      mkdir -p $out/bin
      ln -s ${lib.getExe herdr-telegram-agents-bin} $out/bin/herdr-tg
    '';

    passthru = {inherit herdr-telegram-agents-bin;};

    meta = {
      homepage = "https://github.com/permgps/herdr-telegram-agents";
      license = lib.licenses.mit;
    };
  }
