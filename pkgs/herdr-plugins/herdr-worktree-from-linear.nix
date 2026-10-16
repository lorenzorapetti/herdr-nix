{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  fzf,
  git,
  nodejs,
}:
mkHerdrPlugin rec {
  pname = "herdr-worktree-from-linear";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "tdi";
    repo = "herdr-worktree-from-linear";
    rev = "v${version}";
    hash = "sha256-lExUhr0T3oLz1gleEj9iiUTdlcI9s4FSMMgfYaruBSM=";
  };

  # No npm dependencies. glow, which renders the issue pane, is optional and
  # left to the user's PATH.
  wrapCommands = ["node"];
  runtimeInputs = [fzf git nodejs];

  settingsFile = "config.json";

  doCheck = true;
  nativeCheckInputs = [git nodejs];
  checkPhase = ''
    runHook preCheck
    export HOME=$(mktemp -d)
    node --test
    runHook postCheck
  '';

  postInstall = ''
    find $out -mindepth 1 -maxdepth 1 \
      ! -name herdr-plugin.toml ! -name package.json ! -name bin ! -name lib \
      ! -name config.example.json ! -name README.md \
      -exec rm -rf {} +
  '';

  # Upstream ships no license.
  meta.homepage = "https://github.com/tdi/herdr-worktree-from-linear";
}
