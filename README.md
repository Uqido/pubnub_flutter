# PubNubFlutter

[![pub package](https://img.shields.io/pub/v/pubnub.svg)](https://pub.dartlang.org/packages/pubnub)

A Flutter plugin to access PubNub functionalities such as publish, subscribe, status and presence..
The plugin allows having more than one client on the plugin side.

## Usage
To use this plugin, add `pubnub_flutter` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

### Example

``` dart
// Instantiate plugin without a filter expression:
 _pubNubFlutter = PubNubFlutter([
      PubNubConfig('client1', 'pub-c-xxxx',
          'sub-cxxxx',
          presenceTimeout: 120),
      PubNubConfig('client2', 'pub-c-xxxx',
          'sub-cxxx'),
    ]);

    _pubNubFlutter.uuid('client1').then((uuid) => print('UUID1: $uuid'));
    _pubNubFlutter.uuid('client2').then((uuid) => print('UUID2: $uuid'));
        
// Instantiate plugin with a filter expression:
_pubNubFlutter = PubNubFlutter([PubNubConfig('client1', 'pub-c-xxxx',
          'sub-cxxxx',
          presenceTimeout: 120,
        uuid: '127c1ab5-fc7f-4c46-8460-3207b6782007',
        filter: 'uuid != "127c1ab5-fc7f-4c46-8460-3207b6782007"']);

// Subscribe to a channel:
_pubNubFlutter.subscribe('client1', ['Olivier-Channel']);

// Unsubscribe from a channel:
_pubNubFlutter.unsubscribe('client1',channel: 'test_channel');

//  Unsubscribe from all channels:
_pubNubFlutter.unsubscribeAll('client1');

// Publish a message to a channel:
_pubNubFlutter.publish(
    {'message': 'Hello World'},
    'test_channel',
);

// Publish a message to a channel passing metadata optional filter expression acts upon:
_pubNubFlutter.publish('client1',
    {'message': 'Hello World'},
    'test_channel',
    metadata: {
        'uuid': '127c1ab5-fc7f-4c46-8460-3207b6782007'
    }
);

// Listen for Messages:
_pubNubFlutter.onMessageReceived.listen((message) => print('Message:$message'));

// Listen for Status:
_pubNubFlutter.onStatusReceived.listen((status) => print('Status:${status.toString()}'));

// Listen to Presence:
_pubNubFlutter.onPresenceReceived.listen((presence) => print('Presence:${presence.toString()}'));

// Listen for Errors:
_pubNubFlutter.onErrorReceived.listen((error) => print('Error:$error'));


```
