import 'dart:io';

import 'package:flutter/services.dart';

class DeviceIntegrityService {
  static const _channel = MethodChannel('bits_mobile_app/device_integrity');
  static const _developerOptionsCheckEnabled = false;

  Future<bool> isDeveloperOptionsEnabled() async {
    // Disabled while USB-debugging smoke tests are being performed.
    if (!_developerOptionsCheckEnabled || !Platform.isAndroid) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('isDeveloperOptionsEnabled') ??
          false;
    } on PlatformException {
      return false;
    }
  }

  Future<String?> readStableDeviceId() async {
    if (!Platform.isAndroid) return null;

    try {
      final value = await _channel.invokeMethod<String>('getStableDeviceId');
      final id = value?.trim();
      return id == null || id.isEmpty ? null : 'android-$id';
    } on PlatformException {
      return null;
    }
  }
}
