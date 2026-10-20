{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
}:
mkHerdrPlugin rec {
  pname = "herdr-oh-my-opencode-slim";
  version = "3.0.5";

  src = fetchFromGitHub {
    owner = "alvinunreal";
    repo = "oh-my-opencode-slim";
    rev = "v${version}";
    hash = "sha256-kfMuSUbC5q3EPfxAcPlIkF13mgOQy0LjkCUWBmedoxA=";
  };

  # The manifest declares no actions, panes or events: the herdr side lives in
  # the OpenCode plugin, which opencode installs from npm and which finds herdr
  # through HERDR_PANE_ID. Linking only lists it in herdr.
  files = ["herdr-plugin.toml" "LICENSE" "README.md"];
  wrapCommands = [];

  meta = {
    homepage = "https://github.com/alvinunreal/oh-my-opencode-slim";
    changelog = "https://github.com/alvinunreal/oh-my-opencode-slim/releases/tag/v${version}";
    license = lib.licenses.mit;
  };
}
