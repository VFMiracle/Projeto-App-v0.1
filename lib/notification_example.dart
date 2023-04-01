import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone;
import 'package:timezone/timezone.dart' as timezone;

class NotificationExample{
  static final NotificationExample _ntfctnExample = NotificationExample._internal();
  static const AndroidNotificationDetails _androidNtfctnDetails = AndroidNotificationDetails(
    'channel ID',
    'channel name',
    channelDescription: 'channel description',
    playSound: true,
    priority: Priority.high,
    importance: Importance.high,
  );

  final NotificationDetails ntfctnDetails = const NotificationDetails(android: _androidNtfctnDetails);
  final FlutterLocalNotificationsPlugin flutterLocalNtfctnsPlugin = FlutterLocalNotificationsPlugin();

  NotificationExample._internal();

  factory NotificationExample(){
    return _ntfctnExample;
  }

  startup() async {
    const  AndroidInitializationSettings androidIntlztnSettings = AndroidInitializationSettings('app_icon');
    const InitializationSettings intlztnSettings = InitializationSettings(android: androidIntlztnSettings);

    timezone.initializeTimeZones();

    await flutterLocalNtfctnsPlugin.initialize(intlztnSettings, onSelectNotification: selectNotification);
  }

  Future<void> cancelNotification(int ntfctnId) async{
    flutterLocalNtfctnsPlugin.cancel(ntfctnId);
  }

  Future<void> displayNotification() async{
    await flutterLocalNtfctnsPlugin.show(
      0,
      'Notification Title',
      'This is the Notification Body',
      ntfctnDetails,
      payload: 'Notification Payload',
    );
  }

  Future<void> scheduleNotification() async{
    await flutterLocalNtfctnsPlugin.zonedSchedule(
      0,
      "Notification Title",
      "This is the Notification Body!",
      timezone.TZDateTime.now(timezone.local).add(const Duration(seconds: 5)),
      ntfctnDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> selectNotification(String? payload) async {
    if (payload != null) {
      debugPrint('notification payload: $payload');
    }
  }
}