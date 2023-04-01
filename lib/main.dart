// Copyright 2018 The Flutter team. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:projeto_app/notification_manager.dart';
import 'package:projeto_app/database/db_manager.dart';
import 'package:projeto_app/manage/time_record_panel.dart';
import 'package:projeto_app/record/cronometer_panel.dart';

main() async{
  WidgetsFlutterBinding.ensureInitialized();
  NotificationManager().startup();
  await DBManager.startup();

  runApp(MainMenu());
}

//Displays the opening page when the app is initialized.
class MainMenu extends StatelessWidget {
  final CronometerPanelInitialState _crnmtrPanelIntlState = CronometerPanelInitialState();

  MainMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Main Menu"),
        ),
        body: ListView.separated(
          itemBuilder: (BuildContext context, int index){
            switch(index){
              case 0:{
                return TextButton(
                  child: const Text("Cronometer Panel"),
                  onPressed: () => Navigator.push<void>(context, MaterialPageRoute(
                    builder: (BuildContext context) => CronometerPanel(initialState: _crnmtrPanelIntlState)
                  )),
                );
              }
              case 1:{
                return TextButton(
                  child: const Text("Time Records Panel"),
                  onPressed: () => Navigator.push<void>(context, MaterialPageRoute(
                    builder: (BuildContext context) => const TimeRecordPanel()
                  )),
                );
              }
              default:{
                return const Center(
                  child: Text("ERROR: Trying to build more options than necessary."),
                );
              }
            }
          },
          itemCount: 2,
          separatorBuilder: (BuildContext context, int index) => const Divider(thickness: 1),
        ),
      ),
      theme: ThemeData(
        dividerTheme: DividerThemeData(
          color: Colors.blue[900],
          space: 5,
          thickness: 2.5,
        ),
      ),
      title: 'Time Tracker',
    );
  }
}