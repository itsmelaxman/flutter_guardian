import 'dart:convert';
import 'dart:io';

import 'package:guardian_core/guardian_core.dart';

final class ReportWriter {
  const ReportWriter();

  void writeJson(GuardianReport report, File output) {
    output.writeAsStringSync(report.toPrettyJson());
  }

  void writeHtml(GuardianReport report, File output) {
    output.writeAsStringSync(renderHtml(report));
  }
}

String renderHtml(GuardianReport report) {
  final rows = report.issues
      .map((issue) {
        final location = [issue.file, issue.line].whereType<Object>().join(':');
        return '<tr>'
            '<td>${_escape(issue.severity.name)}</td>'
            '<td>${_escape(issue.category.name)}</td>'
            '<td>${_escape(issue.id)}</td>'
            '<td>${_escape(location)}</td>'
            '<td>${_escape(issue.message)}</td>'
            '</tr>';
      })
      .join('\n');
  final scores = jsonEncode(report.score.toJson());
  return '''
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Flutter Guardian Report</title>
  <style>
    body { font-family: system-ui, sans-serif; margin: 32px; color: #172026; }
    table { border-collapse: collapse; width: 100%; }
    th, td { border-bottom: 1px solid #d7dee4; padding: 8px; text-align: left; }
    th { background: #eef3f7; }
    code { background: #eef3f7; padding: 2px 4px; }
  </style>
</head>
<body>
  <h1>Flutter Guardian Report</h1>
  <p>Status: <strong>${report.passed ? 'PASS' : 'FAIL'}</strong></p>
  <p>Scores: <code>${_escape(scores)}</code></p>
  <table>
    <thead>
      <tr><th>Severity</th><th>Category</th><th>Rule</th><th>Location</th><th>Message</th></tr>
    </thead>
    <tbody>
      $rows
    </tbody>
  </table>
</body>
</html>
''';
}

String _escape(String value) {
  return const HtmlEscape(HtmlEscapeMode.element).convert(value);
}
