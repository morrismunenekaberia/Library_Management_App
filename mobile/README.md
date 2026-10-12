# Library Management Mobile App

Flutter client for the Library Management application.

## API Configuration & Running

The backend API base URL is configured at run/build time using `--dart-define=API_BASE_URL=...`.

- **Emulator**:
  ```bash
  flutter run
  ```
  *(Defaults to `http://10.0.2.2:3000/api`)*

- **Phone (physical Android device over Wi-Fi)**:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://192.168.137.171:3000/api
  ```

- **Release APK**:
  ```bash
  flutter build apk --release --dart-define=API_BASE_URL=http://192.168.137.171:3000/api
  ```

> **Note**: The IP address (`192.168.137.171`) is your computer's local LAN IP and must be updated whenever your network or IP address changes. Ensure that both your computer running the Node.js API and your physical phone are connected to the same Wi-Fi network.

## Testing & Analysis

```bash
flutter analyze
flutter test
```
