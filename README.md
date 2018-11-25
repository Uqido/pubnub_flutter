# PubNubFlutter

[![pub package](https://img.shields.io/pub/v/pubnub.svg)](https://pub.dartlang.org/packages/pubnub)

A Flutter plugin to access PubNub functionalities such as publish, subscribe, status, state and presence..

## Usage
To use this plugin, add `pubnub` as a [dependency in your pubspec.yaml file](https://flutter.io/platform-plugins/).

### Example

``` dart
// Import package
import 'package:pubnub/pubnub.dart';

// Instantiate
_pubNub = PubNub("publish key", "subscribe key");

// Listen for status changes
_pubNubFlutter.onStatusReceived.listen((status) {
    print("Status:${status.toString()}");
});

// Listen for new message
_pubNubFlutter.onMessageReceived.listen((message) {
   print("Message:${message}");
});

// Listen for errors
_pubNubFlutter.onErrorReceived.listen((error) {
    print("Error:${error}");
});

// Subscribe to at least one channel
_pubNubFlutter.subscribe(["my_channel"]);

// Unsubscribe from one channel
_pubNubFlutter.unsubscribe(channel: "my_channel");

// Send message
_pubNubFlutter.publish({'msg': 'hello world'}, "my_channel");

```
