{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  buildGoModule,
}: let
  version = "0.18.0";

  src = fetchFromGitHub {
    owner = "kryptamine";
    repo = "herdr-auto-title";
    rev = "v${version}";
    hash = "sha256-HhzsksVi8e5hT45ZI8SfoqeYXZ8PSchV/XE4MTVDUfk=";
  };

  # Upstream's [[build]] step runs `go build` into the plugin directory, which
  # `herdr plugin link` doesn't run; build it here instead.
  herdr-auto-title-bin = buildGoModule {
    pname = "herdr-auto-title-bin";
    inherit version src;
    vendorHash = "sha256-QxFp1b7pf7bn3Hh0hyaj8ke5Z61N+WwjhHt3pFiapTs=";

    meta.mainProgram = "herdr-auto-title";
  };
in
  mkHerdrPlugin {
    pname = "herdr-auto-title";
    inherit version src;

    # Every entry point runs ./herdr-auto-title directly.
    wrapCommands = [];

    # No settingsFile: it reads herdr-auto-title/config.env from the XDG config
    # directory, not $HERDR_PLUGIN_CONFIG_DIR.

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name config.env.example ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +

      ln -s ${lib.getExe herdr-auto-title-bin} $out/herdr-auto-title
    '';

    passthru = {inherit herdr-auto-title-bin;};

    meta = {
      homepage = "https://github.com/kryptamine/herdr-auto-title";
      changelog = "https://github.com/kryptamine/herdr-auto-title/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
