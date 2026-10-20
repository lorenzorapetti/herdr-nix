{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  python3,
  television,
}:
mkHerdrPlugin rec {
  pname = "herdr-termscope";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "iurysza";
    repo = "termscope";
    rev = "v${version}";
    hash = "sha256-LtH5aGxNdFgF4gx6XGBB1+dq58rBKise8x10YkVp90c=";
  };

  # The [[build]] hook finds or installs Television and records its path,
  # which `herdr plugin link` doesn't run; fall back to Nix's when neither
  # TERMSCOPE_TV nor a recorded path names one.
  postPatch = ''
    substituteInPlace termscope_herdr.py \
      --replace-fail 'candidates.extend(_HOMEBREW_TV_PATHS)' 'candidates.extend([*_HOMEBREW_TV_PATHS, "${lib.getExe television}"])'
  '';

  wrapCommands = ["python3"];
  runtimeInputs = [python3];

  # test_installer.py covers the [[build]] hook replaced above.
  doCheck = true;
  nativeCheckInputs = [python3];
  checkPhase = ''
    runHook preCheck
    export HOME=$(mktemp -d)
    patchShebangs termscope
    rm tests/test_installer.py
    python3 -m unittest discover -s tests
    runHook postCheck
  '';

  postInstall = ''
    find $out -mindepth 1 -maxdepth 1 \
      ! -name herdr-plugin.toml ! -name termscope ! -name termscope_herdr.py ! -name cable \
      ! -name version.txt ! -name LICENSE ! -name README.md \
      -exec rm -rf {} +
  '';

  meta = {
    homepage = "https://github.com/iurysza/termscope";
    changelog = "https://github.com/iurysza/termscope/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.mit;
  };
}
