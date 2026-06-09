import 'package:guardian_core/guardian_core.dart';

void main() {
  final policy = GuardianPolicy.fromYaml('security: {block_debug_logs: true}');
  print(policy.security.blockDebugLogs);
}
