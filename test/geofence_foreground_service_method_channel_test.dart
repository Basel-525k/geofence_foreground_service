import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geofence_foreground_service/geofence_foreground_service_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelGeofenceForegroundService platform = MethodChannelGeofenceForegroundService();
  const MethodChannel channel = MethodChannel('geofence_foreground_service');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('startGeofencingService', () async {});
}
