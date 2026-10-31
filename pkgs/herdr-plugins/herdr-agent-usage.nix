{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  buildGoModule,
  bash,
  coreutils,
  curl,
  gawk,
}: let
  version = "0.5.23";

  src = fetchFromGitHub {
    owner = "senna-lang";
    repo = "herdr-agent-usage";
    rev = "v${version}";
    hash = "sha256-q3KuB11K/8xwcUIcvhX/bhlbdt3invPqHERBLcEjJhk=";
  };

  # Upstream's [[build]] step runs `go build` or downloads a release binary into
  # bin/, which `herdr plugin link` doesn't run; build it here instead.
  usagebar = buildGoModule {
    pname = "usagebar";
    inherit version src;
    vendorHash = "sha256-JP3q+6jFY7U80a6zS/3gEIWgmH+YkvUEsvOQa3rMWEA=";

    subPackages = ["cmd/usagebar"];

    preCheck = ''
      export HOME=$(mktemp -d)
    '';

    meta.mainProgram = "usagebar";
  };
in
  mkHerdrPlugin {
    pname = "herdr-agent-usage";
    inherit version src;

    runtimeInputs = [bash coreutils curl gawk];

    settingsFile = "config.toml";

    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name bin ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +
      # bin/ensure-binary.sh stays: the setup action calls it, and it does
      # nothing once bin/usagebar exists.
      ln -s ${lib.getExe usagebar} $out/bin/usagebar
    '';

    passthru = {inherit usagebar;};

    meta = {
      homepage = "https://github.com/senna-lang/herdr-agent-usage";
      license = lib.licenses.mit;
    };
  }
