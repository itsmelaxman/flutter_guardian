# Test Apps

This folder contains self-contained fixtures for testing Flutter Guardian.

## guardian_clean_app

Expected to pass:

```bash
dart run flutter_guardian audit --project-root apps/guardian_clean_app
```

## guardian_sample_app

Expected to fail because it intentionally contains release-governance violations:

```bash
dart run flutter_guardian audit --project-root apps/guardian_sample_app
```

The unsafe app is written with only local Dart imports so editors do not show missing Flutter package URI errors while still exercising Guardian rules.
