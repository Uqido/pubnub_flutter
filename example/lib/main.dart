import 'package:flutter/material.dart';
import 'package:pubnub_flutter/pubnub_flutter.dart';

//  PubNubFlutter({'clients':{'client1':{'pubKey':'xxx','subKey': 'rrrr', 'authKey':'wwwww', 'presenceTimeout':20, 'uuid':'ytttttt', 'filter':'vddsfdsfds'},
//                 'client2':{'subKey': 'ttttt', 'authKey':'fffff'}});

// _pubNubFlutter.unsubscribe(client: 'client1', channel: 'Olivier-Channel');

// _pubNubFlutter.subscribe(client: 'client1', channels: ['Olivier-Channel']);
// _pubNubFlutter.subscribe(client: 'client2', channels: ['Yegor-Channel']);

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
    _pubNubFlutter = PubNubFlutter([
      PubNubConfig('client1', 'pub-c-5089170e-d981-4b05-9fe0-8118cb3ae389',
          'sub-c-3e109ccc-e640-11e8-a679-1679df73129d',
          presenceTimeout: 120),
      PubNubConfig('client2', 'pub-c-5089170e-d981-4b05-9fe0-8118cb3ae389',
          'sub-c-3e109ccc-e640-11e8-a679-1679df73129d'),
    ]);

    _pubNubFlutter.uuid('client1').then((uuid) => print('UUID1: $uuid'));
    _pubNubFlutter.uuid('client2').then((uuid) => print('UUID2: $uuid'));

    _pubNubFlutter.onStatusReceived
        .listen((status) => print('Status:${status.toString()}'));

    _pubNubFlutter.onPresenceReceived
        .listen((presence) => print('Presence:${presence.toString()}'));

    _pubNubFlutter.onMessageReceived
        .listen((message) => print('Message:$message'));

    _pubNubFlutter.onErrorReceived.listen((error) => print('Error:$error'));
  }

  @override
  void dispose() {
    print('Unsubscribe all');
    _pubNubFlutter.unsubscribeAll('client1');
    _pubNubFlutter.unsubscribeAll('client2');
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <
                  Widget>[
                FlatButton(
                    color: Colors.black12,
                    onPressed: () {
                      _pubNubFlutter.unsubscribe('client1', 'Olivier-Channel');
                      _pubNubFlutter.unsubscribe('client2', 'Yegor-Channel');
                    },
                    child: Text('Unsubscribe')),
                FlatButton(
                    color: Colors.black12,
                    onPressed: () {
                      _pubNubFlutter.subscribe('client1', ['Olivier-Channel']);
                      _pubNubFlutter.subscribe('client2', ['Yegor-Channel']);
                    },
                    child: Text('Subscribe')),
                FlatButton(
                    color: Colors.black12,
                    onPressed: () {
                      _pubNubFlutter.publish(
                        'client1',
                        {'message': 'Hello World Olivier'},
                        'Olivier-Channel',
                      );
                      _pubNubFlutter.publish(
                        'client2',
                        {'message': 'Hello World Yegor'},
                        'Yegor-Channel',
                      );

                      _pubNubFlutter.presence("client1", "Olivier-Channel", {
                        "clientType": "advisorSession",
                        "username": "BernieSuperTrump"
                      });
                      // Below is used to filter the uuid, works in combination with the filter expression in the create method above
                      //metadata: {
                      //  'uuid': '127c1ab5-fc7f-4c46-8460-3207b6782007'
                      //});
                    },
                    child: Text('Send Message'))
              ])
            ],
          )),
        ),
      );
}
