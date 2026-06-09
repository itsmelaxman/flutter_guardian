import 'dart:io';

import 'package:guardian_architecture/guardian_architecture.dart';
import 'package:guardian_assets/guardian_assets.dart';
import 'package:guardian_core/guardian_core.dart';
import 'package:guardian_dependencies/guardian_dependencies.dart';
import 'package:guardian_generator/guardian_generator.dart';
import 'package:guardian_reports/guardian_reports.dart';
import 'package:guardian_security/guardian_security.dart';

final class GuardianCli {
  GuardianCli({
    List<GuardianAnalyzer>? analyzers,
    this.scanner = const ProjectScanner(),
    this.reportWriter = const ReportWriter(),
    IOSink? out,
    IOSink? err,
  }) : analyzers =
           analyzers ??
           const [
             SecurityAnalyzer(),
             ArchitectureAnalyzer(),
             DependencyAnalyzer(),
             AssetAnalyzer(),
             BuildAnalyzer(),
           ],
       out = out ?? stdout,
       err = err ?? stderr;

  final List<GuardianAnalyzer> analyzers;
  final ProjectScanner scanner;
  final ReportWriter reportWriter;
  final IOSink out;
  final IOSink err;

  Future<int> run(List<String> args) async {
    if (args.isEmpty || args.first == 'help' || args.first == '--help') {
      out.writeln(usage);
      return 0;
    }
    return switch (args.first) {
      'audit' => _audit(args.skip(1).toList()),
      'generate' => _generate(args.skip(1).toList()),
      _ => _unknown(args.first),
    };
  }

  Future<int> _audit(List<String> args) async {
    final root = Directory(
      _option(args, '--project-root') ?? Directory.current.path,
    );
    final jsonPath =
        _option(args, '--json') ?? '${root.path}/guardian-report.json';
    final htmlPath =
        _option(args, '--html') ?? '${root.path}/guardian-report.html';

    final policy = GuardianPolicy.load(root);
    final context = AnalyzerContext(
      projectRoot: root,
      policy: policy,
      snapshot: scanner.scan(root),
    );

    final issues = <GuardianIssue>[];
    for (final analyzer in analyzers) {
      issues.addAll(await analyzer.analyze(context));
    }
    final report = GuardianReport(
      projectRoot: root.path,
      snapshotHash: context.snapshot.hash,
      generatedAt: DateTime.now().toUtc(),
      issues: issues,
    );

    reportWriter.writeJson(report, File(jsonPath));
    reportWriter.writeHtml(report, File(htmlPath));

    out.writeln(
      'Flutter Guardian audit ${report.passed ? 'passed' : 'failed'}',
    );
    out.writeln('JSON report: $jsonPath');
    out.writeln('HTML report: $htmlPath');
    out.writeln('Score: ${report.score.overall}/100');
    out.writeln('Report hash: ${report.reportHash}');
    out.writeln('Violations: ${report.issues.length}');
    return report.passed ? 0 : 1;
  }

  Future<int> _generate(List<String> args) async {
    final inputPath = _option(args, '--from') ?? _option(args, '--input');
    if (inputPath == null) {
      err.writeln('Missing required option --from <path>.');
      err.writeln(usage);
      return 1;
    }

    final input = File(inputPath);
    if (!input.existsSync()) {
      err.writeln('Config input was not found: $inputPath');
      return 1;
    }

    final className = _option(args, '--class') ?? 'AppEnv';
    final outputPath = _option(args, '--out') ?? 'lib/generated/app_env.dart';
    final generated = _generateConfig(
      input.path,
      input.readAsStringSync(),
      className,
    );
    final output = File(outputPath);
    final force = args.contains('--force');
    if (output.existsSync() && !force) {
      err.writeln(
        'Refusing to overwrite existing file: $outputPath. '
        'Pass --force to replace generated config.',
      );
      return 1;
    }
    output.parent.createSync(recursive: true);
    output.writeAsStringSync(generated.source);
    out.writeln('Generated ${generated.className} at $outputPath');
    return 0;
  }

  int _unknown(String command) {
    err.writeln('Unknown command "$command".');
    err.writeln(usage);
    return 1;
  }
}

const usage = '''
Flutter Guardian

Usage:
  dart run flutter_guardian audit [--project-root <path>] [--json <path>] [--html <path>]
  dart run flutter_guardian generate --from <.env|.yaml|.json> [--out <path>] [--class <name>] [--force]

Exit codes:
  0 = pass
  1 = fail
''';

String? _option(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}

