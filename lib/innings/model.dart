import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Innings {
  final String inningsId;
  final String matchId;
  final String teamId;
  final int runs;
  final int wickets;
  final int balls;
  final int targetScore;
  final bool isCompleted;
  final DateTime createdAt;

  Innings({
    String? inningsId,
    required this.matchId,
    required this.teamId,
    this.runs = 0,
    this.wickets = 0,
    this.balls = 0,
    this.targetScore = 0,
    this.isCompleted = false,
    DateTime? createdAt,
  }) : inningsId = inningsId ?? uuid.v4(),
       createdAt = createdAt ?? DateTime.now();

  int get overNumber => (balls ~/ 6) + 1;

  int get ballNumber => (balls % 6) + 1;

  String get currentBallText => 'Over $overNumber - Ball $ballNumber';

  String get oversDisplay => _calculateOversDisplay(6);

  String _calculateOversDisplay(int ballsPerOver) {
    final effectiveBpo = ballsPerOver <= 0 ? 6 : ballsPerOver;
    final completedOvers = balls ~/ effectiveBpo;
    final remainingBalls = balls % effectiveBpo;
    return '$completedOvers.$remainingBalls';
  }

  /// Balls still to be bowled in the **current partial over** (legal deliveries only).
  int ballsRemainingThisOver({int ballsPerOver = 6}) {
    if (ballsPerOver <= 0) return 6;
    final partial = balls % ballsPerOver;
    return partial == 0 ? ballsPerOver : ballsPerOver - partial;
  }

  /// `true` overs part for display when [ballsPerOver] is not 6.
  String oversDisplayForMatch(int ballsPerOver) {
    return _calculateOversDisplay(ballsPerOver);
  }

  Map<String, dynamic> toMap() {
    return {
      'inningsId': inningsId,
      'matchId': matchId,
      'teamId': teamId,
      'runs': runs,
      'wickets': wickets,
      'balls': balls,
      'targetScore': targetScore,
      'isCompleted': isCompleted ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Innings.fromMap(Map<String, dynamic> map) {
    return Innings(
      inningsId: map['inningsId'],
      matchId: map['matchId'],
      teamId: map['teamId'],
      runs: map['runs'] ?? 0,
      wickets: map['wickets'] ?? 0,
      balls: map['balls'] ?? 0,
      targetScore: map['targetScore'] ?? 0,
      isCompleted: map['isCompleted'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
