# Flutter Guardian

[![Pub](https://img.shields.io/pub/v/flutter_guardian.svg)](https://pub.dartlang.org/packages/flutter_guardian) 
[![License](https://img.shields.io/badge/license-Apache%20License%202.0-blue)](https://github.com/itsmelaxman/flutter_guardian/blob/master/LICENSE)
[![GitHub code size in bytes](https://img.shields.io/github/languages/code-size/itsmelaxman/flutter_guardian.svg)](https://github.com/itsmelaxman/flutter_guardian)

Flutter Guardian is a CI-first governance platform for Flutter applications.

It helps teams enforce:

- security rules
- architecture boundaries
- dependency safety
- asset health
- build readiness checks

Flutter Guardian is not a UI framework or runtime SDK. It runs before release and returns CI-friendly exit codes.

## Installation

Activate globally after publishing:

```bash
dart pub global activate flutter_guardian
```

Or add it as a development dependency:

```yaml
dev_dependencies:
  flutter_guardian: ^1.0.1
```

From this repository:

```bash
dart pub get
dart run flutter_guardian audit
```

## Usage

```bash
flutter_guardian audit
```

From source:

```bash
dart run flutter_guardian audit
```

## Policy

Create `guardian.yaml` in your Flutter app root:

```yaml
security:
  require_obfuscation: true
  block_dotenv: true
  block_debug_logs: true

architecture:
  forbid_feature_to_feature_imports: true

build:
  max_apk_size_mb: 50
```

## What It Checks

- Security issues
- Architecture violations
- Unsafe dependency constraints
- Duplicate or oversized assets
- Build configuration problems
- Missing release safeguards

## Output

Flutter Guardian produces:

- `guardian-report.json`
- `guardian-report.html`
- exit code `0` for pass
- exit code `1` for fail

## Config Generation

Generate compile-time Dart config from `.env`, YAML, or JSON:

```bash
flutter_guardian generate \
  --from .env \
  --out lib/generated/app_env.dart \
  --class AppEnv
```

Existing output files are not overwritten unless `--force` is passed.

## Modules

- `guardian_core`
- `guardian_cli`
- `guardian_security`
- `guardian_architecture`
- `guardian_dependencies`
- `guardian_assets`
- `guardian_generator`
- `guardian_reports`

## Example

- [Flutter Guardian Example](https://github.com/itsmelaxman/flutter_guardian/blob/main/example/flutter_guardian_example.dart)

## Docs

- [User Guide](https://github.com/itsmelaxman/flutter_guardian/blob/main/doc/USER_GUIDE.md)
- [Testing Guide](https://github.com/itsmelaxman/flutter_guardian/blob/main/doc/TESTING.md)
- [Policy Example](https://github.com/itsmelaxman/flutter_guardian/blob/main/doc/policy.example.yaml)

## License

Apache License 2.0. See [LICENSE](LICENSE).
