import 'package:flutter/material.dart';
import 'package:projeto_app/cronometer.dart';
import 'package:projeto_app/cronometer_creator.dart';
import 'package:projeto_app/db_manager.dart';

enum SortOrder{alphabetical, creation}

//Represents the page that manages the recorded state of the project's Cronometers.
class CronometerPanel extends StatefulWidget{
  final CronometerPanelInitialState initialState;

  const CronometerPanel({required this.initialState, Key? key}) : super(key: key);

  @override
  _CronometerPanelState createState() => _CronometerPanelState();
}

//The state of the Cronometer Panel page.
class _CronometerPanelState extends State<CronometerPanel> with TickerProviderStateMixin, WidgetsBindingObserver{
  bool _isRdngCrnmtrRcrds = true;
  SortOrder _selSortOrder = SortOrder.creation;
  DateTime _lastDateTimeInFrgrnd = DateTime.now();
  final List<AnimationController> _counterCtrlrs = [];
  final List<CronometerInfo> _crnmtrsInfo = [];
  
  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DBManager.cronometerRecorder.readCrnmtrRecords().then((crnmtrRecords){
      for(Map<String, dynamic> crnmtrRecord in crnmtrRecords){
        _addCronometer(CronometerInfo(id: crnmtrRecord["IdCronometer"], name: crnmtrRecord["Name"], alarmValue: crnmtrRecord["AlarmValue"]));
      }
      if(widget.initialState.lastDltnDateTime != null){
        for(CronometerInfo crnmtrInfo in _crnmtrsInfo){
          if(widget.initialState.lastCrnmtrValueById.containsKey(crnmtrInfo.id)){
            crnmtrInfo.counterValue = widget.initialState.lastCrnmtrValueById[crnmtrInfo.id]!;
            crnmtrInfo.isRunning = widget.initialState.isCrnmtrRnngById[crnmtrInfo.id]!;
            if(crnmtrInfo.isRunning){
              int temp = DateTime.now().difference(widget.initialState.lastDltnDateTime!).inSeconds;
              crnmtrInfo.counterValue += temp;
            }
          }
        }
      }
      setState(() => _isRdngCrnmtrRcrds = false);
    });
  }

  @override
  void dispose(){
    widget.initialState.lastDltnDateTime = DateTime.now();
    widget.initialState.clear();
    for(AnimationController counterCtrlr in _counterCtrlrs){
      counterCtrlr.dispose();
    }
    for(CronometerInfo crnmtrInfo in _crnmtrsInfo){
      if(crnmtrInfo.counterValue > 0){
        widget.initialState.lastCrnmtrValueById[crnmtrInfo.id] = crnmtrInfo.counterValue;
        widget.initialState.isCrnmtrRnngById[crnmtrInfo.id] = crnmtrInfo.isRunning;
      }
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
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          actions:[
            PopupMenuButton(
              icon: const Icon(Icons.sort),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<SortOrder>>[
                const PopupMenuItem<SortOrder>(
                  value: SortOrder.alphabetical,
                  child: Text("Alphabetical Order")
                ),
                const PopupMenuItem<SortOrder>(
                  value: SortOrder.creation,
                  child: Text("Ascending Creation Order")
                )
              ],
              onSelected: (SortOrder newSelOrder) => setState(() => _selSortOrder = newSelOrder)
            ),
            IconButton(
              color: Colors.white,
              icon: const Icon(Icons.add),
              onPressed: () =>showDialog(
                context: context,
                builder: (context) => const CronometerCreator(),
              ).then((newCrnmtrInfo) => setState((){
                if(newCrnmtrInfo != null){
                  _addCronometer(newCrnmtrInfo);
                }
              })),
            ),
          ],
          title: const Text("Cronometer Panel - 2"),
        ),
        body: _isRdngCrnmtrRcrds ? Center(
          child: Text(
            "Loading recorded cronometers.\n Please wait...",
            style: TextStyle(
              color: Colors.blue[800],
              fontSize: 20,
              fontWeight: FontWeight.bold
            ),
            textAlign: TextAlign.center,
          ),
        ) : _buildCrnmtrsInfoList(),
      ),
      onWillPop: () async {
        /*Navigator.pop(context, DateTime.now());
        return false;*/
        return true;
      }
    );
  }

  void _addCronometer(CronometerInfo newCrnmtrInfo){
    _crnmtrsInfo.add(newCrnmtrInfo);
    _counterCtrlrs.add(
      AnimationController(
        duration: Cronometer.infntDrtn,
        vsync: this,
      )
    );
  }

  Widget _buildCrnmtrsInfoList(){
    if(_crnmtrsInfo.isNotEmpty){
      if(_selSortOrder == SortOrder.alphabetical){
        _crnmtrsInfo.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }else{
        _crnmtrsInfo.sort((a, b) => a.id.compareTo(b.id));
      }
      return ListView.separated(
        itemBuilder: (BuildContext context, int index){
          _updateCounterCtrlrValue(_counterCtrlrs[index], _crnmtrsInfo[index].counterValue);
          if(_crnmtrsInfo[index].isRunning){
            _counterCtrlrs[index].forward();
          }
          return SizedBox(
            child: TextButton(
              child: Table(
                children: [
                  TableRow(
                    children: [
                      Container(
                        alignment: Alignment.centerLeft,
                        child: Text(_crnmtrsInfo[index].name),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        child: Text(_crnmtrsInfo[index].isRunning ? "" : "Paused"),
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
                          onValueCntdClbck: (int newValue) => _crnmtrsInfo[index].counterValue = newValue,
                        ),
                      ),
                      Container(
                        alignment: Alignment.centerRight,
                        child: Text(_crnmtrsInfo[index].alarmValue > 0 ? Counter.writeTimeString(_crnmtrsInfo[index].alarmValue) : ""),
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
                  _startBkgrndCounters(selCounterIndex: index);
                  return Cronometer(
                    name: _crnmtrsInfo[index].name,
                    alarmValue: _crnmtrsInfo[index].alarmValue,
                    initialCounterValue: _crnmtrsInfo[index].counterValue,
                    initialRunState: _crnmtrsInfo[index].isRunning,
                  );
                }
              )).then((dynamic crnmtrState){
                bool wasCrnmtrChgd = false;
                Map<String, dynamic> crnmtrStateMap = crnmtrState;
                _stopBkgrndCounters(selCounterIndex: index);
                if(crnmtrStateMap.containsKey("alarmValue")){
                  if(_crnmtrsInfo[index].alarmValue != crnmtrStateMap["alarmValue"]){
                    _crnmtrsInfo[index].alarmValue = crnmtrStateMap["alarmValue"];
                    wasCrnmtrChgd = true;
                  }
                }else if(_crnmtrsInfo[index].alarmValue != 0){
                  _crnmtrsInfo[index].alarmValue = 0;
                  wasCrnmtrChgd = true;
                }
                if(_crnmtrsInfo[index].name != crnmtrStateMap["name"]){
                  _crnmtrsInfo[index].name = crnmtrStateMap["name"];
                  wasCrnmtrChgd = true;
                }
                if(wasCrnmtrChgd){
                  DBManager.cronometerRecorder.updateCrnmtrInfo(_crnmtrsInfo[index].id,
                    {"Name": crnmtrStateMap["name"], "AlarmValue": _crnmtrsInfo[index].alarmValue});
                }
                setState((){ 
                  _crnmtrsInfo[index].counterValue = crnmtrStateMap["value"];
                  _crnmtrsInfo[index].isRunning = crnmtrStateMap["isRunning"];
                });
              }),
            ),
            height: 40,
          );
        },
        itemCount: _crnmtrsInfo.length,
        separatorBuilder: (BuildContext context, int index) => const Divider(),
      );
    }
    return Center(
      child: Text(
        "No Cronometers exist yet.\n Create a new one to be added to this list.",
        style: TextStyle(
          color: Colors.blue[800],
          fontSize: 20,
          fontWeight: FontWeight.bold
        ),
        textAlign: TextAlign.center,
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
    DBManager.cronometerRecorder.deleteCrnmtrRecord(_crnmtrsInfo[index].id);
    _crnmtrsInfo.removeAt(index);
  }

  void _startBkgrndCounters({int? selCounterIndex}){
    for(int index = 0; index < _crnmtrsInfo.length; index++){
      if((selCounterIndex == null || index != selCounterIndex) && _crnmtrsInfo[index].isRunning){
        _lastDateTimeInFrgrnd = DateTime.now();
      }
    }
  }

  void _stopBkgrndCounters({int? selCounterIndex}){
    for(int index = 0; index < _crnmtrsInfo.length; index++){
      if((selCounterIndex == null || index != selCounterIndex) && _crnmtrsInfo[index].isRunning){
        _crnmtrsInfo[index].counterValue += DateTime.now().difference(_lastDateTimeInFrgrnd).inSeconds;
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

//Maintains information used in the initialization of the Cronometer Panel.
class CronometerPanelInitialState{
  Map<int, int> lastCrnmtrValueById = {};
  Map<int, bool> isCrnmtrRnngById = {};
  DateTime? lastDltnDateTime;

  void clear(){
    lastCrnmtrValueById.clear();
    isCrnmtrRnngById.clear();
  }
}