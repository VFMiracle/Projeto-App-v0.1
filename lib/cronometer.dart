import 'dart:async';
import 'dart:isolate';
import 'dart:ui';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter/material.dart';
import 'package:projeto_app/alarm.dart';
import 'package:projeto_app/background_cronometer.dart';
import 'package:projeto_app/db_manager.dart';

//Represents the page that manages information for an existing Cronometer.
class Cronometer extends StatefulWidget {
  static const String constSctnOfAlarmUpdtPortName = "AlarmUpdatePort";
  static const String constSctnOfCntrUpdtPortName = "CounterUpdatePort";
  static const Duration infntDrtn = Duration(
    days: 365,
  );
  final bool initialRunState;
  final int initialCounterValue;
  late final Alarm alarm;
  late final _CronometerNameRef nameRef;

  Cronometer({required String name, this.initialCounterValue = 0, this.initialRunState = false, int alarmValue = 0, Key? key})
      : super(key: key){
    alarm = Alarm(alarmValue: alarmValue);
    nameRef = _CronometerNameRef(name: name);
    BackgroundCronometer.prepare(name);
  }

  @override
  _CronometerState createState() => _CronometerState();
}

//The state of the Cronometer page.
class _CronometerState extends State<Cronometer>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _isResetBtnVsbl = false, _isLackOfNameDialogDspyd = false;
  String _pauseBtnTextStr = '';
  Color? _pauseBtnTextColor = Colors.lightBlue[400];
  late Animation<int> _counterAnmtn;
  late AnimationController _controller;
  late Counter _counter;
  late StreamSubscription<bool> _kybrdVsbltSbscrp;
  late TextField nameTextField;

  _CronometerState();

  @override
  void initState() {
    super.initState();
    ReceivePort alarmUpdatePort = ReceivePort();
    ReceivePort counterUpdatePort = ReceivePort();
    final String alarmUpdtPortName = widget.nameRef.name + Cronometer.constSctnOfAlarmUpdtPortName;
    final String cntrUpdtPortName = widget.nameRef.name + Cronometer.constSctnOfCntrUpdtPortName;

    _isResetBtnVsbl = !widget.initialRunState && widget.initialCounterValue > 0;
    _pauseBtnTextStr = widget.initialRunState ? 'Pause' : 'Start';

    _controller = AnimationController(
      duration: Cronometer.infntDrtn,
      vsync: this,
    );
    if(widget.initialRunState){
      _controller.forward();
    }
    _counterAnmtn = StepTween(
      begin: 0,
      end: Cronometer.infntDrtn.inSeconds,
    ).animate(_controller);
    _updateCounterValue(widget.initialCounterValue);
    if(widget.alarm.isAlarmSet){
      _counterAnmtn.addListener(_dtrmnWhenToDspyAlarm);
    }

    WidgetsBinding.instance.addObserver(this);

    _kybrdVsbltSbscrp = KeyboardVisibilityController().onChange.listen((visible){
      if(!visible && widget.nameRef.name.isEmpty){
        _showLackOfNameDialog();
      }
    });

    if(IsolateNameServer.lookupPortByName(alarmUpdtPortName) != null){
      IsolateNameServer.removePortNameMapping(alarmUpdtPortName);
    }
    if(IsolateNameServer.lookupPortByName(cntrUpdtPortName) != null){
      IsolateNameServer.removePortNameMapping(cntrUpdtPortName);
    }
    IsolateNameServer.registerPortWithName(alarmUpdatePort.sendPort, alarmUpdtPortName);
    IsolateNameServer.registerPortWithName(counterUpdatePort.sendPort, cntrUpdtPortName);
    alarmUpdatePort.listen(_updateAlarmDelayInfo);
    counterUpdatePort.listen((newCounterValue) => _updateCounterValue(newCounterValue));
  }

  @override
  void dispose() {
    _controller.dispose();
    _kybrdVsbltSbscrp.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  //Se o cronometro estiver correndo ou já tiver contado tempo, inicie ou cancele o cronometro do background dependendo de se o app foi colocado ou tirado do
  //  background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if(ModalRoute.of(context)!.isCurrent){
      if(_counter.animation.value > 0 || _controller.isAnimating){
        if(state == AppLifecycleState.paused){
            _startBkgrndCrnmtr();
        }else if(state == AppLifecycleState.resumed){
          _cancelBkgrndCrnmtr();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController textCtrlr = TextEditingController(text: widget.nameRef.name);
    return Scaffold(
      appBar: AppBar(
        title: nameTextField = TextField(
          controller: textCtrlr,
          onChanged: (text) => widget.nameRef.name = text,
        ),
      ),
      body: WillPopScope(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(
              child: _counter = Counter(
                animation: _counterAnmtn,
              ),
            ),
            if(widget.alarm.isAlarmSet) _setupAlarmWidget()
          ]
        ),
        onWillPop: () async {
          if(widget.nameRef.name.isNotEmpty){
            Map<String, dynamic> crnmtrState = {"value" : _counter.animation.value, "isRunning" : _controller.isAnimating, "name" : widget.nameRef.name};
            if(widget.alarm.isAlarmSet){
              widget.alarm.reset();
              crnmtrState["alarmValue"] = widget.alarm.alarmValue;
            }
            Navigator.pop(context, crnmtrState);
          }else{
            _showLackOfNameDialog();
          }
          return false;
        }
      ),
      bottomNavigationBar: BottomAppBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _buildCounterControlButtons(),
            ),
            TextButton(
              child: const Text("Setup Alarm"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => widget.alarm.alarmOptions,
                ).then((value){
                  if(value != null){
                    if(value){
                      _counter.animation.addListener(_dtrmnWhenToDspyAlarm);
                    }
                    setState((){});
                  }
                });
              },
              style: TextButton.styleFrom(
                textStyle: const TextStyle(
                  fontSize: 30,
                ),
              ),
            ),
          ]
        )
      ),
    );
  }

  //OBS: This function was made because a list of Widgets with optional entries can't be directly given to a Row Widget. So this function
  //  does all the checks for the optional Widgets before returning the list.
  List<Widget> _buildCounterControlButtons(){
    List<Widget> counterControlButtons = [
      TextButton(
        child: Text(_pauseBtnTextStr),
        onPressed: () => _controller.isAnimating ? _pause() : _continue(),
        style: TextButton.styleFrom(
          maximumSize: Size.infinite,
          textStyle: const TextStyle(
            fontSize: 30,
          ),
          primary: _pauseBtnTextColor,
        ),
      ),
    ];
    if(_isResetBtnVsbl){
      counterControlButtons.add(
        TextButton(
          child: const Text("Reset"),
          onLongPress: () => _reset(false),
          onPressed: () => _reset(true),
          style: TextButton.styleFrom(
            maximumSize: Size.infinite,
            primary: Colors.red[800],
            textStyle: const TextStyle(
              fontSize: 30,
            ),
          ),
        ),
      );
    }
    return counterControlButtons;
  }

  void _cancelBkgrndCrnmtr(){
    SendPort? sendPort = IsolateNameServer.lookupPortByName(widget.nameRef.name + BackgroundCronometer.constSctnOfCnclPortName);
    sendPort!.send(true);
  }

  void _continue() async{
    _controller.forward();
    setState(() {
      _isResetBtnVsbl = false;
      _pauseBtnTextColor = Colors.lightBlue[400];
      _pauseBtnTextStr = 'Pause';
    });
  }

  void _dtrmnWhenToDspyAlarm(){
    widget.alarm.dtrmnWhenToDspyAlarm(_counter.animation.value, context,
      (counterValue){
        _updateCounterValue(counterValue);
        _pause();
      },
      () => setState((){}),
      _startBkgrndCrnmtr
    );
  }

  void _pause() async {
    _controller.stop();
    setState(() {
      _isResetBtnVsbl = true;
      _pauseBtnTextColor = Colors.greenAccent[700];
      _pauseBtnTextStr = 'Continue';
    });
  }

  void _reset(bool shouldRecordTime) {
    if(shouldRecordTime){
      DBManager.timeRecorder.recordTime(widget.nameRef.name, _counter.animation.value, DateTime.now());
      debugPrint("Recording Time");
    }
    _controller.reset();
    widget.alarm.wasAlarmDspyd = false;
    _updateCounterValue(0);
    widget.alarm.reset();
    setState((){
      _isResetBtnVsbl = false;
      _pauseBtnTextColor = Colors.lightBlue[400];
      _pauseBtnTextStr = 'Start';
    });
  }

  DecoratedBox _setupAlarmWidget(){
    return DecoratedBox(
      child: SizedBox( 
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              child: Text(
                Counter.writeTimeString(widget.alarm.alarmValue),
                style: const TextStyle(color: Colors.white),
              ),
              padding: const EdgeInsetsDirectional.only(
                end: 7.5,
              ),
            ),
            const VerticalDivider(
              color: Colors.white, 
              width: 5,
              thickness: 2,
            ),
            IconButton(
              color: Colors.white,
              icon: const Icon(Icons.cancel_outlined),
              onPressed: (){
                _counter.animation.removeListener(_dtrmnWhenToDspyAlarm);
                widget.alarm.reset();
                setState(() => widget.alarm.isAlarmSet = false);
              }
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
        height: 40,
        width: 130,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(25),
      ),
    );
  }

  void _showLackOfNameDialog(){
    if(!_isLackOfNameDialogDspyd){
      _isLackOfNameDialogDspyd = true;
      showDialog(
        builder: (context) => AlertDialog(
          actions: [TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          )],
          title: const Text('''Cronometers need a name to be saved. You must give this one a name to save it and/or return to the Cronometer
            Panel.'''),
        ),
        context: context,
      ).then((value) => _isLackOfNameDialogDspyd = false);
    }
  }

  void _startBkgrndCrnmtr({int? customCounterValue}){
    Map<String, dynamic> counterInfo = {"value" : customCounterValue ?? _counter.animation.value, "isRunning" : _controller.isAnimating,
      "alarm" : (widget.alarm.isAlarmSet && !widget.alarm.wasAlarmDspyd) ? widget.alarm : null, "name" : widget.nameRef.name};
    SendPort? sendPort = IsolateNameServer.lookupPortByName(widget.nameRef.name + BackgroundCronometer.constSctnOfRunPortName);
    sendPort!.send(counterInfo);
  }

  void _updateAlarmDelayInfo(dynamic alarmDelayInfo){
    widget.alarm.setQtdDelays = alarmDelayInfo["qtdDelays"];
    setState(() => widget.alarm.alarmValue = alarmDelayInfo["alarmValue"]);
  }

  void _updateCounterValue(int newCounterValue){
    /*OBS: This variable is created because when an AnimationController's value is changed, it's animation is stopped. As such, whether or not the animation is running
    needs to be recorded before the value is changed.*/
    bool isCounterRunning = _controller.isAnimating;
    double clampedCounterValue = newCounterValue.toDouble()/_controller.duration!.inSeconds;
    _controller.value = clampedCounterValue;
    if(isCounterRunning){
      _controller.forward();
    }
  }
}

