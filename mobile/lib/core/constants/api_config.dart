/// Configuration for the backend API base URL.
/// Can be overridden at build/run time with:
/// `--dart-define=API_BASE_URL=http://<IP>:3000/api`
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api',
);

