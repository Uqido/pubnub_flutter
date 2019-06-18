import 'dart:async';

import 'package:flutter/services.dart';

/// PubNub Plugin. This plugin is not intended to implement all PubNub functionalities but rather take a minimal approach
/// for solving most general use cases
/// Main areas covered by the plugin are
/// - Instantiate the plugin passing the required PubNub authentication information
/// - Pass a filter expression when instantiating the plugin
/// - Subscribe to one or more channels
/// - Unsubscribe from one channel or all channels
/// - Publish a message to a channel
/// - Retrieve UUID if was not set during the plugin instantiation
/// {@tool sample}
///
/// Instantiate plugin without a filter expression:
///
/// ```dart
/// _pubNubFlutter = PubNubFlutter('pub-c-2d1121f9-06c1-4413-8d2e-0000000000',
///        'sub-c-324ae474-ecfd-11e8-91a4-00000000000',
///        uuid: '127c1ab5-fc7f-4c46-8460-3207b6782007');
/// ```
/// Instantiate plugin with a filter expression:
///
/// ```dart
/// _pubNubFlutter = PubNubFlutter('pub-c-2d1121f9-06c1-4413-8d2e-0000000000',
///        'sub-c-324ae474-ecfd-11e8-91a4-00000000000',
///        uuid: '127c1ab5-fc7f-4c46-8460-3207b6782007',
///        filter: 'uuid != "127c1ab5-fc7f-4c46-8460-3207b6782007"');
/// ```
///
/// It is also possible to pass a PubNub authKey if such mechanism is used on the PubNub side for additional security.
///
/// ```dart
/// _pubNubFlutter = PubNubFlutter('pub-c-2d1121f9-06c1-4413-8d2e-0000000000',
///        'sub-c-324ae474-ecfd-11e8-91a4-00000000000',
///        authKey: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxx',
///        uuid: '127c1ab5-fc7f-4c46-8460-3207b6782007');
/// ```
///
/// Finally, it is also possible to set a presence timeout value in order to be informed of possible/unexpected disconnections:
///
/// ```dart
/// _pubNubFlutter = PubNubFlutter('pub-c-2d1121f9-06c1-4413-8d2e-0000000000',
///        'sub-c-324ae474-ecfd-11e8-91a4-00000000000',
///        presenceTimeOut: 120,
///        uuid: '127c1ab5-fc7f-4c46-8460-3207b6782007');
/// ```
///
/// Subscribe to a channel:
///
/// ``` dart
/// _pubNubFlutter.subscribe(['test_channel']);
/// ```
///
/// Unsubscribe from a channel:
///
/// ``` dart
/// _pubNubFlutter.unsubscribe(channel: 'test_channel');
/// ```
///
///  Unsubscribe from all channels:
///
/// ``` dart
/// _pubNubFlutter.unsubscribeAll();
/// ```
///
/// Publish a message to a channel:
///
/// ``` dart
///    _pubNubFlutter.publish(
///                            {'message': 'Hello World'},
///                            'test_channel',
///                          );
/// ```
///
/// Publish a message to a channel passing metadata optional filter expression acts upon:
///
/// ``` dart
///    _pubNubFlutter.publish(
///                            {'message': 'Hello World'},
///                            'test_channel',
///                            metadata: {
///                             'uuid': '127c1ab5-fc7f-4c46-8460-3207b6782007'
///                           }
///                          );
/// ```
///
/// Listen for Messages:
///
/// ``` dart
/// _pubNubFlutter.onMessageReceived
///        .listen((message) => print('Message:$message'));
/// ```
///
/// Listen for Status:
///
/// ``` dart
///  _pubNubFlutter.onStatusReceived
///        .listen((status) => print('Status:${status.toString()}'));
/// ```
/// Listen to Presence:
///
/// ``` dart
/// _pubNubFlutter.onPresenceReceived
///        .listen((presence) => print('Presence:${presence.toString()}'));
/// ```
///
/// Listen for Errors:
///
/// ``` dart
/// _pubNubFlutter.onErrorReceived.listen((error) => print('Error:$error'));
/// ```
///
///  {@end-tool}
class PubNubFlutter {
  MethodChannel _channel;
  EventChannel _messageChannel;
  EventChannel _statusChannel;
  EventChannel _presenceChannel;
  EventChannel _errorChannel;

  Stream<Map> _onMessageReceived;
  Stream<Map> _onStatusReceived;
  Stream<Map> _onPresenceReceived;
  Stream<Map> _onErrorReceived;

  /// Create the plugin, UUID and filter expressions are optional and can be used for tracking purposes and filtering purposes, for instance can disable getting messages on the same UUID.
  PubNubFlutter(String publishKey, String subscribeKey,
      {String authKey, int presenceTimeout, String uuid, String filter}) {
    print('PubNubFlutter constructor');
    _channel = MethodChannel('flutter.ingenio.com/pubnub_flutter');
    _messageChannel = const EventChannel('flutter.ingenio.com/pubnub_message');
    _statusChannel = const EventChannel('flutter.ingenio.com/pubnub_status');
    _presenceChannel =
        const EventChannel('flutter.ingenio.com/pubnub_presence');
    _errorChannel = const EventChannel('flutter.ingenio.com/pubnub_error');

    Map<String, dynamic> args = {
      'publishKey': publishKey,
      'subscribeKey': subscribeKey
    };

    if (uuid != null) {
      args['uuid'] = uuid;
    }
    if (filter != null) {
      args['filter'] = filter;
    }
    if (authKey != null) {
      args['authKey'] = authKey;
    }
    if (presenceTimeout != null && presenceTimeout > 0) {
      args['presenceTimeout'] = presenceTimeout;
    }
    _channel.invokeMethod('create', args);
  }

