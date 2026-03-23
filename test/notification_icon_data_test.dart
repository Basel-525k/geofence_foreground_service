import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:geofence_foreground_service/constants/json_keys.dart';
import 'package:geofence_foreground_service/models/notification_icon_data.dart';

void main() {
  test('toJson maps enums and optional color', () {
    const icon = NotificationIconData(
      resType: ResourceType.mipmap,
      resPrefix: ResourcePrefix.ic,
      name: 'launcher',
    );
    final json = icon.toJson();
    expect(json[JsonKeys.resType], 'mipmap');
    expect(json[JsonKeys.resPrefix], 'ic');
    expect(json[JsonKeys.name], 'launcher');
    expect(json[JsonKeys.backgroundColorRgb], isNull);
  });

  test('toJson includes RGB when backgroundColor set', () {
    final icon = NotificationIconData(
      resType: ResourceType.drawable,
      resPrefix: ResourcePrefix.img,
      name: 'bell',
      backgroundColor: const Color(0xAABBCCDD),
    );
    final json = icon.toJson();
    expect(json[JsonKeys.backgroundColorRgb], isNotNull);
    expect(json[JsonKeys.backgroundColorRgb] as String, contains(','));
  });
}
