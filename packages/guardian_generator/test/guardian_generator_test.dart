import 'package:guardian_generator/guardian_generator.dart';
import 'package:test/test.dart';

void main() {
  test('generates strongly typed const Dart config from env', () {
    final generated = const AppEnvGenerator().fromEnv('''
API_URL=https://example.com
FEATURE_ENABLED=true
TIMEOUT_SECONDS=30
''');

    expect(generated.source, contains('final class AppEnv'));
    expect(
      generated.source,
      contains("static const apiUrl = 'https://example.com';"),
    );
    expect(generated.source, contains('static const featureEnabled = true;'));
    expect(generated.source, contains('static const timeoutSeconds = 30;'));
  });

  test('generates config from json', () {
    final generated = const AppEnvGenerator().fromJson(
      '{"api_url":"https://example.com","timeout":30}',
    );

    expect(
      generated.source,
      contains("static const apiUrl = 'https://example.com';"),
    );
    expect(generated.source, contains('static const timeout = 30;'));
  });
}
