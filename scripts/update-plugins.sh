#!/usr/bin/env bash
# Bump every plugin in pkgs/herdr-plugins to its latest upstream release, and
# refresh the hashes that depend on it. Run from the repository root.
#
# A plugin pinned with `rev = "v${version}"` follows the newest vX.Y.Z tag; one
# pinned to a commit follows the default branch. Every hash in a bumped file is
# swapped for a unique placeholder, then the plugin's packages are built and
# each placeholder is replaced with the hash Nix reports, until they build. A
# placeholder can't match anything already in a store or cache, so a stale
# fixed-output derivation is never silently reused.
#
# Prints one "<plugin>: <old> → <new>" line per bumped plugin on stdout. A
# plugin that fails to build is left untouched, and the script exits non-zero
# after trying the rest.
set -euo pipefail

failed=()

system=$(nix eval --impure --raw --expr builtins.currentSystem)
packages=$(nix eval --json ".#packages.$system" --apply builtins.attrNames | jq -r '.[]')

latest_tag() {
  git ls-remote --tags --refs "https://github.com/$1/$2" \
    | sed -n 's#.*refs/tags/v\([0-9]\+\.[0-9]\+\.[0-9]\+\)$#\1#p' \
    | sort -V | tail -n1
}

latest_commit() {
  git ls-remote "https://github.com/$1/$2" HEAD | cut -f1
}

refresh_hashes() {
  local file=$1 name=$2 i=0 old placeholder out pairs specified got found
  local -a attrs placeholders=()

  while read -r old; do
    placeholder=$(nix hash convert --hash-algo sha256 --to sri \
      "$(printf 'herdr-nix-placeholder-%s-%s' "$file" "$i" | sha256sum | cut -d' ' -f1)")
    sed -i "s#\"$old\"#\"$placeholder\"#" "$file"
    placeholders+=("$placeholder")
    i=$((i + 1))
  done < <(grep -oE '(hash|cargoHash|vendorHash|npmDepsHash) = "sha256-[^"]+"' "$file" | grep -oE 'sha256-[^"]+')

  mapfile -t attrs < <(grep -xE "$name(-.+)?" <<<"$packages")
  attrs=("${attrs[@]/#/.#packages.$system.}")

  until out=$(nix build --no-link --keep-going "${attrs[@]}" 2>&1); do
    pairs=$(awk '/specified:/ { s = $2 } /got:/ && s { print s, $2; s = "" }' <<<"$out")
    found=
    while read -r specified got; do
      [[ " ${placeholders[*]} " == *" $specified "* ]] || continue
      sed -i "s#\"$specified\"#\"$got\"#" "$file"
      found=1
    done <<<"$pairs"
    if [[ -z $found ]]; then
      echo "$name: build failed:" >&2
      echo "$out" >&2
      return 1
    fi
  done
}

for file in pkgs/herdr-plugins/*.nix; do
  name=$(basename "$file" .nix)
  owner=$(sed -n 's/^ *owner = "\(.*\)";/\1/p' "$file" | head -n1)
  repo=$(sed -n 's/^ *repo = "\(.*\)";/\1/p' "$file" | head -n1)
  rev=$(sed -n 's/^ *rev = "\(.*\)";/\1/p' "$file" | head -n1)
  [[ -n $owner && -n $repo ]] || continue

  # shellcheck disable=SC2016 # the literal Nix interpolation
  if [[ $rev == 'v${version}' ]]; then
    old=$(sed -n 's/^ *version = "\(.*\)";/\1/p' "$file" | head -n1)
    new=$(latest_tag "$owner" "$repo")
    [[ -n $new && $new != "$old" ]] || continue
    sed -i "0,/version = \"$old\";/s//version = \"$new\";/" "$file"
  else
    old=$rev
    new=$(latest_commit "$owner" "$repo")
    [[ $old =~ ^[0-9a-f]{40}$ && -n $new && $new != "$old" ]] || continue
    sed -i "s/rev = \"$old\";/rev = \"$new\";/" "$file"
    old=${old:0:7} new=${new:0:7}
  fi

  echo "updating $name $old → $new" >&2
  if ! refresh_hashes "$file" "$name"; then
    git checkout -- "$file"
    failed+=("$name")
    continue
  fi
  echo "$name: $old → $new"
done

if ((${#failed[@]})); then
  echo "failed to update: ${failed[*]}" >&2
  exit 1
fi
