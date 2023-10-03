import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geofence_foreground_service/exports.dart';
import 'dart:async';

import 'package:geofence_foreground_service/geofence_foreground_service.dart';
import 'package:geofence_foreground_service/models/zone.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
void callbackDispatcher() async {
  GeofenceForegroundService().handleTrigger(
    backgroundTriggerHandler: (zoneID, triggerType) {
      log(zoneID, name: 'zoneID');
      log('$triggerType', name: 'triggerType');

      return Future.value(true);
    },
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GeofenceForegroundService _geofenceForegroundServicePlugin = GeofenceForegroundService();

  final List<LatLng> timesSquarePolygon = [
    const LatLng(40.758078, -73.985640),
    const LatLng(40.757983, -73.985417),
    const LatLng(40.757881, -73.985493),
    const LatLng(40.757956, -73.985688),
  ];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    await Permission.location.request();
    await Permission.locationAlways.request();
    await Permission.notification.request();

    bool hasServiceStarted = await _geofenceForegroundServicePlugin.startGeofencingService(
      contentTitle: 'Test app is running in the background',
      contentText: 'Test app will be running to ensure seamless integration with ops team',
      notificationChannelId: 'com.app.geofencing_notifications_channel',
      serviceId: 525600,
      isInDebugMode: true,
      callbackDispatcher: callbackDispatcher,
    );

    if (hasServiceStarted) {
      await _geofenceForegroundServicePlugin.addGeofenceZone(
        zone: Zone(
          id: 'zone#1_id',
          radius: 10000,
          coordinates: timesSquarePolygon,
        ),
      );
    }

    log(hasServiceStarted.toString(), name: 'hasServiceStarted');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
      ),
    );
  }
}
