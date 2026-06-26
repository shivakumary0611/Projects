// ignore_for_file: file_names
import 'package:cric_snap/ballrecording/model.dart';
import 'package:cric_snap/innings/model.dart';
import 'package:cric_snap/match/model.dart';
import 'package:cric_snap/players/model.dart';
import 'package:cric_snap/teams/model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cric_snap.db');

    return await openDatabase(
      path,
      version: 4, // bumped from 3 → 4
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createDeliveryEventsTable(db);
        }
        if (oldVersion < 3) {
          await _addRecordingContextColumns(db);
        }
        if (oldVersion < 4) {
          // Add pending-target columns to matches so the target can be stored
          // when the first innings completes before the second exists.
          await _addPendingTargetColumns(db);
        }
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE teams(
            teamId TEXT PRIMARY KEY,
            teamName TEXT NOT NULL,
            abbreviation TEXT NOT NULL,
            teamLogo TEXT,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE players(
            playerId TEXT PRIMARY KEY,
            firstName TEXT NOT NULL,
            lastName TEXT NOT NULL,
            teamId TEXT NOT NULL,
            avatarPath TEXT,
            createdAt TEXT NOT NULL,
            FOREIGN KEY(teamId) REFERENCES teams(teamId) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
  CREATE TABLE matches(
    matchId TEXT PRIMARY KEY,
    homeTeamId TEXT NOT NULL,
    awayTeamId TEXT NOT NULL,
    oversPerInnings INTEGER NOT NULL,
    ballsPerOver INTEGER NOT NULL,
    rebowlWides INTEGER NOT NULL,
    rebowlNoBalls INTEGER NOT NULL,
    recordOrientation TEXT NOT NULL,
    createdAt TEXT NOT NULL,
    homeTeamScore TEXT,
    awayTeamScore TEXT,
    homeTeamOvers TEXT,
    awayTeamOvers TEXT,
    winnerTeamName TEXT,
    pendingTargetForAway INTEGER,
    pendingTargetForHome INTEGER
  )
''');

        await db.execute('''
          CREATE TABLE innings(
            inningsId TEXT PRIMARY KEY,
            matchId TEXT NOT NULL,
            teamId TEXT NOT NULL,
            runs INTEGER NOT NULL,
            wickets INTEGER NOT NULL,
            balls INTEGER NOT NULL,
            targetScore INTEGER NOT NULL,
            isCompleted INTEGER NOT NULL,
            createdAt TEXT NOT NULL,
            FOREIGN KEY(matchId) REFERENCES matches(matchId) ON DELETE CASCADE,
            FOREIGN KEY(teamId) REFERENCES teams(teamId) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE ball_recordings(
            recordingId TEXT PRIMARY KEY,
            inningsId TEXT NOT NULL,
            videoPath TEXT NOT NULL,
            runs INTEGER NOT NULL,
            extraType TEXT,
            isWicket INTEGER NOT NULL,
            isHighlight INTEGER NOT NULL,
            overIndex INTEGER NOT NULL DEFAULT 0,
            ballInOver INTEGER NOT NULL DEFAULT 1,
            actionId TEXT NOT NULL DEFAULT '',
            createdAt TEXT NOT NULL,
            FOREIGN KEY(inningsId) REFERENCES innings(inningsId) ON DELETE CASCADE
          )
        ''');
        await _createDeliveryEventsTable(db);
      },
    );
  }

  Future<void> _createDeliveryEventsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS delivery_events(
        eventId TEXT PRIMARY KEY,
        inningsId TEXT NOT NULL,
        actionId TEXT NOT NULL,
        overIndex INTEGER NOT NULL,
        label TEXT NOT NULL,
        colorValue INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(inningsId) REFERENCES innings(inningsId) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _addRecordingContextColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(ball_recordings)');
    final existing = columns.map((column) => column['name'] as String).toSet();
    if (!existing.contains('overIndex')) {
      await db.execute(
        'ALTER TABLE ball_recordings ADD COLUMN overIndex INTEGER NOT NULL DEFAULT 0',
      );
    }
    if (!existing.contains('ballInOver')) {
      await db.execute(
        'ALTER TABLE ball_recordings ADD COLUMN ballInOver INTEGER NOT NULL DEFAULT 1',
      );
    }
    if (!existing.contains('actionId')) {
      await db.execute(
        "ALTER TABLE ball_recordings ADD COLUMN actionId TEXT NOT NULL DEFAULT ''",
      );
    }
  }

  /// Migration v3 → v4: adds pendingTargetForAway / pendingTargetForHome
  /// to the matches table so targets survive until the second innings is created.
  Future<void> _addPendingTargetColumns(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(matches)');
    final existing = columns.map((c) => c['name'] as String).toSet();
    if (!existing.contains('pendingTargetForAway')) {
      await db.execute(
        'ALTER TABLE matches ADD COLUMN pendingTargetForAway INTEGER',
      );
    }
    if (!existing.contains('pendingTargetForHome')) {
      await db.execute(
        'ALTER TABLE matches ADD COLUMN pendingTargetForHome INTEGER',
      );
    }
  }

  Future<void> insertPlayer(Player player) async {
    final db = await database;

    await db.insert(
      'players',
      player.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Player>> getPlayers() async {
    final db = await database;

    final result = await db.query('players', orderBy: 'createdAt DESC');

    return result.map((map) => Player.fromMap(map)).toList();
  }

  Future<Player?> getPlayerById(String playerId) async {
    final db = await database;

    final result = await db.query(
      'players',
      where: 'playerId = ?',
      whereArgs: [playerId],
    );

    if (result.isNotEmpty) {
      return Player.fromMap(result.first);
    }

    return null;
  }

  Future<void> updatePlayer(Player player) async {
    final db = await database;

    await db.update(
      'players',
      player.toMap(),
      where: 'playerId = ?',
      whereArgs: [player.playerId],
    );
  }

  Future<void> deletePlayer(String playerId) async {
    final db = await database;

    await db.delete('players', where: 'playerId = ?', whereArgs: [playerId]);
  }

  Future<void> insertTeam(Team team) async {
    final db = await database;

    await db.insert(
      'teams',
      team.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Team>> getTeams() async {
    final db = await database;

    final result = await db.query('teams', orderBy: 'createdAt DESC');

    return result.map((map) => Team.fromMap(map)).toList();
  }

  Future<Team?> getTeamById(String teamId) async {
    final db = await database;

    final result = await db.query(
      'teams',
      where: 'teamId = ?',
      whereArgs: [teamId],
    );

    if (result.isNotEmpty) {
      return Team.fromMap(result.first);
    }

    return null;
  }

  /// Oldest row wins if duplicates exist (legacy data).
  Future<Team?> findTeamByNameAndAbbreviation(
    String teamName,
    String abbreviation,
  ) async {
    final db = await database;

    final result = await db.query(
      'teams',
      where: 'teamName = ? AND abbreviation = ?',
      whereArgs: [teamName, abbreviation],
      orderBy: 'createdAt ASC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return Team.fromMap(result.first);
    }

    return null;
  }

  Future<void> updateTeam(Team team) async {
    final db = await database;

    await db.update(
      'teams',
      team.toMap(),
      where: 'teamId = ?',
      whereArgs: [team.teamId],
    );
  }

  Future<void> deleteTeam(String teamId) async {
    final db = await database;

    await db.delete('teams', where: 'teamId = ?', whereArgs: [teamId]);
  }

  Future<void> insertMatch(MatchModel match) async {
    final db = await database;

    await db.insert(
      'matches',
      match.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<MatchModel>> getMatches() async {
    final db = await database;

    final result = await db.query('matches', orderBy: 'createdAt DESC');

    return result.map((map) => MatchModel.fromMap(map)).toList();
  }

  Future<int> countMatches() async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM matches');
    if (rows.isEmpty) return 0;
    final raw = rows.first['c'];
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 0;
  }

  Future<MatchModel?> getMatchById(String matchId) async {
    final db = await database;

    final result = await db.query(
      'matches',
      where: 'matchId = ?',
      whereArgs: [matchId],
    );

    if (result.isNotEmpty) {
      return MatchModel.fromMap(result.first);
    }

    return null;
  }

  Future<void> updateMatch(MatchModel match) async {
    final db = await database;

    await db.update(
      'matches',
      match.toMap(),
      where: 'matchId = ?',
      whereArgs: [match.matchId],
    );
  }

  /// Syncs match scores and winner from innings data.
  /// Call this after innings complete to update the match with:
  /// - homeTeamScore, awayTeamScore (in "runs/wickets" format)
  /// - homeTeamOvers, awayTeamOvers (in "overs.balls" format)
  /// - winnerTeamName (when both innings complete)
  Future<void> syncMatchScoresFromInnings(String matchId) async {
    final db = await database;

    // Get the match
    final matchRows = await db.query(
      'matches',
      where: 'matchId = ?',
      whereArgs: [matchId],
    );
    if (matchRows.isEmpty) return;

    final match = MatchModel.fromMap(matchRows.first);

    // Get all innings for this match
    final inningsRows = await db.query(
      'innings',
      where: 'matchId = ?',
      whereArgs: [matchId],
    );
    final allInnings = inningsRows.map((r) => Innings.fromMap(r)).toList();

    if (allInnings.isEmpty) return;

    // Find home and away innings
    Innings? homeInnings;
    Innings? awayInnings;
    
    for (final innings in allInnings) {
      if (innings.teamId == match.homeTeamId && homeInnings == null) {
        homeInnings = innings;
      } else if (innings.teamId == match.awayTeamId && awayInnings == null) {
        awayInnings = innings;
      }
    }

    String? newHomeScore;
    String? newAwayScore;
    String? newHomeOvers;
    String? newAwayOvers;
    String? newWinner;

    // Update home score and overs if we have it
    if (homeInnings != null) {
      newHomeScore = '${homeInnings.runs}/${homeInnings.wickets}';
      final overs = homeInnings.balls ~/ match.ballsPerOver;
      final balls = homeInnings.balls % match.ballsPerOver;
      newHomeOvers = '$overs.$balls';
    }

    // Update away score and overs if we have it
    if (awayInnings != null) {
      newAwayScore = '${awayInnings.runs}/${awayInnings.wickets}';
      final overs = awayInnings.balls ~/ match.ballsPerOver;
      final balls = awayInnings.balls % match.ballsPerOver;
      newAwayOvers = '$overs.$balls';
    }

    // Determine winner if both innings are complete
    if (homeInnings != null &&
        awayInnings != null &&
        homeInnings.isCompleted &&
        awayInnings.isCompleted) {
      final firstInnings = allInnings[0];
      final secondInnings = allInnings[1];

      if (secondInnings.targetScore > 0 &&
          secondInnings.runs >= secondInnings.targetScore) {
        final team =
            await db.query('teams', where: 'teamId = ?', whereArgs: [secondInnings.teamId]);
        newWinner = team.isNotEmpty ? team.first['teamName'] as String? : 'Team B';
      } else if (firstInnings.runs > secondInnings.runs) {
        final team =
            await db.query('teams', where: 'teamId = ?', whereArgs: [firstInnings.teamId]);
        newWinner = team.isNotEmpty ? team.first['teamName'] as String? : 'Team A';
      } else if (secondInnings.runs > firstInnings.runs) {
        final team =
            await db.query('teams', where: 'teamId = ?', whereArgs: [secondInnings.teamId]);
        newWinner = team.isNotEmpty ? team.first['teamName'] as String? : 'Team B';
      } else {
        newWinner = 'Match Tied';
      }
    }

    // Create updated match
    final updatedMatch = MatchModel(
      matchId: match.matchId,
      homeTeamId: match.homeTeamId,
      awayTeamId: match.awayTeamId,
      oversPerInnings: match.oversPerInnings,
      ballsPerOver: match.ballsPerOver,
      rebowlWides: match.rebowlWides,
      rebowlNoBalls: match.rebowlNoBalls,
      recordOrientation: match.recordOrientation,
      createdAt: match.createdAt,
      homeTeamScore: newHomeScore ?? match.homeTeamScore,
      awayTeamScore: newAwayScore ?? match.awayTeamScore,
      homeTeamOvers: newHomeOvers ?? match.homeTeamOvers,
      awayTeamOvers: newAwayOvers ?? match.awayTeamOvers,
      winnerTeamName: newWinner ?? match.winnerTeamName,
    );

    // Update match in database
    await db.update(
      'matches',
      updatedMatch.toMap(),
      where: 'matchId = ?',
      whereArgs: [match.matchId],
    );
  }

  Future<void> deleteMatch(String matchId) async {
    final db = await database;

    await db.delete('matches', where: 'matchId = ?', whereArgs: [matchId]);
  }

  Future<void> insertInnings(Innings innings) async {
    final db = await database;

    await db.insert(
      'innings',
      innings.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Innings>> getInnings() async {
    final db = await database;

    final result = await db.query('innings', orderBy: 'createdAt DESC');

    return result.map((map) => Innings.fromMap(map)).toList();
  }

  Future<Innings?> getInningsById(String inningsId) async {
    final db = await database;

    final result = await db.query(
      'innings',
      where: 'inningsId = ?',
      whereArgs: [inningsId],
    );

    if (result.isNotEmpty) {
      return Innings.fromMap(result.first);
    }

    return null;
  }

  Future<void> updateInnings(Innings innings) async {
    final db = await database;

    await db.update(
      'innings',
      innings.toMap(),
      where: 'inningsId = ?',
      whereArgs: [innings.inningsId],
    );
  }

  Future<void> deleteInnings(String inningsId) async {
    final db = await database;

    await db.delete('innings', where: 'inningsId = ?', whereArgs: [inningsId]);
  }

  Future<List<BallRecording>> getBallRecordingsByInnings(
    String inningsId,
  ) async {
    final db = await database;

    final result = await db.query(
      'ball_recordings',
      where: 'inningsId = ?',
      whereArgs: [inningsId],
      orderBy: 'createdAt DESC',
    );

    return result.map((map) => BallRecording.fromMap(map)).toList();
  }

  Future<void> insertBallRecording(BallRecording recording) async {
    final db = await database;

    await db.insert(
      'ball_recordings',
      recording.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBallRecording(BallRecording recording) async {
    final db = await database;

    await db.update(
      'ball_recordings',
      recording.toMap(),
      where: 'recordingId = ?',
      whereArgs: [recording.recordingId],
    );
  }

  Future<void> deleteBallRecording(String recordingId) async {
    final db = await database;

    await db.delete(
      'ball_recordings',
      where: 'recordingId = ?',
      whereArgs: [recordingId],
    );
  }

  Future<void> insertDeliveryEvents(List<Map<String, dynamic>> events) async {
    if (events.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final event in events) {
      batch.insert(
        'delivery_events',
        event,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getDeliveryEventsByInnings(
    String inningsId,
  ) async {
    final db = await database;
    return db.query(
      'delivery_events',
      where: 'inningsId = ?',
      whereArgs: [inningsId],
      orderBy: 'createdAt ASC',
    );
  }

  Future<void> deleteDeliveryEventsByAction(String actionId) async {
    final db = await database;
    await db.delete(
      'delivery_events',
      where: 'actionId = ?',
      whereArgs: [actionId],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}