import 'package:cric_snap/database/databaseHelper.dart';
import 'package:cric_snap/innings/model.dart';
import 'package:cric_snap/match/model.dart';
import 'package:cric_snap/services/quick_match_data_source.dart';
import 'package:cric_snap/teams/model.dart';

class DbQuickMatchDataSource implements QuickMatchDataSource {
  @override
  Future<int> nextQuickMatchNumber() async {
    final count = await DatabaseHelper.instance.countMatches();
    return count + 1;
  }

  @override
  Future<QuickTeamResolution> getOrCreateQuickTeam({
    required String teamName,
    required String abbreviation,
  }) async {
    final existing = await DatabaseHelper.instance
        .findTeamByNameAndAbbreviation(teamName, abbreviation);
    if (existing != null) {
      return QuickTeamResolution(team: existing, alreadyExisted: true);
    }

    final team = Team(teamName: teamName, abbreviation: abbreviation);
    await DatabaseHelper.instance.insertTeam(team);
    return QuickTeamResolution(team: team, alreadyExisted: false);
  }

  @override
  Future<void> insertMatch(MatchModel match) async {
    await DatabaseHelper.instance.insertMatch(match);
  }

  @override
  Future<void> insertInnings(Innings innings) async {
    await DatabaseHelper.instance.insertInnings(innings);
  }
}