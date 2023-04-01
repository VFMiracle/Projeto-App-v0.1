import 'package:sqflite/sqflite.dart';

//Manages the records for all existing Cronometers.
class CronometerRecorder{
  final Database _database;

  CronometerRecorder(this._database);

  void deleteCrnmtrRecord(int crnmtrId){
    _database.delete(
      "cronometers",
      where: "IdCronometer = ?",
      whereArgs: [crnmtrId]
    );
  }

  Future<List<Map<String, dynamic>>> readCrnmtrRecords() async {
    Future<List<Map<String, dynamic>>> crnmtrInfoMaps = _database.query(
      "cronometers"
    );
    return crnmtrInfoMaps;
  }

  Future<int> saveCrnmtrInfo(Map<String, dynamic> crnmtrInfoMap) async {
    List<Map<String, Object?>> ltstIdQueryRes;
    _database.insert(
      "cronometers",
      crnmtrInfoMap
    );
    ltstIdQueryRes = await _database.rawQuery(
      '''SELECT MAX(IdCronometer) AS LatestId
      FROM Cronometers'''
    );
    return ltstIdQueryRes[0]["LatestId"] as int;
  }

  void updateCrnmtrInfo(int id, Map<String, dynamic> crnmtrInfoMap) async {
    _database.update(
      "cronometers",
      crnmtrInfoMap,
      where: "IdCronometer = ?",
      whereArgs: [id]
    );
  }
}