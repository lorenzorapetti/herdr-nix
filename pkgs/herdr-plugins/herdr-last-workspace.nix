{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
}: let
  # No release tags upstream yet.
  src = fetchFromGitHub {
    owner = "third774";
    repo = "herdr-last-workspace";
    rev = "8b55ebf15deaa52b49ff1c2500aab0c19c729420";
    hash = "sha256-HaNQx4uGYVGP3L3ljFHEDEE53Fs17fC7ypZFDnVjOHk=";
  };

  version = (lib.importTOML "${src}/herdr-plugin.toml").version;

  # Upstream's [[build]] step runs `cargo build --release`, which
  # `herdr plugin link` doesn't run; build it here instead.
  herdr-last-workspace-bin = rustPlatform.buildRustPackage {
    pname = "herdr-last-workspace-bin";
    inherit version src;
    cargoHash = "sha256-l9y7crYh2rd9CQdr7E5WuLd65Qlc6R2Yi2dZC/z4nNM=";

    meta.mainProgram = "herdr-last-workspace";
  };
in
  mkHerdrPlugin {
    pname = "herdr-last-workspace";
    inherit version src;

    # Every entry point runs ./target/release/herdr-last-workspace directly.
    wrapCommands = [];

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name README.md \
        -exec rm -rf {} +

      mkdir -p $out/target/release
      ln -s ${lib.getExe herdr-last-workspace-bin} $out/target/release/herdr-last-workspace
    '';

    passthru = {inherit herdr-last-workspace-bin;};

    meta = {
      homepage = "https://github.com/third774/herdr-last-workspace";
      # No LICENSE file; Cargo.toml declares MIT.
      license = lib.licenses.mit;
    };
  }
