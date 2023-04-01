import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter/services.dart';
import 'package:numberpicker/numberpicker.dart';

enum NumberPickerType{
  normal,
  compact,
}

enum TimeUnit{
  second,
  minute,
  hour,
  none,
}

//Represents the group of Number Pickers / Text Fields that allow the user to select a time for an Alarm.
class AlarmSelector extends StatefulWidget{
  final int initialHours, initialMinutes, initialSeconds;
  final NumberPickerType numberPickerType;
  final void Function(int) changeClbck;

  const AlarmSelector({required this.changeClbck, required this.numberPickerType, this.initialHours = 0, this.initialMinutes = 0,
    this.initialSeconds = 0, Key? key}) : super(key: key);

  @override
  State<AlarmSelector> createState(){
    return _AlarmSelectorState();
  }
}

//The state for the Alarm Selector.
class _AlarmSelectorState extends State<AlarmSelector>{
  bool _timeSlctrsAreNumPckrs = true,
    //INFO: It allows a certain check to be successful one time.
    //OBS: This variable is needed because Flutter was triggering the focusNode listener of the Time Text Fields when that wasn't desired, and there are no other ways
    //  to detect if a Text Field is currently recieving input. More information can be found in that listener's description.
    _timeSlctrsWereNumPckrs = true;
  TimeUnit _selTimeTextField = TimeUnit.none;
  final int maximumHour = 99, maxOtherTimeUnit = 59;
  late int _hours, _minutes, _seconds;
  late StreamSubscription<bool> kybrdVsbltSbscrp;

  bool get getTimeSlctrsAreNumPckrs{
    return _timeSlctrsAreNumPckrs;
  }

  @override
  void initState(){
    super.initState();
    _hours = widget.initialHours;
    _minutes = widget.initialMinutes;
    _seconds = widget.initialSeconds;
    kybrdVsbltSbscrp = KeyboardVisibilityController().onChange.listen((bool visible){
      if(!visible){
        _switchToNumberPickers();
      }
    });
  }

