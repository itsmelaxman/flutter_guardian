import 'dart:io';

import 'package:guardian_core/guardian_core.dart';
import 'package:guardian_dependencies/guardian_dependencies.dart';
import 'package:test/test.dart';

void main() {
  test('flags loose hosted constraints', () async {
    final dir = Directory.systemTemp.createTempSync(
      'guardian_dependencies_test',
    );
    try {
      File('${dir.path}/pubspec.yaml').writeAsStringSync('''
name: app
dependencies:
  http: any
''');
      final context = AnalyzerContext(
        projectRoot: dir,
        policy: const GuardianPolicy(),
        snapshot: const ProjectScanner().scan(dir),
      );
      final issues = await const DependencyAnalyzer().analyze(context);

      expect(issues.single.id, 'dependencies.loose_constraint');
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
