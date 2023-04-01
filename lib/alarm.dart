import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
/*import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';*/
import 'package:projeto_app/alarm_selector.dart';
import 'package:projeto_app/cronometer.dart';
import 'package:projeto_app/notification_manager.dart';

//Manages the state for all kinds of Alarm.
class Alarm{
  //INFO: wasAlarmDspyd is only related to the foreground Alarm process. The background Alarm process is handled by a different variable of same name in
  //  BackgroundCronometer.
  bool isAlarmSet = false, wasAlarmDspyd = false;
  int alarmValue = 0, _qtdDelays = 0;
  final int _maxXcdngTimeFromAlarm = 30, _delayAmount = 300;
  late _AlarmOptions alarmOptions;

  int get getQtdDelays{
    return _qtdDelays;
  }

  set setQtdDelays(value){
    if(value > _qtdDelays){
      _qtdDelays = value;
    }
  }

  Alarm({int alarmValue = 0}){
    alarmOptions = _AlarmOptions(this);
    if(alarmValue != 0){
      this.alarmValue = alarmValue;
      isAlarmSet = true;
    }
  }

  void cancelAlarm(){
    NotificationManager().cancelAlarm();
  }

  bool dtrmnWhenToDelayAlarm(int counterValue){
    if(counterValue == alarmValue + _maxXcdngTimeFromAlarm){
      alarmValue += _maxXcdngTimeFromAlarm + _delayAmount;
      _qtdDelays++;
      return true;
    }
    return false;
  }

  void dtrmnWhenToDspyAlarm(int counterValue, BuildContext context, void Function(int) pauseMainCounter, void Function() updateCrnmtrState,
  void Function({int? customCounterValue}) startBkgrndCrnmtr){
    if(counterValue == alarmValue && !wasAlarmDspyd){
      wasAlarmDspyd = true;
      _displayAlarm(context, pauseMainCounter, updateCrnmtrState, startBkgrndCrnmtr);
    }
  }

  void reset(){
    if(_qtdDelays > 0){
      alarmValue -= (_maxXcdngTimeFromAlarm + _delayAmount) * _qtdDelays;
      _qtdDelays = 0;
    }
  }

  void _displayAlarm(BuildContext context, void Function(int) pauseMainCounter, void Function() updateCrnmtrState,
  void Function({int? customCounterValue}) startBkgrndCrnmtr) {
    Navigator.push<void>(context, MaterialPageRoute<void>(
      builder: (BuildContext context){
        return _AlarmPanel(alarmValue, pauseMainCounter, updateCrnmtrState, startBkgrndCrnmtr, this);
      }
    ));
  }
}

//Represents the AlertDialog that allows the user to configure the Alarm for a Cronometer.
class _AlarmOptions extends StatefulWidget{
  final Alarm alarmRoot;

  const _AlarmOptions(this.alarmRoot, {Key? key}) : super(key: key);

  @override
  State<_AlarmOptions> createState(){
    return _AlarmOptionsState();
  }
}

//The state for the Alarm Options Dialog.
class _AlarmOptionsState extends State<_AlarmOptions>{
  bool isKybrdOpen = false;
  VoidCallback? _saveButtonClbck;
  late StreamSubscription<bool> kybrdVsbltSbscrp;

  @override
  void initState(){
    super.initState();
    kybrdVsbltSbscrp = KeyboardVisibilityController().onChange.listen((bool visible) => isKybrdOpen = visible);
  }

  @override
  void dispose(){
    kybrdVsbltSbscrp.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return KeyboardDismissOnTap(
      child: WillPopScope(
        child: AlertDialog(
          title: const Text("Alarm Options"),
          contentPadding: const EdgeInsets.only(),
          content: AlarmSelector(
            changeClbck: (int alarmValue){
              widget.alarmRoot.alarmValue = alarmValue;
              if(alarmValue > 0){
                if(_saveButtonClbck == null){
                  setState(() => _saveButtonClbck = _setupAlarm);
                }
              }else{
                setState(() => _saveButtonClbck = null);
              }
            },
            initialHours: _clcltTimeUnitValue(TimeUnit.hour),
            initialMinutes: _clcltTimeUnitValue(TimeUnit.minute),
            initialSeconds: _clcltTimeUnitValue(TimeUnit.second),
            numberPickerType: NumberPickerType.normal,
          ),
          actions: <Widget>[
            TextButton(
              child: Text(widget.alarmRoot.isAlarmSet ? "Update" : "Save"),
              onPressed: _saveButtonClbck,
            ),
          ],
        ),
        onWillPop: () async {
          _closeKeyboard();
          if(widget.alarmRoot.isAlarmSet){
            if(widget.alarmRoot.alarmValue == 0){
              widget.alarmRoot.isAlarmSet = false;
            }
            Navigator.pop(context, false);
          }else{
            Navigator.pop(context, null);
          }
          return false;
        }
      ),
    );
  }

