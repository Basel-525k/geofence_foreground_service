#!/usr/bin/env bash
# Publishes the package to pub.dev, but only from an up to date, clean `main`.
#
# Why: 1.4.0 was once published from a feature branch that was never merged,
# so main later reused the version number and was missing that release's code.
#
# Usage:
#   tool/publish.sh            # run every check, then `flutter pub publish`
#   tool/publish.sh --dry-run  # run every check, then `flutter pub publish --dry-run`
set -euo pipefail

cd "$(dirname "$0")/.."

fail() { echo "publish: $*" >&2; exit 1; }

mode="${1:-}"
case "$mode" in
  ""|--dry-run) ;;
  *) fail "unknown argument '$mode' (expected nothing or --dry-run)" ;;
esac

branch="$(git rev-parse --abbrev-ref HEAD)"
[ "$branch" = "main" ] || fail "on branch '$branch'. Publish only from main: merge the release into main first."

[ -z "$(git status --porcelain)" ] || fail "working tree is not clean. Commit or stash the changes first."

git fetch --quiet origin main
[ "$(git rev-parse HEAD)" = "$(git rev-parse origin/main)" ] ||
  fail "local main is not the same commit as origin/main. Pull or push first."

version="$(sed -n 's/^version:[[:space:]]*//p' pubspec.yaml | tr -d '[:space:]')"
[ -n "$version" ] || fail "could not read the version from pubspec.yaml"

changelog_version="$(sed -n 's/^## //p' CHANGELOG.md | head -1 | tr -d '[:space:]')"
[ "$changelog_version" = "$version" ] ||
  fail "CHANGELOG.md starts with '$changelog_version' but pubspec.yaml says '$version'"

podspec_version="$(sed -n "s/^[[:space:]]*s.version[[:space:]]*=[[:space:]]*'\(.*\)'.*/\1/p" ios/geofence_foreground_service.podspec)"
[ "$podspec_version" = "$version" ] ||
  fail "ios/geofence_foreground_service.podspec says '$podspec_version' but pubspec.yaml says '$version'"

name="$(sed -n 's/^name:[[:space:]]*//p' pubspec.yaml | tr -d '[:space:]')"
published="$(curl -fsS "https://pub.dev/api/packages/$name" |
  python3 -c 'import json,sys; print("\n".join(v["version"] for v in json.load(sys.stdin)["versions"]))')" ||
  fail "could not read the published versions from pub.dev"
if grep -qxF "$version" <<<"$published"; then
  fail "$name $version is already on pub.dev. Bump the version first."
fi

echo "publish: main @ $(git rev-parse --short HEAD), $name $version, all checks passed"

if [ "$mode" = "--dry-run" ]; then
  flutter pub publish --dry-run
else
  flutter pub publish
  echo "publish: done. Tag the release: git tag v$version && git push origin v$version"
fi
