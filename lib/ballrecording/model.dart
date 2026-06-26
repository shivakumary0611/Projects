import 'package:uuid/uuid.dart';

const uuid = Uuid();

class BallRecording {
  final String recordingId;
  final String inningsId;
  final String videoPath;
  final int runs;
  final String extraType;
  final bool isWicket;
  final bool isHighlight;
  final int overIndex;
  final int ballInOver;
  final String actionId;
  final DateTime createdAt;

  BallRecording({
    String? recordingId,
    required this.inningsId,
    required this.videoPath,
    required this.runs,
    required this.extraType,
    required this.isWicket,
    required this.isHighlight,
    this.overIndex = 0,
    this.ballInOver = 1,
    this.actionId = '',
    DateTime? createdAt,
  })  : recordingId = recordingId ?? uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'recordingId': recordingId,
      'inningsId': inningsId,
      'videoPath': videoPath,
      'runs': runs,
      'extraType': extraType,
      'isWicket': isWicket ? 1 : 0,
      'isHighlight': isHighlight ? 1 : 0,
      'overIndex': overIndex,
      'ballInOver': ballInOver,
      'actionId': actionId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BallRecording.fromMap(Map<String, dynamic> map) {
    return BallRecording(
      recordingId: map['recordingId'],
      inningsId: map['inningsId'],
      videoPath: map['videoPath'],
      runs: map['runs'] ?? 0,
      extraType: map['extraType'] ?? '',
      isWicket: map['isWicket'] == 1,
      isHighlight: map['isHighlight'] == 1,
      overIndex: map['overIndex'] ?? 0,
      ballInOver: map['ballInOver'] ?? 1,
      actionId: map['actionId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String get overBallLabel => 'Over ${overIndex + 1} - Ball $ballInOver';

  String get resultLabel {
    if (isWicket) return 'W';
    if (extraType == 'Wide') return runs > 0 ? 'Wd+$runs' : 'Wd';
    if (extraType == 'No Ball') {
      return runs > 0 ? 'NB+$runs' : 'NB';
    }
    return runs == 0 ? 'Dot' : runs.toString();
  }
}
