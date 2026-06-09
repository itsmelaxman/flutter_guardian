# Contributing

Thanks for helping improve Flutter Guardian.

## Local Verification

Run these commands before opening a pull request:

```bash
dart pub get
dart format .
dart run melos exec -- dart analyze .
dart run melos exec -- dart test
```

## Sample App Verification

The clean sample must pass:

```bash
dart run flutter_guardian audit --project-root apps/guardian_clean_app
```

The unsafe sample must fail:

```bash
dart run flutter_guardian audit --project-root apps/guardian_sample_app
```

## Design Rules

- Keep analyzers stateless.
- Put shared contracts in `guardian_core`.
- Keep report output deterministic.
- Do not add Flutter UI/runtime dependencies to the core platform.
- Prefer focused package tests for new rules.
