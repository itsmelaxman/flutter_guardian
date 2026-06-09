import 'package:guardian_generator/guardian_generator.dart';

void main() {
  final generated = const AppEnvGenerator().fromEnv(
    'API_URL=https://example.com',
  );
  print(generated.source);
}
