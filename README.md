# PubNubFlutter

[![pub package](https://img.shields.io/pub/v/pubnub.svg)](https://pub.dartlang.org/packages/pubnub)

A Flutter plugin to access PubNub functionalities such as publish, subscribe, status and presence..

## Usage
To use this plugin, add `pubnub_flutter` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

### Example

``` dart
// Instantiate plugin without a filter expression:
 _pubNubFlutter = PubNubFlutter('pub-c-2d1121f9-06c1-4413-8d2e-0000000000',
        'sub-c-324ae474-ecfd-11e8-91a4-00000000000',
        uuid: '127c1ab5-fc7f-4c46-8460-3207b6782007');
        
// Instantiate plugin with a filter expression:
_pubNubFlutter = PubNubFlutter('pub-c-2d1121f9-06c1-4413-8d2e-0000000000',
        'sub-c-324ae474-ecfd-11e8-91a4-00000000000',
        uuid: '127c1ab5-fc7f-4c46-8460-3207b6782007',
        filter: 'uuid != "127c1ab5-fc7f-4c46-8460-3207b6782007"');

// Subscribe to a channel:
_pubNubFlutter.subscribe(['test_channel']);

// Unsubscribe from a channel:
_pubNubFlutter.unsubscribe(channel: 'test_channel');

//  Unsubscribe from all channels:
_pubNubFlutter.unsubscribeAll();

// Publish a message to a channel:
_pubNubFlutter.publish(
    {'message': 'Hello World'},
    'test_channel',
);

// Publish a message to a channel passing metadata optional filter expression acts upon:
_pubNubFlutter.publish(
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
