import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:citoyen_plus/core/network/dio_client.dart';
import 'package:citoyen_plus/core/network/api_endpoints.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static final Dio _dio = DioClient.getInstance();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    if (!kIsWeb) {
      await _plugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
          linux: linuxSettings,
        ),
      );

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosPlugin = _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        await iosPlugin?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    }
  }

  static Future<void> registerDeviceToken(String fcmToken) async {
    try {
      await _dio.post(
        ApiEndpoints.notificationsRegister,
        data: {'token': fcmToken, 'platform': defaultTargetPlatform.name},
      );
    } catch (_) {}
  }

  static Future<void> show({
    required String titre,
    required String corps,
  }) async {
    if (kIsWeb) return;

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      titre,
      corps,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'citoyen_plus_channel',
          'Citoyen +',
          channelDescription: "Notifications de l'application Citoyen +",
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
        linux: LinuxNotificationDetails(),
      ),
    );
  }
}