//Represents the reusable time counting Text Widget.
class Counter extends AnimatedWidget{
  final Animation<int> animation;
  final Function(int)? onValueCntdClbck;
  final TextStyle? customStyle;
  
  const Counter({required this.animation, this.customStyle, this.onValueCntdClbck, Key? key}) :
    super(key: key, listenable: animation);
  
  @override
  Widget build(BuildContext context) {
    if(onValueCntdClbck != null){
      onValueCntdClbck!(animation.value);
    }
    return Text(
      writeTimeString(animation.value),
      style: customStyle ?? TextStyle(
        fontSize: 85,
        color: Colors.blue[900],
      ),
    );
  }

  static String writeTimeString(int timeInSeconds, {bool shouldDisplaySeconds = true}){
    Duration _time = Duration(seconds: timeInSeconds);
    String _timeString = "${_time.inHours.toString().padLeft(2, '0')}:"
        "${_time.inMinutes.remainder(60).toString().padLeft(2, '0')}";
    if(shouldDisplaySeconds){
      _timeString += ":${_time.inSeconds.remainder(60).toString().padLeft(2, '0')}";
    }
    return _timeString;
  }
}

//OBS: This class exists because the Cronometer's name is received externally, which means it is stored in the widget not the state, but needs to be modifiable from
//  whithin this page. The best solution that can satisfy both conditions without breaking Flutter's rules is to make a custom object that stores the name. That way, 
//  the reference to it is constant but the Name string is mutable.
//Serves as a workaround to allow the Cronometer's name to be modifiable.
class _CronometerNameRef{
  String name;

  _CronometerNameRef({required this.name});
}