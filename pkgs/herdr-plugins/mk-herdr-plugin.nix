{
  lib,
  stdenvNoCC,
  writeShellScript,
}:
# Build a herdr plugin: a directory with a herdr-plugin.toml manifest at its top
# level, which is what `herdr plugin link` expects.
#
# Manifests run bare interpreters (`command = ["bash", ...]`) resolved through
# whatever PATH the herdr server has. Every interpreter listed in
# `wrapCommands` is swapped for a wrapper that puts `runtimeInputs` first on
# PATH, so the plugin doesn't depend on the server's environment. The rest of
# PATH is kept, so the user's own tools (editor, shell hooks) stay reachable.
{
  pname,
  version,
  src,
  runtimeInputs ? [],
  wrapCommands ? ["bash"],
  # Top-level entries of `src` to install; null installs everything.
  files ? null,
  meta ? {},
  passthru ? {},
  ...
} @ args: let
  wrapper = command:
    writeShellScript "${pname}-${command}" ''
      export PATH=${lib.makeBinPath runtimeInputs}''${PATH:+:$PATH}
      exec ${command} "$@"
    '';

  substitutions = lib.concatMapStringsSep " " (command:
    "--replace-fail ${lib.escapeShellArg ''command = ["${command}",''} "
    + lib.escapeShellArg ''command = ["${wrapper command}",'')
  wrapCommands;

  manifest = lib.importTOML "${src}/herdr-plugin.toml";
in
  stdenvNoCC.mkDerivation (
    removeAttrs args ["runtimeInputs" "wrapCommands" "files"]
    // {
      dontConfigure = args.dontConfigure or true;
      dontBuild = args.dontBuild or true;

      installPhase =
        args.installPhase or ''
          runHook preInstall

          mkdir -p $out
          ${
            if files == null
            then "cp -r . $out/"
            else "cp -r ${lib.escapeShellArgs files} $out/"
          }
          ${lib.optionalString (wrapCommands != []) ''
            substituteInPlace $out/herdr-plugin.toml ${substitutions}
          ''}

          runHook postInstall
        '';

      passthru =
        {
          pluginId = manifest.id;
        }
        // passthru;

      meta =
        {
          description = manifest.description or "herdr plugin ${manifest.id}";
          platforms = lib.platforms.unix;
        }
        // meta;
    }
  )
