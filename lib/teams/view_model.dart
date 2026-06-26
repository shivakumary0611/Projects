import 'package:cric_snap/database/databaseHelper.dart';
import 'package:cric_snap/teams/model.dart';
import 'package:flutter/material.dart';

class TeamViewModel extends ChangeNotifier {
  List<Team> _teams = [];
  List<Team> get teams => _teams;

  Future<void> loadTeams() async {
    _teams = await DatabaseHelper.instance.getTeams();
    notifyListeners();
  }

  Future<void> addTeam(Team team) async {
    debugPrint('Adding team: ${team.teamName}');
    await DatabaseHelper.instance.insertTeam(team);
    await loadTeams();
  }

  Future<void> updateTeam(Team team) async {
    await DatabaseHelper.instance.updateTeam(team);
    await loadTeams();
  }

  Future<void> deleteTeam(String teamId) async {
    await DatabaseHelper.instance.deleteTeam(teamId);
    await loadTeams();
  }

  Future<Team?> getTeamById(String teamId) async {
    return await DatabaseHelper.instance.getTeamById(teamId);
  }

  
}
