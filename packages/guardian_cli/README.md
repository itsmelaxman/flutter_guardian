# guardian_cli

Command-line orchestration for Flutter Guardian.

Commands:

```bash
dart run flutter_guardian audit
dart run flutter_guardian generate --from .env
```

The CLI loads `guardian.yaml`, runs analyzers, writes JSON/HTML reports, and returns CI-friendly exit codes.

See the root [README](../../README.md) and [user guide](../../doc/USER_GUIDE.md).
