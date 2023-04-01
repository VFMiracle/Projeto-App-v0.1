import 'package:flutter/material.dart';
import 'package:projeto_app/alarm_selector.dart';
import 'package:projeto_app/cronometer.dart';
import 'package:projeto_app/db_manager.dart';
import 'package:projeto_app/time_entry_creator.dart';

enum OtherOptions{createRecord, toggleSeconds}

class TimeRecordPanel extends StatefulWidget{
  const TimeRecordPanel({Key? key}) : super(key: key);

  @override
  _TimeRecordsPanelState createState() => _TimeRecordsPanelState();
}

class _TimeRecordsPanelState extends State<TimeRecordPanel>{
  bool _isRdngTimeRcrds = true, _shldManageSeconds = false;
  final List<Map<String, dynamic>> _timeRecords = [];
  late DateTime _loadedTimeRcrdsDate;

  @override
  void initState() {
    super.initState();
    _loadTimeRecords(DateTime.now());
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            child: Text(
              "${_loadedTimeRcrdsDate.year}/${_loadedTimeRcrdsDate.month}/${_loadedTimeRcrdsDate.day}",
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
            onPressed: () => showDialog(
              builder: (BuildContext context) => DatePickerDialog(
                firstDate: DateTime(2022),
                initialDate: _loadedTimeRcrdsDate,
                lastDate: DateTime.now(),
              ), 
              context: context,
            //INFO: The value of 'then' is the selected date when OK is pressed and null otherwise.
            ).then((newTimeRcrdDate){
              if(newTimeRcrdDate != null){
                _loadTimeRecords(newTimeRcrdDate);
              }
            }),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.arrow_drop_down_sharp),
            itemBuilder: (BuildContext context) => <PopupMenuEntry<OtherOptions>>[
              const PopupMenuItem(
                child: Text("Create a Record"),
                value: OtherOptions.createRecord,
              ),
              PopupMenuItem(
                child: Text((_shldManageSeconds ? "Hide " : "Show ") + "Seconds of Records"),
                value: OtherOptions.toggleSeconds,
              ),
            ],
            onSelected: (OtherOptions selOption){
              switch(selOption){
                case OtherOptions.createRecord:
                  showDialog(
                    builder: (context) => _TimeRecordCreator(curTimeRcrdsDate : _loadedTimeRcrdsDate),
                    context: context,
                  ).then((newTimeRecord){
                    if(newTimeRecord != null){
                      setState(() => _timeRecords.add(newTimeRecord));
                    }
                  });
                  break;
                case OtherOptions.toggleSeconds:
                  setState(() => _shldManageSeconds = !_shldManageSeconds);
                  break;
              }
            }
          ),
        ],
        title: const Text("Time Records"),
      ),
      body: Center(
        child: !_isRdngTimeRcrds ? _buildTimeRecordsTable() : const Text("Loading time records..."),
      )
    );
  }

  Widget _buildTimeRecordsTable(){
    TextStyle taskTextStyle = TextStyle(
      color: Colors.blue[500],
      fontSize: 25,
    );
    TextStyle timeTextStyle = TextStyle(
      color: Colors.blue[900],
      fontSize: 25,
    );
    if(_timeRecords.isNotEmpty){
      return ListView.separated(
        itemBuilder: (BuildContext context, int index){
          return TextButton(
            child: Row(
              children: [
                Text(
                  _timeRecords[index]["Task"],
                  style: taskTextStyle,
                ),
                Text(
                  Counter.writeTimeString(_timeRecords[index]["TimeInSeconds"], shouldDisplaySeconds: _shldManageSeconds),
                  style: timeTextStyle,
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
            onLongPress: () => showDialog(
              builder:(context) => AlertDialog(
                actions: [
                  TextButton(
                    child: const Text("Yes"),
                    onPressed: (){
                      DBManager.timeRecorder.deleteTimeRecord(_timeRecords[index]["Task"], _loadedTimeRcrdsDate);
                      setState(() => _timeRecords.removeAt(index));
                      Navigator.pop(context);
                    },
                  ),
                  TextButton(
                    child: const Text("No"),
                    onPressed: (){
                      Navigator.pop(context);
                    },
                  ),
                ],
                content: const Text("Are you sure you want to delete this Time Record?"),
              ),
              context: context
            ),
            onPressed: () => showDialog(
              builder:(context) => _TimeRecordEditor(recordInitialTime: _timeRecords[index]["TimeInSeconds"], shldManageSeconds: _shldManageSeconds),
              context: context,
            ).then((recordNewTime){
              if(recordNewTime != null){
                if(!_shldManageSeconds){
                  recordNewTime += _timeRecords[index]["TimeInSeconds"] % 60;
                  DBManager.timeRecorder.updateTimeRecord(_timeRecords[index]["Task"], _loadedTimeRcrdsDate, recordNewTime);
                  setState(() => _timeRecords[index]["TimeInSeconds"] = recordNewTime);
                }else{
                  setState(() => _timeRecords[index]["TimeInSeconds"] = recordNewTime);
                }
              }
            }),
          );
        },
        itemCount: _timeRecords.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(thickness: 2.5),
      );
    }else{
      return const Text("There aren't any time records for this day.");
    }
  }

  void _loadTimeRecords(DateTime newTimeRcrdDate){
    setState(() => _isRdngTimeRcrds = true);
    _timeRecords.clear();
    _loadedTimeRcrdsDate = newTimeRcrdDate;
    DBManager.timeRecorder.getTimeRecordsOfDay(_loadedTimeRcrdsDate).then((List<Map<String, dynamic>> timeRecords){
      for(Map<String, dynamic> timeRecord in timeRecords){
        Map<String, dynamic> timeRecordMap = {};
        timeRecord.forEach((key, value) => timeRecordMap[key] = value);
        _timeRecords.add(timeRecordMap);
      }
      setState(() => _isRdngTimeRcrds = false);
    });
  }
}

class _TimeRecordCreator extends StatefulWidget{
  final DateTime curTimeRcrdsDate;

  const _TimeRecordCreator({required this.curTimeRcrdsDate, Key? key}) : super(key: key);

  @override
  _TimeRecordCreatorState createState() => _TimeRecordCreatorState();
}

class _TimeRecordCreatorState extends State<_TimeRecordCreator>{

  //OBS: The code of this build method will be deleted and substituted for an instance of TimeEntryCreator, which is an instance of the CronometerCreator that can be 
  //  adapeted to a wider range of scenarios.
  @override
  Widget build(BuildContext context){
    return TimeEntryCreator(
      asyncSubmitClbck: (int timeValue, String taskName){
        Map<String, dynamic> newTimeRecord = {"Task" : taskName, "TimeInSeconds" : timeValue};
        DBManager.timeRecorder.recordTime(taskName, timeValue, widget.curTimeRcrdsDate);
        Navigator.pop(context, newTimeRecord);
      },
      isNonZeroTimeValueRqrd: true,
      textFieldLabel: "Task Name",
      titleText: "Time Record Creator",
    );
  }
}

class _TimeRecordEditor extends StatefulWidget{
  final bool shldManageSeconds;
  final int recordInitialTime;

  const _TimeRecordEditor({required this.recordInitialTime, required this.shldManageSeconds, Key? key}) : super(key: key);

  @override
  _TimeRecordEditorState createState() => _TimeRecordEditorState();
}

class _TimeRecordEditorState extends State<_TimeRecordEditor>{
  int recordNewTime = 0;

  @override
  Widget build(BuildContext context){
    int recordInitialHours = widget.recordInitialTime ~/ Duration.secondsPerHour;
    int recordInitialMinutes = (widget.recordInitialTime - recordInitialHours * Duration.secondsPerHour) ~/ Duration.secondsPerMinute;
    return AlertDialog(
      actions: <Widget>[
        TextButton(
          child: const Text("Submit"),
          onPressed: () => Navigator.pop(context, recordNewTime),
        ),
      ],
      content: AlarmSelector(
        changeClbck: (int recordNewTime){
          this.recordNewTime = recordNewTime;
        },
        initialHours: recordInitialHours,
        initialMinutes: recordInitialMinutes,
        initialSeconds: widget.shldManageSeconds ? widget.recordInitialTime - recordInitialHours * Duration.secondsPerHour -
          recordInitialMinutes * Duration.secondsPerMinute : -1,
        numberPickerType: NumberPickerType.normal,
      ),
      title: const Text("Time Record Editor"),
    );
  }
}