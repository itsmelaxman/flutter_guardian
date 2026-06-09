import 'dart:io';

import 'package:guardian_architecture/guardian_architecture.dart';
import 'package:guardian_core/guardian_core.dart';
import 'package:test/test.dart';

void main() {
  test('detects feature-to-feature imports', () async {
    final dir = Directory.systemTemp.createTempSync(
      'guardian_architecture_test',
    );
    try {
      Directory(
        '${dir.path}/lib/features/a/presentation',
      ).createSync(recursive: true);
      File(
        '${dir.path}/lib/features/a/presentation/page.dart',
      ).writeAsStringSync("import '../../b/domain/model.dart';\n");

      final context = AnalyzerContext(
        projectRoot: dir,
        policy: const GuardianPolicy(),
        snapshot: const ProjectScanner().scan(dir),
      );
      final issues = await const ArchitectureAnalyzer().analyze(context);

      expect(
        issues.map((issue) => issue.id),
        contains('architecture.feature_boundary'),
      );
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
