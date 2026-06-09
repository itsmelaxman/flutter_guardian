import 'dart:io';

import 'package:guardian_core/guardian_core.dart';
import 'package:test/test.dart';

void main() {
  test('parses guardian.yaml policy', () {
    final policy = GuardianPolicy.fromYaml('''
security:
  require_obfuscation: true
  block_dotenv: false
architecture:
  forbid_feature_to_feature_imports: false
  feature_directory: modules
  layers:
    - core
    - data
    - ui
build:
  max_apk_size_mb: 42
''');

    expect(policy.security.requireObfuscation, isTrue);
    expect(policy.security.blockDotEnv, isFalse);
    expect(policy.architecture.forbidFeatureToFeatureImports, isFalse);
    expect(policy.architecture.featureDirectoryName, 'modules');
    expect(policy.architecture.layers, ['core', 'data', 'ui']);
    expect(policy.build.maxApkSizeMb, 42);
  });

  test('report fails when any error exists', () {
    final report = GuardianReport(
      projectRoot: '/app',
      snapshotHash: 'snapshot',
      generatedAt: DateTime.utc(2026),
      issues: const [
        GuardianIssue(
          id: 'security.debug_log',
          category: GuardianCategory.security,
          severity: GuardianSeverity.error,
          message: 'debug log',
        ),
      ],
    );

    expect(report.passed, isFalse);
    expect(report.score.security, 75);
    expect(report.toJson()['passed'], isFalse);
    expect(report.toJson()['reportHash'], report.reportHash);
  });

  test('project scanner creates deterministic immutable snapshot hash', () {
    final dir = Directory.systemTemp.createTempSync('guardian_snapshot_test');
    try {
      File('${dir.path}/b.txt').writeAsStringSync('b');
      File('${dir.path}/a.txt').writeAsStringSync('a');

      final first = const ProjectScanner().scan(dir);
      final second = const ProjectScanner().scan(dir);

      expect(first.files.map((file) => file.path), ['a.txt', 'b.txt']);
      expect(first.hash, second.hash);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}
