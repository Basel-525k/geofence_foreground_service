import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geofence_foreground_service/exports.dart';
import 'dart:async';

import 'package:geofence_foreground_service/geofence_foreground_service.dart';
import 'package:geofence_foreground_service/models/zone.dart';
import 'package:permission_handler/permission_handler.dart';

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
      serviceId: 525000,
    );

    if (hasServiceStarted) {
      await _geofenceForegroundServicePlugin.addGeofenceZone(
        zone: Zone(
          id: 'zone#1_id',
          radius: 10000,
          coordinates: [
            const LatLng(31.475190, 34.401974),
            const LatLng(31.478389, 34.405458),
            const LatLng(31.476515, 34.408737),
            const LatLng(31.472951, 34.404793),
          ],
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
