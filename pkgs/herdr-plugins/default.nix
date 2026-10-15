{
  lib,
  newScope,
}:
lib.makeScope newScope (self: {
  mkHerdrPlugin = self.callPackage ./mk-herdr-plugin.nix {};

  herdr-worktrunk = self.callPackage ./herdr-worktrunk.nix {};
})
