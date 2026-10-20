{
  lib,
  callPackage,
  mkHerdrPlugin,
  fetchFromGitHub,
}: let
  version = "0.13.4";

  src = fetchFromGitHub {
    owner = "zenbu-labs";
    repo = "terminal-browser";
    rev = "v${version}";
    hash = "sha256-UWEvvce32J5wlbdrB1+MZuuo1MG/FN2HaTV9W61sFXs=";
  };

  # What the manifest's [[build]] hook installs into ~/.local/share.
  terminal-browser-bin = callPackage ./prebuilt-release.nix {} {
    pname = "terminal-browser";
    electron = true;
    inherit version;
    url = target: "https://terminal-browser.sh/install/dl/stable/v${version}/terminal-browser-${target}.tar.gz";
    releaseHashes = {
      x86_64-linux = "sha256-YnfaqrqxZxGrPxlhzf+tnvrF5wrFXVB24shkltZJ06Q=";
      aarch64-linux = "sha256-DPVn2CGJlaJPts5LBsB8z1ioxReQYFgIc1Xx4vrRlp8=";
      x86_64-darwin = "sha256-AbxpkbrRIvQuTypRZKGY2DhLlEwDbeESB4/VH1jcZ+0=";
      aarch64-darwin = "sha256-8BcjDHjGCgfvRFGh6wqScn8LlVqPzYeuw1iRDF0MA8c=";
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
