import 'package:flutter/material.dart';
import 'package:pubnub_flutter/pubnub_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PubNubFlutter _pubNubFlutter;

  @override
  void initState() {
    super.initState();
    _pubNubFlutter = PubNubFlutter('pub-c-2d1121f9-06c1-4413-8d2e-865f0cfe702a',
        'sub-c-324ae474-ecfd-11e8-91a4-7e00ddddd7aa',
        filter: 'uuid != "toto"');

    _pubNubFlutter.uuid().then((uuid) => print('UUID: $uuid'));

    _pubNubFlutter.onStatusReceived
        .listen((status) => print('Status:${status.toString()}'));

    _pubNubFlutter.onMessageReceived
        .listen((message) => print('Message:$message'));

    _pubNubFlutter.onErrorReceived.listen((error) => print('Error:$error'));
  }

  @override
  void dispose() {
    print('Unsubscribe all');
    _pubNubFlutter.unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: const Text('PubNub'),
          ),
          body: Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    FlatButton(
                        color: Colors.black12,
                        onPressed: () {
                          _pubNubFlutter.unsubscribe(
                              channel: 'olivier_channel');
                        },
                        child: Text('Unsubscribe')),
                    FlatButton(
                        color: Colors.black12,
                        onPressed: () {
                          _pubNubFlutter.subscribe(['olivier_channel']);
                        },
                        child: Text('Subscribe')),
                    FlatButton(
                        color: Colors.black12,
                        onPressed: () {
                          _pubNubFlutter.publish(
                              {'message': 'Hello World'}, 'olivier_channel');
                        },
                        child: Text('Send Message'))
                  ])
            ],
          )),
        ),
      );
}
