import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:projeto_app/database/cronometer_recorder.dart';
import 'package:projeto_app/database/time_recorder.dart';

//Manages the general state of the Database.
class DBManager{
  static late final CronometerRecorder cronometerRecorder;
  static late final Database _database;
  static late final TimeRecorder timeRecorder;

  DBManager._();

  static Future<void> startup() async{
    _database = await openDatabase(
      join(await getDatabasesPath(), "projeto_app.db"),
      onCreate: (database, version){
        database.execute(
          '''CREATE TABLE cronometers(
            IdCronometer INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            Name TEXT NOT NULL,
            AlarmValue INTEGER DEFAULT 0 NOT NULL
          );'''
        ); 
        database.execute(
          '''CREATE TABLE timeRecords(
            IdTimeRecord INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
            Task TEXT NOT NULL,
            TimeInSeconds INTEGER default 0,
            CreationDate TEXT
          )''',
        );
      },
      onUpgrade: (database, oldVersion, newVersion){
        return database.execute(
          ''' ''',
        );
      },
      version: 5,
    );
    cronometerRecorder = CronometerRecorder(_database);
    timeRecorder = TimeRecorder(_database);
  }
}