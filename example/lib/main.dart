import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geofence_foreground_service/constants/geofence_event_type.dart';
import 'package:geofence_foreground_service/exports.dart';
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static final LatLng _londonCityCenter = LatLng.degree(51.509865, -0.118092);
  static final List<LatLng> _timesSquarePolygon = [
    LatLng.degree(40.758078, -73.985640),
    LatLng.degree(40.757983, -73.985417),
    LatLng.degree(40.757881, -73.985493),
    LatLng.degree(40.757956, -73.985688),
  ];

  bool _hasServiceStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      final bgPermission = await Permission.locationAlways.status;
      if (!bgPermission.isGranted) {
        _showPermissionDialog();
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('Background location is required for geofencing.'),
        actions: [
          TextButton(
            onPressed: () => openAppSettings(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Permissions not granted. Please enable them in settings.'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  Future<bool> checkAndRequestPermissions() async {
    var locationStatus = await Permission.location.status;
    var locationAlwaysStatus = await Permission.locationAlways.status;
    var notificationStatus = await Permission.notification.status;

    if (!locationStatus.isGranted) {
      locationStatus = await Permission.location.request();
    }

    if (!locationAlwaysStatus.isGranted) {
      locationAlwaysStatus = await Permission.locationAlways.request();
      if (!locationAlwaysStatus.isGranted) {
        await openAppSettings();
        return false;
      }
    }

    if (!notificationStatus.isGranted) {
      notificationStatus = await Permission.notification.request();
    }

    return locationStatus.isGranted &&
        locationAlwaysStatus.isGranted &&
        notificationStatus.isGranted;
  }

  Future<void> _startServiceIfNeeded() async {
    if (!_hasServiceStarted) {
      _hasServiceStarted =
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
      log(_hasServiceStarted.toString(), name: 'hasServiceStarted');
    }
  }

  Future<void> _createLondonGeofence() async {
    final hasPermissions = await checkAndRequestPermissions();
    if (!hasPermissions) {
      _showPermissionDeniedMessage();
      return;
    }

    await _startServiceIfNeeded();

    await GeofenceForegroundService().addGeofenceZone(
      zone: Zone(
        id: 'zone#1_id',
        radius: 1000,
        coordinates: [_londonCityCenter],
        notificationResponsivenessMs: 15000,
        triggers: [
          GeofenceEventType.dwell,
          GeofenceEventType.enter,
          GeofenceEventType.exit
        ],
        expirationDuration: const Duration(days: 1),
        dwellLoiteringDelay: const Duration(hours: 1),
        initialTrigger: GeofenceEventType.enter,
      ),
    );
  }

  Future<void> _createTimesSquarePolygonGeofence() async {
    final hasPermissions = await checkAndRequestPermissions();
    if (!hasPermissions) {
      _showPermissionDeniedMessage();
      return;
    }

    await _startServiceIfNeeded();

    await GeofenceForegroundService().addGeofenceZone(
      zone: Zone(
        id: 'zone#2_id',
        radius: 10000,
        coordinates: _timesSquarePolygon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                  onPressed: _createLondonGeofence,
                  child: const Text('Create Circular London Geofence')),
              const SizedBox(height: 30),
              ElevatedButton(
                  onPressed: _createTimesSquarePolygonGeofence,
                  child: const Text('Create Polygon Times Square Geofence')),
            ],
          ),
        ),
      ),
    );
  }
}
