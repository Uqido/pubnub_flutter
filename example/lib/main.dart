import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pubnub_flutter/pubnub_flutter.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {




      platformVersion = await PubnubFlutter.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child:Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Text('Running on: $_platformVersion\n'),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children:<Widget>[
            FlatButton(color: Colors.black12,onPressed: () {PubnubFlutter.unsubscribe(channel: "olivier_channel");},
            child: Text("Unsubscribe")),
            FlatButton(color: Colors.black12,onPressed: () {PubnubFlutter.subscribe(
                publishKey: "pub-c-2d1121f9-06c1-4413-8d2e-865f0cfe702a",
                subscribeKey: "sub-c-324ae474-ecfd-11e8-91a4-7e00ddddd7aa",
                channel: "olivier_channel");},
                child: Text("Subscribe"))
              ])
          ],)
        ),
      ),
    );
  }
}
