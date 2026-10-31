{
  lib,
  callPackage,
  mkHerdrPlugin,
  fetchFromGitHub,
}: let
  version = "0.15.3";

  src = fetchFromGitHub {
    owner = "zenbu-labs";
    repo = "terminal-browser";
    rev = "v${version}";
    hash = "sha256-EoXsd18QRRfUXuPhDrI4UoXv6DaJP/IkVdGLmD6ryzY=";
  };

  # What the manifest's [[build]] hook installs into ~/.local/share.
  terminal-browser-bin = callPackage ./prebuilt-release.nix {} {
    pname = "terminal-browser";
    electron = true;
    inherit version;
    url = target: "https://terminal-browser.sh/install/dl/stable/v${version}/terminal-browser-${target}.tar.gz";
    releaseHashes = {
      x86_64-linux = "sha256-JE6ZW1VO2yn2bPB/f4MKdoha5qb6Iz3sU5gL+wpQlUE=";
      aarch64-linux = "sha256-afJqdr3MYeR4JzOqG5/LbgZ3SsnWsN8+n7sKpKuw9rw=";
      x86_64-darwin = "sha256-+Ru2Afk7KVm3aySm5LdlyretNaiFuXwHvqof0Hc/awU=";
      aarch64-darwin = "sha256-Ea+8HAzAuNErte/8LiuvCFB90yRW1uAFKCTBvDDBCPA=";
    };

    # The launcher follows symlinks to find its install root.
    postInstall = ''
      mkdir -p $out/bin
      ln -s $out/lib/terminal-browser/bin/terminal-browser $out/bin/terminal-browser
    '';

    meta = {
      homepage = "https://github.com/zenbu-labs/terminal-browser";
      license = lib.licenses.mit;
      mainProgram = "terminal-browser";
    };
  };
in
  mkHerdrPlugin {
    pname = "herdr-terminal-browser";
    inherit version src;
    pluginRoot = "herdr-plugin";

    runtimeInputs = [terminal-browser-bin];

    postInstall = ''
      cp ${src}/LICENSE $out/
    '';

    passthru = {
      inherit terminal-browser-bin;
      inherit (terminal-browser-bin) releases;
    };

    meta = {
      homepage = "https://github.com/zenbu-labs/terminal-browser";
      changelog = "https://github.com/zenbu-labs/terminal-browser/releases/tag/v${version}";
      license = lib.licenses.mit;
      inherit (terminal-browser-bin.meta) platforms;
    };
  }
