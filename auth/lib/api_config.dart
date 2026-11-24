import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:8081";
    }
    // Android emulator uses 10.0.2.2 to reach PC localhost
    if (Platform.isAndroid) {
      return "http://10.0.2.2:8081";
    }
    // Windows, macOS, Linux, iOS simulator run on the machine itself
    return "http://localhost:8081";
  }
}
