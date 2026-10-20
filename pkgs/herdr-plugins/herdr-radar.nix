{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  nodejs,
}:
mkHerdrPlugin rec {
  pname = "herdr-radar";
  version = "1.4.8";

  src = fetchFromGitHub {
    owner = "hhdebb";
    repo = "herdr-radar";
    rev = "v${version}";
    hash = "sha256-vf8A7G94aC7zfjZ9KW944lzqwNssS3HS6DmRk/bQ+8o=";
  };

  # No npm dependencies. The [[build]] hook writes radar's managed blocks into
  # herdr's config and installs its font, which `herdr plugin link` doesn't
  # run; use the "configure" and "install-font" actions instead. Font tools
  # (fc-cache, fc-match) stay the user's.
  wrapCommands = ["node"];
  runtimeInputs = [nodejs];

  settingsFile = "config.toml";

  doCheck = true;
  nativeCheckInputs = [nodejs];
  checkPhase = ''
    runHook preCheck
    export HOME=$(mktemp -d)
    node --test
    runHook postCheck
  '';

  postInstall = ''
    find $out -mindepth 1 -maxdepth 1 \
      ! -name herdr-plugin.toml ! -name package.json ! -name bin ! -name lib ! -name dist \
      ! -name assets ! -name shell ! -name LICENSE ! -name THIRD_PARTY_NOTICES.md ! -name README.md \
      -exec rm -rf {} +
  '';

  meta = {
    homepage = "https://github.com/hhdebb/herdr-radar";
    changelog = "https://github.com/hhdebb/herdr-radar/blob/v${version}/CHANGELOG.md";
    license = with lib.licenses; [mit ofl];
  };
}
