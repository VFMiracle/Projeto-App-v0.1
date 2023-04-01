import 'package:flutter/material.dart';
import 'package:projeto_app/db_manager.dart';
import 'package:projeto_app/time_entry_creator.dart';

//Maintains and displays the information that belongs to a Cronometer.
class CronometerInfo{
  bool isRunning = false;
  int id;
  int counterValue = 0;
  int alarmValue;
  String name;

  CronometerInfo({required this.id, required this.name, this.alarmValue = 0});

  Map<String, dynamic> toMap(){
    return <String, dynamic>{
      "Name": name,
      "AlarmValue": alarmValue
    };
  }

  @override
  String toString(){
    String stateInString = "Name: $name, Counter Value: ${counterValue.toString()}, Alarm Value: ${alarmValue.toString()}, "
      "Is it running? ${(isRunning ? "Yes" : "No")}";
    return stateInString;
  }
}

//Represents the Alert Dialog responsible for creating new Cronometers.
class CronometerCreator extends StatefulWidget{
  const CronometerCreator({Key? key}) : super(key: key);

  @override
  _CronometerCreatorState createState() => _CronometerCreatorState();
}

//The state for the Cronometer Creator Dialog.
class _CronometerCreatorState extends State<CronometerCreator>{

  @override
  Widget build(BuildContext context){
    return TimeEntryCreator(
      asyncSubmitClbck: (int crnmtrAlarmValue, String crnmtrName) async{
        int newCrnmtrId = await DBManager.cronometerRecorder.saveCrnmtrInfo({"Name": crnmtrName, "AlarmValue": crnmtrAlarmValue});
        CronometerInfo newCrnmtrInfo = CronometerInfo(id: newCrnmtrId, name: crnmtrName, alarmValue: crnmtrAlarmValue);
        Navigator.pop(context, newCrnmtrInfo);
      },
      submitButtonText: "Add",
      textFieldLabel: "Name: ",
      titleText: "New Cronometer Details"
    );
  }
}
