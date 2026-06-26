import 'package:cric_snap/innings/model.dart';
import 'package:cric_snap/match/model.dart';
import 'package:cric_snap/services/quick_match_constants.dart';
import 'package:cric_snap/services/quick_match_data_source.dart';
import 'package:cric_snap/teams/model.dart';

class QuickMatchResult {
  QuickMatchResult({
    required this.match,
    required this.teamA,
    required this.teamB,
    required this.quickMatchNumber,
  });

  final MatchModel match;
  final Team teamA;
  final Team teamB;

  /// Sequence index used in team names, e.g. `Team A (3)`.
  final int quickMatchNumber;
}

class QuickMatchService {
  QuickMatchService(this._dataSource);

  final QuickMatchDataSource _dataSource;

  /// Creates a match with **Team A (n)** home first, **Team B (n)** away.
  /// Each call uses the next [n] based on how many matches are already stored.
  Future<QuickMatchResult> start({
    required int overs,
    int ballsPerOver = 6,
  }) async {
    final n = await _dataSource.nextQuickMatchNumber();

    final resA = await _dataSource.getOrCreateQuickTeam(
      teamName: quickMatchTeamAName(n),
      abbreviation: quickMatchTeamAAbbrev(n),
    );
    final resB = await _dataSource.getOrCreateQuickTeam(
      teamName: quickMatchTeamBName(n),
      abbreviation: quickMatchTeamBAbbrev(n),
    );

    final teamA = resA.team;
    final teamB = resB.team;

    final match = MatchModel(
      homeTeamId: teamA.teamId,
      awayTeamId: teamB.teamId,
      oversPerInnings: overs,
      ballsPerOver: ballsPerOver,
      rebowlWides: true,
      rebowlNoBalls: true,
      recordOrientation: 'Portrait',
      homeTeamScore: '0/0',
      awayTeamScore: '0/0',
      homeTeamOvers: '0.0',
      awayTeamOvers: '0.0',
    );

    await _dataSource.insertMatch(match);

    final firstInnings = Innings(
      matchId: match.matchId,
      teamId: teamA.teamId,
      targetScore: 0,
    );
    final secondInnings = Innings(
      matchId: match.matchId,
      teamId: teamB.teamId,
      targetScore: 0,
    );

    await _dataSource.insertInnings(firstInnings);
    await _dataSource.insertInnings(secondInnings);

    return QuickMatchResult(
      match: match,
      teamA: teamA,
      teamB: teamB,
      quickMatchNumber: n,
    );
  }
}
