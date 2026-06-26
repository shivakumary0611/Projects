// ignore_for_file: file_names
import 'package:cric_snap/ballrecording/model.dart';
import 'package:cric_snap/ballrecording/view_model.dart';
import 'package:cric_snap/camera/view.dart';
import 'package:cric_snap/database/databaseHelper.dart';
import 'package:cric_snap/innings/model.dart';
import 'package:cric_snap/innings/view_model.dart';
import 'package:cric_snap/match/model.dart';
import 'package:cric_snap/match/view_model.dart';
import 'package:cric_snap/videoplayer/video_player.dart';
import 'package:cric_snap/widget/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateRecordingView extends StatefulWidget {
  final Innings innings;
  final MatchModel match;
  final String? videoPath;

  const CreateRecordingView({
    super.key,
    required this.innings,
    required this.match,
    this.videoPath,
  });

  @override
  State<CreateRecordingView> createState() => _CreateRecordingViewState();
}

class _CreateRecordingViewState extends State<CreateRecordingView> {
  bool _isHighlight = false;
  bool _isSaving = false;
  bool _isExternalChangeHandling = false;
  late Innings _currentInnings;
  late MatchModel _currentMatch;
  final List<Innings> _undoStack = [];
  final List<String> _undoActionIds = [];
  final List<_BallEvent> _ballEvents = [];
  String? _recordedVideoPath;
  String? _nextTeamName;

  bool get _isInningsComplete {
    final ballsPerOver = _currentMatch.ballsPerOver <= 0
        ? 6
        : _currentMatch.ballsPerOver;

    final totalBallsAllowed = _currentMatch.oversPerInnings * ballsPerOver;

    // Overs completed
    if (_currentInnings.balls >= totalBallsAllowed) {
      return true;
    }

    // All out
    if (_currentInnings.wickets >= 10) {
      return true;
    }

    // Target chased
    if (_currentInnings.targetScore > 0 &&
        _currentInnings.runs >= _currentInnings.targetScore) {
      return true;
    }

    return false;
  }

  @override
  void initState() {
    super.initState();
    _currentInnings = widget.innings;
    _currentMatch = widget.match;
    _recordedVideoPath = widget.videoPath; // pre-fill if launched from camera
    _loadDeliveryEvents();
    _refreshCurrentStateFromDb();
    try {
      context.read<MatchesViewModel>().addListener(_onExternalChange);
      context.read<InningsViewModel>().addListener(_onExternalChange);
    } catch (_) {}
    _checkFirstTimeScoring();
  }

