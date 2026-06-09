import 'dart:io';

import 'package:guardian_core/guardian_core.dart';
import 'package:yaml/yaml.dart';

final class DependencyAnalyzer implements GuardianAnalyzer {
  const DependencyAnalyzer();

  @override
  String get id => 'dependencies';

  @override
  GuardianCategory get category => GuardianCategory.dependencies;

  @override
  Future<List<GuardianIssue>> analyze(AnalyzerContext context) async {
    final pubspec = File('${context.projectRoot.path}/pubspec.yaml');
    if (!pubspec.existsSync()) {
      return const [
        GuardianIssue(
          id: 'dependencies.pubspec_missing',
          category: GuardianCategory.dependencies,
          severity: GuardianSeverity.error,
          message: 'pubspec.yaml was not found at project root.',
        ),
      ];
    }
    final yaml = loadYaml(pubspec.readAsStringSync());
    if (yaml is! YamlMap) return const [];
    return [
      ..._scanSection(yaml['dependencies'], 'dependencies', context.policy),
      ..._scanSection(
        yaml['dev_dependencies'],
        'dev_dependencies',
        context.policy,
      ),
    ];
  }

  Iterable<GuardianIssue> _scanSection(
    Object? section,
    String sectionName,
    GuardianPolicy policy,
  ) sync* {
    if (section is! YamlMap) return;
    for (final entry in section.entries) {
      final name = entry.key.toString();
      if (name == 'flutter' || name == 'sdk') continue;
      final spec = entry.value;
      if (spec is YamlMap && spec.containsKey('git')) {
        yield _issue(
          name,
          sectionName,
          'dependencies.git_source',
          'Dependency "$name" uses a git source; pin a reviewed hosted release where possible.',
        );
      } else if (spec is YamlMap && spec.containsKey('path')) {
        yield _issue(
          name,
          sectionName,
          'dependencies.path_source',
          'Dependency "$name" uses a local path source; CI reproducibility depends on repository layout.',
        );
      } else if (policy.dependencies.warnOnHostedUnpinned &&
          spec is String &&
          _isLoose(spec)) {
        yield _issue(
          name,
          sectionName,
          'dependencies.loose_constraint',
          'Dependency "$name" has a loose version constraint "$spec".',
        );
      } else if (spec is String && spec.contains('-')) {
        yield _issue(
          name,
          sectionName,
          'dependencies.prerelease',
          'Dependency "$name" uses a prerelease constraint "$spec".',
        );
      }
    }
  }

  GuardianIssue _issue(String name, String section, String id, String message) {
    return GuardianIssue(
      id: id,
      category: GuardianCategory.dependencies,
      severity: GuardianSeverity.warning,
      file: 'pubspec.yaml',
      message: message,
      metadata: {'dependency': name, 'section': section, 'riskScore': 50},
    );
  }
}

bool _isLoose(String constraint) {
  final trimmed = constraint.trim();
  return trimmed == 'any' ||
      trimmed.startsWith('>=') ||
      trimmed.startsWith('>');
}
