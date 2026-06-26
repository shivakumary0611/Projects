import 'package:cric_snap/database/databaseHelper.dart';
import 'package:cric_snap/players/model.dart';
import 'package:flutter/foundation.dart';

class PlayerViewModel extends ChangeNotifier {
  List<Player> _players = [];
  List<Player> get players => _players;

  Future<void> loadPlayers() async {
    _players = await DatabaseHelper.instance.getPlayers();
    notifyListeners();
  }

  Future<void> addPlayer(Player player) async {
    await DatabaseHelper.instance.insertPlayer(player);
    loadPlayers();
  }

  Future<void> updatePlayer(Player player) async {
    await DatabaseHelper.instance.updatePlayer(player);
    loadPlayers();
  }

  Future<void> deletePlayer(String playerId) async {
    await DatabaseHelper.instance.deletePlayer(playerId);
    await loadPlayers();
  }

  Future<Player?> getPlayerById(String playerId) async {
    return await DatabaseHelper.instance.getPlayerById(playerId);
  }
}
