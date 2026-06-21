import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfoUtil {
  static Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'UNKNOWN_IOS_DEVICE';
    }
    return 'UNKNOWN_DEVICE';
  }
}