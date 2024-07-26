import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geofence_foreground_service/constants/geofence_event_type.dart';
import 'package:geofence_foreground_service/exports.dart';
import 'dart:async';

import 'package:geofence_foreground_service/geofence_foreground_service.dart';
import 'package:geofence_foreground_service/models/notification_icon_data.dart';
import 'package:geofence_foreground_service/models/zone.dart';
import 'package:permission_handler/permission_handler.dart';

@pragma('vm:entry-point')
void callbackDispatcher() async {
  GeofenceForegroundService().handleTrigger(
    backgroundTriggerHandler: (zoneID, triggerType) {
      log(zoneID, name: 'zoneID');

      if (triggerType == GeofenceEventType.enter) {
        log('enter', name: 'triggerType');
      } else if (triggerType == GeofenceEventType.exit) {
        log('exit', name: 'triggerType');
      } else if (triggerType == GeofenceEventType.dwell) {
        log('dwell', name: 'triggerType');
      } else {
        log('unknown', name: 'triggerType');
      }

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
  final List<LatLng> timesSquarePolygon = [
    LatLng.degree(40.758078, -73.985640),
    LatLng.degree(40.757983, -73.985417),
    LatLng.degree(40.757881, -73.985493),
    LatLng.degree(40.757956, -73.985688),
  ];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    await Future.wait([
      Permission.location.request(),
      Permission.locationAlways.request(),
      Permission.notification.request(),
    ]);

    bool hasServiceStarted =
        await GeofenceForegroundService().startGeofencingService(
      contentTitle: 'Test app is running in the background',
      contentText:
          'Test app will be running to ensure seamless integration with ops team',
      notificationChannelId: 'com.app.geofencing_notifications_channel',
      serviceId: 525600,
      isInDebugMode: true,
      notificationIconData: const NotificationIconData(
        resType: ResourceType.mipmap,
        resPrefix: ResourcePrefix.ic,
        name: 'launcher',
      ),
      callbackDispatcher: callbackDispatcher,
    );

    if (hasServiceStarted) {
      await GeofenceForegroundService().addGeofenceZone(
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
