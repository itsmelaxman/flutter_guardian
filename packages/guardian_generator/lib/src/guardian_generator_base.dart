import 'dart:convert';

import 'package:yaml/yaml.dart';

final class GeneratedConfig {
  const GeneratedConfig({required this.className, required this.source});

  final String className;
  final String source;
}

final class AppEnvGenerator {
  const AppEnvGenerator();

  GeneratedConfig fromEnv(String source, {String className = 'AppEnv'}) {
    final values = <String, Object?>{};
    for (final rawLine in source.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final index = line.indexOf('=');
      if (index <= 0) continue;
      values[line.substring(0, index).trim()] = _coerce(
        line.substring(index + 1).trim(),
      );
    }
    return _build(values, className);
  }

  GeneratedConfig fromYaml(String source, {String className = 'AppEnv'}) {
    final yaml = loadYaml(source);
    final values = <String, Object?>{};
    if (yaml is YamlMap) {
      for (final entry in yaml.entries) {
        values[entry.key.toString()] = entry.value;
      }
    }
    return _build(values, className);
  }

  GeneratedConfig fromJson(String source, {String className = 'AppEnv'}) {
    final decoded = jsonDecode(source);
    final values = <String, Object?>{};
    if (decoded is Map<String, Object?>) {
      values.addAll(decoded);
    } else if (decoded is Map) {
      for (final entry in decoded.entries) {
        values[entry.key.toString()] = entry.value;
      }
    }
    return _build(values, className);
  }

  GeneratedConfig _build(Map<String, Object?> values, String className) {
    final buffer = StringBuffer()
      ..writeln('// GENERATED CODE - DO NOT MODIFY BY HAND.')
      ..writeln('final class $className {')
      ..writeln('  const $className._();');
    final keys = values.keys.toList()..sort();
    for (final key in keys) {
      final name = _identifier(key);
      final value = values[key];
      buffer.writeln('  static const $name = ${_literal(value)};');
    }
    buffer.writeln('}');
    return GeneratedConfig(className: className, source: buffer.toString());
  }
}

String _identifier(String key) {
  final words = key
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'value';
  return [
    words.first,
    ...words.skip(1).map((word) => word[0].toUpperCase() + word.substring(1)),
  ].join();
}

String _literal(Object? value) {
  if (value is bool || value is num) return '$value';
  final string = value?.toString() ?? '';
  final escaped = string.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  return "'$escaped'";
}

Object _coerce(String value) {
  final lower = value.toLowerCase();
  if (lower == 'true') return true;
  if (lower == 'false') return false;
  return int.tryParse(value) ?? double.tryParse(value) ?? value;
}
