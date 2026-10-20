{
  lib,
  stdenvNoCC,
  bun,
}:
# node_modules/ for a project with a bun.lock, which nixpkgs has no fetcher for:
# a fixed-output `bun install`. Optional dependencies for every platform are
# installed so the hash is the same on every system. It sits in a directory
# named node_modules, which is where packages look up their own dependencies.
{
  pname,
  version,
  src,
  hash,
  # Directory of `src` holding package.json and bun.lock.
  root ? null,
  # Extra `bun install` flags, such as ["--production"].
  installFlags ? [],
}:
stdenvNoCC.mkDerivation ({
    pname = "${pname}-node-modules";
    inherit version src;

    nativeBuildInputs = [bun];

    dontConfigure = true;

    buildPhase = ''
      runHook preBuild
      export HOME=$(mktemp -d)
      bun install --frozen-lockfile --ignore-scripts --no-progress \
        --cpu='*' --os='*' ${lib.escapeShellArgs installFlags}
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      # Workspaces get node_modules/ of their own too; keep each where it was.
      find . -name node_modules -prune -type d | while read -r dir; do
        mkdir -p "$out/$(dirname "$dir")"
        cp -r "$dir" "$out/$dir"
      done
      runHook postInstall
    '';

    # Patching shebangs would add store references a fixed-output path can't have.
    dontFixup = true;

    outputHash = hash;
    outputHashMode = "recursive";
    impureEnvVars = lib.fetchers.proxyImpureEnvVars;
  }
  // lib.optionalAttrs (root != null) {
    sourceRoot = "${src.name}/${root}";
  })
