{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  coreutils,
  git,
  less,
  python3,
  util-linux,
}: let
  # No release tags upstream yet.
  src = fetchFromGitHub {
    owner = "deimantasnork";
    repo = "captains-deck";
    rev = "3628cda7f75e2ddf2a65d91a360045c27067ed4b";
    hash = "sha256-4Eto0ATPsWR5+7vDndDFZcBUqIT1hF8Si/x3aUVGvYg=";
  };
in
  mkHerdrPlugin {
    pname = "herdr-captains-deck";
    version = (lib.importTOML "${src}/herdr-plugin.toml").version;
    inherit src;

    # Standard library only; `column` comes from util-linux.
    runtimeInputs = [coreutils git less python3 util-linux];

    doCheck = true;
    nativeCheckInputs = [git (python3.withPackages (ps: [ps.pytest])) util-linux];
    checkPhase = ''
      runHook preCheck
      export HOME=$(mktemp -d)
      # The tests write stub scripts with `#!/usr/bin/env` shebangs, which the
      # sandbox lacks.
      patchShebangs scripts tests
      grep -rl /usr/bin/env tests | xargs sed -i "s#/usr/bin/env#$(command -v env)#g"
      python3 -m pytest tests/ -q
      runHook postCheck
    '';

    # web/ is a separate phone bridge the manifest never starts.
    postInstall = ''
      find $out -mindepth 1 -maxdepth 1 \
        ! -name herdr-plugin.toml ! -name scripts ! -name fm_home.example \
        ! -name LICENSE ! -name README.md \
        -exec rm -rf {} +
    '';

    meta = {
      homepage = "https://github.com/deimantasnork/captains-deck";
      license = lib.licenses.mit;
    };
  }
