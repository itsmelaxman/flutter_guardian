# Testing Flutter Guardian

Use these commands from the repository root.

## 1. Verify The Workspace

```bash
dart pub get
dart format .
dart run melos exec -- dart analyze .
dart run melos exec -- dart test
```

## 2. Run The Failing Sample

```bash
dart run flutter_guardian audit \
  --project-root apps/guardian_sample_app \
  --json apps/guardian_sample_app/guardian-report.json \
  --html apps/guardian_sample_app/guardian-report.html
```

Expected result:

```text
Flutter Guardian audit failed
exit code 1
```

Open `apps/guardian_sample_app/guardian-report.html` in a browser to inspect the human-readable report.

This fixture includes tiny `release/app-release.apk` and `release/app-release.aab` placeholder files so the build budget checks are exercised without committing real app binaries.

## 3. Run The Passing Sample

```bash
dart run flutter_guardian audit \
  --project-root apps/guardian_clean_app \
  --json apps/guardian_clean_app/guardian-report.json \
  --html apps/guardian_clean_app/guardian-report.html
```

Expected result:

```text
Flutter Guardian audit passed
exit code 0
```

## 4. Test Config Generation

```bash
dart run flutter_guardian generate \
  --from apps/guardian_clean_app/config/app_env.yaml \
  --out apps/guardian_clean_app/lib/generated/app_env.dart \
  --class AppEnv
```

Expected output:

```dart
final class AppEnv {
  const AppEnv._();
  static const apiUrl = 'https://api.example.com';
  static const featureEnabled = true;
  static const timeout = 30;
}
```

The generated file is ignored by Git.

If you run the command again, use `--force` to intentionally replace the generated file:

```bash
dart run flutter_guardian generate \
  --from apps/guardian_clean_app/config/app_env.yaml \
  --out apps/guardian_clean_app/lib/generated/app_env.dart \
  --class AppEnv \
  --force
```
