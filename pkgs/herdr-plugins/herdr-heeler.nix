{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  buildNpmPackage,
  nodejs,
}: let
  version = "0.1.16";

  src = fetchFromGitHub {
    owner = "ZingerLittleBee";
    repo = "Heeler";
    rev = "v${version}";
    hash = "sha256-j8NVkhqZzqyJUjldr0Fcuddz1fCz2iCix1tYcHWZdCg=";
  };

  # Upstream's [[build]] step runs `npm ci`, which `herdr plugin link` doesn't
  # run; install the dependencies here instead.
  node-modules = buildNpmPackage {
    pname = "herdr-heeler-node-modules";
    inherit version src;
    sourceRoot = "${src.name}/plugin";
    npmDepsHash = "sha256-iqKtzJwxYTwlB/2s1QDWJCtgxTVuXIiv6xVosFiujgQ=";

    dontNpmBuild = true;

    doCheck = true;
    checkPhase = ''
      runHook preCheck
      export HOME=$(mktemp -d)
      # The tests write stubs with `#!/usr/bin/env` shebangs, which the sandbox
      # lacks.
      grep -rl /usr/bin/env test | xargs sed -i "s#/usr/bin/env#$(command -v env)#g"
      node --test
      runHook postCheck
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r node_modules $out/
      runHook postInstall
    '';
  };
in
  mkHerdrPlugin {
    pname = "herdr-heeler";
    inherit version src;
    pluginRoot = "plugin";

    wrapCommands = ["node"];
    runtimeInputs = [nodejs];

    postInstall = ''
      rm -rf $out/test $out/test-vectors
      cp ${src}/LICENSE $out/
      ln -s ${node-modules}/node_modules $out/node_modules
    '';

    passthru = {inherit node-modules;};

    meta = {
      homepage = "https://github.com/ZingerLittleBee/Heeler";
      license = lib.licenses.asl20;
    };
  }
