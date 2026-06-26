import 'package:cric_snap/ballrecording/model.dart';
import 'package:cric_snap/database/databaseHelper.dart';
import 'package:flutter/material.dart';

class BallRecordingViewModel extends ChangeNotifier {
  List<BallRecording> _recordings = [];

  List<BallRecording> get recordings => _recordings;

  Future<void> loadRecordings(String inningsId) async {
    final db = await DatabaseHelper.instance.database;

    final result = await db.query(
      'ball_recordings',
      where: 'inningsId = ?',
      whereArgs: [inningsId],
      orderBy: 'createdAt DESC',
    );

    _recordings = result.map((e) => BallRecording.fromMap(e)).toList();

    notifyListeners();
  }

  Future<void> addRecording(BallRecording recording) async {
    final db = await DatabaseHelper.instance.database;

    await db.insert(
      'ball_recordings',
      recording.toMap(),
    );

    await loadRecordings(recording.inningsId);
  }

  Future<void> deleteRecording(
    String recordingId,
    String inningsId,
  ) async {
    final db = await DatabaseHelper.instance.database;

    await db.delete(
      'ball_recordings',
      where: 'recordingId = ?',
      whereArgs: [recordingId],
    );

    await loadRecordings(inningsId);
  }
}