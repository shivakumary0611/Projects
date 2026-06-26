import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Team {
  final String teamId;
  final String teamName;
  final String abbreviation;
  final String? teamLogo;
  final DateTime createdAt;

  Team({
    String? teamId,
    required this.teamName,
    required this.abbreviation,
    this.teamLogo,
    DateTime? createdAt,
  })  : teamId = teamId ?? uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'abbreviation': abbreviation,
      'teamLogo': teamLogo,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      teamId: map['teamId'],
      teamName: map['teamName'] ?? '',
      abbreviation: map['abbreviation'] ?? '',
      teamLogo: map['teamLogo'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}