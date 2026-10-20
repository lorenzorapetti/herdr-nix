{
  lib,
  callPackage,
  mkHerdrPlugin,
  fetchFromGitHub,
  makeWrapper,
}: let
  version = "0.4.3";

  src = fetchFromGitHub {
    owner = "zenbu-labs";
    repo = "terminal-code";
    rev = "v${version}";
    hash = "sha256-AanxPsn7YE5MD46Nr3Tzdo2tg3/GNK3Yn/ZZxhZlW5M=";
  };

  prebuiltRelease = callPackage ./prebuilt-release.nix {};

  # tode downloads this code-server build (CODE_SERVER_VERSION and its hashes
  # in src/codeserver/vendored.ts) on first use; bump it along with tode.
  # nixpkgs' code-server isn't in the binary cache, and building it is a VS
  # Code build.
  code-server = prebuiltRelease rec {
    pname = "code-server";
    version = "4.132.0";
    url = target: "https://github.com/coder/code-server/releases/download/v${version}/code-server-${version}-${target}.tar.gz";
    targets = {
      x86_64-linux = "linux-amd64";
      aarch64-linux = "linux-arm64";
      x86_64-darwin = "macos-amd64";
      aarch64-darwin = "macos-arm64";
    };
    releaseHashes = {
      x86_64-linux = "sha256-o40m9MuB92j+3f954pN/0/Ocg9Pai+PaciXhCH5i5O0=";
      aarch64-linux = "sha256-reVppnfRwE7mbvFTOCt+Fb8mH5VUB2Y8fdxrh/nuKfw=";
      x86_64-darwin = "sha256-7dx6jqnUV1rj5IE8Yk9+ASvhkaBnDS5Rh6YwH9WfYwc=";
      aarch64-darwin = "sha256-RJgU9mN/qvm2hUT3vOVg9exQDeaIgV1cf5r6elFXeZI=";
    };

    # The optional native Microsoft sign-in broker links webkit2gtk; VS Code
    # falls back to signing in through the browser without it.
    preInstall = ''
      rm -f lib/vscode/extensions/microsoft-authentication/dist/{libmsalruntime.so,msal-node-runtime.node}
    '';

    meta = {
      homepage = "https://github.com/coder/code-server";
      license = lib.licenses.mit;
      mainProgram = "code-server";
    };
  };

  # What the manifest's [[build]] hook installs into ~/.local/lib/tode.
  tode = prebuiltRelease {
    pname = "tode";
    inherit version;
    electron = true;
    url = target: "https://tode-releases.zenbu-labs.workers.dev/dl/stable/v${version}/tode-${target}.tar.gz";
    releaseHashes = {
      x86_64-linux = "sha256-LgsSMhy4PDtCuEUW8punlhiRUxTEWawWJ1zDPpw0AFE=";
      aarch64-linux = "sha256-cI7dX+dqspFUGOiLwe/lZUncNEahhkXRlNZzro1ggBw=";
      x86_64-darwin = "sha256-FE/X0+JeU/1PGrrGhgzX9UXBMoAjrPvDaRtIjsm//3Q=";
      aarch64-darwin = "sha256-6ikueIHvB2zNo8kAx+nd7JDoqADRtXS5MCwPEMNyqCc=";
    };

    nativeBuildInputs = [makeWrapper];

    # The launcher finds its tree through TODE_INSTALL_ROOT, ~/.local/lib/tode
    # otherwise.
    postInstall = ''
      makeWrapper $out/lib/tode/bin/tode $out/bin/tode \
        --set TODE_INSTALL_ROOT $out/lib/tode \
        --set-default TODE_CODE_SERVER ${code-server}/lib/code-server/bin/code-server
    '';

    meta = {
      homepage = "https://github.com/zenbu-labs/terminal-code";
      license = lib.licenses.mit;
      mainProgram = "tode";
    };
  };
in
  mkHerdrPlugin {
    pname = "herdr-terminal-code";
    inherit version src;
    pluginRoot = "herdr-plugin";

    runtimeInputs = [tode];

    postInstall = ''
      cp ${src}/LICENSE $out/
    '';

    passthru = {
      inherit code-server tode;
      releases = code-server.releases ++ tode.releases;
    };

    meta = {
      homepage = "https://github.com/zenbu-labs/terminal-code";
      changelog = "https://github.com/zenbu-labs/terminal-code/releases/tag/v${version}";
      license = lib.licenses.mit;
      inherit (tode.meta) platforms;
    };
  }
