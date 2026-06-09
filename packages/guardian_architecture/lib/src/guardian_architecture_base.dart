import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:guardian_core/guardian_core.dart';

final class ArchitectureAnalyzer implements GuardianAnalyzer {
  const ArchitectureAnalyzer();

  @override
  String get id => 'architecture';

  @override
  GuardianCategory get category => GuardianCategory.architecture;

  @override
  Future<List<GuardianIssue>> analyze(AnalyzerContext context) async {
    final issues = <GuardianIssue>[];
    for (final file in context.dartFiles) {
      if (!file.path.startsWith('lib/')) continue;
      final result = parseString(
        content: file.file.readAsStringSync(),
        path: file.absolutePath,
      );
      final visitor = _ImportVisitor(
        file,
        result.lineInfo,
        context.policy.architecture,
      );
      result.unit.accept(visitor);
      issues.addAll(visitor.issues);
    }
    return issues;
  }
}

final class _ImportVisitor extends RecursiveAstVisitor<void> {
  _ImportVisitor(this.file, this.lineInfo, this.policy);

  final ProjectFile file;
  final LineInfo lineInfo;
  final ArchitecturePolicy policy;
  final issues = <GuardianIssue>[];

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return;
    final targetPath = _resolveImport(file.path, uri);
    if (targetPath == null) return;

    final sourceFeature = _featureName(file.path, policy.featureDirectoryName);
    final targetFeature = _featureName(targetPath, policy.featureDirectoryName);
    if (policy.forbidFeatureToFeatureImports &&
        sourceFeature != null &&
        targetFeature != null &&
        sourceFeature != targetFeature) {
      _add(
        node,
        'architecture.feature_boundary',
        'Feature "$sourceFeature" imports feature "$targetFeature".',
      );
    }

    final sourceLayer = _layerName(file.path, policy.layers);
    final targetLayer = _layerName(targetPath, policy.layers);
    if (policy.enforceLayerDirection &&
        sourceLayer != null &&
        targetLayer != null &&
        !_canImportLayer(sourceLayer, targetLayer, policy.layers)) {
      _add(
        node,
        'architecture.layer_direction',
        'Layer "$sourceLayer" must not import layer "$targetLayer".',
      );
    }
    super.visitImportDirective(node);
  }

  void _add(ImportDirective node, String id, String message) {
    final location = lineInfo.getLocation(node.offset);
    issues.add(
      GuardianIssue(
        id: id,
        category: GuardianCategory.architecture,
        severity: GuardianSeverity.error,
        file: file.path,
        line: location.lineNumber,
        column: location.columnNumber,
        message: message,
      ),
    );
  }
}

String? _resolveImport(String sourcePath, String uri) {
  if (uri.startsWith('package:')) {
    final parts = uri.split('/');
    final libIndex = parts.indexWhere((part) => part.contains(':'));
    if (libIndex != 0 || parts.length < 2) return null;
    return 'lib/${parts.skip(1).join('/')}';
  }
  if (!uri.startsWith('.')) return null;
  final sourceParts = sourcePath.split('/')..removeLast();
  for (final part in uri.split('/')) {
    if (part == '.' || part.isEmpty) continue;
    if (part == '..') {
      if (sourceParts.isNotEmpty) sourceParts.removeLast();
    } else {
      sourceParts.add(part);
    }
  }
  return sourceParts.join('/');
}

String? _featureName(String path, String featureDirectoryName) {
  final parts = path.split('/');
  final index = parts.indexOf(featureDirectoryName);
  if (index == -1 || index + 1 >= parts.length) return null;
  return parts[index + 1];
}

String? _layerName(String path, List<String> layers) {
  final parts = path.split('/');
  for (final layer in layers) {
    if (parts.contains(layer)) return layer;
  }
  return null;
}

bool _canImportLayer(String source, String target, List<String> layers) {
  final rank = {for (final (index, layer) in layers.indexed) layer: index};
  return rank[source]! >= rank[target]!;
}
