{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  expat,
  glib,
  gtk3,
  libgbm,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  nspr,
  nss,
  pango,
  systemd,
}:
# A prebuilt release tarball, unpacked into $out/lib/<pname> and patched for
# Nix's loader. Only for what can't reasonably be built from source, like the
# patched Electron (a Chromium build) behind zenbu-labs' tools.
#
# `releaseHashes` maps each Nix system to its tarball's hash, and `url` gets
# that system's name in `targets`. scripts/update-plugins.sh refreshes every
# system's hash through `passthru.releases`.
{
  pname,
  version,
  url,
  releaseHashes,
  targets ? {
    x86_64-linux = "linux-x64";
    aarch64-linux = "linux-arm64";
    x86_64-darwin = "darwin-x64";
    aarch64-darwin = "darwin-arm64";
  },
  # Link the libraries Electron needs.
  electron ? false,
  buildInputs ? [],
  passthru ? {},
  meta ? {},
  ...
} @ args: let
  inherit (stdenvNoCC.hostPlatform) system isLinux;

  electronLibs = [
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    glib
    gtk3
    libgbm
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    nspr
    nss
    pango
    (lib.getLib systemd)
  ];
in
  stdenvNoCC.mkDerivation (removeAttrs args ["url" "releaseHashes" "targets" "electron"]
    // {
      src = fetchurl {
        url = url (targets.${system} or (throw "${pname}: unsupported system ${system}"));
        hash = releaseHashes.${system};
      };

      nativeBuildInputs = lib.optionals isLinux [autoPatchelfHook] ++ args.nativeBuildInputs or [];
      buildInputs =
        lib.optionals isLinux ([stdenv.cc.cc.lib] ++ lib.optionals electron electronLibs)
        ++ buildInputs;

      dontConfigure = true;
      dontBuild = true;
      # Bundled binaries and Electron's resources stay as shipped.
      dontStrip = true;

      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib
        cp -a . $out/lib/${pname}
        runHook postInstall
      '';

      passthru =
        {
          releases =
            lib.mapAttrsToList (system: hash: {
              url = url targets.${system};
              inherit hash;
            })
            releaseHashes;
        }
        // passthru;

      meta =
        {
          platforms = builtins.attrNames releaseHashes;
          sourceProvenance = [lib.sourceTypes.binaryNativeCode];
        }
        // meta;
    })
