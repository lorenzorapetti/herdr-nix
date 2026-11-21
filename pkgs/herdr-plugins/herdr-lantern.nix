{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  coreutils,
  curl,
  findutils,
  gawk,
  git,
  gnused,
  python3,
}:
mkHerdrPlugin rec {
  pname = "herdr-lantern";
  version = "0.17.12";

  src = fetchFromGitHub {
    owner = "aigorahub";
    repo = "herdr-lantern";
    rev = "v${version}";
    hash = "sha256-3mD/Ar+kHRwTfoFF6WUfbv0rd9j2GJXJLqFboQcpF+8=";
  };

  # The agent CLI it runs in the chat pane (claude, codex, pi, ...) is the
  # user's.
  wrapCommands = ["sh"];
  runtimeInputs = [coreutils curl findutils gawk git gnused python3];

  # No settingsFile: helper.conf is KEY=value lines, neither JSON nor TOML.

  doCheck = true;
  nativeCheckInputs = [git python3];
  checkPhase = ''
    runHook preCheck
    export HOME=$(mktemp -d)
    python3 tests/codex_jobs.py
    python3 tests/session_cleanup.py
    python3 tests/teams.py
    runHook postCheck
  '';

  postInstall = ''
    find $out -mindepth 1 -maxdepth 1 \
      ! -name herdr-plugin.toml ! -name launch.sh ! -name open.sh ! -name evening.sh \
      ! -name lib.sh ! -name bin ! -name helper.conf.example ! -name prompt.md \
      ! -name herd-workflows.md ! -name LICENSE ! -name README.md \
      -exec rm -rf {} +
    rm -f $out/bin/*.cmd
  '';

  meta = {
    homepage = "https://github.com/aigorahub/herdr-lantern";
    changelog = "https://github.com/aigorahub/herdr-lantern/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.mit;
  };
}
