import 'package:guardian_core/guardian_core.dart';
import 'package:guardian_reports/guardian_reports.dart';
import 'package:test/test.dart';

void main() {
  test('renders HTML report with escaped issue content', () {
    final html = renderHtml(
      GuardianReport(
        projectRoot: '/app',
        snapshotHash: 'snapshot',
        generatedAt: DateTime.utc(2026),
        issues: const [
          GuardianIssue(
            id: 'security.secret',
            category: GuardianCategory.security,
            severity: GuardianSeverity.error,
            message: '<secret>',
          ),
        ],
      ),
    );

    expect(html, contains('&lt;secret&gt;'));
    expect(html, contains('Flutter Guardian Report'));
  });
}
