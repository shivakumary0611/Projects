import 'package:cric_snap/innings/model.dart';
import 'package:cric_snap/match/model.dart';
import 'package:cric_snap/teams/model.dart';

/// Result of resolving a quick-match squad row (new vs reused).
class QuickTeamResolution {
  const QuickTeamResolution({required this.team, required this.alreadyExisted});

  final Team team;
  final bool alreadyExisted;
}

/// Persistence boundary for [QuickMatchService] (mock in tests).
abstract class QuickMatchDataSource {
  /// Next quick-match index = current stored match count + 1.
  Future<int> nextQuickMatchNumber();

  Future<QuickTeamResolution> getOrCreateQuickTeam({
    required String teamName,
    required String abbreviation,
  });

  Future<void> insertMatch(MatchModel match);

  Future<void> insertInnings(Innings innings);
}