  /// Subscribe to a list of channels
  Future<void> subscribe(List<String> channels) async {
    await _channel.invokeMethod('subscribe', {'channels': channels});
    return;
  }

  /// Publishes a message on a specified channel, some metadata can be passed and used in conjunction with filter expressions
  Future<void> publish(Map message, String channel, {Map metadata}) async {
    Map args = {'message': message, 'channel': channel};

    if (metadata != null) {
      args['metadata'] = metadata;
    }

    return await _channel.invokeMethod('publish', args);
  }

  /// Unsubscribes from a single channel
  Future<void> unsubscribe({String channel}) async {
    return await _channel.invokeMethod('unsubscribe', {'channel': channel});
  }

  /// Unsubscribes from all channels
  Future<void> unsubscribeAll() async {
    return await _channel.invokeMethod('unsubscribe');
  }

  /// Get the UUID configured for PubNub. Note that when the UUID is passed  in the plugin creation, the returned UUID is the same
  /// If the UUID has not been passed in the plugin creation, then PubNub assigns a new UUID. This may be important for tracking how many devices/clients are using the API and
  /// may impact how much the service costs
  Future<String> uuid() async {
    return await _channel.invokeMethod('uuid');
  }

  /// Fires whenever the a message is received.
  Stream<Map> get onMessageReceived {
    if (_onMessageReceived == null) {
      _onMessageReceived = _messageChannel
          .receiveBroadcastStream()
          .map((dynamic event) => _parseMessage(event));
    }
    return _onMessageReceived;
  }

  /// Fires whenever the status changes.
  Stream<Map> get onStatusReceived {
    if (_onStatusReceived == null) {
      _onStatusReceived = _statusChannel
          .receiveBroadcastStream()
          .map((dynamic event) => _parseStatus(event));
    }
    return _onStatusReceived;
  }

  /// Fires whenever the presence changes.
  Stream<Map> get onPresenceReceived {
    if (_onPresenceReceived == null) {
      _onPresenceReceived = _presenceChannel
          .receiveBroadcastStream()
          .map((dynamic event) => _parsePresence(event));
    }
    return _onPresenceReceived;
  }

  /// Fires whenever an error is received.
  Stream<Map> get onErrorReceived {
    if (_onErrorReceived == null) {
      _onErrorReceived = _errorChannel
          .receiveBroadcastStream()
          .map((dynamic event) => _parseError(event));
    }
    return _onErrorReceived;
  }

  /// Fires whenever a status is received.
  Map _parseStatus(Map status) {
    int category = status['category'];
    status['category'] = PNStatusCategory.values[category];
    int operation = status['operation'];
    status['operation'] = PNOperationType.values[operation];
    return status;
  }

  /// Fires whenever presence is received
  Map _parsePresence(Map presence) {
    return presence;
  }

  /// Fires whenever a PubNub error is received
  Map _parseError(Map error) {
    int operation = error['operation'];
    error['operation'] = PNOperationType.values[operation];
    return error;
  }

  /// Fires whenever a message is received
  Map _parseMessage(Map message) {
    return message;
  }
}

/// Values for the status category. Not this is an intersection of both iOS and Android enums as both have different values
enum PNStatusCategory {
  PNUnknownCategory,
  PNAcknowledgmentCategory,
  PNAccessDeniedCategory,
  PNTimeoutCategory,
  PNNetworkIssuesCategory,
  PNConnectedCategory,
  PNReconnectedCategory,
  PNDisconnectedCategory,
  PNUnexpectedDisconnectCategory,
  PNCancelledCategory,
  PNBadRequestCategory,
  PNMalformedFilterExpressionCategory,
  PNMalformedResponseCategory,
  PNDecryptionErrorCategory,
  PNTLSConnectionFailedCategory,
  PNTLSUntrustedCertificateCategory,
  PNRequestMessageCountExceededCategory,
}

/// Operation type coming back in the status
enum PNOperationType {
  PNUnknownOperation,
  PNSubscribeOperation,
  PNUnsubscribeOperation,
  PNPublishOperation,
  PNHistoryOperation,
  PNFetchMessagesOperation,
  PNDeleteMessagesOperation,
  PNWhereNowOperation,
  PNHeartbeatOperation,
  PNSetStateOperation,
  PNAddChannelsToGroupOperation,
  PNRemoveChannelsFromGroupOperation,
  PNChannelGroupsOperation,
  PNRemoveGroupOperation,
  PNChannelsForGroupOperation,
  PNPushNotificationEnabledChannelsOperation,
  PNAddPushNotificationsOnChannelsOperation,
  PNRemovePushNotificationsFromChannelsOperation,
  PNRemoveAllPushNotificationsOperation,
  PNTimeOperation,
}
