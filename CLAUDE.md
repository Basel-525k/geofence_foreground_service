# geofence_foreground_service

## Publishing to pub.dev

- **Publish only from `main`.** Never run `flutter pub publish` on a feature or release branch.
  Merge the release into `main` first, then publish from `main` at the same commit as `origin/main`.
- Publish with `tool/publish.sh` (or check first with `tool/publish.sh --dry-run`), not with
  `flutter pub publish` directly. The script refuses to run unless you are on a clean, up to date
  `main`, the version is not already on pub.dev, and `CHANGELOG.md` and the iOS podspec carry the
  same version as `pubspec.yaml`.
- After publishing, tag the commit: `git tag v<version> && git push origin v<version>`.
- Why: 1.4.0 was published from `feat/polygon-cover-and-ios-initial-state` before that branch was
  merged. `main` then reused 1.4.0 for a different change and was missing the published code.
- Claude: never publish to pub.dev yourself. Leave that to the maintainer.

## Releases

- A release bumps the version in `pubspec.yaml`, `ios/geofence_foreground_service.podspec` and the
  top `CHANGELOG.md` heading together.
- `.pubignore` replaces `.gitignore` for pub. Keep the two in sync when `.gitignore` changes.
