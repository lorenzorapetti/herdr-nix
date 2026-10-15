{self}: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.herdr;

  herdr =
    if cfg.package == null
    then "herdr"
    else lib.getExe cfg.package;
  jq = lib.getExe pkgs.jq;

  # Plugin manifests this module wants to have registered. herdr resolves a
  # linked path to its canonical form, so the desired set is keyed on the
  # canonical store path of each configured plugin.
  desiredPluginManifests = builtins.toJSON (
    map (plugin: "${toString plugin}/herdr-plugin.toml") cfg.plugins
  );

  # Ids of the configured herdrPlugins packages; herdr keeps one registration
  # per id, so two variants of a plugin can't be enabled together.
  pluginIds = lib.concatMap (p: lib.optional (p ? pluginId) p.pluginId) cfg.plugins;

  # Plugin ids registered from the nix store that are no longer configured.
  stalePluginIds = ''
    .result.plugins[]?
    | select((.manifest_path // "") | startswith($store))
    | select((.manifest_path as $p | $desired | index($p)) | not)
    | .plugin_id
  '';

  # Configured plugin manifests that are not registered yet.
  missingPluginManifests = ''
    ($desired - [.result.plugins[]?.manifest_path?])[]
  '';
in {
  # Modelled on nix-community/home-manager#9815, but taking a list. If that PR
  # lands with its attrset-shaped option, evaluation fails with a duplicate
  # declaration of programs.herdr.plugins and this module has to adapt.
  options.programs.herdr.plugins = lib.mkOption {
    type = with lib.types; listOf (either package path);
    default = [];
    example = lib.literalExpression "[ herdrPlugins.herdr-worktrunk ]";
    description = ''
      Plugins to register with herdr. Each entry is a plugin package or a path
      to a plugin directory whose top level contains a
      {file}`herdr-plugin.toml` manifest, from which herdr reads the plugin id.

      Plugins registered outside this option, for example with
      {command}`herdr plugin install`, are left untouched.
    '';
  };

  config = lib.mkMerge [
    {
      _module.args.herdrPlugins =
        lib.mkDefault self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.herdrPlugins;
    }

    # Unconditional on cfg.plugins, so emptying the list unlinks what an earlier
    # generation registered.
    (lib.mkIf cfg.enable {
      assertions =
        [
          {
            assertion = lib.allUnique pluginIds;
            message = "programs.herdr.plugins: plugin ids must be unique, got ${toString pluginIds}.";
          }
        ]
        ++ map (plugin: {
          assertion = builtins.pathExists "${plugin}/herdr-plugin.toml";
          message = "programs.herdr.plugins: ${toString plugin} has no herdr-plugin.toml at its top level.";
        })
        (builtins.filter (p: !lib.isDerivation p) cfg.plugins);

      home.activation.herdrPlugins = lib.hm.dag.entryAfter ["writeBoundary"] ''
        registered="$(${herdr} plugin list --json 2>/dev/null || true)"

        # `plugin list` falls back to the on-disk registry when no server is
        # running, so the diff below still converges. `plugin unlink` needs a
        # reachable server and is therefore deferred (best effort) until the
        # next activation, while `plugin link` persists offline.
        printf '%s' "$registered" \
          | ${jq} -r \
            --arg store "${builtins.storeDir}/" \
            --argjson desired ${lib.escapeShellArg desiredPluginManifests} '${stalePluginIds}' \
          | while read -r id; do
              [ -n "$id" ] && run ${herdr} plugin unlink "$id" >/dev/null 2>&1 || true
            done

        printf '%s' "$registered" \
          | ${jq} -r --argjson desired ${lib.escapeShellArg desiredPluginManifests} '${missingPluginManifests}' \
          | while read -r manifest; do
              [ -n "$manifest" ] && run ${herdr} plugin link "$manifest" >/dev/null 2>&1 || true
            done
      '';
    })
  ];
}
