import 'package:guardian_cli/guardian_cli.dart';

Future<void> main() async {
  await GuardianCli().run(['help']);
}
