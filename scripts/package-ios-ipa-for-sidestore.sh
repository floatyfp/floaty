#!/usr/bin/env bash
# Build a SideStore/AltStore-friendly .ipa from a .app bundle (macOS only: uses codesign).
set -euo pipefail

RUNNER_APP="${1:?Usage: $0 <path/to/App.app> <output.ipa>}"
OUT_IPA="${2:?}"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "error: codesign requires macOS" >&2
  exit 1
fi

if [[ ! -d "$RUNNER_APP" ]]; then
  echo "error: app bundle not found: $RUNNER_APP" >&2
  exit 1
fi

OUT_IPA="$(cd "$(dirname "$OUT_IPA")" && pwd)/$(basename "$OUT_IPA")"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

mkdir -p "$WORKDIR/Payload"
cp -a "$RUNNER_APP" "$WORKDIR/Payload/"
APP="$WORKDIR/Payload/$(basename "$RUNNER_APP")"

rm -rf "$APP/_CodeSignature"
rm -rf "$APP/Frameworks"/*/_CodeSignature 2>/dev/null || true

if [[ -d "$APP/Frameworks" ]] && compgen -G "$APP/Frameworks"/* >/dev/null; then
  codesign -s - -f "$APP/Frameworks"/*
fi
codesign -s - -f "$APP"

mkdir -p "$(dirname "$OUT_IPA")"
rm -f "$OUT_IPA"
(
  cd "$WORKDIR"
  zip -r "$OUT_IPA" Payload
)

if unzip -l "$OUT_IPA" | awk 'NR>3 {print $4}' | grep -q '\.\./'; then
  echo "error: IPA still contains ../ in zip paths" >&2
  exit 1
fi

SIZE="$(stat -f%z "$OUT_IPA")"
echo "Wrote $OUT_IPA ($SIZE bytes)"
