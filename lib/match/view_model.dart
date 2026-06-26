import 'package:cric_snap/database/databaseHelper.dart';
import 'package:cric_snap/innings/view_model.dart';
import 'package:cric_snap/match/model.dart';
import 'package:flutter/material.dart';

class MatchesViewModel extends ChangeNotifier {
  List<MatchModel> _matches = [];

  List<MatchModel> get matches => _matches;

  Future<void> loadMatches() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('matches', orderBy: 'createdAt DESC');
    _matches = result.map((e) => MatchModel.fromMap(e)).toList();
    
    // Sync scores for all matches to ensure they're up-to-date
    for (final match in _matches) {
      await DatabaseHelper.instance.syncMatchScoresFromInnings(match.matchId);
    }
    
    // Reload after syncing to get fresh data
    final refreshed = await db.query('matches', orderBy: 'createdAt DESC');
    _matches = refreshed.map((e) => MatchModel.fromMap(e)).toList();
    
    notifyListeners();
  }

  Future<void> addMatch(MatchModel match) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('matches', match.toMap());
    await loadMatches();
  }

  Future<void> updateMatch(
    MatchModel match, {
    InningsViewModel? inningsViewModel,
  }) async {
    final db = await DatabaseHelper.instance.database;

    // Fetch existing to detect overs change.
    final existing = await DatabaseHelper.instance.getMatchById(match.matchId);

    await db.update(
      'matches',
      match.toMap(),
      where: 'matchId = ?',
      whereArgs: [match.matchId],
    );

    if (existing != null && existing.oversPerInnings != match.oversPerInnings) {
      final newMaxBalls = match.oversPerInnings * match.ballsPerOver;

      // 1. Reopen any innings that was "completed" only because of overs,
      //    but now has room left (not all-out).
      await db.rawUpdate(
        'UPDATE innings SET isCompleted = 0 '
        'WHERE matchId = ? AND isCompleted = 1 AND wickets < 10 AND balls < ?',
        [match.matchId, newMaxBalls],
      );

      // 2. Clear targets from all non-completed innings — the batting team's
      //    innings is still live so the target is not yet known.
      await db.update(
        'innings',
        {'targetScore': 0},
        where: 'matchId = ?',
        whereArgs: [match.matchId],
      );

      // Notify the InningsViewModel so the innings page refreshes.
      await inningsViewModel?.loadInnings();
    }

    // Sync match scores from innings after update
    await DatabaseHelper.instance.syncMatchScoresFromInnings(match.matchId);
    
    await loadMatches();
  }

  Future<void> deleteMatch(String matchId) async {
    final db = await DatabaseHelper.instance.database;

    final inningsResult = await db.query(
      'innings',
      columns: ['inningsId'],
      where: 'matchId = ?',
      whereArgs: [matchId],
    );

    for (final innings in inningsResult) {
      final inningsId = innings['inningsId'] as String;
      await db.delete(
        'ball_recordings',
        where: 'inningsId = ?',
        whereArgs: [inningsId],
      );
    }

    await db.delete('innings', where: 'matchId = ?', whereArgs: [matchId]);
    await db.delete('matches', where: 'matchId = ?', whereArgs: [matchId]);

    await loadMatches();
  }
}
