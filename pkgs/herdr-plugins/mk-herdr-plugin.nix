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
  # Directory of `src` holding herdr-plugin.toml, when it isn't the top level;
  # only that directory is installed.
  pluginRoot ? null,
  runtimeInputs ? [],
  wrapCommands ? ["bash"],
  # Top-level entries of `src` to install; null installs everything.
  files ? null,
  # File the plugin reads from its herdr config dir ($HERDR_PLUGIN_CONFIG_DIR),
  # e.g. "config.toml"; the Home Manager module writes `pluginSettings` to it.
  settingsFile ? null,
  meta ? {},
  passthru ? {},
  ...
} @ args: let
  wrapper = command:
    writeShellScript "${pname}-${command}" ''
      export PATH=${lib.makeBinPath runtimeInputs}''${PATH:+:$PATH}
      exec ${command} "$@"
    '';

  # Swap the leading program of every `command = ["<command>", …]` array, with
  # any whitespace (including newlines) after the bracket, and fail when a
  # listed command never appears so stale `wrapCommands` don't go unnoticed.
  substitutions =
    lib.concatMapStrings (command: ''
      sed -z -E -i 's#(command[[:space:]]*=[[:space:]]*\[[[:space:]]*)"${command}"#\1"${wrapper command}"#g' $out/herdr-plugin.toml
      grep -qF '"${wrapper command}"' $out/herdr-plugin.toml \
        || { echo 'mkHerdrPlugin: no `command = ["${command}", …]` in herdr-plugin.toml' >&2; exit 1; }
    '')
    wrapCommands;

  manifest = lib.importTOML "${src}/${lib.optionalString (pluginRoot != null) "${pluginRoot}/"}herdr-plugin.toml";
in
  stdenvNoCC.mkDerivation (
    removeAttrs args ["pluginRoot" "runtimeInputs" "wrapCommands" "files" "settingsFile"]
    // lib.optionalAttrs (pluginRoot != null) {
      sourceRoot = args.sourceRoot or "${src.name}/${pluginRoot}";
    }
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
            ${substitutions}
          ''}

          runHook postInstall
        '';

      passthru =
        {
          pluginId = manifest.id;
          inherit settingsFile;
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