  Future<void> _checkFirstTimeScoring() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstScoring = prefs.getBool('is_first_scoring_launch') ?? true;
      if (isFirstScoring) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showScoringGuideDialog();
        });
      }
    } catch (_) {}
  }

  void _showScoringGuideDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _ScoringGuideDialog(
          onComplete: () async {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_first_scoring_launch', false);
            } catch (_) {}
          },
        );
      },
    );
  }

  void _onExternalChange() {
    if (!mounted) return;
    if (_isSaving || _isExternalChangeHandling) return;

    _isExternalChangeHandling = true;
    _refreshCurrentStateFromDb().then((reopened) {
      _isExternalChangeHandling = false;
      if (!mounted) return;
      if (reopened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Overs updated — innings reopened for scoring.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Future<bool> _refreshCurrentStateFromDb() async {
    final updatedMatch = await DatabaseHelper.instance.getMatchById(
      widget.match.matchId,
    );
    final updatedInnings = await DatabaseHelper.instance.getInningsById(
      widget.innings.inningsId,
    );
    if (!mounted) return false;
    var reopened = false;

    if (updatedMatch != null && updatedInnings != null) {
      final otherTeamId = updatedInnings.teamId == updatedMatch.homeTeamId
          ? updatedMatch.awayTeamId
          : updatedMatch.homeTeamId;
      final otherTeam = await DatabaseHelper.instance.getTeamById(otherTeamId);

      final ballsPerOver = updatedMatch.ballsPerOver <= 0
          ? 6
          : updatedMatch.ballsPerOver;
      final totalBallsAllowed = updatedMatch.oversPerInnings * ballsPerOver;

      var inningsToUse = updatedInnings;
      if (updatedInnings.isCompleted &&
          updatedInnings.wickets < 10 &&
          updatedInnings.balls < totalBallsAllowed) {
        final reopenedInnings = Innings(
          inningsId: updatedInnings.inningsId,
          matchId: updatedInnings.matchId,
          teamId: updatedInnings.teamId,
          runs: updatedInnings.runs,
          wickets: updatedInnings.wickets,
          balls: updatedInnings.balls,
          targetScore: updatedInnings.targetScore,
          isCompleted: false,
          createdAt: updatedInnings.createdAt,
        );
        await DatabaseHelper.instance.updateInnings(reopenedInnings);
        inningsToUse = reopenedInnings;
        reopened = true;
      }

      setState(() {
        _currentMatch = updatedMatch;
        _currentInnings = inningsToUse;
        _nextTeamName = otherTeam?.teamName;
      });
      return reopened;
    }

    if (updatedMatch != null || updatedInnings != null) {
      String? nextName;
      if (updatedMatch != null && updatedInnings != null) {
         final otherId = updatedInnings.teamId == updatedMatch.homeTeamId
            ? updatedMatch.awayTeamId
            : updatedMatch.homeTeamId;
         final t = await DatabaseHelper.instance.getTeamById(otherId);
         nextName = t?.teamName;
      }

      setState(() {
        if (updatedMatch != null) _currentMatch = updatedMatch;
        if (updatedInnings != null) _currentInnings = updatedInnings;
        if (nextName != null) _nextTeamName = nextName;
      });
    }

    return reopened;
  }

  Future<void> _loadDeliveryEvents() async {
    final rows = await DatabaseHelper.instance.getDeliveryEventsByInnings(
      widget.innings.inningsId,
    );
    if (!mounted) return;
    setState(() {
      _ballEvents
        ..clear()
        ..addAll(rows.map(_BallEvent.fromMap));
    });
  }

  @override
  void dispose() {
    try {
      context.read<MatchesViewModel>().removeListener(_onExternalChange);
      context.read<InningsViewModel>().removeListener(_onExternalChange);
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecordingSave = _recordedVideoPath != null;
    final inningsComplete = _isInningsComplete;

    return Scaffold(
      appBar: CustomAppBar(
        title: isRecordingSave ? 'Save Recording' : 'Cricket Run Counter',
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () async {
          final reopened = await _refreshCurrentStateFromDb();
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                reopened
                    ? 'Refreshed: innings reopened for scoring.'
                    : 'Refreshed.',
              ),
              backgroundColor: reopened ? Colors.green : Colors.blueGrey,
            ),
          );
        },
        tooltip: 'Refresh scoring state',
        child: const Icon(Icons.refresh),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ScoreboardHeader(
              innings: _currentInnings,
              match: _currentMatch,
              ballEvents: _eventsForCurrentOver(),
              onViewOvers: _showOverHistorySheet,
            ),
            const SizedBox(height: 16),
            if (!isRecordingSave) ...[
              if (inningsComplete)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: (_currentMatch.winnerTeamName ?? '').isNotEmpty
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (_currentMatch.winnerTeamName ?? '').isNotEmpty
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_currentMatch.winnerTeamName ?? '').isNotEmpty
                            ? _currentMatch.winnerTeamName == 'Match Tied'
                                ? '🎭 Match Tied! Both teams tied.'
                                : '🏆 ${_currentMatch.winnerTeamName} won the match!'
                            : 'This innings has completed. Update the overs before adding more score.',
                        style: TextStyle(
                          color: (_currentMatch.winnerTeamName ?? '').isNotEmpty
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if ((_currentMatch.winnerTeamName ?? '').isEmpty) ...[
                        if (_currentInnings.targetScore == 0) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _updateOvers,
                              icon: const Icon(Icons.add),
                              label: const Text('Add one extra over'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _goToNextInnings,
                            icon: const Icon(Icons.arrow_forward),
                            label:
                                Text('Go to ${_nextTeamName ?? "another team"} scoring page'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _RunCounterPad(
                enabled: !inningsComplete,
                onDot: inningsComplete ? null : () => _applyBall(runs: 0),
                onWide: inningsComplete ? null : () => _applyBall(runs: 0, extra: 'Wide', isHighlight: _isHighlight),
                onWideLongPress: inningsComplete ? null : () => _showWideRunsSheet(),
                onNoBall: inningsComplete ? null : () => _applyBall(runs: 0, extra: 'No Ball', isHighlight: _isHighlight),
                onNoBallLongPress: inningsComplete ? null : () => _showNoBallRunsSheet(),
                onRuns: inningsComplete
                    ? null
                    : (runs) => _applyBall(runs: runs),
                onWicket: inningsComplete ? null : () => _applyBall(runs: 0, isWicket: true, isHighlight: _isHighlight),
                onWicketLongPress: inningsComplete ? null : () => _showWicketRunsSheet(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving || _undoStack.isEmpty
                      ? null
                      : _undoLastScoreAction,
                  icon: const Icon(Icons.undo),
                  label: const Text('Undo last action'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isSaving || inningsComplete
                      ? null
                      : () async {
                          final videoPath = await Navigator.push<String?>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CameraRecordingView(
                                innings: _currentInnings,
                                matchModel: _currentMatch,
                              ),
                            ),
                          );
                          if (videoPath != null) {
                            if (!mounted) return;
                            setState(() {
                              _recordedVideoPath = videoPath;
                            });
                          }
                        },
                  icon: const Icon(Icons.videocam_outlined),
                  label: const Text('Record'),
                ),
              ),
            ],
            if (isRecordingSave) ...[
              _RecordingReadyPanel(
                isHighlight: _isHighlight,
                onHighlightChanged: (value) {
                  setState(() {
                    _isHighlight = value;
                  });
                },
                onPlayVideo: () {
                  if (_recordedVideoPath != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => VideoPlayerView(
                          videoPath: _recordedVideoPath!,
                          title: 'Ball Preview',
                          subtitle: 'Recorded video clip',
                          resultLabel: 'REC',
                          resultColor: const Color(0xFFE85D04),
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              if (inningsComplete)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: (_currentMatch.winnerTeamName ?? '').isNotEmpty
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (_currentMatch.winnerTeamName ?? '').isNotEmpty
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_currentMatch.winnerTeamName ?? '').isNotEmpty
                            ? _currentMatch.winnerTeamName == 'Match Tied'
                                ? '🎭 Match Tied! Both teams tied.'
                                : '🏆 ${_currentMatch.winnerTeamName} won the match!'
                            : 'This innings has completed. Update the overs before adding more score.',
                        style: TextStyle(
                          color: (_currentMatch.winnerTeamName ?? '').isNotEmpty
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if ((_currentMatch.winnerTeamName ?? '').isEmpty) ...[
                        if (_currentInnings.targetScore == 0) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _updateOvers,
                              icon: const Icon(Icons.add),
                              label: const Text('Add one extra over'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _goToNextInnings,
                            icon: const Icon(Icons.arrow_forward),
                            label:
                                Text('Go to ${_nextTeamName ?? "another team"} scoring page'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              _RunCounterPad(
                enabled: !inningsComplete,
                onDot: inningsComplete
                    ? null
                    : () => _applyBall(
                        runs: 0,
                        isHighlight: _isHighlight,
                        closeAfter: true,
                      ),
                onWide: inningsComplete
                    ? null
                    : () => _applyBall(
                        runs: 0,
                        extra: 'Wide',
                        isHighlight: _isHighlight,
                        closeAfter: true,
                      ),
                onWideLongPress: inningsComplete
                    ? null
                    : () => _showWideRunsSheet(closeAfter: true),
                onNoBall: inningsComplete
                    ? null
                    : () => _applyBall(
                        runs: 0,
                        extra: 'No Ball',
                        isHighlight: _isHighlight,
                        closeAfter: true,
                      ),
                onNoBallLongPress: inningsComplete
                    ? null
                    : () => _showNoBallRunsSheet(closeAfter: true),
                onRuns: inningsComplete
                    ? null
                    : (runs) => _applyBall(
                        runs: runs,
                        isHighlight: _isHighlight,
                        closeAfter: true,
                      ),
                onWicket: inningsComplete
                    ? null
                    : () => _applyBall(
                        runs: 0,
                        isWicket: true,
                        isHighlight: _isHighlight,
                        closeAfter: true,
                      ),
                onWicketLongPress: inningsComplete
                    ? null
                    : () => _showWicketRunsSheet(closeAfter: true),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: null,
    );
  }

  Future<void> _applyBall({
    required int runs,
    String extra = '',
    bool isWicket = false,
    bool isHighlight = false,
    bool closeAfter = false,
  }) async {
    if (_isSaving || _isInningsComplete) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final inningsViewModel = context.read<InningsViewModel>();
      final matchesViewModel = context.read<MatchesViewModel>();
      final recordingViewModel = context.read<BallRecordingViewModel>();

      final freshMatch =
          await DatabaseHelper.instance.getMatchById(_currentMatch.matchId) ??
          _currentMatch;
      final freshInnings =
          await DatabaseHelper.instance.getInningsById(
            _currentInnings.inningsId,
          ) ??
          _currentInnings;
      final previousMatch = await DatabaseHelper.instance.getMatchById(
        _currentMatch.matchId,
      );

      if (mounted) {
        _currentMatch = freshMatch;
        _currentInnings = freshInnings;
      }

      final isWide = extra == 'Wide';
      final isNoBall = extra == 'No Ball';
      var totalRuns = runs;
      var updatedBalls = _currentInnings.balls;
      final ballsPerOver = freshMatch.ballsPerOver <= 0
          ? 6
          : freshMatch.ballsPerOver;
      final overIndex = _currentInnings.balls ~/ ballsPerOver;
      final ballInOver = (_currentInnings.balls % ballsPerOver) + 1;
      final actionId = DateTime.now().microsecondsSinceEpoch.toString();

      if (isWide || isNoBall) {
        totalRuns += 1;
      }

      var shouldCountBall = true;
      if (isWide && freshMatch.rebowlWides) shouldCountBall = false;
      if (isNoBall && freshMatch.rebowlNoBalls) shouldCountBall = false;
      if (shouldCountBall) updatedBalls += 1;

      final totalBallsAllowed =
          freshMatch.oversPerInnings * freshMatch.ballsPerOver;
      final targetReached =
          _currentInnings.targetScore > 0 &&
          (_currentInnings.runs + totalRuns) >= _currentInnings.targetScore;

      final inningsCompleted =
          updatedBalls >= totalBallsAllowed ||
          (isWicket ? _currentInnings.wickets + 1 : _currentInnings.wickets) >=
              10 ||
          targetReached;

      final updatedInnings = Innings(
        inningsId: _currentInnings.inningsId,
        matchId: _currentInnings.matchId,
        teamId: _currentInnings.teamId,
        runs: _currentInnings.runs + totalRuns,
        wickets: isWicket
            ? _currentInnings.wickets + 1
            : _currentInnings.wickets,
        balls: updatedBalls,
        targetScore: _currentInnings.targetScore,
        isCompleted: inningsCompleted,
        createdAt: _currentInnings.createdAt,
      );

      await inningsViewModel.updateInnings(updatedInnings);
      await matchesViewModel.loadMatches();

      final latestMatch = await DatabaseHelper.instance.getMatchById(
        _currentMatch.matchId,
      );

      if (latestMatch != null) {
        _currentMatch = latestMatch;
      }

      if (targetReached) {
        final team = await DatabaseHelper.instance.getTeamById(
          updatedInnings.teamId,
        );

        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Match Won'),
            content: Text(
              '${team?.teamName ?? "Batting Team"} has successfully chased the target.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

      MatchModel? currentMatch;
      try {
        currentMatch = matchesViewModel.matches.firstWhere(
          (m) => m.matchId == _currentMatch.matchId,
        );
      } catch (_) {
        currentMatch = null;
      }

      String? winnerMessage;

      if (inningsCompleted) {
        final inningsList = await DatabaseHelper.instance.getInnings();

        final matchInnings = inningsList
            .where((i) => i.matchId == updatedInnings.matchId)
            .toList();

        if (matchInnings.length == 2 &&
            matchInnings.every((i) => i.isCompleted)) {
          final first = matchInnings[0];
          final second = matchInnings[1];

          final firstTeam = await DatabaseHelper.instance.getTeamById(
            first.teamId,
          );

          final secondTeam = await DatabaseHelper.instance.getTeamById(
            second.teamId,
          );

          if (second.targetScore > 0 && second.runs >= second.targetScore) {
            winnerMessage = '${secondTeam?.teamName ?? "Team"} won the match';
          } else if (first.runs > second.runs) {
            winnerMessage = '${firstTeam?.teamName ?? "Team"} won the match';
          } else if (second.runs > first.runs) {
            winnerMessage = '${secondTeam?.teamName ?? "Team"} won the match';
          } else {
            winnerMessage = 'Match Tied';
          }
        }
      }

      if (inningsCompleted && !targetReached && winnerMessage == null) {
        final finishedTeam = await DatabaseHelper.instance.getTeamById(
          updatedInnings.teamId,
        );
        String nextTeamName = 'next team';
        if (currentMatch != null) {
          final otherTeamId = updatedInnings.teamId == currentMatch.homeTeamId
              ? currentMatch.awayTeamId
              : currentMatch.homeTeamId;
          final otherTeam = await DatabaseHelper.instance.getTeamById(
            otherTeamId,
          );
          nextTeamName = otherTeam?.teamName ?? nextTeamName;
        }
        final finishedTeamName = finishedTeam?.teamName ?? 'this team';

        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Innings Complete'),
              content: Text(
                '$finishedTeamName overs completed. Start batting for $nextTeamName now?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        if (winnerMessage != null && mounted) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Match Result'),
              content: Text(winnerMessage!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }

      if (_recordedVideoPath != null) {
        final recording = BallRecording(
          inningsId: _currentInnings.inningsId,
          videoPath: _recordedVideoPath!,
          runs: runs,
          extraType: extra,
          isWicket: isWicket,
          isHighlight: isHighlight,
          overIndex: overIndex,
          ballInOver: ballInOver,
          actionId: actionId,
        );
        await recordingViewModel.addRecording(recording);
      }

      if (!mounted) return;

      final newEvents = _eventsForAction(
        runs: runs,
        totalRuns: totalRuns,
        extra: extra,
        isWicket: isWicket,
        overIndex: overIndex,
      );
      await DatabaseHelper.instance.insertDeliveryEvents(
        newEvents
            .asMap()
            .entries
            .map(
              (entry) => entry.value.toMap(
                inningsId: _currentInnings.inningsId,
                actionId: actionId,
                sequence: entry.key,
              ),
            )
            .toList(),
      );

      final hadWinner = (previousMatch?.winnerTeamName ?? '').trim().isNotEmpty;
      final nowHasWinner = (currentMatch?.winnerTeamName ?? '')
          .trim()
          .isNotEmpty;
      if (!mounted) return;
      if (!hadWinner && nowHasWinner) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Match Result'),
              content: Text(
                currentMatch?.winnerTeamName == 'Match Tied'
                    ? 'Match Tied'
                    : '${currentMatch?.winnerTeamName} wins the match',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }

      if (!mounted) return;
      if (closeAfter) {
        setState(() {
          _recordedVideoPath = null;
          _isHighlight = false;
          _undoStack.add(_currentInnings);
          _undoActionIds.add(actionId);
          _currentInnings = updatedInnings;
          _ballEvents.addAll(newEvents);
        });
        _showScoreFeedback(
          context,
          runs: runs,
          totalRuns: totalRuns,
          extra: extra,
          isWicket: isWicket,
          countedBall: shouldCountBall,
        );
        return;
      }

      _showScoreFeedback(
        context,
        runs: runs,
        totalRuns: totalRuns,
        extra: extra,
        isWicket: isWicket,
        countedBall: shouldCountBall,
      );

      setState(() {
        _undoStack.add(_currentInnings);
        _undoActionIds.add(actionId);
        _currentInnings = updatedInnings;
        _ballEvents.addAll(newEvents);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showNoBallRunsSheet({bool closeAfter = false}) async {
    if (_isSaving || _isInningsComplete) return;

    final selectedExtra = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'No Ball - Free Hit',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose extra runs scored off the bat. The no-ball bonus run is added automatically.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [0, 1, 2, 3, 4, 6].map((runs) {
                  return ChoiceChip(
                    label: Text(runs == 0 ? 'NB only' : '+$runs'),
                    selected: false,
                    onSelected: (_) => Navigator.pop(context, runs),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );

    if (selectedExtra == null || !mounted) return;
    await _applyBall(
      runs: selectedExtra,
      extra: 'No Ball',
      isHighlight: _isHighlight,
      closeAfter: closeAfter,
    );
  }

  Future<void> _showWicketRunsSheet({bool closeAfter = false}) async {
    if (_isSaving || _isInningsComplete) return;

    final selectedRuns = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Wicket Runs',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the runs completed on the wicket delivery.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [0, 1, 2, 3].map((runs) {
                  return ChoiceChip(
                    label: Text(runs == 0 ? 'No runs' : '+$runs'),
                    selected: false,
                    onSelected: (_) => Navigator.pop(context, runs),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );

    if (selectedRuns == null || !mounted) return;
    await _applyBall(
      runs: selectedRuns,
      isWicket: true,
      closeAfter: closeAfter,
    );
  }

  Future<void> _showWideRunsSheet({bool closeAfter = false}) async {
    if (_isSaving) return;

    final selectedExtra = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Wide',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose extra runs scored beyond the wide run. If no extra runs were scored, select Wd only.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [0, 1, 2, 3, 4].map((runs) {
                  return ChoiceChip(
                    label: Text(runs == 0 ? 'Wd only' : '+$runs'),
                    selected: false,
                    onSelected: (_) => Navigator.pop(context, runs),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );

    if (selectedExtra == null || !mounted) return;
    await _applyBall(
      runs: selectedExtra,
      extra: 'Wide',
      isHighlight: _isHighlight,
      closeAfter: closeAfter,
    );
  }

  Future<void> _undoLastScoreAction() async {
    if (_isSaving || _undoStack.isEmpty) return;

    final shouldUndo = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Undo last action?'),
          content: const Text(
            'This will restore the score, wickets, and balls to the previous delivery.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Undo'),
            ),
          ],
        );
      },
    );

    if (shouldUndo != true || !mounted) return;

    setState(() {
      _isSaving = true;
    });
    try {
      final inningsViewModel = context.read<InningsViewModel>();
      final matchesViewModel = context.read<MatchesViewModel>();
      final previousInnings = _undoStack.removeLast();

      await inningsViewModel.updateInnings(previousInnings);
      await matchesViewModel.loadMatches();

      if (!mounted) return;
      final actionId = _undoActionIds.isEmpty
          ? null
          : _undoActionIds.removeLast();
      if (actionId != null) {
        await DatabaseHelper.instance.deleteDeliveryEventsByAction(actionId);
      }
      setState(() {
        _currentInnings = previousInnings;
      });
      await _loadDeliveryEvents();
      if (mounted) {
        _showPlainFeedback(context, 'Last scoring action undone.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _updateOvers() async {
    final newOvers = _currentMatch.oversPerInnings + 1;
    final updatedMatch = MatchModel(
      matchId: _currentMatch.matchId,
      homeTeamId: _currentMatch.homeTeamId,
      awayTeamId: _currentMatch.awayTeamId,
      oversPerInnings: newOvers,
      ballsPerOver: _currentMatch.ballsPerOver,
      rebowlWides: _currentMatch.rebowlWides,
      rebowlNoBalls: _currentMatch.rebowlNoBalls,
      recordOrientation: _currentMatch.recordOrientation,
      createdAt: _currentMatch.createdAt,
      homeTeamScore: _currentMatch.homeTeamScore,
      awayTeamScore: _currentMatch.awayTeamScore,
      homeTeamOvers: _currentMatch.homeTeamOvers,
      awayTeamOvers: _currentMatch.awayTeamOvers,
      winnerTeamName: _currentMatch.winnerTeamName,
    );

    await DatabaseHelper.instance.updateMatch(updatedMatch);

    // Also need to update the innings isCompleted flag to false if it was true
    if (_currentInnings.isCompleted) {
      final reopenedInnings = Innings(
        inningsId: _currentInnings.inningsId,
        matchId: _currentInnings.matchId,
        teamId: _currentInnings.teamId,
        runs: _currentInnings.runs,
        wickets: _currentInnings.wickets,
        balls: _currentInnings.balls,
        targetScore: _currentInnings.targetScore,
        isCompleted: false,
        createdAt: _currentInnings.createdAt,
      );
      await DatabaseHelper.instance.updateInnings(reopenedInnings);
    }

    await _refreshCurrentStateFromDb();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Overs updated to $newOvers.')),
      );
    }
  }

  Future<void> _goToNextInnings() async {
    final inningsViewModel = context.read<InningsViewModel>();
    await inningsViewModel.loadInnings();

    final matchInnings = inningsViewModel.innings
        .where((i) => i.matchId == _currentMatch.matchId)
        .toList();

    if (matchInnings.length < 2) {
      // Create second innings if it doesn't exist
      final existingTeamIds = matchInnings.map((i) => i.teamId).toSet();
      final otherTeamId = _currentInnings.teamId == _currentMatch.homeTeamId
          ? _currentMatch.awayTeamId
          : _currentMatch.homeTeamId;

      if (!existingTeamIds.contains(otherTeamId)) {
        final newInnings = Innings(
          matchId: _currentMatch.matchId,
          teamId: otherTeamId,
        );
        await inningsViewModel.addInnings(newInnings);
        // Reload to get the new innings with its ID
        await inningsViewModel.loadInnings();
      }
    }

    final allInnings = inningsViewModel.innings
        .where((i) => i.matchId == _currentMatch.matchId)
        .toList();

    try {
      final nextInnings = allInnings.firstWhere(
        (i) => i.inningsId != _currentInnings.inningsId,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CreateRecordingView(
              innings: nextInnings,
              match: _currentMatch,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not find or create next innings.')),
        );
      }
    }
  }

  void _showScoreFeedback(
    BuildContext context, {
    required int runs,
    required int totalRuns,
    required String extra,
    required bool isWicket,
    required bool countedBall,
  }) {
    /*   final displayRuns = (extra == 'No Ball' || extra == 'Wide')
        ? totalRuns
        : runs;
    final message = switch (extra) {
      'No Ball' =>
        'No ball recorded. Added $displayRuns run${displayRuns == 1 ? '' : 's'}; free hit next.',
      'Wide' =>
        'Wide recorded. Added $displayRuns run${displayRuns == 1 ? '' : 's'}${countedBall ? '.' : '; ball to be re-bowled.'}',
      _ when isWicket => 'Wicket recorded.',
      _ when runs == 0 => 'Dot ball recorded.',
      _ => '$displayRuns run${displayRuns == 1 ? '' : 's'} recorded.',
    };
    _showPlainFeedback(context, message);
    */
  }

  List<_BallEvent> _eventsForAction({
    required int runs,
    required int totalRuns,
    required String extra,
    required bool isWicket,
    required int overIndex,
  }) {
    if (extra == 'Wide') {
      return [
        _BallEvent(
          label: runs > 0 ? 'Wd+$runs' : 'Wd',
          color: const Color(0xFF2563EB),
          overIndex: overIndex,
        ),
      ];
    }
    if (extra == 'No Ball') {
      return [
        _BallEvent(
          label: runs > 0 ? 'NB+$runs' : 'NB',
          color: const Color(0xFFF59E0B),
          overIndex: overIndex,
        ),
      ];
    }
    if (isWicket) {
      return [
        _BallEvent(
          label: 'W',
          color: const Color(0xFFDC2626),
          overIndex: overIndex,
        ),
      ];
    }
    return [
      _BallEvent(
        label: runs == 0 ? 'Dot' : runs.toString(),
        color: runs >= 4 ? const Color(0xFF16A34A) : const Color(0xFFE85D04),
        overIndex: overIndex,
      ),
    ];
  }

  void _showPlainFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1200),
        ),
      );
  }

  List<_BallEvent> _eventsForCurrentOver() {
    final ballsPerOver = _currentMatch.ballsPerOver <= 0
        ? 6
        : _currentMatch.ballsPerOver;
    final currentOver = _currentInnings.balls ~/ ballsPerOver;
    return _ballEvents
        .where((event) => event.overIndex == currentOver)
        .toList();
  }

  int _scoreForEvents(List<_BallEvent> events) {
    var total = 0;
    for (final event in events) {
      final label = event.label;
      if (label.startsWith('Wd+')) {
        total += 1 + (int.tryParse(label.substring(3)) ?? 0);
        continue;
      }
      if (label == 'Wd') {
        total += 1;
        continue;
      }
      if (label.startsWith('NB+')) {
        total += 1 + (int.tryParse(label.substring(3)) ?? 0);
        continue;
      }
      if (label == 'NB') {
        total += 1;
        continue;
      }
      if (label == 'W' || label == 'Dot') {
        continue;
      }
      if (label.startsWith('+')) {
        total += int.tryParse(label.substring(1)) ?? 0;
        continue;
      }
      total += int.tryParse(label) ?? 0;
    }
    return total;
  }

  void _showOverHistorySheet() {
    final ballsPerOver = _currentMatch.ballsPerOver <= 0
        ? 6
        : _currentMatch.ballsPerOver;
    final grouped = <int, List<_BallEvent>>{};
    for (final event in _ballEvents) {
      grouped.putIfAbsent(event.overIndex, () => []).add(event);
    }
    final overIndexes = grouped.keys.toList()..sort((a, b) => a.compareTo(b));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Over History',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Each row shows what happened in that over.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: overIndexes.isEmpty
                        ? const Center(child: Text('No balls recorded yet.'))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: overIndexes.length,
                            itemBuilder: (context, index) {
                              final overIndex = overIndexes[index];
                              final events = grouped[overIndex]!;
                              final score = _scoreForEvents(events);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Over ${overIndex + 1}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF7ED),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFFED7AA),
                                            ),
                                          ),
                                          child: Text(
                                            '$score runs',
                                            style: const TextStyle(
                                              color: Color(0xFFC2410C),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${events.length} result marker${events.length == 1 ? '' : 's'}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _BallTrail(
                                      events: events,
                                      ballsPerOver: ballsPerOver,
                                      legalBallsThisOver: events
                                          .where(
                                            (event) =>
                                                !event.label.startsWith('Wd') &&
                                                !event.label.startsWith('NB'),
                                          )
                                          .length,
                                      showTitle: false,
                                      dark: false,
                                      rebowlWides: _currentMatch.rebowlWides,
                                      rebowlNoBalls: _currentMatch.rebowlNoBalls,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scoreboard header
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreboardHeader extends StatelessWidget {
  final Innings innings;
  final MatchModel match;
  final List<_BallEvent> ballEvents;
  final VoidCallback onViewOvers;

  const _ScoreboardHeader({
    required this.innings,
    required this.match,
    required this.ballEvents,
    required this.onViewOvers,
  });

  @override
  Widget build(BuildContext context) {
    final ballsPerOver = match.ballsPerOver <= 0 ? 6 : match.ballsPerOver;
    final totalBalls = match.oversPerInnings * ballsPerOver;
    final ballsLeft = (totalBalls - innings.balls).clamp(0, totalBalls);
    final overs = innings.oversDisplayForMatch(ballsPerOver);
    final currentRunRate = innings.balls == 0
        ? 0
        : innings.runs / innings.balls * ballsPerOver;
    final target = innings.targetScore;
    final runsRequired = target > 0
        ? (target - innings.runs).clamp(0, target)
        : 0;
    final requiredRunRate = target > 0 && ballsLeft > 0
        ? runsRequired / ballsLeft * ballsPerOver
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF083F32), Color(0xFF111827), Color(0xFF241407)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.greenAccent.withValues(alpha: 0.28),
                  ),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Color(0xFF86EFAC),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$ballsLeft balls left',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${innings.runs}/${innings.wickets}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '$overs ov',
                  style: TextStyle(
                    color: Colors.orange.shade100,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: totalBalls == 0 ? 0 : innings.balls / totalBalls,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade300),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ScorePill(
                label: 'CRR',
                value: currentRunRate.toStringAsFixed(2),
                icon: Icons.speed,
              ),
              _ScorePill(
                label: 'This over',
                value: innings.currentBallText,
                icon: Icons.sports_baseball,
              ),
              if (target > 0)
                _ScorePill(
                  label: 'Need',
                  value: '$runsRequired runs',
                  icon: Icons.flag,
                ),
              if (target > 0)
                _ScorePill(
                  label: 'RRR',
                  value: requiredRunRate.toStringAsFixed(2),
                  icon: Icons.trending_up,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _BallTrail(
            events: ballEvents,
            ballsPerOver: ballsPerOver,
            legalBallsThisOver: innings.balls % ballsPerOver,
            rebowlWides: match.rebowlWides,
            rebowlNoBalls: match.rebowlNoBalls,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange.shade100,
              ),
              onPressed: onViewOvers,
              icon: const Icon(Icons.list_alt, size: 18),
              label: const Text('View overs'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recording ready panel
// ─────────────────────────────────────────────────────────────────────────────

class _RecordingReadyPanel extends StatelessWidget {
  final bool isHighlight;
  final ValueChanged<bool> onHighlightChanged;
  final VoidCallback? onPlayVideo;

  const _RecordingReadyPanel({
    required this.isHighlight,
    required this.onHighlightChanged,
    this.onPlayVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onPlayVideo,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE85D04).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE85D04).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.videocam_rounded,
                            color: Color(0xFFE85D04),
                            size: 28,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE85D04),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Recording ready',
                                style: TextStyle(
                                  color: Color(0xFF111827),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.play_circle_outline,
                                size: 16,
                                color: Color(0xFFE85D04),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap to preview video.',
                            style: TextStyle(
                              color: Color(0xFFE85D04),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Highlight saves this clip as an important moment.',
                            style: TextStyle(
                              color: Color(0xFF8A6A5C),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(value: isHighlight, onChanged: onHighlightChanged),
              const Text(
                'Highlight',
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ball event model + trail widget
// ─────────────────────────────────────────────────────────────────────────────

class _BallEvent {
  final String label;
  final Color color;
  final int overIndex;

  const _BallEvent({
    required this.label,
    required this.color,
    required this.overIndex,
  });

  factory _BallEvent.fromMap(Map<String, dynamic> map) {
    return _BallEvent(
      label: map['label'] as String? ?? '',
      color: Color(map['colorValue'] as int? ?? 0xFF475569),
      overIndex: map['overIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap({
    required String inningsId,
    required String actionId,
    required int sequence,
  }) {
    final timestamp = DateTime.now()
        .add(Duration(microseconds: sequence))
        .toIso8601String();
    return {
      'eventId': '$actionId-$sequence',
      'inningsId': inningsId,
      'actionId': actionId,
      'overIndex': overIndex,
      'label': label,
      'colorValue': color.toARGB32(),
      'createdAt': timestamp,
    };
  }
}

class _BallTrail extends StatelessWidget {
  final List<_BallEvent> events;
  final bool showTitle;
  final bool dark;
  final int ballsPerOver;
  final int legalBallsThisOver;
  final bool rebowlWides;
  final bool rebowlNoBalls;

  const _BallTrail({
    required this.events,
    this.showTitle = true,
    this.dark = true,
    this.ballsPerOver = 6,
    this.legalBallsThisOver = 0,
    this.rebowlWides = true,
    this.rebowlNoBalls = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayEvents = [...events];
    final extraEvents = displayEvents
        .where(
          (event) =>
              (event.label.startsWith('Wd') && rebowlWides) ||
              (event.label.startsWith('NB') && rebowlNoBalls),
        )
        .length;
    final targetSlots = <int>[
      6,
      ballsPerOver + extraEvents,
      displayEvents.length,
      legalBallsThisOver + extraEvents,
    ].reduce((value, element) => value > element ? value : element);

    while (displayEvents.length < targetSlots) {
      displayEvents.add(
        _BallEvent(
          label: '',
          color: Colors.white.withValues(alpha: 0.38),
          overIndex: 0,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle) ...[
          Text(
            'This over',
            style: TextStyle(
              color: dark
                  ? Colors.white.withValues(alpha: 0.72)
                  : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayEvents.map((event) {
            final isEmpty = event.label.isEmpty;
            return Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEmpty
                    ? Colors.white.withValues(alpha: 0.08)
                    : event.color.withValues(alpha: 0.18),
                border: Border.all(
                  color: isEmpty
                      ? Colors.white.withValues(alpha: 0.22)
                      : event.color.withValues(alpha: 0.72),
                ),
              ),
              child: Text(
                event.label,
                style: TextStyle(
                  color: isEmpty
                      ? Colors.transparent
                      : (dark ? Colors.white : event.color),
                  fontSize: event.label.length > 2 ? 10 : 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score pill
// ─────────────────────────────────────────────────────────────────────────────

class _ScorePill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ScorePill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.orange.shade200),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Run counter pad
// ─────────────────────────────────────────────────────────────────────────────

class _RunCounterPad extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onDot;
  final VoidCallback? onWide;
  final VoidCallback? onWideLongPress;
  final VoidCallback? onNoBall;
  final VoidCallback? onNoBallLongPress;
  final ValueChanged<int>? onRuns;
  final VoidCallback? onWicket;
  final VoidCallback? onWicketLongPress;

  const _RunCounterPad({
    required this.enabled,
    this.onDot,
    this.onWide,
    this.onWideLongPress,
    this.onNoBall,
    this.onNoBallLongPress,
    this.onRuns,
    this.onWicket,
    this.onWicketLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.55,
      children: [
        _CounterButton(
          label: 'Dot',
          icon: Icons.radio_button_unchecked,
          color: const Color(0xFF475569),
          onPressed: enabled ? onDot : null,
        ),
        _CounterButton(
          label: 'Wide',
          icon: Icons.swap_horiz,
          color: const Color(0xFF2563EB),
          onPressed: enabled ? onWide : null,
          onLongPress: enabled ? onWideLongPress : null,
        ),
        _CounterButton(
          label: 'No Ball',
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFF59E0B),
          onPressed: enabled ? onNoBall : null,
          onLongPress: enabled ? onNoBallLongPress : null,
        ),
        for (final runs in [1, 2, 3, 4, 6])
          _CounterButton(
            label: runs.toString(),
            icon: runs >= 4 ? Icons.bolt : Icons.add,
            color: runs >= 4
                ? const Color(0xFF16A34A)
                : const Color(0xFFE85D04),
            onPressed: enabled ? () => onRuns?.call(runs) : null,
          ),
        _CounterButton(
          label: 'Wicket',
          icon: Icons.close,
          color: const Color(0xFFDC2626),
          onPressed: enabled ? onWicket : null,
          onLongPress: enabled ? onWicketLongPress : null,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Counter button
// ─────────────────────────────────────────────────────────────────────────────

class _CounterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  const _CounterButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final borderColor = disabled
        ? Colors.grey.shade300
        : color.withValues(alpha: 0.18);
    final shadowColor = disabled
        ? Colors.grey.withValues(alpha: 0.08)
        : color.withValues(alpha: 0.12);
    final textColor = disabled ? Colors.grey.shade500 : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        onLongPress: onLongPress,
        child: Ink(
          decoration: BoxDecoration(
            color: disabled ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor, size: 20),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: textColor,
                      fontSize: label.length > 5 ? 14 : 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Premium First-Time Scoring Guide Dialog
// ─────────────────────────────────────────────────────────────────────────────

class _ScoringGuideDialog extends StatelessWidget {
  final VoidCallback onComplete;
  const _ScoringGuideDialog({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF083F32), // Dark Emerald Green
              Color(0xFF111827), // Deep Dark Gray
              Color(0xFF241407), // Deep Brown/Gold accent
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: const Color(0xFFFFBA08).withValues(alpha: 0.1), // Gold glow
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(
            color: const Color(0xFFFFBA08).withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFBA08).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sports_cricket, color: Color(0xFFFFBA08), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Scoring Guide',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Here is a quick breakdown of your scoring dashboard controls:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            // Guide list
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _guideItem(
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFF59E0B),
                      title: 'No Ball',
                      description: 'TAP to instantly add 1 extra run.\nLONG PRESS to specify Free Hit runs scored off the bat.',
                    ),
                    const SizedBox(height: 12),
                    _guideItem(
                      icon: Icons.swap_horiz,
                      color: const Color(0xFF2563EB),
                      title: 'Wide',
                      description: 'TAP to instantly add 1 extra run.\nLONG PRESS to specify additional runs (byes/boundaries).',
                    ),
                    const SizedBox(height: 12),
                    _guideItem(
                      icon: Icons.close,
                      color: const Color(0xFFDC2626),
                      title: 'Wicket',
                      description: 'TAP to record a standard 0-run wicket.\nLONG PRESS to add runs scored on the wicket ball.',
                    ),
                    const SizedBox(height: 12),
                    _guideItem(
                      icon: Icons.radio_button_unchecked,
                      color: const Color(0xFF475569),
                      title: 'Dot & Number Buttons',
                      description: 'TAP Dot for 0 runs off the bat.\nTAP numbers (1, 2, 3, 4, 6) to score standard runs.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Complete Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFBA08), // Gold
                foregroundColor: const Color(0xFF083F32), // Deep Emerald
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 3,
              ),
              onPressed: () {
                onComplete();
                Navigator.pop(context);
              },
              child: const Text(
                'Got It!',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _guideItem({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
