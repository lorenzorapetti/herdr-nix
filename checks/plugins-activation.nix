{
  self,
  pkgs,
  home-manager,
}: let
  inherit (pkgs) lib;

  hmConfig = home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    modules = [
      self.homeModules.default
      ({herdrPlugins, ...}: {
        home = {
          username = "test";
          homeDirectory = "/home/test";
          stateVersion = "25.11";
        };
        programs.herdr = {
          enable = true;
          plugins = [herdrPlugins.herdr-worktrunk herdrPlugins.herdr-bar];
          pluginSettings = {
            worktrunk.picker_placement = "popup";
            herdr-bar.colors.accent = "#89b4fa";
          };
        };
      })
    ];
  };

  inherit (hmConfig) config;
  herdr = lib.getExe config.programs.herdr.package;
  manifest = "${self.packages.${pkgs.stdenv.hostPlatform.system}.herdr-worktrunk}/herdr-plugin.toml";
  activation = pkgs.writeText "herdr-plugins-activation" config.home.activation.herdrPlugins.data;
  settingsFile = path: config.xdg.configFile."herdr/plugins/config/${path}".source;
in
  pkgs.runCommand "herdr-plugins-activation-check" {nativeBuildInputs = [pkgs.jq];} ''
    grep -qxF 'picker_placement = "popup"' ${settingsFile "worktrunk/config.toml"} \
      || { echo "unexpected worktrunk config.toml:"; cat ${settingsFile "worktrunk/config.toml"}; exit 1; }
    [ "$(jq -r .colors.accent ${settingsFile "herdr-bar/config.json"})" = "#89b4fa" ] \
      || { echo "unexpected herdr-bar config.json:"; cat ${settingsFile "herdr-bar/config.json"}; exit 1; }

    export HOME=$TMPDIR/home XDG_CONFIG_HOME=$TMPDIR/home/.config
    mkdir -p $XDG_CONFIG_HOME
    run() { "$@"; }

    registrations() {
      ${herdr} plugin list --json \
        | jq --arg m ${lib.escapeShellArg manifest} '[.result.plugins[] | select(.manifest_path == $m)] | length'
    }

    source ${activation}
    [ "$(registrations)" = 1 ] || { echo "worktrunk not registered:"; ${herdr} plugin list --json; exit 1; }

    # Re-running must not register it twice.
    source ${activation}
    [ "$(registrations)" = 1 ] || { echo "activation is not idempotent:"; ${herdr} plugin list --json; exit 1; }

    touch $out
  ''
