import 'dart:async';

import 'package:flutter/services.dart';

/// Indicates the current battery state.
enum PubNubStatus { subscribed, unsubscribed }

class PubNubFlutter {
  MethodChannel _channel;
  EventChannel _messageChannel;
  EventChannel _statusChannel;
  EventChannel _errorChannel;

  static Stream<Map> _onMessageReceived;
  static Stream<PubNubStatus> _onStatusReceived;
  static Stream<Map> _onErrorReceived;

  PubNubFlutter(String publishKey, String subscribeKey) {
    _channel = MethodChannel('pubnub_flutter');
    _messageChannel = const EventChannel('plugins.flutter.io/pubnub_message');
    _statusChannel = const EventChannel('plugins.flutter.io/pubnub_status');
    _errorChannel = const EventChannel('plugins.flutter.io/pubnub_error');

    _channel.invokeMethod('create', {"publishKey": publishKey, "subscribeKey": subscribeKey});

  }

  Future<void> subscribe(List<String> channels) async {
    await _channel.invokeMethod('subscribe', {"channels": channels});
    return;
  }

  Future<void> publish(Map message, String channel) async {
    await _channel.invokeMethod('publish', {"message": message, "channel": channel});
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
  Stream<Map> get onMessageReceived {
    if (_onMessageReceived == null) {
      _onMessageReceived = _messageChannel
          .receiveBroadcastStream()
          .map((dynamic event) => _parseEvent(event));
    }
    return _onMessageReceived;
  }

  Map _parseEvent(Map state) {
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

  /// Fires whenever the battery state changes.
  Stream<Map> get onErrorReceived {
    if (_onErrorReceived == null) {
      _onErrorReceived = _errorChannel
          .receiveBroadcastStream()
          .map((dynamic event) => _parseError(event));
    }
    return _onErrorReceived;
  }

  /// Fires whenever a status is received.
  PubNubStatus _parseStatus(String state) {
    switch (state) {
      case 'Subscribe':
        return PubNubStatus.subscribed;
      case 'Unsubscribe':
        return PubNubStatus.unsubscribed;
      default:
        throw ArgumentError('$state is not a valid PubNubStatus.');
    }
  }

  Map _parseError(Map error) {
    return error;
  }
}
