import 'package:cric_snap/innings/innings_display_order.dart';
import 'package:cric_snap/innings/model.dart';
import 'package:cric_snap/match/model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('home innings appear before away innings', () {
    final match = MatchModel(
      homeTeamId: 'home-id',
      awayTeamId: 'away-id',
      oversPerInnings: 5,
      ballsPerOver: 6,
      rebowlWides: true,
      rebowlNoBalls: true,
      recordOrientation: 'Portrait',
    );

    final awayFirst = Innings(
      inningsId: 'inn-1',
      matchId: match.matchId,
      teamId: match.awayTeamId,
      createdAt: DateTime(2026, 1, 2),
    );
    final homeFirst = Innings(
      inningsId: 'inn-2',
      matchId: match.matchId,
      teamId: match.homeTeamId,
      createdAt: DateTime(2026, 1, 1),
    );

    final list = [awayFirst, homeFirst];
    sortInningsForMatchDisplay(list, match);

    expect(list.first.teamId, match.homeTeamId);
    expect(list.last.teamId, match.awayTeamId);
  });

  test('unknown teams sort after home and away', () {
    final match = MatchModel(
      homeTeamId: 'home-id',
      awayTeamId: 'away-id',
      oversPerInnings: 5,
      ballsPerOver: 6,
      rebowlWides: true,
      rebowlNoBalls: true,
      recordOrientation: 'Portrait',
    );

    final other = Innings(
      matchId: match.matchId,
      teamId: 'other',
      createdAt: DateTime(2026, 1, 1),
    );
    final away = Innings(
      matchId: match.matchId,
      teamId: match.awayTeamId,
      createdAt: DateTime(2026, 1, 1),
    );
    final home = Innings(
      matchId: match.matchId,
      teamId: match.homeTeamId,
      createdAt: DateTime(2026, 1, 2),
    );

    final list = [other, away, home];
    sortInningsForMatchDisplay(list, match);

    expect(list.map((e) => e.teamId).toList(), [
      match.homeTeamId,
      match.awayTeamId,
      'other',
    ]);
  });
}