  @override
  void dispose(){
    kybrdVsbltSbscrp.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: _buildTimeSelectors(),
    );
  }

  int _buildAlarmValue(){
    return _hours * Duration.secondsPerHour + _minutes * Duration.secondsPerMinute + (_seconds >= 0 ? _seconds : 0);
  }

  Expanded _buildTimeNumberPicker(TimeUnit timeUnit){
    List<int> dimensions = _getNumberPickerDmnsns();
    return Expanded(
      child: GestureDetector(
        onTap:() => setState((){
          _selTimeTextField = timeUnit;
          _timeSlctrsAreNumPckrs = false;
        }),
        child: NumberPicker(
          infiniteLoop: true,
          itemHeight: dimensions[1].toDouble(),
          itemWidth: dimensions[0].toDouble(),
          maxValue: timeUnit == TimeUnit.hour ? maximumHour : maxOtherTimeUnit,
          minValue: 0,
          onChanged: (value){
            setState(() => _setTimeUnitValue(timeUnit, value));
            widget.changeClbck(_buildAlarmValue());
          },
          value: _getTimeUnitValue(timeUnit),
          zeroPad: true,
        ),
      )
    );
  }

  List<Widget> _buildTimeSelectors(){
    List<Widget> timeSlctrs = [
      _timeSlctrsAreNumPckrs ? _buildTimeNumberPicker(TimeUnit.hour) : _buildTimeTextField(TimeUnit.hour, context),
      const Text(
        ':',
        style: TextStyle(
          fontSize: 30,
        ),
      ),
      _timeSlctrsAreNumPckrs ? _buildTimeNumberPicker(TimeUnit.minute) : _buildTimeTextField(TimeUnit.minute, context)
    ];
    if(widget.initialSeconds >= 0){
      timeSlctrs.add(
          const Text(
            ':',
            style: TextStyle(
              fontSize: 30,
            ),
          )
      );
      timeSlctrs.add(_timeSlctrsAreNumPckrs ? _buildTimeNumberPicker(TimeUnit.second) : _buildTimeTextField(TimeUnit.second, context));
    }
    return timeSlctrs;
  }

  TextStyle? _buildTimeTextFieldStyle(BuildContext context){
    ThemeData themeData = Theme.of(context);
    TextStyle? style = themeData.textTheme.headline5;
    style = style!.merge(TextStyle(color: themeData.colorScheme.secondary));
    return style;
  }

  Expanded _buildTimeTextField(TimeUnit timeUnit, BuildContext context){
    int timeUnitValue = _getTimeUnitValue(timeUnit);
    String timeUnitStrValue = (timeUnitValue < 10 ? "0" : "") + timeUnitValue.toString();
    //INFO: This focusNode will handle almost all focus related operations for the Widget. Currently it selects all the text when the Widget gains focus and gives it
    //  focus when it's respective NumberPicker was tapped.
    FocusNode focusNode = FocusNode();
    TextEditingController controller = TextEditingController(text: timeUnitStrValue);
    focusNode.addListener((){
      //OBS: focusNode is triggered at unwanted moments for unknown reasons. As such a check is needed for the cases where it should run. Those cases are twofold: right
      //  after the Number Pickers are turned into Text Fields, and when a Text Field of a different Time Unit is selected. While the latter case can be handled by
      //  _selTimeTextField, the former needed the _timeSlctrsWereNumPckrs to do so.
      if(focusNode.hasPrimaryFocus && (_timeSlctrsWereNumPckrs || _selTimeTextField != timeUnit)){
        _timeSlctrsWereNumPckrs = false;
        _selTimeTextField = timeUnit;
        controller.selection = TextSelection(baseOffset: 0, extentOffset: timeUnitStrValue.length);
      }
    });
    if(_selTimeTextField == timeUnit){
      focusNode.requestFocus();
    }

    return Expanded(
      child: TextField(
        controller: controller,
        decoration: const InputDecoration(border: InputBorder.none,),
        enableInteractiveSelection: false,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        inputFormatters:[
          FilteringTextInputFormatter.digitsOnly,
          _AlarmTextFieldFormatter(this, timeUnit),
        ],
        onChanged: (value){
          int intValue = int.parse(value);
          _setTimeUnitValue(timeUnit, intValue);
          widget.changeClbck(_buildAlarmValue());
          if(value == "00"){
            controller.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
          }
        },
        onSubmitted: (value) => _switchToNumberPickers(),
        style: _buildTimeTextFieldStyle(context),
      ),
    );
  }

  List<int> _getNumberPickerDmnsns(){
    List<int> dimensions = [];
    switch(widget.numberPickerType){
      case NumberPickerType.compact:{
        dimensions.add(80);
        dimensions.add(30);
      } break;
      default:{
        dimensions.add(100);
        dimensions.add(50);
      } break;
    }
    return dimensions;
  }

  int _getTimeUnitValue(TimeUnit timeUnit){
    switch(timeUnit){
      case TimeUnit.hour:
        return _hours;
      case TimeUnit.minute:
        return _minutes;
      case TimeUnit.second:
        return _seconds;
      default: return 0;
    }
  }

  void _setTimeUnitValue(TimeUnit timeUnit, int value){
    switch(timeUnit){
      case TimeUnit.hour:
        _hours = value;
      break;
      case TimeUnit.minute:
        _minutes = value;
      break;
      case TimeUnit.second:
        _seconds = value;
      break;
      default: break;
    }
  }

  void _switchToNumberPickers(){
    setState((){
      _timeSlctrsAreNumPckrs = true;
      _timeSlctrsWereNumPckrs = true;
      _selTimeTextField = TimeUnit.none;
    });
  }
}

//Controls the formatting for an Alarm Selector's text field.
class _AlarmTextFieldFormatter extends TextInputFormatter{
  final _AlarmSelectorState _alarmSlctrState;
  final TimeUnit _timeUnit;

  _AlarmTextFieldFormatter(
    this._alarmSlctrState,
    this._timeUnit,
  );

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if(newValue.text.isNotEmpty){
      switch(newValue.text.length){
        case 1:
          return TextEditingValue(text: "0" + newValue.text, selection: const TextSelection.collapsed(offset: 2));
        case 2:
          return newValue;
        default:{
          int newValueTextInInt = int.parse(newValue.text);
          if((_timeUnit == TimeUnit.hour && newValueTextInInt <= _alarmSlctrState.maximumHour) ||
              (_timeUnit != TimeUnit.hour && newValueTextInInt <= _alarmSlctrState.maxOtherTimeUnit)){
            return TextEditingValue(text: newValue.text.substring(1), selection: const TextSelection.collapsed(offset: 2));
          }else{
            return oldValue;
          }
        }
      }
    }else{
      return const TextEditingValue(text: "00");
    }
  }
}