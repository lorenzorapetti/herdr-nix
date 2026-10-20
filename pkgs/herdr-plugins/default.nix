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

  herdr-file-viewer = self.callPackage ./herdr-file-viewer.nix {};

  herdr-last-workspace = self.callPackage ./herdr-last-workspace.nix {};

  herdr-plus = self.callPackage ./herdr-plus.nix {};

  herdr-reviewr = self.callPackage ./herdr-reviewr.nix {};

  herdr-worktree-from-linear = self.callPackage ./herdr-worktree-from-linear.nix {};

  herdr-worktrunk = self.callPackage ./herdr-worktrunk.nix {};
})
