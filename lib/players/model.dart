import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Player {
  final String playerId;
  final String firstName;
  final String lastName;
  final String teamId;
  final String? avatarPath;
  final DateTime createdAt;

  Player({
    String? playerId,
    required this.firstName,
    required this.lastName,
    required this.teamId,
    this.avatarPath,
    DateTime? createdAt,
  })  : playerId = playerId ?? uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'firstName': firstName,
      'lastName': lastName,
      'teamId': teamId,
      'avatarPath': avatarPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      playerId: map['playerId'],
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      teamId: map['teamId'] ?? '',
      avatarPath: map['avatarPath'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}