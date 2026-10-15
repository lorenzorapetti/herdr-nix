# herdr-nix

Nix flake packaging [herdr](https://herdr.dev) plugins (like nixpkgs'
`vimPlugins`) plus a Home Manager module that registers them. `README.md` is
the user-facing docs; keep it in sync with changes.

## Layout

- `flake.nix`: `overlays.default`, `homeModules.{default,herdr}`, and per-system
  outputs via `flake-utils.lib.eachDefaultSystem`: `legacyPackages.herdrPlugins`,
  `packages` (every plugin), `checks` (every plugin + `plugins-activation`),
  `formatter` (alejandra).
- `pkgs/herdr-plugins/default.nix`: `lib.makeScope` set; one
  `callPackage ./<attr>.nix {}` per plugin, alphabetical.
- `pkgs/herdr-plugins/mk-herdr-plugin.nix`: builder. Installs `src` with
  `herdr-plugin.toml` at the top, rewrites bare interpreters in manifest
  `command = [...]` arrays (`wrapCommands`) to wrappers putting
  `runtimeInputs` first on PATH, and exposes `passthru.pluginId` (manifest
  `id`) and `passthru.settingsFile`.
- `modules/home-manager.nix`: adds `programs.herdr.plugins` and
  `programs.herdr.pluginSettings` (written as JSON/TOML to each plugin's
  `settingsFile`), links/unlinks plugins on activation, asserts on duplicate ids.
- `checks/plugins-activation.nix`: runs the activation script against a real
  herdr and checks generated settings files.
- `scripts/update-plugins.sh`: bumps plugins to the latest `vX.Y.Z` tag (or
  default-branch commit) and refreshes `hash`/`cargoHash`/`vendorHash`. Run by
  `.github/workflows/update.yml`; `cachix.yml` builds and pushes on `main`.

## Commands

```sh
nix build .#<attr>
nix flake check -L   # all plugins + activation check
nix fmt              # alejandra
```

## Conventions

- Adding a plugin: use the `add-herdr-plugin` skill (`.claude/skills/`).
- Plugin files must stay parseable by `scripts/update-plugins.sh`: file
  basename = attribute name, `owner`/`repo`/`rev`/`version` on their own
  lines, `rev = "v${version}"` for tagged releases or a full commit hash
  otherwise.
- herdr never runs a manifest's `[[build]]` hooks on `plugin link`, so
  binaries those hooks would fetch are built from source in Nix (`<attr>-bin`,
  exposed in `passthru`) and symlinked where the manifest expects them.
- Tools a binary shells out to are added with `wrapProgram --suffix PATH`, so
  the user's own versions win; user-facing tools (editor, renderers, fonts)
  are left to the user's PATH.
- Comments explain why, briefly. Commit messages are short imperative
  subjects (`Add <attr> plugin`).
