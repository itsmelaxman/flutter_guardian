import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

enum GuardianSeverity { info, warning, error }

enum GuardianCategory {
  security,
  architecture,
  dependencies,
  assets,
  build,
  generator,
}

final class GuardianIssue {
  const GuardianIssue({
    required this.id,
    required this.category,
    required this.severity,
    required this.message,
    this.file,
    this.line,
    this.column,
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final GuardianCategory category;
  final GuardianSeverity severity;
  final String message;
  final String? file;
  final int? line;
  final int? column;
  final Map<String, Object?> metadata;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'category': category.name,
    'severity': severity.name,
    'message': message,
    if (file != null) 'file': file,
    if (line != null) 'line': line,
    if (column != null) 'column': column,
    if (metadata.isNotEmpty) 'metadata': metadata,
  };
}

final class GuardianScore {
  const GuardianScore({
    required this.security,
    required this.architecture,
    required this.dependencies,
    required this.assets,
    required this.build,
  });

  factory GuardianScore.fromIssues(List<GuardianIssue> issues) {
    int scoreFor(GuardianCategory category) {
      var score = 100;
      for (final issue in issues.where((issue) => issue.category == category)) {
        score -= switch (issue.severity) {
          GuardianSeverity.error => 25,
          GuardianSeverity.warning => 10,
          GuardianSeverity.info => 2,
        };
      }
      return score.clamp(0, 100);
    }

    return GuardianScore(
      security: scoreFor(GuardianCategory.security),
      architecture: scoreFor(GuardianCategory.architecture),
      dependencies: scoreFor(GuardianCategory.dependencies),
      assets: scoreFor(GuardianCategory.assets),
      build: scoreFor(GuardianCategory.build),
    );
  }

  final int security;
  final int architecture;
  final int dependencies;
  final int assets;
  final int build;

  int get overall =>
      ((security + architecture + dependencies + assets + build) / 5).round();

  Map<String, Object?> toJson() => <String, Object?>{
    'overall': overall,
    'security': security,
    'architecture': architecture,
    'dependencies': dependencies,
    'assets': assets,
    'build': build,
  };
}

final class GuardianReport {
  GuardianReport({
    required this.projectRoot,
    required this.snapshotHash,
    required this.generatedAt,
    required List<GuardianIssue> issues,
  }) : issues = List<GuardianIssue>.unmodifiable(
         _deduplicateIssues(issues)..sort(compareIssues),
       );

  final String projectRoot;
  final String snapshotHash;
  final DateTime generatedAt;
  final List<GuardianIssue> issues;

  GuardianScore get score => GuardianScore.fromIssues(issues);

  bool get passed =>
      issues.every((issue) => issue.severity != GuardianSeverity.error);

  Map<String, Object?> toJson() => <String, Object?>{
    'tool': 'flutter_guardian',
    'schemaVersion': 1,
    'projectRoot': projectRoot,
    'snapshotHash': snapshotHash,
    'reportHash': reportHash,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'passed': passed,
    'scores': score.toJson(),
    'violations': issues.map((issue) => issue.toJson()).toList(),
  };

  String get reportHash {
    final stableJson = jsonEncode(<String, Object?>{
      'tool': 'flutter_guardian',
      'schemaVersion': 1,
      'projectRoot': projectRoot,
      'snapshotHash': snapshotHash,
      'passed': passed,
      'scores': score.toJson(),
      'violations': issues.map((issue) => issue.toJson()).toList(),
    });
    return sha256.convert(utf8.encode(stableJson)).toString();
  }

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

int compareIssues(GuardianIssue a, GuardianIssue b) {
  final file = (a.file ?? '').compareTo(b.file ?? '');
  if (file != 0) return file;
  final line = (a.line ?? 0).compareTo(b.line ?? 0);
  if (line != 0) return line;
  return a.id.compareTo(b.id);
}

List<GuardianIssue> _deduplicateIssues(List<GuardianIssue> issues) {
  final byStableKey = <String, GuardianIssue>{};
  for (final issue in issues) {
    byStableKey[_issueKey(issue)] = issue;
  }
  return byStableKey.values.toList();
}

String _issueKey(GuardianIssue issue) {
  return [
    issue.id,
    issue.category.name,
    issue.severity.name,
    issue.file ?? '',
    issue.line ?? '',
    issue.column ?? '',
    issue.message,
    jsonEncode(issue.metadata),
  ].join('\u0000');
}

final class GuardianPolicy {
  const GuardianPolicy({
    this.security = const SecurityPolicy(),
    this.architecture = const ArchitecturePolicy(),
    this.build = const BuildPolicy(),
    this.assets = const AssetPolicy(),
    this.dependencies = const DependencyPolicy(),
  });

