import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceInfoUtil {
  static const _storage = FlutterSecureStorage();
  static const _deviceIdKey = 'app_unique_device_id';

  static Future<String> getDeviceId() async {
    String? deviceId = await _storage.read(key: _deviceIdKey);

    if (deviceId == null || deviceId.isEmpty) {
      deviceId = _generateUniqueId();
      await _storage.write(key: _deviceIdKey, value: deviceId);
    }

    return deviceId;
  }

  static String _generateUniqueId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum =
        List.generate(8, (_) => random.nextInt(10).toString()).join();
    return 'DEV-$timestamp-$randomNum';
  }
}
