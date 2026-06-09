import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:guardian_core/guardian_core.dart';
import 'package:yaml/yaml.dart';

final class AssetAnalyzer implements GuardianAnalyzer {
  const AssetAnalyzer();

  @override
  String get id => 'assets';

  @override
  GuardianCategory get category => GuardianCategory.assets;

  @override
  Future<List<GuardianIssue>> analyze(AnalyzerContext context) async {
    final declared = _declaredAssets(context.projectRoot);
    final issues = <GuardianIssue>[
      ..._oversizedImages(context),
      ..._duplicates(context),
      ..._unusedDeclaredAssets(context, declared),
    ];
    return issues;
  }

  Iterable<GuardianIssue> _oversizedImages(AnalyzerContext context) sync* {
    final maxBytes = context.policy.assets.maxImageSizeKb * 1024;
    for (final file in context.files.where((file) => _isImage(file.path))) {
      if (file.sizeBytes > maxBytes) {
        yield GuardianIssue(
          id: 'assets.oversized_image',
          category: GuardianCategory.assets,
          severity: GuardianSeverity.warning,
          file: file.path,
          message: 'Image exceeds ${context.policy.assets.maxImageSizeKb} KB.',
          metadata: {'sizeBytes': file.sizeBytes},
        );
      }
    }
  }

  Iterable<GuardianIssue> _duplicates(AnalyzerContext context) sync* {
    final hashes = <String, ProjectFile>{};
    for (final file in context.files.where(
      (file) => _isAssetCandidate(file.path),
    )) {
      final digest = sha256.convert(file.file.readAsBytesSync()).toString();
      final existing = hashes[digest];
      if (existing != null) {
        yield GuardianIssue(
          id: 'assets.duplicate_file',
          category: GuardianCategory.assets,
          severity: GuardianSeverity.warning,
          file: file.path,
          message: 'Asset duplicates ${existing.path}.',
          metadata: {'duplicateOf': existing.path},
        );
      } else {
        hashes[digest] = file;
      }
    }
  }

  Iterable<GuardianIssue> _unusedDeclaredAssets(
    AnalyzerContext context,
    Set<String> declared,
  ) sync* {
    if (declared.isEmpty) return;
    final libText = StringBuffer();
    for (final file in context.dartFiles) {
      libText.write(file.file.readAsStringSync());
      libText.write('\n');
    }
    final source = libText.toString();
    for (final asset in declared) {
      if (!source.contains(asset)) {
        yield GuardianIssue(
          id: 'assets.unused_declared_asset',
          category: GuardianCategory.assets,
          severity: GuardianSeverity.info,
          file: 'pubspec.yaml',
          message:
              'Declared asset "$asset" was not referenced from Dart source.',
          metadata: {'asset': asset},
        );
      }
    }
  }
}

Set<String> _declaredAssets(Directory root) {
  final file = File('${root.path}/pubspec.yaml');
  if (!file.existsSync()) return const {};
  final yaml = loadYaml(file.readAsStringSync());
  if (yaml is! YamlMap || yaml['flutter'] is! YamlMap) return const {};
  final assets = (yaml['flutter'] as YamlMap)['assets'];
  if (assets is! YamlList) return const {};
  return assets.whereType<String>().toSet();
}

bool _isImage(String path) {
  final lower = path.toLowerCase();
  return lower.endsWith('.png') ||
      lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif');
}

bool _isAssetCandidate(String path) {
  return path.startsWith('assets/') ||
      path.startsWith('fonts/') ||
      _isImage(path);
}
