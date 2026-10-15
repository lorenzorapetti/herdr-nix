{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  bash,
  coreutils,
  fzf,
  gawk,
  git,
  gnused,
  jq,
  worktrunk,
}:
mkHerdrPlugin rec {
  pname = "herdr-worktrunk";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "devashish2203";
    repo = "herdr-worktrunk";
    rev = "v${version}";
    hash = "sha256-Tx++zTQ1z4H8dLdCjOZ1yX9QGY/i6M3Yvi39KGHDoH4=";
  };

  # Newer releases also ship PowerShell scripts for Windows, which herdr's nix
  # builds don't target.
  postInstall = ''
    rm -rf $out/tests $out/*.ps1
  '';

  runtimeInputs = [bash coreutils fzf gawk git gnused jq worktrunk];

  meta = {
    homepage = "https://github.com/devashish2203/herdr-worktrunk";
    license = lib.licenses.mit;
  };
}
