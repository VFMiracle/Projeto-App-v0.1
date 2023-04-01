import 'package:sqflite/sqflite.dart';

class TimeRecorder{
  final Database _database;

  TimeRecorder(this._database);

  void _addTimeRecord(Map<String, dynamic> timeRecordMap){
    _database.insert(
      "timeRecords",
      timeRecordMap,
    );
  }

  Future<int?> _getTimeRecordTime(String task, String creationDate) async {
    List<Map<String, dynamic>> queryResult = await _database.query(
      "timeRecords",
      columns: ["TimeInSeconds"],
      where: "Task = ? AND CreationDate = ?",
      whereArgs: [task, creationDate]
    );
    if(queryResult.isNotEmpty){
      return queryResult[0]["TimeInSeconds"];
    }else{
      return null;
    }
  }

  Future<void> deleteTimeRecord(String taskName, DateTime creationDate) async {
    String crtnDateString = "${creationDate.year}-${creationDate.month}-${creationDate.day}";
    _database.delete(
      "timeRecords",
      where: "Task = ? AND CreationDate = ?",
      whereArgs: [taskName, crtnDateString],
    );

  }

  Future<List<Map<String, dynamic>>> getTimeRecordsOfDay(DateTime selDate){
    return _database.query(
      "timeRecords",
      columns: ["Task", "TimeInSeconds"],
      where: "CreationDate = ?",
      whereArgs: ["${selDate.year}-${selDate.month}-${selDate.day}"]
    );
  }

  void recordTime(String taskName, int timeInSeconds, DateTime creationDate) async {
    String crtnDateString = "${creationDate.year}-${creationDate.month}-${creationDate.day}";
    int? timeRcrdCurTime = await _getTimeRecordTime(taskName, crtnDateString);
    if(timeRcrdCurTime == null){
      Map<String, dynamic> timeRecordMap = {
        "Task" : taskName,
        /*INFO: This disconsiders the time's proximity to another minute. It might better to use some kind of rounding in the future.*/
        "TimeInSeconds" : timeInSeconds,  /*INFO: This is only done to facilitate testing. However, consider recording the time in seconds.*/
        //INFO: The format for dates in TimeRecords table is YYYY-MM-DD.
        "CreationDate" : crtnDateString,
      };
      _addTimeRecord(timeRecordMap);
    }else{
      updateTimeRecord(taskName, creationDate, timeRcrdCurTime + (timeInSeconds));
    }
  }

  Future<void> updateTimeRecord(String recordTaskName, DateTime recordCreationDate, int newTime) async {
    String rcrdCrtnDateString = "${recordCreationDate.year}-${recordCreationDate.month}-${recordCreationDate.day}";
    _database.update(
      "timeRecords",
      {"TimeInSeconds": newTime},
      where: "Task = ? AND CreationDate = ?",
      whereArgs: [recordTaskName, rcrdCrtnDateString],
    );
  }

  Future<List<Map<String, dynamic>>> testGetTimeRecords(){
    return _database.query(
      "timeRecords"
    );
  }
}