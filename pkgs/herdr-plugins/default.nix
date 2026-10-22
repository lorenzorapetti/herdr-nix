{
  lib,
  newScope,
}:
lib.makeScope newScope (self: {
  mkHerdrPlugin = self.callPackage ./mk-herdr-plugin.nix {};
  fetchBunDeps = self.callPackage ./fetch-bun-deps.nix {};

  herdr-agent-router = self.callPackage ./herdr-agent-router.nix {};

  herdr-agent-usage = self.callPackage ./herdr-agent-usage.nix {};

  herdr-annotate-full = self.callPackage ./herdr-annotate.nix {variant = "full";};
  herdr-annotate-lite = self.callPackage ./herdr-annotate.nix {variant = "lite";};

  herdr-auto-title = self.callPackage ./herdr-auto-title.nix {};

  herdr-automatic-rename = self.callPackage ./herdr-automatic-rename.nix {};

  herdr-bar = self.callPackage ./herdr-bar.nix {};

  herdr-board = self.callPackage ./herdr-board.nix {};

  herdr-captains-deck = self.callPackage ./herdr-captains-deck.nix {};

  herdr-clauth = self.callPackage ./herdr-clauth.nix {};

  herdr-collie = self.callPackage ./herdr-collie.nix {};

  herdr-crabbox = self.callPackage ./herdr-crabbox.nix {};

  herdr-dagr = self.callPackage ./herdr-dagr.nix {};

  herdr-file-annotator = self.callPackage ./herdr-file-annotator.nix {};

  herdr-file-viewer = self.callPackage ./herdr-file-viewer.nix {};

  herdr-focus-notify = self.callPackage ./herdr-focus-notify.nix {};

  herdr-ghzinga = self.callPackage ./herdr-ghzinga.nix {};

  herdr-heeler = self.callPackage ./herdr-heeler.nix {};

  herdr-hunk-diff = self.callPackage ./herdr-hunk-diff.nix {};

  herdr-lantern = self.callPackage ./herdr-lantern.nix {};

  herdr-last-workspace = self.callPackage ./herdr-last-workspace.nix {};

  herdr-llmtrim = self.callPackage ./herdr-llmtrim.nix {};

  herdr-memex = self.callPackage ./herdr-memex.nix {};

  herdr-mirror = self.callPackage ./herdr-mirror.nix {};

  herdr-mobile-relay = self.callPackage ./herdr-mobile-relay.nix {};

  herdr-navigator = self.callPackage ./herdr-navigator.nix {};

  herdr-nvim = self.callPackage ./herdr-nvim.nix {};

  herdr-oh-my-opencode-slim = self.callPackage ./herdr-oh-my-opencode-slim.nix {};

  herdr-ohmyzsh = self.callPackage ./herdr-ohmyzsh.nix {};

  herdr-pairfob = self.callPackage ./herdr-pairfob.nix {};

  herdr-pi-workflows = self.callPackage ./herdr-pi-workflows.nix {};

  herdr-plugin-manager = self.callPackage ./herdr-plugin-manager.nix {};

  herdr-plus = self.callPackage ./herdr-plus.nix {};

  herdr-projects = self.callPackage ./herdr-projects.nix {};

  herdr-radar = self.callPackage ./herdr-radar.nix {};

  herdr-remote = self.callPackage ./herdr-remote.nix {};

  herdr-reviewr = self.callPackage ./herdr-reviewr.nix {};

  herdr-roamgate = self.callPackage ./herdr-roamgate.nix {};

  herdr-sidebar = self.callPackage ./herdr-sidebar.nix {};

  herdr-splits-nvim = self.callPackage ./herdr-splits-nvim.nix {};

  herdr-spreader = self.callPackage ./herdr-spreader.nix {};

  herdr-tab-smart-rename = self.callPackage ./herdr-tab-smart-rename.nix {};

  herdr-telegram-agents = self.callPackage ./herdr-telegram-agents.nix {};

  herdr-terminal-browser = self.callPackage ./herdr-terminal-browser.nix {};

  herdr-terminal-code = self.callPackage ./herdr-terminal-code.nix {};

  herdr-termote = self.callPackage ./herdr-termote.nix {};

  herdr-termscope = self.callPackage ./herdr-termscope.nix {};

  herdr-tsk = self.callPackage ./herdr-tsk.nix {};

  herdr-ttt = self.callPackage ./herdr-ttt.nix {};

  herdr-vim-navigation = self.callPackage ./herdr-vim-navigation.nix {};

  herdr-web-ui = self.callPackage ./herdr-web-ui.nix {};

  herdr-worktree-from-linear = self.callPackage ./herdr-worktree-from-linear.nix {};

  herdr-worktrunk = self.callPackage ./herdr-worktrunk.nix {};

  herdr-zoetrope = self.callPackage ./herdr-zoetrope.nix {};
})
