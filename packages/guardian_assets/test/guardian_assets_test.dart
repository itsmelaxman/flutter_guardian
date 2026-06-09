import 'dart:io';

import 'package:guardian_assets/guardian_assets.dart';
import 'package:guardian_core/guardian_core.dart';
import 'package:test/test.dart';

void main() {
  test('flags duplicate assets', () async {
    final dir = Directory.systemTemp.createTempSync('guardian_assets_test');
    try {
      Directory('${dir.path}/assets').createSync();
      File('${dir.path}/assets/a.txt').writeAsStringSync('same');
      File('${dir.path}/assets/b.txt').writeAsStringSync('same');
      final context = AnalyzerContext(
        projectRoot: dir,
        policy: const GuardianPolicy(),
        snapshot: const ProjectScanner().scan(dir),
      );
      final issues = await const AssetAnalyzer().analyze(context);

      expect(
        issues.map((issue) => issue.id),
        contains('assets.duplicate_file'),
      );
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
