{
  lib,
  callPackage,
  mkHerdrPlugin,
  fetchFromGitHub,
}: let
  version = "0.15.9";

  src = fetchFromGitHub {
    owner = "zenbu-labs";
    repo = "terminal-browser";
    rev = "v${version}";
    hash = "sha256-Voqtm/ij6nv+LqZZK+h7wHmdgisuQ7N7OlCuzfBDXj4=";
  };

  # What the manifest's [[build]] hook installs into ~/.local/share.
  terminal-browser-bin = callPackage ./prebuilt-release.nix {} {
    pname = "terminal-browser";
    electron = true;
    inherit version;
    url = target: "https://terminal-browser.sh/install/dl/stable/v${version}/terminal-browser-${target}.tar.gz";
    releaseHashes = {
      x86_64-linux = "sha256-0Z3OBQiBNuFkpTueRHpeAgf0cWjgCf/Ei2m1i8JGQJU=";
      aarch64-linux = "sha256-Kk2p+bj2SWlm2KAZDfM08/1u0eoQQt77rFk0P+8P55w=";
      x86_64-darwin = "sha256-Niij5V52b0ZBtqY6bnbFq0dLg/0uDf8rSR44bXdvSXM=";
      aarch64-darwin = "sha256-+gspcWsEx61H0IJdSIVEPyc/bc0ru2vr2I8qlSUTN3E=";
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
