import 'package:guardian_core/guardian_core.dart';
import 'package:guardian_reports/guardian_reports.dart';

void main() {
  final report = GuardianReport(
    projectRoot: '.',
    snapshotHash: 'snapshot',
    generatedAt: DateTime.utc(2026),
    issues: const [],
  );
  print(renderHtml(report));
}
