import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  // Schedule fee reminder 3 days before due date
  static Future<void> scheduleFeeReminder(DateTime dueDate, String memberName) async {
    final scheduleTime = tz.TZDateTime.from(
      dueDate.subtract(const Duration(days: 3)), 
      tz.local,
    );

    await _plugin.zonedSchedule(
      1,
      'Fee Reminder',
      'Hi $memberName, your fee is due in 3 days!',
      scheduleTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'fee_channel', 
          'Fee Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> showInstantNotification(String title, String body) async {
    await _plugin.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails('core_channel', 'General Notifications'),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
