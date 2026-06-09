import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:guardian_core/guardian_core.dart';

final class SecurityAnalyzer implements GuardianAnalyzer {
  const SecurityAnalyzer();

  @override
  String get id => 'security';

  @override
  GuardianCategory get category => GuardianCategory.security;

  @override
  Future<List<GuardianIssue>> analyze(AnalyzerContext context) async {
    final issues = <GuardianIssue>[];
    if (context.policy.security.blockDotEnv) {
      issues.addAll(_scanDotEnvFiles(context));
    }

    for (final file in context.dartFiles) {
      final content = file.file.readAsStringSync();
      final result = parseString(content: content, path: file.absolutePath);
      final visitor = _SecurityVisitor(
        file,
        result.lineInfo,
        context.policy.security,
      );
      result.unit.accept(visitor);
      issues.addAll(visitor.issues);
    }
    return issues;
  }

  Iterable<GuardianIssue> _scanDotEnvFiles(AnalyzerContext context) sync* {
    for (final file in context.files) {
      final name = file.path.split(Platform.pathSeparator).last;
      if (name == '.env' || name.startsWith('.env.')) {
        yield GuardianIssue(
          id: 'security.dotenv_file',
          category: GuardianCategory.security,
          severity: GuardianSeverity.error,
          file: file.path,
          message: '.env files must not be committed to release source trees.',
        );
      }
    }
  }
}

final class _SecurityVisitor extends RecursiveAstVisitor<void> {
  _SecurityVisitor(this.file, this.lineInfo, this.policy);

  final ProjectFile file;
  final LineInfo lineInfo;
  final SecurityPolicy policy;
  final issues = <GuardianIssue>[];

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue ?? '';
    if (policy.blockDotEnv && uri.contains('flutter_dotenv')) {
      _add(
        node,
        'security.dotenv_usage',
        GuardianSeverity.error,
        'flutter_dotenv imports are blocked for release-governed apps.',
      );
    }
    super.visitImportDirective(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (policy.blockDebugLogs && (name == 'print' || name == 'debugPrint')) {
      _add(
        node,
        'security.debug_log',
        GuardianSeverity.error,
        'Debug logging call "$name" is not allowed in release code.',
      );
    }
    if (policy.blockDotEnv && name.toLowerCase().contains('dotenv')) {
      _add(
        node,
        'security.dotenv_usage',
        GuardianSeverity.error,
        'Runtime .env access is blocked; generate compile-time config instead.',
      );
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final text = node.function.toSource();
    if (policy.blockDebugLogs && text == 'print') {
      _add(
        node,
        'security.debug_log',
        GuardianSeverity.error,
        'Debug logging call "print" is not allowed in release code.',
      );
    }
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (!policy.blockHardcodedSecrets) return;
    final value = node.value.trim();
    final finding = classifySecret(value);
    if (finding != null) {
      _add(node, finding.id, finding.severity, finding.message);
    }
    super.visitSimpleStringLiteral(node);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    if (!policy.blockHardcodedSecrets) return;
    final value = node.stringValue?.trim();
    if (value != null) {
      final finding = classifySecret(value);
      if (finding != null) {
        _add(node, finding.id, finding.severity, finding.message);
      }
    }
    super.visitAdjacentStrings(node);
  }

  void _add(
    AstNode node,
    String id,
    GuardianSeverity severity,
    String message,
  ) {
    final location = lineInfo.getLocation(node.offset);
    issues.add(
      GuardianIssue(
        id: id,
        category: GuardianCategory.security,
        severity: severity,
        file: file.path,
        line: location.lineNumber,
        column: location.columnNumber,
        message: message,
      ),
    );
  }
}

final class SecretFinding {
  const SecretFinding(this.id, this.message, this.severity);

  final String id;
  final String message;
  final GuardianSeverity severity;
}

SecretFinding? classifySecret(String value) {
  if (value.isEmpty || value.length < 16) return null;
  final lower = value.toLowerCase();
  if (_looksLikeJwt(value)) {
    return const SecretFinding(
      'security.jwt_literal',
      'JWT-like token literal detected in Dart source.',
      GuardianSeverity.error,
    );
  }
  if (lower.contains('apikey') ||
      lower.contains('api_key') ||
      lower.contains('secret') ||
      lower.contains('password')) {
    return const SecretFinding(
      'security.secret_literal',
      'Hardcoded secret-looking string literal detected.',
      GuardianSeverity.error,
    );
  }
  if (_highEntropy(value) &&
      RegExp(r'[A-Za-z]').hasMatch(value) &&
      RegExp(r'\d').hasMatch(value)) {
    return const SecretFinding(
      'security.high_entropy_literal',
      'High-entropy string literal detected; verify it is not a credential.',
      GuardianSeverity.warning,
    );
  }
  return null;
}

bool _looksLikeJwt(String value) {
  final parts = value.split('.');
  if (parts.length != 3) return false;
  return parts.every(
    (part) => RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(part) && part.length > 8,
  );
}

bool _highEntropy(String value) {
  final unique = value.runes.toSet().length;
  return value.length >= 32 && unique >= 16;
}
