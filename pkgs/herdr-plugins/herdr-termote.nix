{
  lib,
  stdenvNoCC,
  mkHerdrPlugin,
  fetchFromGitHub,
  fetchPnpmDeps,
  buildGoModule,
  go_1_27,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  coreutils,
}: let
  version = "2.8.0";

  src = fetchFromGitHub {
    owner = "lamngockhuong";
    repo = "termote";
    rev = "v${version}";
    hash = "sha256-ZAMywSGV2kZyN2PyUz8ND4imauLntlyjipu/z6ZOaUE=";
  };

  # The web client the server embeds.
  pwa = stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "termote-pwa";
    inherit version src;

    pnpmWorkspaces = ["termote"];
    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname version src pnpmWorkspaces;
      pnpm = pnpm_10;
      fetcherVersion = 4;
      hash = "sha256-yLdcEeTX5HBfiyoDjIPbPDjy8VQ4Lh9pkdSRDx61O0w=";
    };

    nativeBuildInputs = [nodejs pnpm_10 pnpmConfigHook];

    buildPhase = ''
      runHook preBuild
      pnpm --filter termote build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r pwa/dist $out
      runHook postInstall
    '';
  });

  # The plugin runs `termote` from PATH, or from the ~/.local install its
  # installer makes; Nix's goes on PATH. go.mod asks for a newer patch release
  # than nixpkgs' default Go.
  termote = (buildGoModule.override {go = go_1_27;}) {
    pname = "termote";
    inherit version src;
    modRoot = "server";
    vendorHash = "sha256-BCoufqV8eSpt1KkYBSnLKcA1HN1n5AXPQ9xoyie7HBE=";

    preBuild = ''
      find webui/dist -mindepth 1 ! -name .gitkeep -delete
      cp -r ${pwa}/. webui/dist/
      chmod -R u+w webui/dist
    '';

    env.CGO_ENABLED = 0;
    ldflags = ["-s" "-w" "-X main.cliVersion=${version}"];

    # The suite drives real tmux, zellij and herdr sessions.
    doCheck = false;

    # Named after its module directory otherwise.
    postInstall = ''
      mv $out/bin/server $out/bin/termote
    '';

    meta.mainProgram = "termote";
  };
in
  mkHerdrPlugin {
    pname = "herdr-termote";
    inherit version src;
    pluginRoot = "herdr-plugin";

    wrapCommands = ["sh"];
    runtimeInputs = [coreutils termote];

    postInstall = ''
      cp ${src}/LICENSE $out/
    '';

    passthru = {inherit pwa termote;};

    meta = {
      homepage = "https://github.com/lamngockhuong/termote";
      changelog = "https://github.com/lamngockhuong/termote/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.mit;
    };
  }
