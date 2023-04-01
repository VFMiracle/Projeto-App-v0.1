import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:projeto_app/database/db_manager.dart';
import 'package:projeto_app/record/cronometer_creator.dart';
import 'package:projeto_app/record/cronometer_list.dart';

enum SortOrder{alphabetical, creation}

//Represents the page that manages the recorded state of the project's Cronometers.
class CronometerPanel extends StatefulWidget{
  final CronometerPanelInitialState initialState;

  const CronometerPanel({required this.initialState, Key? key}) : super(key: key);

  @override
  _CronometerPanelState createState() => _CronometerPanelState();
}

//The state of the Cronometer Panel page.
class _CronometerPanelState extends State<CronometerPanel>{
  bool _isRdngCrnmtrRcrds = true;
  List<int>? _srchdCrnmtrsId;
  SortOrder _selSortOrder = SortOrder.creation;
  final List<CronometerInfo> _crnmtrsInfo = [];
  final FocusNode srchBarFocusNode = FocusNode();
  late final StreamSubscription<bool> kybrdVsbltSbscrp;
  
  @override
  void initState(){
    super.initState();
    kybrdVsbltSbscrp = KeyboardVisibilityController().onChange.listen((bool visible){
      if(!visible){
        srchBarFocusNode.unfocus();
      }
    });
    DBManager.cronometerRecorder.readCrnmtrRecords().then((crnmtrRecords){
      for(Map<String, dynamic> crnmtrRecord in crnmtrRecords){
        _crnmtrsInfo.add(CronometerInfo(id: crnmtrRecord["IdCronometer"], name: crnmtrRecord["Name"], alarmValue: crnmtrRecord["AlarmValue"]));
      }
      if(widget.initialState.lastDltnDateTime != null){
        for(CronometerInfo crnmtrInfo in _crnmtrsInfo){
          if(widget.initialState.lastCrnmtrValueById.containsKey(crnmtrInfo.id)){
            crnmtrInfo.counterValue = widget.initialState.lastCrnmtrValueById[crnmtrInfo.id]!;
            crnmtrInfo.isRunning = widget.initialState.isCrnmtrRnngById[crnmtrInfo.id]!;
            if(crnmtrInfo.isRunning){
              crnmtrInfo.counterValue += DateTime.now().difference(widget.initialState.lastDltnDateTime!).inSeconds;
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
    for(CronometerInfo crnmtrInfo in _crnmtrsInfo){
      if(crnmtrInfo.counterValue > 0){
        widget.initialState.lastCrnmtrValueById[crnmtrInfo.id] = crnmtrInfo.counterValue;
        widget.initialState.isCrnmtrRnngById[crnmtrInfo.id] = crnmtrInfo.isRunning;
      }
    }
    super.dispose();
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
                  _crnmtrsInfo.add(newCrnmtrInfo);
                }
              })),
            ),
          ],
          title: const Text("Cronometer Panel"),
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

  Widget _buildCrnmtrsInfoList(){
    if(_crnmtrsInfo.isNotEmpty){
      if(_selSortOrder == SortOrder.alphabetical){
        _crnmtrsInfo.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }else{
        _crnmtrsInfo.sort((a, b) => a.id.compareTo(b.id));
      }
      return KeyboardDismissOnTap(
        child: Column(
          children: [
            Container(
              child: Row(
                children: [
                  Container(
                    child: const Icon(Icons.search),
                    margin: const EdgeInsets.only(left: 10, right: 15),
                  ),
                  Expanded(
                    child: Container(
                      child: TextField(
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: "Search for a Cronometer",
                          hintStyle: TextStyle(color: Color.fromARGB(255, 30, 58, 71)),
                        ),
                        focusNode: srchBarFocusNode,
                        onChanged: (String searchTerm){
                          _srchdCrnmtrsId = null;
                          if(searchTerm.isNotEmpty){
                            _srchdCrnmtrsId = [];
                            for(CronometerInfo crnmtrInfo in _crnmtrsInfo){
                              if(crnmtrInfo.name.toLowerCase().contains(searchTerm.toLowerCase())){
                                _srchdCrnmtrsId!.add(crnmtrInfo.id);
                              }
                            }
                          }
                          setState((){});
                        },
                        style: const TextStyle(color: Colors.white),
                      ),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                        color: Color.fromARGB(255, 41, 102, 133),
                        shape: BoxShape.rectangle,
                      ),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                    ),
                  ),
                ]
              ),
              decoration: const BoxDecoration(
                boxShadow: [BoxShadow(blurRadius: 15, offset: Offset(0, -2.5))],
                color: Color.fromARGB(255, 51, 157, 211),
              ),
              padding: const EdgeInsets.symmetric(vertical: 7.5)
            ),
            CronometerList(crnmtrsInfo: _crnmtrsInfo, srchBarFocusNode: srchBarFocusNode, srchdCrnmtrsId: _srchdCrnmtrsId),
          ]
        ),
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