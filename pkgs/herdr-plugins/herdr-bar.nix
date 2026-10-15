{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  coreutils,
  procps,
  python3,
}:
mkHerdrPlugin rec {
  pname = "herdr-bar";
  version = "0.7.3";

  src = fetchFromGitHub {
    owner = "jeffarese";
    repo = "herdr-bar";
    rev = "v${version}";
    hash = "sha256-LILcta5y5EilQ5B6DKjYyWlwB2k88Kx1rTZXqv/uJhw=";
  };

  # Standard library only. It also calls `ps` for agent ages, and `fc-match` to
  # detect a Nerd Font; that one is left to the user's PATH so it sees their
  # font configuration.
  wrapCommands = ["sh" "python3"];
  runtimeInputs = [coreutils procps python3];

  settingsFile = "config.json";

  doCheck = true;
  nativeCheckInputs = [procps python3];
  checkPhase = ''
    runHook preCheck
    PYTHONPATH=src python3 -m unittest discover -s tests -t .
    runHook postCheck
  '';

  postInstall = ''
    find $out -mindepth 1 -maxdepth 1 \
      ! -name herdr-plugin.toml ! -name run.py ! -name src ! -name LICENSE ! -name README.md \
      -exec rm -rf {} +
  '';

  meta = {
    homepage = "https://github.com/jeffarese/herdr-bar";
    changelog = "https://github.com/jeffarese/herdr-bar/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.mit;
  };
}
