/*
 * Copyright 2019 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:movisens_flutter/movisens_flutter.dart';

ThemeData darkTheme = ThemeData(
  // Define the default Brightness and Colors
  brightness: Brightness.dark,
  primaryColor: Colors.lightBlue[800],
  accentColor: Colors.cyan[600],

  // Define the default Font Family
  fontFamily: 'Montserrat',

  // Define the default TextTheme. Use this to specify the default
  // text styling for headlines, titles, bodies of text, and more.
  textTheme: TextTheme(
    headline: TextStyle(fontSize: 72.0, fontWeight: FontWeight.bold),
    title: TextStyle(fontSize: 36.0, fontStyle: FontStyle.italic),
    body1: TextStyle(fontSize: 14.0, fontFamily: 'Hind'),
  ),
);

void main() => runApp(MovisensApp());

class MovisensApp extends StatefulWidget {
  @override
  _MovisensAppState createState() => _MovisensAppState();
}

class _MovisensAppState extends State<MovisensApp> {
  Movisens _movisens;
  StreamSubscription<Map<String, dynamic>> _subscription;
  List<Map<String, dynamic>> movisensEvents = [];
  String address = 'unknown', name = 'unknown';
  int weight, height, age;

  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothDevice _sensor;
  @override
  void initState() {
    super.initState();
    startListening();
  }

  void onData(Map<String, dynamic> d) {
    print(" onData_flutter: " + "$d");
    setState(() {
      movisensEvents.add(d);
    });
  }

  void stopListening() {
    _subscription.cancel();
  }

  void startListening() {
    //address = '88:6B:0F:82:1D:33';// move4

    address = '00:07:80:78:63:A5'; // ECG4

    name = 'MOVISENS Sensor 00840';
    weight = 100;
    height = 180;
    age = 25;

    UserData userData = new UserData(weight, height, Gender.male, age, SensorLocation.chest, address, name);

    _movisens = new Movisens(userData);

    try {
      _subscription = _movisens.movisensStream.listen(onData);
    } on MovisensException catch (exception) {
      print(exception);
    }
  }

  void startBluetoothScan() {
    flutterBlue.startScan(timeout: Duration(seconds: 4));

    // Listen to scan results
    var subscription = flutterBlue.scanResults.listen((results) {
        // do something with scan results
        for (ScanResult r in results) {
            if(r.device.name.contains("MOVISENS")) {
              connect(r.device);
              print("Connected to movisens");
            }
            print('${r.device.name} found! rssi: ${r.rssi}');
        }
    });
  }
  void connect(device) async{
    setState(() {
      _sensor = device;
    });
    await device.connect();
    print(device);    
  }
   void disconnect(device) async{
    setState(() {
      _sensor = null;
    });
    await device.disconnect();
    print("Disconnected");    
  }
  void stopBluetoothScan() {
    flutterBlue.stopScan();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movisens Log App',
      theme: darkTheme,
      home: Scaffold(
        appBar: AppBar(title: Text("Movisens Test"),),
        body: Column(children: <Widget>[
FlatButton(child: Text("scan"),color: Colors.red,padding: EdgeInsets.all(10),onPressed: () {startBluetoothScan();},),
         Container(height: 200,child:ListView.builder(
            itemCount: this.movisensEvents.length, itemBuilder: (context, index) => this._buildRow(index)),
         )
        ])),
    );
  }

  _buildRow(int index) {
    Map<String, dynamic> d = movisensEvents[index];
    return new Container(
        child: new ListTile(
          leading: Icon(_getIcon(d)),
          title: new Text(
            d.toString(),
            style: TextStyle(fontSize: 12),
          ),
        ),
        decoration: new BoxDecoration(border: new Border(bottom: new BorderSide())));
  }

  IconData _getIcon(Map<String, dynamic> d) {
    if (d.containsKey("TapMarker")) return Icons.touch_app;
    if (d.containsKey("MovementAcceleration")) return Icons.arrow_downward;
    if (d.containsKey("BodyPosition")) return Icons.accessibility;
    if (d.containsKey("Met")) return Icons.cached;
    if (d.containsKey("StepCount")) return Icons.directions_walk;
    if (d.containsKey("BatteryLevel")) return Icons.battery_charging_full;
    if (d.containsKey("ConnectionStatus"))
      return Icons.bluetooth_connected;
    else
      return Icons.device_unknown;
  }
}