  factory GuardianPolicy.load(Directory root) {
    final file = File('${root.path}/guardian.yaml');
    if (!file.existsSync()) return const GuardianPolicy();
    return GuardianPolicy.fromYaml(file.readAsStringSync());
  }

  factory GuardianPolicy.fromYaml(String source) {
    final yaml = loadYaml(source);
    if (yaml is! YamlMap) return const GuardianPolicy();
    return GuardianPolicy(
      security: SecurityPolicy.fromYaml(yaml['security']),
      architecture: ArchitecturePolicy.fromYaml(yaml['architecture']),
      build: BuildPolicy.fromYaml(yaml['build']),
      assets: AssetPolicy.fromYaml(yaml['assets']),
      dependencies: DependencyPolicy.fromYaml(yaml['dependencies']),
    );
  }

  final SecurityPolicy security;
  final ArchitecturePolicy architecture;
  final BuildPolicy build;
  final AssetPolicy assets;
  final DependencyPolicy dependencies;
}

final class SecurityPolicy {
  const SecurityPolicy({
    this.requireObfuscation = false,
    this.blockDotEnv = true,
    this.blockDebugLogs = true,
    this.blockHardcodedSecrets = true,
  });

  factory SecurityPolicy.fromYaml(Object? yaml) {
    final map = yaml is YamlMap ? yaml : const <Object?, Object?>{};
    return SecurityPolicy(
      requireObfuscation: _bool(map['require_obfuscation']) ?? false,
      blockDotEnv: _bool(map['block_dotenv']) ?? true,
      blockDebugLogs: _bool(map['block_debug_logs']) ?? true,
      blockHardcodedSecrets: _bool(map['block_hardcoded_secrets']) ?? true,
    );
  }

  final bool requireObfuscation;
  final bool blockDotEnv;
  final bool blockDebugLogs;
  final bool blockHardcodedSecrets;
}

final class ArchitecturePolicy {
  const ArchitecturePolicy({
    this.forbidFeatureToFeatureImports = true,
    this.enforceLayerDirection = true,
    this.featureDirectoryName = 'features',
    this.layers = const ['domain', 'data', 'presentation'],
  });

  factory ArchitecturePolicy.fromYaml(Object? yaml) {
    final map = yaml is YamlMap ? yaml : const <Object?, Object?>{};
    return ArchitecturePolicy(
      forbidFeatureToFeatureImports:
          _bool(map['forbid_feature_to_feature_imports']) ?? true,
      enforceLayerDirection: _bool(map['enforce_layer_direction']) ?? true,
      featureDirectoryName: map['feature_directory']?.toString() ?? 'features',
      layers:
          _stringList(map['layers']) ??
          const ['domain', 'data', 'presentation'],
    );
  }

  final bool forbidFeatureToFeatureImports;
  final bool enforceLayerDirection;
  final String featureDirectoryName;
  final List<String> layers;
}

final class BuildPolicy {
  const BuildPolicy({
    this.maxApkSizeMb = 50,
    this.maxAabSizeMb = 100,
    this.requireSigning = true,
    this.blockCleartextTraffic = true,
  });

  factory BuildPolicy.fromYaml(Object? yaml) {
    final map = yaml is YamlMap ? yaml : const <Object?, Object?>{};
    return BuildPolicy(
      maxApkSizeMb: _int(map['max_apk_size_mb']) ?? 50,
      maxAabSizeMb: _int(map['max_aab_size_mb']) ?? 100,
      requireSigning: _bool(map['require_signing']) ?? true,
      blockCleartextTraffic: _bool(map['block_cleartext_traffic']) ?? true,
    );
  }

  final int maxApkSizeMb;
  final int maxAabSizeMb;
  final bool requireSigning;
  final bool blockCleartextTraffic;
}

final class AssetPolicy {
  const AssetPolicy({this.maxImageSizeKb = 1024});

  factory AssetPolicy.fromYaml(Object? yaml) {
    final map = yaml is YamlMap ? yaml : const <Object?, Object?>{};
    return AssetPolicy(maxImageSizeKb: _int(map['max_image_size_kb']) ?? 1024);
  }

