import 'dart:async';

import 'package:flutter/services.dart';

/// Indicates the current battery state.
enum PubNubStatus { subscribed, unsubscribed }

class PubnubFlutter {
  MethodChannel _channel;
  EventChannel _messageChannel;
  EventChannel _statusChannel;

  static Stream<String> _onMessageReceived;
  static Stream<PubNubStatus> _onStatusReceived;

  PubnubFlutter(String publishKey, String subscribeKey) {
    _channel = MethodChannel('pubnub_flutter');
    _messageChannel = const EventChannel('plugins.flutter.io/pubnub_message');
    _statusChannel = const EventChannel('plugins.flutter.io/pubnub_status');

    _channel.invokeMethod('create', {"publishKey": publishKey, "subscribeKey": subscribeKey});

  }

  Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<void> subscribe(List<String> channels) async {
    await _channel.invokeMethod('subscribe', {"channels": channels});
    return;
  }

  Future<void> unsubscribe({String channel}) async {
    final String version = await _channel.invokeMethod('unsubscribe',
        {"channel": channel});
    return;
  }

  Future<void> unsubscribeAll() async {
    final String version = await _channel.invokeMethod('unsubscribe');
    return;
  }

  /// Fires whenever the battery state changes.
  Stream<String> get onMessageReceived {
    if (_onMessageReceived == null) {
      _onMessageReceived = _messageChannel
          .receiveBroadcastStream()
          .map((dynamic event) => _parseEvent(event));
    }
    return _onMessageReceived;
  }

  String _parseEvent(String state) {
    return state;
  }

  /// Fires whenever the battery state changes.
  Stream<PubNubStatus> get onStatusReceived {
    if (_onStatusReceived == null) {
      _onStatusReceived = _statusChannel
          .receiveBroadcastStream()
          .map((dynamic event) => _parseStatus(event));
    }
    return _onStatusReceived;
  }

  /// Fires whenever a status is received.
  PubNubStatus _parseStatus(String state) {
    switch (state) {
      case 'subscribe':
        return PubNubStatus.subscribed;
      case 'unsubscribe':
        return PubNubStatus.unsubscribed;
      default:
        throw ArgumentError('$state is not a valid PubNubStatus.');
    }
  }
}
