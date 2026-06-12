# Changelog

## 1.0.2

- Replaced project license files with canonical Apache License 2.0 text for pub.dev recognition.
- Improved the main README with clearer installation, usage, policy, CI, report, package, and FAQ sections.
- Bumped workspace package versions and internal package constraints to `1.0.2`.

## 1.0.1

- Added a root package example at `example/flutter_guardian_example.dart`.
- Updated README and docs index links so user guides and policy examples are directly pressable from package pages.

## 1.0.0

- Added the `flutter_guardian audit` CLI flow.
- Added policy-as-code support through `guardian.yaml`.
- Added AST-based security scanning for debug logs, `.env` usage, JWT-like values, and secret-like literals.
- Added architecture boundary checks for feature imports and layer direction.
- Added dependency, asset, build, config generation, JSON report, and HTML report modules.
- Added `flutter_guardian generate` for `.env`, YAML, and JSON config inputs.
- Added Apache License 2.0 project licensing.