  final int maxImageSizeKb;
}

final class DependencyPolicy {
  const DependencyPolicy({this.warnOnHostedUnpinned = true});

  factory DependencyPolicy.fromYaml(Object? yaml) {
    final map = yaml is YamlMap ? yaml : const <Object?, Object?>{};
    return DependencyPolicy(
      warnOnHostedUnpinned: _bool(map['warn_on_hosted_unpinned']) ?? true,
    );
  }

  final bool warnOnHostedUnpinned;
}

abstract interface class GuardianAnalyzer {
  /// Analyzers must be deterministic and side-effect free.
  ///
  /// They may read only from [AnalyzerContext.snapshot] and policy data, must
  /// not write files, must not perform network calls, and must not mutate
  /// global state. Analyzer results must be identical for identical snapshots.
  String get id;
  GuardianCategory get category;
  Future<List<GuardianIssue>> analyze(AnalyzerContext context);
}

final class AnalyzerContext {
  const AnalyzerContext({
    required this.projectRoot,
    required this.policy,
    required this.snapshot,
  });

  final Directory projectRoot;
  final GuardianPolicy policy;
  final ProjectSnapshot snapshot;

  List<ProjectFile> get files => snapshot.files;

  Iterable<ProjectFile> get dartFiles =>
      files.where((file) => file.path.endsWith('.dart'));
}

final class ProjectSnapshot {
  ProjectSnapshot({required List<ProjectFile> files})
    : files = List<ProjectFile>.unmodifiable(
        List<ProjectFile>.of(files)..sort((a, b) => a.path.compareTo(b.path)),
      );

  final List<ProjectFile> files;

  String get hash {
    final digestInput = StringBuffer();
    for (final file in files) {
      digestInput
        ..write(file.path)
        ..write('\u0000')
        ..write(file.sizeBytes)
        ..write('\u0000')
        ..write(file.sha256Hash)
        ..write('\n');
    }
    return sha256.convert(utf8.encode(digestInput.toString())).toString();
  }
}

final class ProjectFile {
  const ProjectFile({
    required this.path,
    required this.absolutePath,
    required this.sizeBytes,
    required this.sha256Hash,
  });

  final String path;
  final String absolutePath;
  final int sizeBytes;
  final String sha256Hash;

  File get file => File(absolutePath);
}

final class ProjectScanner {
  const ProjectScanner();

  ProjectSnapshot scan(Directory root) {
    final files = <ProjectFile>[];
    if (!root.existsSync()) return ProjectSnapshot(files: files);
    for (final entity in root.listSync(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = _relative(root.path, entity.path);
      if (_isIgnored(relative)) continue;
      final bytes = entity.readAsBytesSync();
      files.add(
        ProjectFile(
          path: relative,
          absolutePath: entity.path,
          sizeBytes: bytes.length,
          sha256Hash: sha256.convert(bytes).toString(),
        ),
      );
    }
    return ProjectSnapshot(files: files);
  }
}

bool _isIgnored(String path) {
  final name = path.split(Platform.pathSeparator).last;
  if (name == 'guardian-report.json' || name == 'guardian-report.html') {
    return true;
  }
  final parts = path.split(Platform.pathSeparator);
  return parts.any(
    (part) =>
        part == '.dart_tool' ||
        part == '.git' ||
        part == 'build' ||
        part == '.gradle' ||
        part == 'Pods',
  );
}

String _relative(String root, String child) {
  final normalizedRoot = root.endsWith(Platform.pathSeparator)
      ? root
      : '$root${Platform.pathSeparator}';
  return child.startsWith(normalizedRoot)
      ? child.substring(normalizedRoot.length)
      : child;
}

bool? _bool(Object? value) => switch (value) {
  bool() => value,
  String() =>
    value.toLowerCase() == 'true'
        ? true
        : value.toLowerCase() == 'false'
        ? false
        : null,
  _ => null,
};

int? _int(Object? value) => switch (value) {
  int() => value,
  num() => value.toInt(),
  String() => int.tryParse(value),
  _ => null,
};

List<String>? _stringList(Object? value) {
  if (value is YamlList) {
    return value.map((entry) => entry.toString()).toList(growable: false);
  }
  if (value is List) {
    return value.map((entry) => entry.toString()).toList(growable: false);
  }
  return null;
}
