import 'package:flutter/material.dart';
import 'package:projeto_app/adaptable_widgets/time_counter.dart';
import 'package:projeto_app/database/db_manager.dart';
import 'package:projeto_app/record/cronometer.dart';
import 'package:projeto_app/record/cronometer_creator.dart';

class CronometerList extends StatefulWidget{
  late final CronometerListInfo information;

  CronometerList({required crnmtrsInfo, required srchBarFocusNode, required srchdCrnmtrsId, Key? key}) : super(key: key){
    information = CronometerListInfo(crnmtrsInfo: crnmtrsInfo, srchBarFocusNode: srchBarFocusNode, srchdCrnmtrsId: srchdCrnmtrsId);
  }

  @override
  State<CronometerList> createState(){
    return CronometerListState();
  }
}

class CronometerListState extends State<CronometerList> with TickerProviderStateMixin, WidgetsBindingObserver{
  DateTime _lastDateTimeInFrgrnd = DateTime.now();
  final List<AnimationController> _counterCtrlrs = [];

  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for(CronometerInfo _ in widget.information.crnmtrsInfo){
      _counterCtrlrs.add(
        AnimationController(
          duration: Cronometer.infntDrtn,
          vsync: this,
        )
      );
    }
  }

  @override
  void dispose(){
    for(AnimationController counterCtrlr in _counterCtrlrs){
      counterCtrlr.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if(ModalRoute.of(context)!.isCurrent){
      if(state == AppLifecycleState.paused){
        _startBkgrndCounters();
      }else if(state == AppLifecycleState.resumed){
        _stopBkgrndCounters();
      }
    }
  }

  @override
  Widget build(BuildContext context){
    return Expanded(
      child: widget.information.srchdCrnmtrsId == null || widget.information.srchdCrnmtrsId!.isNotEmpty ? ListView.separated(
        itemBuilder: (BuildContext context, int index){
          _updateCounterCtrlrValue(_counterCtrlrs[index], widget.information.crnmtrsInfo[index].counterValue);
          if(widget.information.crnmtrsInfo[index].isRunning){
            _counterCtrlrs[index].forward();
          }
          return Visibility(
            child: SizedBox(
              child: TextButton(
                child: Table(
                  children: [
                    TableRow(
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Text(widget.information.crnmtrsInfo[index].name),
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: Text(widget.information.crnmtrsInfo[index].isRunning ? "" : "Paused"),
                        ),
                      ]
                    ),
                    TableRow(
                      children: [
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Counter(
                            animation: StepTween(
                              begin: 0,
                              end: Cronometer.infntDrtn.inSeconds,
                            ).animate(_counterCtrlrs[index]),
                            customStyle: DefaultTextStyle.of(context).style,
                            onValueCntdClbck: (int newValue) => widget.information.crnmtrsInfo[index].counterValue = newValue,
                          ),
                        ),
                        Container(
                          alignment: Alignment.centerRight,
                          child: Text(widget.information.crnmtrsInfo[index].alarmValue > 0 ?
                            Counter.writeTimeString(widget.information.crnmtrsInfo[index].alarmValue) : ""),
                        ),
                      ],
                    ),
                  ],
                ),
                onLongPress: () => showDialog(
                  context: context,
                  builder: _buildCrnmtrDeletionDialog,
                ).then((value){
                  if(value != null){
                    setState(() => _removeCronometer(index));
                  }
                }),
                onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
                  builder:(BuildContext context){
                    if(widget.information.srchBarFocusNode.hasFocus){
                      widget.information.srchBarFocusNode.unfocus();
                    }
                    _startBkgrndCounters(selCounterIndex: index);
                    return Cronometer(
                      name: widget.information.crnmtrsInfo[index].name,
                      alarmValue: widget.information.crnmtrsInfo[index].alarmValue,
                      initialCounterValue: widget.information.crnmtrsInfo[index].counterValue,
                      initialRunState: widget.information.crnmtrsInfo[index].isRunning,
                    );
                  }
                )).then((dynamic crnmtrState){
                  bool wasCrnmtrChgd = false;
                  Map<String, dynamic> crnmtrStateMap = crnmtrState;
                  _stopBkgrndCounters(selCounterIndex: index);
                  if(crnmtrStateMap.containsKey("alarmValue")){
                    if(widget.information.crnmtrsInfo[index].alarmValue != crnmtrStateMap["alarmValue"]){
                      widget.information.crnmtrsInfo[index].alarmValue = crnmtrStateMap["alarmValue"];
                      wasCrnmtrChgd = true;
                    }
                  }else if(widget.information.crnmtrsInfo[index].alarmValue != 0){
                    widget.information.crnmtrsInfo[index].alarmValue = 0;
                    wasCrnmtrChgd = true;
                  }
                  if(widget.information.crnmtrsInfo[index].name != crnmtrStateMap["name"]){
                    widget.information.crnmtrsInfo[index].name = crnmtrStateMap["name"];
                    wasCrnmtrChgd = true;
                  }
                  if(wasCrnmtrChgd){
                    DBManager.cronometerRecorder.updateCrnmtrInfo(widget.information.crnmtrsInfo[index].id,
                      {"Name": crnmtrStateMap["name"], "AlarmValue": widget.information.crnmtrsInfo[index].alarmValue});
                  }
                  setState((){ 
                    widget.information.crnmtrsInfo[index].counterValue = crnmtrStateMap["value"];
                    widget.information.crnmtrsInfo[index].isRunning = crnmtrStateMap["isRunning"];
                  });
                }),
              ),
              height: 40,
            ),
            maintainState: widget.information.crnmtrsInfo[index].isRunning,
            visible: widget.information.srchdCrnmtrsId == null || widget.information.srchdCrnmtrsId!.contains(widget.information.crnmtrsInfo[index].id),
          );
        },
        itemCount: widget.information.crnmtrsInfo.length,
        separatorBuilder: (BuildContext context, int index) => Visibility(
          child: const Divider(),
          visible: widget.information.srchdCrnmtrsId == null || widget.information.srchdCrnmtrsId!.contains(widget.information.crnmtrsInfo[index].id),
        )
      ) : Center(
        child: Container(
          child: Text(
            "No Cronometers with the searched term were found.",
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 20,
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 25),
        ),
      ),
    );
  }

  AlertDialog _buildCrnmtrDeletionDialog(BuildContext context){
    return AlertDialog(
      actions: <Widget>[
        TextButton(
          child: const Text("Yes"),
          onPressed: () => Navigator.pop(context, true),
        ),
        TextButton(
          child: const Text("No"),
          onPressed: () => Navigator.pop(context),
        ),
      ],
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      title: const Text(
        "Do you want to remove this Cronometer?",
        textAlign: TextAlign.center,
      ),
    );
  }

  void _removeCronometer(int index){
    _counterCtrlrs[index].dispose();
    _counterCtrlrs.removeAt(index);
    DBManager.cronometerRecorder.deleteCrnmtrRecord(widget.information.crnmtrsInfo[index].id);
    widget.information.crnmtrsInfo.removeAt(index);
  }

  void _startBkgrndCounters({int? selCounterIndex}){
    for(int index = 0; index < widget.information.crnmtrsInfo.length; index++){
      if((selCounterIndex == null || index != selCounterIndex) && widget.information.crnmtrsInfo[index].isRunning){
        _lastDateTimeInFrgrnd = DateTime.now();
      }
    }
  }

  void _stopBkgrndCounters({int? selCounterIndex}){
    for(int index = 0; index < widget.information.crnmtrsInfo.length; index++){
      if((selCounterIndex == null || index != selCounterIndex) && widget.information.crnmtrsInfo[index].isRunning){
        widget.information.crnmtrsInfo[index].counterValue += DateTime.now().difference(_lastDateTimeInFrgrnd).inSeconds;
      }
    }
    if(selCounterIndex == null){
      setState((){});
    }
  }

  void _updateCounterCtrlrValue(AnimationController counterCtrlr, int newCounterValue){
    double clampedCounterValue = newCounterValue.toDouble()/counterCtrlr.duration!.inSeconds;
    counterCtrlr.value = clampedCounterValue;
  }
}

class CronometerListInfo{
  final List<int>? srchdCrnmtrsId;
  final List<CronometerInfo> crnmtrsInfo;
  final FocusNode srchBarFocusNode;

  CronometerListInfo({required this.crnmtrsInfo, required this.srchBarFocusNode, required this.srchdCrnmtrsId});
}