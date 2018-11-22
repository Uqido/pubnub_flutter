import 'dart:async';

import 'package:flutter/services.dart';

class PubnubFlutter {
  static const MethodChannel _channel =
      const MethodChannel('pubnub_flutter');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> subscribe({String publishKey, String subscribeKey, String channel}) async {
    final String version = await _channel.invokeMethod('subscribe',
        {"publishKey": publishKey, "subscribeKey": subscribeKey, "channel": channel});
    return;
  }

  static Future<void> unsubscribe({String channel}) async {
    final String version = await _channel.invokeMethod('unsubscribe',
        {"channel": channel});
    return;
  }
}