GeneratedConfig _generateConfig(String path, String source, String className) {
  final generator = const AppEnvGenerator();
  final lower = path.toLowerCase();
  if (lower.endsWith('.json')) {
    return generator.fromJson(source, className: className);
  }
  if (lower.endsWith('.yaml') || lower.endsWith('.yml')) {
    return generator.fromYaml(source, className: className);
  }
  return generator.fromEnv(source, className: className);
}

final class BuildAnalyzer implements GuardianAnalyzer {
  const BuildAnalyzer();

  @override
  String get id => 'build';

  @override
  GuardianCategory get category => GuardianCategory.build;

  @override
  Future<List<GuardianIssue>> analyze(AnalyzerContext context) async {
    return [
      ..._artifactSizes(context),
      ..._androidManifest(context),
      ..._androidSigning(context),
      ..._obfuscation(context),
    ];
  }

  Iterable<GuardianIssue> _artifactSizes(AnalyzerContext context) sync* {
    for (final file in context.files) {
      final lower = file.path.toLowerCase();
      if (lower.endsWith('.apk')) {
        final maxBytes = context.policy.build.maxApkSizeMb * 1024 * 1024;
        if (file.sizeBytes > maxBytes) {
          yield _issue(
            'build.apk_size',
            GuardianSeverity.error,
            file.path,
            'APK exceeds ${context.policy.build.maxApkSizeMb} MB.',
            {'sizeBytes': file.sizeBytes},
          );
        }
      }
      if (lower.endsWith('.aab')) {
        final maxBytes = context.policy.build.maxAabSizeMb * 1024 * 1024;
        if (file.sizeBytes > maxBytes) {
          yield _issue(
            'build.aab_size',
            GuardianSeverity.error,
            file.path,
            'AAB exceeds ${context.policy.build.maxAabSizeMb} MB.',
            {'sizeBytes': file.sizeBytes},
          );
        }
      }
    }
  }

  Iterable<GuardianIssue> _androidManifest(AnalyzerContext context) sync* {
    for (final file in context.files.where(
      (file) => file.path.endsWith('AndroidManifest.xml'),
    )) {
      final content = file.file.readAsStringSync();
      if (context.policy.build.blockCleartextTraffic &&
          content.contains('android:usesCleartextTraffic="true"')) {
        yield _issue(
          'build.cleartext_traffic',
          GuardianSeverity.error,
          file.path,
          'Cleartext traffic is enabled in AndroidManifest.xml.',
          const {},
        );
      }
      if (content.contains('android:debuggable="true"')) {
        yield _issue(
          'build.debuggable_manifest',
          GuardianSeverity.error,
          file.path,
          'android:debuggable="true" must not be committed for release builds.',
          const {},
        );
      }
    }
  }

  Iterable<GuardianIssue> _androidSigning(AnalyzerContext context) sync* {
    if (!context.policy.build.requireSigning) return;
    final releaseGradle = context.files.where(
      (file) =>
          file.path.endsWith('android/app/build.gradle') ||
          file.path.endsWith('android/app/build.gradle.kts'),
    );
    for (final file in releaseGradle) {
      final content = file.file.readAsStringSync();
      if (!content.contains('signingConfig') ||
          content.contains('signingConfig signingConfigs.debug')) {
        yield _issue(
          'build.release_signing',
          GuardianSeverity.warning,
          file.path,
          'Release signing configuration was not detected.',
          const {},
        );
      }
    }
  }

  Iterable<GuardianIssue> _obfuscation(AnalyzerContext context) sync* {
    if (!context.policy.security.requireObfuscation) return;
    final ciFiles = context.files.where(
      (file) =>
          file.path.startsWith('.github/workflows/') ||
          file.path.contains('codemagic') ||
          file.path.contains('bitrise') ||
          file.path.contains('gitlab-ci'),
    );
    final combined = ciFiles
        .map((file) => file.file.readAsStringSync())
        .join('\n');
    if (!combined.contains('--obfuscate')) {
      yield _issue(
        'build.obfuscation_missing',
        GuardianSeverity.error,
        null,
        'Policy requires Flutter release builds to pass --obfuscate.',
        const {},
      );
    }
  }

  GuardianIssue _issue(
    String id,
    GuardianSeverity severity,
    String? file,
    String message,
    Map<String, Object?> metadata,
  ) {
    return GuardianIssue(
      id: id,
      category: GuardianCategory.build,
      severity: severity,
      file: file,
      message: message,
      metadata: metadata,
    );
  }
}
