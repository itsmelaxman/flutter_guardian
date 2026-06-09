const hardcodedJwt =
    'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.c2lnbmF0dXJlMTIz';
const hardcodedApiKey = 'api_key_sample_1234567890_secret_value';

void main() {
  print('debug log');
  loadDotenv();
  debugPrint('debug log');
  debugPrint(hardcodedJwt);
  debugPrint(hardcodedApiKey);
}

void debugPrint(Object? message) {}

void loadDotenv() {}
