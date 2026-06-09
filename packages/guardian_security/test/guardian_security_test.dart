import 'dart:io';

import 'package:guardian_core/guardian_core.dart';
import 'package:guardian_security/guardian_security.dart';
import 'package:test/test.dart';

void main() {
  test('detects debug logs and secret literals through Dart AST', () async {
    final dir = Directory.systemTemp.createTempSync('guardian_security_test');
    try {
      File('${dir.path}/main.dart').writeAsStringSync(r'''
void main() {
  print('hello');
  const token = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.c2lnbmF0dXJlMTIz';
}
''');

      final context = AnalyzerContext(
        projectRoot: dir,
        policy: const GuardianPolicy(),
        snapshot: const ProjectScanner().scan(dir),
      );

      final issues = await const SecurityAnalyzer().analyze(context);

      expect(issues.map((issue) => issue.id), contains('security.debug_log'));
      expect(issues.map((issue) => issue.id), contains('security.jwt_literal'));
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
