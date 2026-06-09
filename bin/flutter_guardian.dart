import 'dart:io';

import 'package:guardian_cli/guardian_cli.dart';

Future<void> main(List<String> args) async {
  exitCode = await GuardianCli().run(args);
}
