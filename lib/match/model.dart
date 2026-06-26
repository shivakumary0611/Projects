import 'package:uuid/uuid.dart';

const uuid = Uuid();

class MatchModel {
  final String matchId;
  final String homeTeamId;
  final String awayTeamId;
  final int oversPerInnings;
  final int ballsPerOver;
  final bool rebowlWides;
  final bool rebowlNoBalls;
  final String recordOrientation;
  final DateTime createdAt;

  final String? homeTeamScore;
  final String? awayTeamScore;
  final String? homeTeamOvers;
  final String? awayTeamOvers;
  final String? winnerTeamName;

  MatchModel({
    String? matchId,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.oversPerInnings,
    this.ballsPerOver = 6,
    this.rebowlWides = true,
    this.rebowlNoBalls = true,
    this.recordOrientation = 'Portrait',
    DateTime? createdAt,
    this.homeTeamScore,
    this.awayTeamScore,
    this.homeTeamOvers,
    this.awayTeamOvers,
    this.winnerTeamName,
  })  : matchId = matchId ?? uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'oversPerInnings': oversPerInnings,
      'ballsPerOver': ballsPerOver,
      'rebowlWides': rebowlWides ? 1 : 0,
      'rebowlNoBalls': rebowlNoBalls ? 1 : 0,
      'recordOrientation': recordOrientation,
      'createdAt': createdAt.toIso8601String(),
      'homeTeamScore': homeTeamScore,
      'awayTeamScore': awayTeamScore,
      'homeTeamOvers': homeTeamOvers,
      'awayTeamOvers': awayTeamOvers,
      'winnerTeamName': winnerTeamName,
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      matchId: map['matchId'],
      homeTeamId: map['homeTeamId'],
      awayTeamId: map['awayTeamId'],
      oversPerInnings: map['oversPerInnings'] ?? 0,
      ballsPerOver: map['ballsPerOver'] ?? 6,
      rebowlWides: map['rebowlWides'] == 1,
      rebowlNoBalls: map['rebowlNoBalls'] == 1,
      recordOrientation: map['recordOrientation'] ?? 'Portrait',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      homeTeamScore: map['homeTeamScore'],
      awayTeamScore: map['awayTeamScore'],
      homeTeamOvers: map['homeTeamOvers'],
      awayTeamOvers: map['awayTeamOvers'],
      winnerTeamName: map['winnerTeamName'],
    );
  }
}