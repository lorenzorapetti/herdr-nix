{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  coreutils,
  jq,
}:
mkHerdrPlugin rec {
  pname = "herdr-vim-navigation";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "paulbkim-dev";
    repo = "vim-herdr-navigation";
    rev = "v${version}";
    hash = "sha256-4lFrDzbdZiCIHIdkJ9q2lMlo+RCsu9eBXjK58VEuhDE=";
  };

  # jq tells Vim panes apart from the rest; without it every key moves focus.
  runtimeInputs = [coreutils jq];

  # editor/ holds the Vim and Neovim halves the user sources from their config.
  postInstall = ''
    find $out -mindepth 1 -maxdepth 1 \
      ! -name herdr-plugin.toml ! -name navigate.sh ! -name editor ! -name LICENSE ! -name README.md \
      -exec rm -rf {} +
  '';

  meta = {
    homepage = "https://github.com/paulbkim-dev/vim-herdr-navigation";
    license = lib.licenses.mit;
  };
}
