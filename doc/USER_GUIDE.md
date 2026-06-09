# Flutter Guardian User Guide

## 1. Add Policy

Create `guardian.yaml` in the root of the Flutter app you want to audit.

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

## 2. Run Audit

```bash
dart run flutter_guardian audit
```

Custom paths:

```bash
dart run flutter_guardian audit \
  --project-root /path/to/app \
  --json build/reports/guardian-report.json \
  --html build/reports/guardian-report.html
```

## 3. Read Results

Audit writes two files:

- `guardian-report.json`: CI and dashboard friendly.
- `guardian-report.html`: human friendly.

The command exits with:

- `0`: no error-level violations.
- `1`: at least one error-level violation.

Warnings and info findings lower scores but do not fail the build.

## 4. CI Integration

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

The same command works in GitLab, Jenkins, Azure Pipelines, Bitrise, and Codemagic.

## 5. Generate Config

Input `.env`:

```env
API_URL=https://api.example.com
TIMEOUT=30
FEATURE_ENABLED=true
```

Generate Dart:

```bash
dart run flutter_guardian generate \
  --from .env \
  --out lib/generated/app_env.dart \
  --class AppEnv
```

Flutter Guardian will not overwrite an existing output file by default. Use `--force` only for files that are intentionally generated:

```bash
dart run flutter_guardian generate \
  --from .env \
  --out lib/generated/app_env.dart \
  --class AppEnv \
  --force
```

Generated output:

```dart
final class AppEnv {
  const AppEnv._();
  static const apiUrl = 'https://api.example.com';
  static const featureEnabled = true;
  static const timeout = 30;
}
```

YAML and JSON inputs are also supported:

```bash
dart run flutter_guardian generate --from config/app_env.yaml
dart run flutter_guardian generate --from config/app_env.json
```

## 6. Architecture Rules

Flutter Guardian treats this structure as feature-based architecture:

```text
lib/features/auth/
lib/features/profile/
```

When `forbid_feature_to_feature_imports` is enabled, this is blocked:

```dart
// lib/features/auth/presentation/login_page.dart
import '../../profile/domain/profile.dart';
```

Layer rules use:

```text
data
domain
presentation
```

The allowed direction is inward toward `domain`.

## 7. Build Rules

Build rules inspect committed files and generated artifacts when present:

- `*.apk`
- `*.aab`
- `AndroidManifest.xml`
- `android/app/build.gradle`
- `android/app/build.gradle.kts`
- CI workflow files for `--obfuscate`

For best results, run Guardian after producing release artifacts in CI.

## 8. Local Sample Apps

This repository includes test fixtures under `apps/`:

- `apps/guardian_sample_app`: intentionally fails and exercises major rules.
- `apps/guardian_clean_app`: expected to pass.

See [Testing](TESTING.md).
