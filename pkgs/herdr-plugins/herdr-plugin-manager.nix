{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  bash,
  coreutils,
  curl,
  gawk,
  git,
  gnused,
  ncurses,
  perl,
  python3,
}:
mkHerdrPlugin rec {
  pname = "herdr-plugin-manager";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "speardragon";
    repo = "herdr-plugin-manager";
    rev = "v${version}";
    hash = "sha256-3o5ogbx8Yfcm9KgqSulnkyCLTDYwVVM/Tl99C7RkN0U=";
  };

  # Plugins it installs go through `herdr plugin install`, outside Nix; ones
  # linked from the Nix store are managed by the Home Manager module instead.
  runtimeInputs = [bash coreutils curl gawk git gnused ncurses python3];

  doCheck = true;
  nativeCheckInputs = [git perl python3];
  checkPhase = ''
    runHook preCheck
    export HOME=$(mktemp -d)
    # A test writes a stub with a `#!/usr/bin/env` shebang, which the sandbox
    # lacks.
    patchShebangs tests bin
    grep -rl /usr/bin/env tests | xargs sed -i "s#/usr/bin/env#$(command -v env)#g"
    bash tests/run.sh
    runHook postCheck
  '';

  # input_source.js is run by osascript on macOS only, but harmless elsewhere.
  postInstall = ''
    find $out -mindepth 1 -maxdepth 1 \
      ! -name herdr-plugin.toml ! -name bin ! -name LICENSE ! -name README.md \
      -exec rm -rf {} +
    rm -f $out/bin/*.ps1
  '';

  meta = {
    homepage = "https://github.com/speardragon/herdr-plugin-manager";
    changelog = "https://github.com/speardragon/herdr-plugin-manager/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.mit;
  };
}
