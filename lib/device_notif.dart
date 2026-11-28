import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class DeviceNotif {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();
  static bool _ready = false;

  static Future<void> init() async {
    if (kIsWeb || _ready) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Minta izin notifikasi di Android 13+
    await androidImpl?.requestNotificationsPermission();

    // Buat channel prioritas tinggi agar muncul pop-up banner di HP
    const channel = AndroidNotificationChannel(
      'campusfind_alerts',
      'Notifikasi CampusFind',
      description: 'Pemberitahuan kecocokan barang, klaim, dan verifikasi satpam',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await androidImpl?.createNotificationChannel(channel);
    _ready = true;
  }

  static Future<void> show({
    required String id,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;
    if (!_ready) await init();

    const androidDetails = AndroidNotificationDetails(
      'campusfind_alerts',
      'Notifikasi CampusFind',
      channelDescription:
      'Pemberitahuan kecocokan barang, klaim, dan verifikasi satpam',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    await _plugin.show(
      id.hashCode & 0x7FFFFFFF,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}