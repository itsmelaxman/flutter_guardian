# Guardian Sample App

This is an intentionally unsafe Flutter-style fixture for testing Flutter Guardian.

It is not a production app. It exists to prove that `flutter_guardian audit` catches release-governance violations across security, architecture, dependencies, assets, and build configuration.

The Dart source is self-contained and avoids real Flutter package imports so editors do not show missing URI errors when you inspect the fixture.

Expected audit result:

```text
exit code 1
```
