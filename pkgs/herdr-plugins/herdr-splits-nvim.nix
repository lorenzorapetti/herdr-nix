{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  coreutils,
  gnugrep,
  gnused,
  neovim-unwrapped,
  vimPlugins,
}:
mkHerdrPlugin rec {
  pname = "herdr-splits-nvim";
  version = "0.5.3";

  src = fetchFromGitHub {
    owner = "lmilojevicc";
    repo = "herdr-splits.nvim";
    rev = "v${version}";
    hash = "sha256-7rHAPSjd2n16FGOcqI/1KNHl1yCmMOVVwiJl/eEU9n8=";
  };

  runtimeInputs = [coreutils gnugrep gnused];

  # No settingsFile: herdr-splits.conf is KEY=value lines, neither JSON nor
  # TOML.

  # The test runner is a git submodule upstream.
  doCheck = true;
  nativeCheckInputs = [neovim-unwrapped];
  checkPhase = ''
    runHook preCheck
    export HOME=$(mktemp -d)
    rm -rf deps/mini.test
    ln -s ${vimPlugins.mini-test} deps/mini.test
    nvim --headless --noplugin -i NONE -u scripts/minimal_init.lua -c "lua MiniTest.run()"
    runHook postCheck
  '';

  # lua/ and plugin/ are the Neovim half, kept so this path can also go on
  # Neovim's runtimepath.
  postInstall = ''
    find $out -mindepth 1 -maxdepth 1 \
      ! -name herdr-plugin.toml ! -name scripts ! -name lua ! -name plugin \
      ! -name LICENSE ! -name README.md \
      -exec rm -rf {} +
    rm -f $out/scripts/minimal_init.lua
  '';

  meta = {
    homepage = "https://github.com/lmilojevicc/herdr-splits.nvim";
    license = lib.licenses.mit;
  };
}
