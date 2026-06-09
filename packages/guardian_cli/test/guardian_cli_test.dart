import 'dart:convert';
import 'dart:io';

import 'package:guardian_cli/guardian_cli.dart';
import 'package:test/test.dart';

void main() {
  test('audit writes reports and returns failure for violations', () async {
    final dir = Directory.systemTemp.createTempSync('guardian_cli_test');
    try {
      File('${dir.path}/pubspec.yaml').writeAsStringSync('name: app\n');
      File(
        '${dir.path}/main.dart',
      ).writeAsStringSync("void main() => print('debug');");

      final exitCode = await GuardianCli(
        out: _nullSink,
        err: _nullSink,
      ).run(['audit', '--project-root', dir.path]);

      expect(exitCode, 1);
      expect(File('${dir.path}/guardian-report.json').existsSync(), isTrue);
      expect(File('${dir.path}/guardian-report.html').existsSync(), isTrue);
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('generate writes const Dart config from env input', () async {
    final dir = Directory.systemTemp.createTempSync(
      'guardian_cli_generate_test',
    );
    try {
      File('${dir.path}/.env').writeAsStringSync('API_URL=https://example.com');
      final output = '${dir.path}/lib/generated/app_env.dart';

      final exitCode = await GuardianCli(
        out: _nullSink,
        err: _nullSink,
      ).run(['generate', '--from', '${dir.path}/.env', '--out', output]);

      expect(exitCode, 0);
      expect(File(output).readAsStringSync(), contains('static const apiUrl'));
    } finally {
      dir.deleteSync(recursive: true);
    }
  });

  test('generate refuses to overwrite output unless forced', () async {
    final dir = Directory.systemTemp.createTempSync(
      'guardian_cli_generate_overwrite_test',
    );
    try {
      File('${dir.path}/.env').writeAsStringSync('API_URL=https://example.com');
      final output = File('${dir.path}/lib/generated/app_env.dart')
        ..createSync(recursive: true)
        ..writeAsStringSync('manual');

      final exitCode = await GuardianCli(
        out: _nullSink,
        err: _nullSink,
      ).run(['generate', '--from', '${dir.path}/.env', '--out', output.path]);

      expect(exitCode, 1);
      expect(output.readAsStringSync(), 'manual');

      final forcedExitCode = await GuardianCli(out: _nullSink, err: _nullSink)
          .run([
            'generate',
            '--from',
            '${dir.path}/.env',
            '--out',
            output.path,
            '--force',
          ]);

      expect(forcedExitCode, 0);
      expect(output.readAsStringSync(), contains('static const apiUrl'));
    } finally {
      dir.deleteSync(recursive: true);
    }
  });
}

final _nullSink = _NullSink();

final class _NullSink implements IOSink {
  @override
  Encoding encoding = systemEncoding;

  @override
  void add(List<int> data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<void> close() async {}

  @override
  Future<void> get done => Future<void>.value();

  @override
  Future<void> flush() async {}

  @override
  void write(Object? object) {}

  @override
  void writeAll(Iterable<Object?> objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object? object = '']) {}
}
