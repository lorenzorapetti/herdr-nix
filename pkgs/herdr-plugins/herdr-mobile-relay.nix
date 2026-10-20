{
  lib,
  stdenvNoCC,
  mkHerdrPlugin,
  fetchFromGitHub,
  buildGoModule,
  go_1_27,
  bun,
  coreutils,
  curl,
  gawk,
  gnugrep,
  gnused,
  openssl,
  util-linux,
}: let
  version = "0.22.10";
  # Stamped into the binary, the manifest and web/version.json; upstream uses
  # the commit, the tag keeps it in step with version bumps.
  revision = "v${version}";

  src = fetchFromGitHub {
    owner = "0cv";
    repo = "herdr-mobile-relay";
    rev = "v${version}";
    hash = "sha256-hw9I7guqG/QMl3TIwWxyvFMVTfEVlE56htNOvzWv9ds=";
  };

  relay = (buildGoModule.override {go = go_1_27;}) {
    pname = "herdr-mobile-relay-bin";
    inherit version src;
    vendorHash = "sha256-wczagA/d0yR0hXEfg6ohwlJ/cqBF6zxQL+PlfDD0HFA=";
    subPackages = ["cmd/herdr-mobile-relay"];

    env.CGO_ENABLED = 0;
    ldflags = ["-s" "-w" "-X main.version=${version}" "-X main.revision=${revision}"];

    meta.mainProgram = "herdr-mobile-relay";
  };

  goTarget = "${stdenvNoCC.hostPlatform.go.GOOS}/${stdenvNoCC.hostPlatform.go.GOARCH}";
in
  # herdr never runs the [[build]] hook, which installs a signed release bundle
  # into ~/.local/share/herdr-mobile-relay. The plugin directory is laid out as
  # that bundle instead (binary, stamped web app, release-manifest.json at the
  # top), which is where the relay scripts look first.
  mkHerdrPlugin {
    pname = "herdr-mobile-relay";
    inherit version src;

    files = ["herdr-plugin.toml" "relay" "LICENSE" "README.md"];
    wrapCommands = ["bash" "sh"];
    runtimeInputs = [coreutils curl gawk gnugrep gnused openssl util-linux];

    nativeBuildInputs = [bun];

    # The event hook only looks for the bundle under ~/.local/share.
    postPatch = ''
      substituteInPlace relay/plugin-on-event.sh \
        --replace-fail 'RELAY_BIN=''${HERDR_RELAY_BIN:-"$RELEASE_ROOT/current/herdr-mobile-relay"}' \
                       'RELAY_BIN=''${HERDR_RELAY_BIN:-"$(dirname "$0")/../herdr-mobile-relay"}'
    '';

    # As scripts/package-release.sh.
    postInstall = ''
      install -m755 ${lib.getExe relay} $out/herdr-mobile-relay
      cp -r web $out/web
      chmod -R u+w $out/web
      bun frontend/scripts/validate-build.mjs $out/web
      bun scripts/stamp-web-version.mjs $out/web/version.json ${version} ${revision}
    '';

    # The release manifest hashes every file in the plugin, so it's written
    # once patchShebangs is done with them.
    postFixup = ''
      $out/herdr-mobile-relay release-manifest $out ${version} ${revision} ${goTarget} >/dev/null
    '';

    doInstallCheck = true;
    installCheckPhase = ''
      $out/herdr-mobile-relay verify-release --version ${version} --revision ${revision} $out >/dev/null
    '';

    passthru = {inherit relay;};

    meta = {
      homepage = "https://github.com/0cv/herdr-mobile-relay";
      changelog = "https://github.com/0cv/herdr-mobile-relay/blob/v${version}/CHANGELOG.md";
      license = lib.licenses.agpl3Plus;
    };
  }
