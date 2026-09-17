#!/usr/bin/env bash
# Checks TwintailLauncher's latest GitHub release and, if newer than what's
# pinned in version.json, updates the version + fetches fresh sha256 hashes
# for both .deb assets (amd64 + arm64).
#
# Exits 0 with no changes if already up to date.
# Exits 0 and rewrites version.json if an update was applied.
# Exits 1 on error (network failure, missing asset, hash fetch failure).

set -euo pipefail

REPO="TwintailTeam/TwintailLauncher"
FILE="version.json"

current_version=$(jq -r '.version' "$FILE")
current_amd64_hash=$(jq -r '.hashes.amd64' "$FILE")

latest_tag=$(curl -fsSL \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${REPO}/releases/latest" \
  | jq -r '.tag_name')

# Tags look like "ttl-v2.5.0"
latest_version="${latest_tag#ttl-v}"

if [ -z "$latest_version" ] || [ "$latest_version" = "null" ]; then
  echo "Failed to determine latest version from tag '$latest_tag'" >&2
  exit 1
fi

if [ "$latest_version" = "$current_version" ] && [[ "$current_amd64_hash" != *"0000000000"* ]]; then
  echo "Already up to date ($current_version)."
  exit 0
fi

echo "Update available: $current_version -> $latest_version"

fetch_hash() {
  local arch="$1"
  local url="https://github.com/${REPO}/releases/download/ttl-v${latest_version}/twintaillauncher_${latest_version}_${arch}.deb"

  echo "Fetching $arch asset..." >&2
  if ! curl -fsSL -o "/tmp/ttl_${arch}.deb" "$url"; then
    echo "Failed to download $url" >&2
    return 1
  fi

  # nix hash file gives SRI form directly (requires Nix 2.19+)
  nix hash file --sri "/tmp/ttl_${arch}.deb"
}

amd64_hash=$(fetch_hash amd64)
arm64_hash=$(fetch_hash arm64)

jq -n \
  --arg version "$latest_version" \
  --arg amd64 "$amd64_hash" \
  --arg arm64 "$arm64_hash" \
  '{version: $version, hashes: {amd64: $amd64, arm64: $arm64}}' \
  > "$FILE"

echo "Updated $FILE to version $latest_version."
