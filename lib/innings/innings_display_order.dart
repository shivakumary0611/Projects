import 'package:cric_snap/innings/model.dart';
import 'package:cric_snap/match/model.dart';

/// Orders innings for UI: home team first, away second, then others by [createdAt].
void sortInningsForMatchDisplay(List<Innings> innings, MatchModel match) {
  int orderForTeam(String teamId) {
    if (teamId == match.homeTeamId) return 0;
    if (teamId == match.awayTeamId) return 1;
    return 2;
  }

  innings.sort((a, b) {
    final ao = orderForTeam(a.teamId);
    final bo = orderForTeam(b.teamId);
    if (ao != bo) return ao.compareTo(bo);
    return a.createdAt.compareTo(b.createdAt);
  });
}
