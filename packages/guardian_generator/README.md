# guardian_generator

Compile-time config generator for Flutter Guardian.

Converts `.env`, YAML, or JSON inputs into Dart classes with `static const` values so release apps do not need runtime config parsing.

```bash
dart run flutter_guardian generate --from .env --out lib/generated/app_env.dart
```

See the root [README](https://github.com/itsmelaxman/flutter_guardian/blob/main/README.md) and [User Guide](https://github.com/itsmelaxman/flutter_guardian/blob/main/doc/USER_GUIDE.md).
