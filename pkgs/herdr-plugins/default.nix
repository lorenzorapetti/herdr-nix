{
  lib,
  newScope,
}:
lib.makeScope newScope (self: {
  mkHerdrPlugin = self.callPackage ./mk-herdr-plugin.nix {};

  herdr-annotate-full = self.callPackage ./herdr-annotate.nix {variant = "full";};
  herdr-annotate-lite = self.callPackage ./herdr-annotate.nix {variant = "lite";};

  herdr-worktrunk = self.callPackage ./herdr-worktrunk.nix {};
})
