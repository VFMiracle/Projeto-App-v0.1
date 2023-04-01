import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone;

//Manages the display state of the project's Notifications.
class NotificationManager{
  static final NotificationManager _ntfctnManager = NotificationManager._internal();
  final FlutterLocalNotificationsPlugin flutterLocalNtfctnsPlugin = FlutterLocalNotificationsPlugin();

  NotificationManager._internal();

  factory NotificationManager(){
    return _ntfctnManager;
  }

  startup() async {
    const  AndroidInitializationSettings androidIntlztnSettings = AndroidInitializationSettings('app_icon');
    const InitializationSettings intlztnSettings = InitializationSettings(android: androidIntlztnSettings);

    timezone.initializeTimeZones();

    await flutterLocalNtfctnsPlugin.initialize(intlztnSettings);
  }

  Future<void> cancelAlarm() async{
    flutterLocalNtfctnsPlugin.cancel(1);
  }

  Future<void> cancelCronometer() async{
    flutterLocalNtfctnsPlugin.cancel(0);
  }

  Future<void> displayAlarm() async{
    const int instntBitFlag = 4;
    AndroidNotificationDetails androidAlarmDetails = AndroidNotificationDetails(
      'alarm',
      'Alarm',
      additionalFlags: Int32List.fromList(<int>[instntBitFlag]),
      channelDescription: 'A notification informing that the alarm was reached. It shows up whether or not the app is in the background.',
      priority: Priority.high,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
    );
    NotificationDetails alarmDetails = NotificationDetails(android: androidAlarmDetails);
    await flutterLocalNtfctnsPlugin.show(
      1,
      "Alarm Reached",
      null,
      alarmDetails,
    );
  }

  //OBS: This function is responsible for displaying a Cronometer Notification with a playing Alarm. It needs to be a separate function since functions that display 
  //  Notifications don't interact well with conditional statements, which means they can't change their behaviour depending on the current state.
  Future<void> displayAlarmCrnmtr(String name, String counterStatus) async{
    const int instntBitFlag = 4, noClearBitFlag = 32, ongngEventBitFlag = 2, onlyAlertOnceBitFlag = 8;
    AndroidNotificationDetails andrdAlarmCrnmtrDetails = AndroidNotificationDetails(
      'alarmCronometer',
      'AlarmCronometer',
      additionalFlags: Int32List.fromList(<int>[instntBitFlag, noClearBitFlag, ongngEventBitFlag, onlyAlertOnceBitFlag]),
      channelDescription: 'Teh background cronometer combined with a playing alarm.',
      importance: Importance.max,
      priority: Priority.max,
      sound: const RawResourceAndroidNotificationSound('notification_sound'),
      styleInformation: const BigTextStyleInformation(''),
    );
    NotificationDetails alarmCrnmtrDetails = NotificationDetails(android: andrdAlarmCrnmtrDetails);
    await flutterLocalNtfctnsPlugin.show(
      1,
      name + " - Alarm",
      counterStatus + " (ALARM REACHED)",
      alarmCrnmtrDetails,
    );
  }

  Future<void> displayCronometer(String name, String counterStatus) async{
    const AndroidNotificationDetails androidCrnmtrDetails = AndroidNotificationDetails(
      'cronometer',
      'Cronometer',
      channelDescription: 'The background representation of the cronometer.',
      playSound: false,
      priority: Priority.low,
      importance: Importance.low,
      styleInformation: BigTextStyleInformation(''),
    );
    const NotificationDetails crnmtrDetails = NotificationDetails(android: androidCrnmtrDetails);
    await flutterLocalNtfctnsPlugin.show(
      0,
      name,
      counterStatus,
      crnmtrDetails,
    );
  }
}