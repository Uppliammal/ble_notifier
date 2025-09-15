import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _initialized = false;
  
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS initialization settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    // Initialize the plugin
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    _initialized = true;
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    print("Notification tapped: ${response.payload}");
    Get.snackbar("Notification", "Tapped: ${response.payload}");
  }
  
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'ble_notifications',
      'BLE Device Notifications',
      channelDescription: 'Notifications for BLE device proximity changes',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
  
  Future<void> showPersistentNotification({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'ble_foreground',
      'BLE Scanning Service',
      channelDescription: 'BLE scanning is running in the background',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
    );
    
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await _notifications.show(
      999,
      title,
      body,
      notificationDetails,
    );
  }
  
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
  
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
} 