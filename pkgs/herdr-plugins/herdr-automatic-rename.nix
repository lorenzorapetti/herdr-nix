{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  bash,
  coreutils,
  git,
  gnugrep,
  gnused,
  jq,
}:
mkHerdrPlugin rec {
  pname = "herdr-automatic-rename";
  version = "0.13.1";

  src = fetchFromGitHub {
    owner = "qu8n";
    repo = "herdr-automatic-rename";
    rev = "v${version}";
    hash = "sha256-joPW6hvONbWbdChu/eUCjrnmIB/dBXIMxl76X0QVL5I=";
  };

  runtimeInputs = [bash coreutils git gnugrep gnused jq];

  # No settingsFile: it sources config.sh from its own XDG config directory.

  doCheck = true;
  nativeCheckInputs = [git jq];
  checkPhase = ''
    runHook preCheck
    export HOME=$(mktemp -d)
    # The tests run `/usr/bin/env` and write stubs with it as their shebang,
    # which the sandbox lacks.
    patchShebangs tests
    grep -rl /usr/bin/env tests | xargs sed -i "s#/usr/bin/env#$(command -v env)#g"
    tests/run.sh
    runHook postCheck
  '';

  # shell/ holds the hooks the user sources from their shell's startup file.
  postInstall = ''
    find $out -mindepth 1 -maxdepth 1 \
      ! -name herdr-plugin.toml ! -name '*.sh' ! -name shell \
      ! -name LICENSE ! -name README.md \
      -exec rm -rf {} +
    rm $out/install.sh
  '';

  meta = {
    homepage = "https://github.com/qu8n/herdr-automatic-rename";
    changelog = "https://github.com/qu8n/herdr-automatic-rename/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.mit;
  };
}