  int _clcltTimeUnitValue(TimeUnit timeUnit){
    switch(timeUnit){
      case TimeUnit.hour:
        return widget.alarmRoot.alarmValue ~/ Duration.secondsPerHour;
      case TimeUnit.minute:
        return (widget.alarmRoot.alarmValue - _clcltTimeUnitValue(TimeUnit.hour)*Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
      case TimeUnit.second:
        return widget.alarmRoot.alarmValue - _clcltTimeUnitValue(TimeUnit.hour)*Duration.secondsPerHour -
          _clcltTimeUnitValue(TimeUnit.minute)*Duration.secondsPerMinute;
      default: return 0;
    }
  }

  void _closeKeyboard(){
    //OBS: This is done when the Alarm Options is closed so the keyboard won't try to focus the Cronometer's name field.
    if(isKybrdOpen){
      FocusManager.instance.primaryFocus!.unfocus();
    }
  }

  void _setupAlarm(){
    bool result = !widget.alarmRoot.isAlarmSet;
    widget.alarmRoot.isAlarmSet = true;
    widget.alarmRoot.wasAlarmDspyd = false;
    _closeKeyboard();
    Navigator.pop(context, result);
  }
}

//Represents the page displayed if the Alarm plays while it is in the foreground.
class _AlarmPanel extends StatefulWidget{
  final int alarmValue;
  final void Function() updateCrnmtrState;
  final void Function(int) pauseMainCounter;
  final void Function({int? customCounterValue}) startBkgrndCrnmtr;
  final Alarm alarmRoot;
  const _AlarmPanel(this.alarmValue, this.pauseMainCounter, this.updateCrnmtrState, this.startBkgrndCrnmtr, this.alarmRoot, {Key? key}) : super(key: key);

  @override
  _AlarmPanelState createState() => _AlarmPanelState();
}

//The state for the Alarm Panel Route.
class _AlarmPanelState extends State<_AlarmPanel> with SingleTickerProviderStateMixin, WidgetsBindingObserver{
  late AnimationController controller;
  late Counter _counter;

  @override
  initState(){
    super.initState();
    controller = AnimationController(
      duration: Cronometer.infntDrtn,
      vsync: this,
    );
    controller.forward();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    controller.dispose();
    widget.alarmRoot.cancelAlarm();
    _counter.animation.removeListener(_dtrmnWhenToDelayAlarm);
    WidgetsBinding.instance.removeObserver(this);
    /*FlutterRingtonePlayer.stop();*/
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if(state == AppLifecycleState.paused){
      widget.startBkgrndCrnmtr(customCounterValue: _counter.animation.value);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context){
    ThemeData themeData = Theme.of(context);
    /*FlutterRingtonePlayer.play(fromAsset: "android/app/src/main/res/raw/notification_sound.mp3", looping: true);*/
    Widget route = Scaffold(
      body: Column(
        children: [
          Text(
            "Tempo Esgotado",
            style: TextStyle(
              color: themeData.colorScheme.primary,
              fontSize: 30,
            ),
          ),
          _counter = Counter(
            animation: StepTween(
              begin: widget.alarmValue,
              end: Cronometer.infntDrtn.inSeconds,
            ).animate(controller),
          ),
          Text(
            Counter.writeTimeString(widget.alarmValue),
            style: const TextStyle(
              fontSize: 20,
            ),
          ),
          Row(
            children:[
              TextButton(
                child: const Text(
                  "Pause",
                  style: TextStyle(
                    fontSize: 25,
                  ),
                ),
                onPressed: (){
                  widget.pauseMainCounter(_counter.animation.value);
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 25,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ],
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    );
    _counter.animation.addListener(_dtrmnWhenToDelayAlarm);
    return route;
  }

  void _dtrmnWhenToDelayAlarm(){
    bool wasAlarmDelayed = widget.alarmRoot.dtrmnWhenToDelayAlarm(_counter.animation.value);
    if(wasAlarmDelayed){
      widget.updateCrnmtrState();
      widget.alarmRoot.wasAlarmDspyd = false;
      Navigator.pop(context);
    }
  }
}