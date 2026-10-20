{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  python3,
  uv,
}:
mkHerdrPlugin rec {
  pname = "herdr-remote";
  version = "0.8.1";

  src = fetchFromGitHub {
    owner = "dcolinmorgan";
    repo = "herdr-remote";
    rev = "v${version}";
    hash = "sha256-D1bqHgIRumsSS8ejleC+RH0CUp2Uyr+2MNWSMy9NTHs=";
  };

  # The hook only forwards events to the relay over UDP, with the standard
  # library; uv runs it on the python3 put first on PATH. The relay, Telegram
  # bot and dashboard in relay/ are started separately (relay/start.sh).
  wrapCommands = ["uv"];
  runtimeInputs = [python3 uv];

  postInstall = ''
    find $out -mindepth 1 -maxdepth 1 \
      ! -name herdr-plugin.toml ! -name relay ! -name LICENSE ! -name README.md ! -name QUICKSTART.md \
      -exec rm -rf {} +
    rm $out/relay/herdr-plugin.toml $out/relay/*.ps1
  '';

  meta = {
    homepage = "https://github.com/dcolinmorgan/herdr-remote";
    # Dual-licensed: AGPL-3.0-or-later or a commercial license.
    license = lib.licenses.agpl3Plus;
  };
}
