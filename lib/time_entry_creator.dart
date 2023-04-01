import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:projeto_app/alarm_selector.dart';

//A template AlertDialog for making something from a String and a time value.
class TimeEntryCreator extends StatefulWidget{
  final bool isTextFieldTextRqrd, isNonZeroTimeValueRqrd;
  final String textFieldLabel, titleText, submitButtonText;
  final void Function(int, String) asyncSubmitClbck;
  final NumberPickerType numberPickerType;

  const TimeEntryCreator({
    required this.asyncSubmitClbck,
    required this.textFieldLabel,
    required this.titleText,
    this.isNonZeroTimeValueRqrd = false,
    this.isTextFieldTextRqrd = true,
    this.numberPickerType = NumberPickerType.compact,
    this.submitButtonText = "Submit",
    Key? key
  }) : super(key: key);

  @override
  _TimeEntryCreatorState createState() => _TimeEntryCreatorState();
}

//The state for the Time Entry Creator Dialog.
class _TimeEntryCreatorState extends State<TimeEntryCreator>{
  bool _shldShowTextFieldWrnng = false, _shldShowTimeValueWrnng = false;
  int _crnmtrAlarmValue = 0;
  TextEditingController textCtrlr = TextEditingController();

  @override
  void initState(){
    super.initState();
    textCtrlr.addListener((){
      if(_shldShowTextFieldWrnng){
        setState(() => _shldShowTextFieldWrnng = false);
      }
    });
  }

  @override
  Widget build(BuildContext context){
    return KeyboardDismissOnTap(
      child: AlertDialog(
        actions: <Widget>[
          TextButton(
            child: Text(widget.submitButtonText),
            onPressed: (){
              if(textCtrlr.text.isNotEmpty || !widget.isTextFieldTextRqrd){
                if(_crnmtrAlarmValue > 0 || !widget.isNonZeroTimeValueRqrd){
                  widget.asyncSubmitClbck(_crnmtrAlarmValue, textCtrlr.text);
                }else{
                  setState(() => _shldShowTimeValueWrnng = true);
                }
              }else{
                setState(() => _shldShowTextFieldWrnng = true);
              }
            },
          ),
        ],
        buttonPadding: const EdgeInsets.only(right: 5),
        content: Column(
          children: _buildColumnChildren(),
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 0),
        title: Text(widget.titleText),
      ),
    );
  }

  List<Widget> _buildColumnChildren(){
    List<Widget> contentColumnChldr = <Widget>[];
    TextStyle errorTextStyle = TextStyle(
      color: Colors.red[600],
      fontSize: 13,
    );
    if(_shldShowTimeValueWrnng){
      contentColumnChldr.add(Text(
        "A time value is required to submit.",
        style: errorTextStyle,
      ));
    }
    if(_shldShowTextFieldWrnng){
      contentColumnChldr.add(Text(
        "The field " + widget.textFieldLabel + " required to submit.",
        style: errorTextStyle,
      ));
    }
    contentColumnChldr.addAll(<Widget>[
      Row(
        children: <Widget>[
          Text(
            widget.textFieldLabel + ": ",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(child: TextField(
            controller: textCtrlr,
          )),
        ],
      ),
      const SizedBox(height: 20),
      AlarmSelector(
        changeClbck: (int alarmValue){
          if(_shldShowTimeValueWrnng){
            setState(() => _shldShowTimeValueWrnng = false);
          }
          _crnmtrAlarmValue = alarmValue;
        },
        numberPickerType: widget.numberPickerType
      ),
    ]);
    return contentColumnChldr;
  }
}