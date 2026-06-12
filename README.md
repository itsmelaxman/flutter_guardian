# Flutter Guardian

[![Pub](https://img.shields.io/pub/v/flutter_guardian.svg)](https://pub.dartlang.org/packages/flutter_guardian)
[![License](https://img.shields.io/badge/license-Apache%20License%202.0-blue)](https://github.com/itsmelaxman/flutter_guardian/blob/main/LICENSE)
[![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/itsmelaxman/flutter_guardian.svg)](https://github.com/itsmelaxman/flutter_guardian)

Flutter Guardian is a CI-first release audit tool for Flutter apps.

It helps you catch common release risks before your app ships, including security mistakes, architecture violations, dependency issues, asset problems, and build configuration gaps.

Use it locally while developing, or run it in CI to fail a build when important release rules are broken.

## What It Does

Flutter Guardian checks your project for:

- Security risks such as debug logs, `.env` usage, hardcoded secrets, and missing release safeguards.
- Architecture issues such as feature-to-feature imports and invalid layer direction.
- Dependency problems such as unsafe or weak version constraints.
- Asset issues such as missing, duplicate, or oversized assets.
- Build readiness problems such as large release artifacts or unsafe Android settings.
- Generated config safety for `.env`, YAML, and JSON inputs.

Flutter Guardian is not a UI framework, runtime SDK, or replacement for Flutter's analyzer. It is a release guard that runs before shipping.

## Installation

Activate it globally:

```bash
dart pub global activate flutter_guardian
```

Or add it to your app as a development dependency:

```yaml
dev_dependencies:
  flutter_guardian: ^1.0.1
```

If you are working from this repository:

```bash
dart pub get
dart run flutter_guardian audit
```

## Quick Start

Run an audit from your Flutter app root:

```bash
flutter_guardian audit
```

If you added it as a development dependency, run:

```bash
dart run flutter_guardian audit
```

Flutter Guardian writes reports and exits with a CI-friendly status code:

- `0` means no error-level violations were found.
- `1` means at least one error-level violation was found.

## Policy File

Create a `guardian.yaml` file in your Flutter app root to customize the rules.

```yaml
security:
  require_obfuscation: true
  block_dotenv: true
  block_debug_logs: true
  block_hardcoded_secrets: true

architecture:
  forbid_feature_to_feature_imports: true
  enforce_layer_direction: true
  feature_directory: features
  layers:
    - domain
    - data
    - presentation

build:
  max_apk_size_mb: 50
  max_aab_size_mb: 100
  require_signing: true
  block_cleartext_traffic: true

assets:
  max_image_size_kb: 1024

dependencies:
  warn_on_hosted_unpinned: true
```

If `guardian.yaml` is missing, Flutter Guardian uses conservative defaults.

## Reports

By default, Flutter Guardian produces:

- `guardian-report.json` for CI, dashboards, and automation.
- `guardian-report.html` for people reviewing the audit.

You can choose custom output paths:

```bash
flutter_guardian audit \
  --json build/reports/guardian-report.json \
  --html build/reports/guardian-report.html
```

## CI Example

GitHub Actions:

```yaml
name: guardian

on:
  pull_request:
  push:
    branches: [main]

jobs:
  guardian:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dart-lang/setup-dart@v1
      - run: dart pub get
      - run: dart run flutter_guardian audit
```

The same command can be used in GitLab, Jenkins, Azure Pipelines, Bitrise, Codemagic, and other CI systems.

## Config Generation

Flutter Guardian can generate compile-time Dart config from `.env`, YAML, or JSON files.

```bash
flutter_guardian generate \
  --from .env \
  --out lib/generated/app_env.dart \
  --class AppEnv
```

Existing output files are not overwritten unless `--force` is passed.

```bash
flutter_guardian generate \
  --from .env \
  --out lib/generated/app_env.dart \
  --class AppEnv \
  --force
```

## Packages

Flutter Guardian is split into small packages:

- `flutter_guardian`: main package and public executable.
- `guardian_cli`: command line interface.
- `guardian_core`: shared policy, scanner, and report contracts.
- `guardian_security`: security analyzer.
- `guardian_architecture`: architecture boundary analyzer.
- `guardian_dependencies`: dependency health analyzer.
- `guardian_assets`: asset analyzer.
- `guardian_generator`: Dart config generator.
- `guardian_reports`: JSON and HTML report writers.

Most users only need the main `flutter_guardian` package.

## FAQ

### Is Flutter Guardian a linter?

No. Flutter Guardian is a release audit tool. It complements Dart analyzer, Flutter lints, and custom lint rules by checking release-focused risks across project structure, assets, dependencies, build files, and policy configuration.

### Does it run inside my app?

No. Flutter Guardian does not run at app runtime. It runs as a command line tool before release, usually on a developer machine or in CI.

### Will it change my source code?

The `audit` command only scans your project and writes report files. The `generate` command writes a Dart config file only to the output path you provide.

### Can I use it without a `guardian.yaml` file?

Yes. If no policy file is found, Flutter Guardian uses conservative defaults. Add `guardian.yaml` when you want stricter or more project-specific rules.

### Can it fail my CI pipeline?

Yes. Flutter Guardian exits with code `1` when it finds error-level violations. This makes it easy to block unsafe releases in CI.

### Does it replace manual review?

No. It catches repeatable checks automatically, but it does not replace code review, security review, QA, or release approval.

### Which apps should use it?

Flutter Guardian is useful for production Flutter apps, teams with release gates, apps with feature-based architecture, and projects that want repeatable CI checks before publishing.

### Can I use only one module?

Yes. The repository is modular, but the recommended starting point is the main `flutter_guardian` package because it wires the common audit flow together.

## Example And Docs

- [Example](https://github.com/itsmelaxman/flutter_guardian/blob/main/example/flutter_guardian_example.dart)
- [User Guide](https://github.com/itsmelaxman/flutter_guardian/blob/main/doc/USER_GUIDE.md)
- [Testing Guide](https://github.com/itsmelaxman/flutter_guardian/blob/main/doc/TESTING.md)
- [Policy Example](https://github.com/itsmelaxman/flutter_guardian/blob/main/doc/policy.example.yaml)

## License

Apache License 2.0. See [LICENSE](LICENSE).
