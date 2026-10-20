# herdr-nix

[herdr](https://herdr.dev) plugins packaged for Nix, the way nixpkgs packages
`vimPlugins`, plus a Home Manager module that registers them.

## Usage

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    herdr-nix = {
      url = "github:lorenzorapetti/herdr-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };
}
```

Import the module into your Home Manager configuration:

```nix
{
  imports = [inputs.herdr-nix.homeModules.default];
}
```

Then enable herdr and pick plugins:

```nix
{herdrPlugins, ...}: {
  programs.herdr.enable = true;
  programs.herdr.plugins = [herdrPlugins.herdr-worktrunk];
}
```

`programs.herdr.enable`, `package` and `settings` come from Home Manager itself.
This flake adds `programs.herdr.plugins` and `programs.herdr.pluginSettings`.

### Configuring plugins

Each plugin reads its own config file from its herdr config dir
(`herdr plugin config-dir <id>`). Set `pluginSettings.<id>` as a Nix attrset,
and the module writes it in the file name and format (JSON, TOML or YAML)
that plugin expects:

```nix
{herdrPlugins, ...}: {
  programs.herdr.plugins = with herdrPlugins; [herdr-bar herdr-worktrunk];
  programs.herdr.pluginSettings = {
    herdr-bar = {                      # -> herdr-bar/config.json
      mouse = true;
      colors.accent = "#89b4fa";
    };
    worktrunk.show_remote_branches = true; # -> worktrunk/config.toml
  };
}
```

Keys are plugin ids, not attribute names (see the table below). Only plugins
listed in `programs.herdr.plugins` whose package declares a `settingsFile` can
be configured this way. For any other plugin, write the file yourself:

```nix
xdg.configFile."herdr/plugins/config/<id>/config.toml".text = ''
  key = "value"
'';
```

The module passes `herdrPlugins` to every module as an argument. You can also
use `overlays.default` and get it as `pkgs.herdrPlugins`, or reach it directly
at `inputs.herdr-nix.legacyPackages.${system}.herdrPlugins`.

### How registration works

Activation diffs `herdr plugin list` against the configured plugins:

- Configured plugins that aren't registered yet are linked with
  `herdr plugin link`. This works even when no herdr server is running.
- Plugins registered from the nix store that are no longer configured are
  unlinked. Unlinking needs a running server, so if none is running it is
  retried on the next activation.
- Plugins installed any other way, for example with `herdr plugin install`,
  are left alone.

## Binary cache

CI builds every plugin for x86_64-linux and aarch64-linux and pushes the
results to [Cachix](https://herdr-nix.cachix.org):

```nix
nix.settings = {
  extra-substituters = ["https://herdr-nix.cachix.org"];
  extra-trusted-public-keys = ["herdr-nix.cachix.org-1:UpdsQYx39PK0PToKQaa2EFq19Lsjs1M9Ho+X7VNt9gs="];
};
```

## Plugins

| Attribute | Plugin id | Upstream |
| --- | --- | --- |
| `herdr-agent-router` | `nidhi-singh02.agent-router` | [nidhi-singh02/agent-router](https://github.com/nidhi-singh02/agent-router) |
| `herdr-agent-usage` | `usagebar` | [senna-lang/herdr-agent-usage](https://github.com/senna-lang/herdr-agent-usage) |
| `herdr-annotate-full` | `annotate` | [plannotator/herdr-annotate](https://github.com/plannotator/herdr-annotate), with plannotator-tui document review |
| `herdr-annotate-lite` | `annotate` | [plannotator/herdr-annotate](https://github.com/plannotator/herdr-annotate), terminal annotations only |
| `herdr-auto-title` | `herdr.auto-title` | [kryptamine/herdr-auto-title](https://github.com/kryptamine/herdr-auto-title) |
| `herdr-automatic-rename` | `herdr-automatic-rename` | [qu8n/herdr-automatic-rename](https://github.com/qu8n/herdr-automatic-rename) |
| `herdr-bar` | `herdr-bar` | [jeffarese/herdr-bar](https://github.com/jeffarese/herdr-bar) |
| `herdr-board` | `herdr-board` | [nelsonPires5/herdr-board](https://github.com/nelsonPires5/herdr-board) |
| `herdr-captains-deck` | `herdr-firstmate-flow` | [deimantasnork/captains-deck](https://github.com/deimantasnork/captains-deck) |
| `herdr-clauth` | `clauth` | [uwuclxdy/clauth](https://github.com/uwuclxdy/clauth) |
| `herdr-collie` | `herdr.collie` | [AltanS/collie](https://github.com/AltanS/collie) |
| `herdr-crabbox` | `crabbox` | [openclaw/crabbox](https://github.com/openclaw/crabbox) |
| `herdr-dagr` | `herdr-dagr` | [aemrebarut/herdr-dagr](https://github.com/aemrebarut/herdr-dagr) |
| `herdr-file-annotator` | `jonasbaeumer.file-annotator` | [JonasBaeumer/herdr-file-annotator](https://github.com/JonasBaeumer/herdr-file-annotator) |
| `herdr-file-viewer` | `herdr-file-viewer` | [smarzban/herdr-file-viewer](https://github.com/smarzban/herdr-file-viewer) |
| `herdr-ghzinga` | `dutifuldev.ghzinga` | [osolmaz/ghzinga](https://github.com/osolmaz/ghzinga) |
| `herdr-heeler` | `heeler` | [ZingerLittleBee/Heeler](https://github.com/ZingerLittleBee/Heeler) |
| `herdr-hunk-diff` | `jhochenbaum.hunkdiff` | [jhochenbaum/herdr-hunk-diff](https://github.com/jhochenbaum/herdr-hunk-diff) |
| `herdr-lantern` | `aigora.lantern` | [aigorahub/herdr-lantern](https://github.com/aigorahub/herdr-lantern) |
| `herdr-last-workspace` | `third774.last-workspace` | [third774/herdr-last-workspace](https://github.com/third774/herdr-last-workspace) |
| `herdr-llmtrim` | `llmtrim.proxy` | [fkiene/llmtrim-herdr](https://github.com/fkiene/llmtrim-herdr) |
| `herdr-memex` | `nicosuave.memex` | [nicosuave/memex](https://github.com/nicosuave/memex) |
| `herdr-mirror` | `mirror` | [nikok6/herdr-mirror](https://github.com/nikok6/herdr-mirror) |
| `herdr-navigator` | `herdr-navigator` | [thanhdat77/herdr-navigator](https://github.com/thanhdat77/herdr-navigator) |
| `herdr-nvim` | `chmarax.herdr-nvim` | [ChmaraX/herdr-nvim](https://github.com/ChmaraX/herdr-nvim) |
| `herdr-ohmyzsh` | `ohmyzsh.shell` | [robbyrussell/herdr-ohmyzsh](https://github.com/robbyrussell/herdr-ohmyzsh) |
| `herdr-pairfob` | `pairfob` | [arronKler/pairfob](https://github.com/arronKler/pairfob) |
| `herdr-pi-workflows` | `osolmaz.pi-workflows` | [osolmaz/pi-workflows](https://github.com/osolmaz/pi-workflows) |
| `herdr-plugin-manager` | `ray.plugin-manager` | [speardragon/herdr-plugin-manager](https://github.com/speardragon/herdr-plugin-manager) |
| `herdr-plus` | `cloudmanic.herdr-plus` | [cloudmanic/herdr-plus](https://github.com/cloudmanic/herdr-plus) |
| `herdr-projects` | `herdr-projects` | [eliasstravik/herdr-projects](https://github.com/eliasstravik/herdr-projects) |
| `herdr-radar` | `hhdebb.herdr-radar` | [hhdebb/herdr-radar](https://github.com/hhdebb/herdr-radar) |
| `herdr-remote` | `herdr-remote.relay` | [dcolinmorgan/herdr-remote](https://github.com/dcolinmorgan/herdr-remote) |
| `herdr-reviewr` | `persiyanov.reviewr` | [persiyanov/herdr-reviewr](https://github.com/persiyanov/herdr-reviewr) |
| `herdr-roamgate` | `roamgate` | [powerfooI/roamgate](https://github.com/powerfooI/roamgate) |
| `herdr-sidebar` | `herdr-sidebar` | [alexarthurs/herdr-sidebar](https://github.com/alexarthurs/herdr-sidebar) |
| `herdr-splits-nvim` | `herdr-splits` | [lmilojevicc/herdr-splits.nvim](https://github.com/lmilojevicc/herdr-splits.nvim) |
| `herdr-spreader` | `herdr-spreader` | [yuk1ty/herdr-spreader](https://github.com/yuk1ty/herdr-spreader) |
| `herdr-tab-smart-rename` | `tab-smart-rename` | [iurysza/herdr-tab-smart-rename](https://github.com/iurysza/herdr-tab-smart-rename) |
| `herdr-telegram-agents` | `permgps.telegram-agents` | [permgps/herdr-telegram-agents](https://github.com/permgps/herdr-telegram-agents) |
| `herdr-termote` | `lamngockhuong.termote` | [lamngockhuong/termote](https://github.com/lamngockhuong/termote) |
| `herdr-termscope` | `termscope` | [iurysza/termscope](https://github.com/iurysza/termscope) |
| `herdr-tsk` | `herdr-tsk` | [smarzban/tsk](https://github.com/smarzban/tsk) |
| `herdr-ttt` | `ttt.editor` | [eugenioenko/ttt](https://github.com/eugenioenko/ttt) |
| `herdr-vim-navigation` | `vim-herdr-navigation` | [paulbkim-dev/vim-herdr-navigation](https://github.com/paulbkim-dev/vim-herdr-navigation) |
| `herdr-web-ui` | `devswha.herdr-web-ui` | [devswha/herdr-web-ui](https://github.com/devswha/herdr-web-ui) |
| `herdr-worktree-from-linear` | `tdi.worktree-from-linear` | [tdi/herdr-worktree-from-linear](https://github.com/tdi/herdr-worktree-from-linear) |
| `herdr-worktrunk` | `worktrunk` | [devashish2203/herdr-worktrunk](https://github.com/devashish2203/herdr-worktrunk) |
| `herdr-zoetrope` | `furkankly.zoetrope` | [furkankly/zoetrope](https://github.com/furkankly/zoetrope) |

Both `herdr-annotate` variants register as `annotate`, so enable only one;
the module asserts on duplicate ids.

Some plugins need a step outside their own directory, which is left to you:

- `herdr-ohmyzsh`: run its "install" action, or add `herdr.plugin.zsh` to
  Oh My Zsh yourself.
- `herdr-radar`: run its "configure" and "install-font" actions.
- `herdr-board`: agents call the `board` CLI; add
  `herdrPlugins.herdr-board.passthru.herdr-board-bin` to `home.packages`.
- `herdr-llmtrim`: install [llmtrim](https://github.com/fkiene/llmtrim), the
  proxy it drives, yourself.
- `herdr-pairfob`, `herdr-collie`, `herdr-roamgate`: the background service
  they install runs from the plugin's store path; rerun the start action after
  an upgrade to move it to the new one.

Plugin ids are what you reference in herdr's config, for example
`command = "worktrunk.open"` in a `plugin_action` key binding.

## Adding a plugin

Add a file to `pkgs/herdr-plugins/` and list it in
`pkgs/herdr-plugins/default.nix`:

```nix
{
  mkHerdrPlugin,
  fetchFromGitHub,
  bash,
  jq,
}:
mkHerdrPlugin rec {
  pname = "herdr-example";
  version = "1.0.0";
  src = fetchFromGitHub { /* ... */ };

  # Put first on PATH for every interpreter in `wrapCommands`.
  runtimeInputs = [bash jq];
  # Bare interpreters in the manifest's `command = ["…", …]` to wrap.
  wrapCommands = ["bash"];
  # File read from $HERDR_PLUGIN_CONFIG_DIR, if any; enables pluginSettings.
  settingsFile = "config.toml";
}
```

Plugin manifests run bare interpreters through whatever PATH the herdr server
happens to have. `mkHerdrPlugin` rewrites each `command = ["bash", …]` to a
wrapper that puts `runtimeInputs` first on PATH. Your own PATH is still
appended after them.

Set `pluginRoot = "<dir>";` when the manifest isn't at the top of the
repository; only that directory is installed. For a project with a `bun.lock`,
`fetchBunDeps { inherit pname version src; hash = …; }` gives its
`node_modules/`, which nixpkgs has no fetcher for. For what can't reasonably be
built from source, `callPackage ./prebuilt-release.nix {}` unpacks a release
tarball per system and patches it for Nix's loader; `update-plugins.sh`
refreshes the hash of every system it lists.

## Development

```sh
nix build .#herdr-worktrunk
nix flake check   # builds every plugin and tests activation against a real herdr
nix fmt
```
