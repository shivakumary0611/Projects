import 'package:cric_snap/database/databaseHelper.dart';
import 'package:cric_snap/innings/model.dart';
import 'package:flutter/material.dart';

class InningsViewModel extends ChangeNotifier {
  List<Innings> _innings = [];

  List<Innings> get innings => _innings;

  Future<void> loadInnings() async {
    final db = await DatabaseHelper.instance.database;
    final result = await db.query('innings', orderBy: 'createdAt DESC');
    _innings = result.map((e) => Innings.fromMap(e)).toList();
    notifyListeners();
  }

  Future<void> addInnings(Innings innings) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('innings', innings.toMap());

    // ── Auto-stamp target if the other team already finished ────────────────
    // Check if there is a completed innings for the other team in this match.
    final allRows = await db.query(
      'innings',
      where: 'matchId = ? AND teamId != ? AND isCompleted = 1',
      whereArgs: [innings.matchId, innings.teamId],
    );
    if (allRows.isNotEmpty) {
      // Use the most-recently completed opponent innings.
      final opponentRows = allRows.map((r) => Innings.fromMap(r)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final opponentInnings = opponentRows.first;
      final target = opponentInnings.runs + 1;

      // Only stamp if this innings has no target yet.
      if (innings.targetScore == 0) {
        final withTarget = Innings(
          inningsId: innings.inningsId,
          matchId: innings.matchId,
          teamId: innings.teamId,
          runs: innings.runs,
          wickets: innings.wickets,
          balls: innings.balls,
          targetScore: target,
          isCompleted: innings.isCompleted,
          createdAt: innings.createdAt,
        );
        await db.update(
          'innings',
          withTarget.toMap(),
          where: 'inningsId = ?',
          whereArgs: [innings.inningsId],
        );
      }
    }

    await loadInnings();
  }

  Future<void> updateInnings(Innings innings) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'innings',
      innings.toMap(),
      where: 'inningsId = ?',
      whereArgs: [innings.inningsId],
    );

    // ── When this innings just completed, stamp target on sibling innings ───
    // ── When this innings completes, always refresh target on opponent innings ──
if (innings.isCompleted) {
  final siblingRows = await db.query(
    'innings',
    where: 'matchId = ? AND teamId != ?',
    whereArgs: [innings.matchId, innings.teamId],
  );

  for (final row in siblingRows) {
    final sibling = Innings.fromMap(row);

    final updatedSibling = Innings(
      inningsId: sibling.inningsId,
      matchId: sibling.matchId,
      teamId: sibling.teamId,
      runs: sibling.runs,
      wickets: sibling.wickets,
      balls: sibling.balls,
      targetScore: innings.runs + 1,
      isCompleted: sibling.isCompleted,
      createdAt: sibling.createdAt,
    );

    await db.update(
      'innings',
      updatedSibling.toMap(),
      where: 'inningsId = ?',
      whereArgs: [sibling.inningsId],
    );
  }
  
  // Sync match scores from innings
  await DatabaseHelper.instance.syncMatchScoresFromInnings(innings.matchId);
}

    await loadInnings();
    notifyListeners();
  }

  /// Called by the match page when overs are updated.
  /// Clears the target from all innings of this match that are NOT yet
  /// completed, because the first team's innings is still live and the
  /// target may change.
  Future<void> clearTargetsForMatch(String matchId) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'innings',
      {'targetScore': 0},
      where: 'matchId = ? AND isCompleted = 0',
      whereArgs: [matchId],
    );
    await loadInnings();
  }

  Future<void> deleteInnings(String inningsId) async {
    final db = await DatabaseHelper.instance.database;
    String? matchId;
    final rows = await db.query(
      'innings',
      where: 'inningsId = ?',
      whereArgs: [inningsId],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      matchId = rows.first['matchId'] as String?;
    }
    await db.delete('innings', where: 'inningsId = ?', whereArgs: [inningsId]);

    // If there are remaining innings for this match, clear their targets
    // since the completed innings that set them is gone.
    if (matchId != null) {
      await db.update(
        'innings',
        {'targetScore': 0},
        where: 'matchId = ?',
        whereArgs: [matchId],
      );
    }

    await loadInnings();
  }
}