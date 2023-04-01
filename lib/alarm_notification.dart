import 'package:projeto_app/notification_manager.dart';

class AlarmNotification{
  bool _wasAlarmDspyd = false;
  int alarmValue;

  AlarmNotification(this.alarmValue);
  
  void cancel(){
    _wasAlarmDspyd = false;
    NotificationManager().cancelAlarm();
  }

  void dtrmnWhenToDisplay(int counterValue){
    if(counterValue == alarmValue && !_wasAlarmDspyd){
      _wasAlarmDspyd = true;
      NotificationManager().displayAlarm();
    }
  }
}