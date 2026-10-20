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

  herdr-ghzinga = self.callPackage ./herdr-ghzinga.nix {};

  herdr-heeler = self.callPackage ./herdr-heeler.nix {};

  herdr-hunk-diff = self.callPackage ./herdr-hunk-diff.nix {};

  herdr-lantern = self.callPackage ./herdr-lantern.nix {};

  herdr-last-workspace = self.callPackage ./herdr-last-workspace.nix {};

  herdr-llmtrim = self.callPackage ./herdr-llmtrim.nix {};

  herdr-memex = self.callPackage ./herdr-memex.nix {};

  herdr-plus = self.callPackage ./herdr-plus.nix {};

  herdr-reviewr = self.callPackage ./herdr-reviewr.nix {};

  herdr-worktree-from-linear = self.callPackage ./herdr-worktree-from-linear.nix {};

  herdr-worktrunk = self.callPackage ./herdr-worktrunk.nix {};
})
