import 'package:guardian_security/guardian_security.dart';

void main() {
  final finding = classifySecret(
    'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.signature123',
  );
  print(finding?.id);
}
