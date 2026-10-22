{
  lib,
  mkHerdrPlugin,
  fetchFromGitHub,
  rustPlatform,
}: let
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "yankewei";
    repo = "herdr-focus-notify";
    rev = "v${version}";
    hash = "sha256-/x772u1kge5ZDT674Vh7HWNsz3mUroxpFJahsVTp1Hk=";
  };

  # Upstream's [[build]] hook runs `cargo build`, which `herdr plugin link`
  # doesn't execute; build the binary here and point the manifest at it.
  focus-notify-bin = rustPlatform.buildRustPackage {
    pname = "herdr-focus-notify-bin";
    inherit version src;
    cargoHash = "sha256-cbxDZOvKLeEZ3raq1nMGioOv3+0ZLXNkAQ/wP2oLazQ=";

    # Four integration tests depend on real process spawn timing and a fake
    # socket server; they are flaky in the Nix sandbox (upstream CI runs them
    # on a normal macOS host). The other tests still run.
    checkFlags = [
      "--skip=a_hanging_agent_lookup_still_sends_the_notification_within_the_budget"
      "--skip=a_hanging_worktree_lookup_delays_the_notification_by_the_budget_at_most"
      "--skip=normal_notification_names_the_pane_and_never_requests_an_explanation"
      "--skip=notification_content_click_runs_the_focus_helper"
    ];

    meta.mainProgram = "herdr-focus-notify";
  };
in
mkHerdrPlugin {
  pname = "herdr-focus-notify";
  inherit version src;

  # Every manifest command runs bin/herdr-focus-notify directly.
  wrapCommands = [];

  postInstall = ''
    # Upstream's manifest runs target/release/... after its [[build]] hook;
    # rewrite it to the binary this derivation installs.
    sed -i 's#target/release/herdr-focus-notify#bin/herdr-focus-notify#g' $out/herdr-plugin.toml

    mkdir -p $out/bin
    ln -s ${lib.getExe focus-notify-bin} $out/bin/herdr-focus-notify

    find $out -mindepth 1 -maxdepth 1 \
      ! -name herdr-plugin.toml ! -name bin ! -name LICENSE ! -name README.md \
      -exec rm -rf {} +
  '';

  passthru = {inherit focus-notify-bin;};

  meta = {
    homepage = "https://github.com/yankewei/herdr-focus-notify";
    changelog = "https://github.com/yankewei/herdr-focus-notify/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.mit;
    # Runtime is macOS-only (it shells out to alerter), but the Rust code has
    # no compile-time macOS dependency; keep the default unix platforms so
    # Linux CI compiles it. Herdr's manifest `platforms = ["macos"]` prevents
    # linking on other systems.
  };
}
