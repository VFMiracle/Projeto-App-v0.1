import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:projeto_app/alarm.dart';
import 'package:projeto_app/cronometer.dart';
import 'package:projeto_app/notification_manager.dart';

//Controls the running state and reads the information of the Background Cronometer Notification.
class BackgroundCronometer{
  static const String constSctnOfRunPortName = "BkgrndRunPort";
  static const String constSctnOfCnclPortName = "BkgrndCnclPort";

  bool wasAlarmDelayed = false;
  Alarm? _alarm;
  Timer? counter;
  Map<String, dynamic>? crnmtrInfoMap;
  late DateTime startTime;
  late final String crnmtrName;

  BackgroundCronometer._();

  static void prepare(String crnmtrName) {
    BackgroundCronometer bkgrndCrnmtr = BackgroundCronometer._();
    ReceivePort runPort = ReceivePort();
    ReceivePort cancelPort = ReceivePort();
    String nameOfRunPort = crnmtrName + constSctnOfRunPortName;
    String nameOfCnclPort = crnmtrName + constSctnOfCnclPortName;
    bkgrndCrnmtr.crnmtrName = crnmtrName;
    //OBS: The instance is added as a Widgets Binding Observer because that way it remains active even while the cellphone screen is blocked. This was done because the
    //  Background Cronometer was missing system ticks while the screen was dark.
    if(IsolateNameServer.lookupPortByName(nameOfRunPort) != null){
      IsolateNameServer.removePortNameMapping(nameOfRunPort);
    }
    if(IsolateNameServer.lookupPortByName(nameOfCnclPort) != null){
      IsolateNameServer.removePortNameMapping(nameOfCnclPort);
    }
    IsolateNameServer.registerPortWithName(runPort.sendPort, nameOfRunPort);
    IsolateNameServer.registerPortWithName(cancelPort.sendPort, nameOfCnclPort);
    runPort.listen(bkgrndCrnmtr._run);
    cancelPort.listen(bkgrndCrnmtr._cancel);
  }

  String _buildStatus(int counterValue, int? alarmValue, bool isRunning){
    String counterStatus = "";
    counterStatus += Counter.writeTimeString(counterValue) + (isRunning ? "" : " - Paused");
    if(alarmValue != null){
      counterStatus += "   (Alarm for: " + Counter.writeTimeString(alarmValue) + ")";
    }
    return counterStatus;
  }

  void _cancel(dynamic _){
    if(counter != null){
      if(wasAlarmDelayed){
        SendPort? alarmSendPort = IsolateNameServer.lookupPortByName(crnmtrName + Cronometer.constSctnOfAlarmUpdtPortName);
        alarmSendPort!.send({"alarmValue" : _alarm!.alarmValue, "qtdDelays" : _alarm!.getQtdDelays});
      }
      SendPort? counterSendPort = IsolateNameServer.lookupPortByName(crnmtrName + Cronometer.constSctnOfCntrUpdtPortName);
      counterSendPort!.send(crnmtrInfoMap!["value"]);
      crnmtrInfoMap = null;
      counter!.cancel();
      NotificationManager().cancelCronometer();
    }
  }

  void _run(dynamic newCrnmtrInfoMap){
    crnmtrInfoMap = newCrnmtrInfoMap;
    crnmtrInfoMap!["startValue"] = crnmtrInfoMap!["value"];
    startTime = DateTime.now();
    if(crnmtrInfoMap!["isRunning"]){
      _alarm = crnmtrInfoMap!["alarm"];
      counter = Timer.periodic(const Duration(seconds: 1), (timer){
        crnmtrInfoMap!["value"] = crnmtrInfoMap!["startValue"] + (DateTime.now().difference(startTime).inMilliseconds/1000).round();
        if(_alarm != null){
          if(crnmtrInfoMap!["value"] > _alarm!.alarmValue){
            NotificationManager().displayAlarmCrnmtr(crnmtrInfoMap!["name"], _buildStatus(crnmtrInfoMap!["value"], _alarm!.alarmValue, true));
            if(_alarm!.dtrmnWhenToDelayAlarm(crnmtrInfoMap!["value"])){
              wasAlarmDelayed = true;
              _alarm!.cancelAlarm();
              NotificationManager().displayCronometer(crnmtrInfoMap!["name"], _buildStatus(crnmtrInfoMap!["value"], _alarm!.alarmValue, true));
            }
          }else if(crnmtrInfoMap!["value"] == _alarm!.alarmValue){
            NotificationManager().displayAlarmCrnmtr(crnmtrInfoMap!["name"], _buildStatus(crnmtrInfoMap!["value"], _alarm!.alarmValue, true));
            NotificationManager().cancelCronometer();
          }else{
            NotificationManager().displayCronometer(crnmtrInfoMap!["name"], _buildStatus(crnmtrInfoMap!["value"], _alarm!.alarmValue, true));
          }
        }else{
          NotificationManager().displayCronometer(crnmtrInfoMap!["name"], _buildStatus(crnmtrInfoMap!["value"], null, true));
        }
      });
    }else{
      NotificationManager().displayCronometer(crnmtrInfoMap!["name"], _buildStatus(crnmtrInfoMap!["value"], crnmtrInfoMap!["alarmValue"], false));
    }
  }
}