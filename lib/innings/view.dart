import 'dart:io';

import 'package:cric_snap/camera/createRecordingview.dart';
import 'package:cric_snap/innings/innings_display_order.dart';
import 'package:cric_snap/innings/model.dart';
import 'package:cric_snap/innings/over_history_sheet.dart';
import 'package:cric_snap/innings/view_model.dart';
import 'package:cric_snap/match/model.dart';
import 'package:cric_snap/match/view_model.dart';
import 'package:cric_snap/ballrecording/view.dart';
import 'package:cric_snap/teams/model.dart';
import 'package:cric_snap/teams/view_model.dart';
import 'package:cric_snap/widget/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class InningsView extends StatefulWidget {
  final MatchModel match;

  const InningsView({super.key, required this.match});

  @override
  State<InningsView> createState() => _InningsViewState();
}

class _InningsViewState extends State<InningsView> {
  MatchModel get _currentMatch {
    try {
      final vm = context.read<MatchesViewModel>();
      return vm.matches.firstWhere((m) => m.matchId == widget.match.matchId);
    } catch (_) {
      return widget.match;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final inningsViewModel = context.read<InningsViewModel>();
      final teamViewModel = context.read<TeamViewModel>();
      final matchesViewModel = context.read<MatchesViewModel>();

      await inningsViewModel.loadInnings();
      if (!mounted) return;
      await teamViewModel.loadTeams();
      if (!mounted) return;
      await matchesViewModel.loadMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inningsViewModel = context.watch<InningsViewModel>();
    final teamViewModel = context.watch<TeamViewModel>();
    context.watch<MatchesViewModel>();

    final match = _currentMatch;
    final allInnings = inningsViewModel.innings
        .where((i) => i.matchId == match.matchId)
        .toList();
    sortInningsForMatchDisplay(allInnings, match);

    final isMatchComplete =
        allInnings.length == 2 && allInnings.every((i) => i.isCompleted);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Innings'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isMatchComplete ? null : () => _addInnings(context, match),
        icon: const Icon(Icons.add),
        label: Text(isMatchComplete ? 'Match Complete' : 'Add Innings'),
      ),
      body: allInnings.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No innings yet.\nTap + Add Innings to begin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: allInnings.length,
              itemBuilder: (context, index) {
                final innings = allInnings[index];
                Team? team;
                try {
                  team = teamViewModel.teams.firstWhere(
                    (t) => t.teamId == innings.teamId,
                  );
                } catch (_) {}

                return _InningsCard(
                  innings: innings,
                  match: match,
                  team: team,
                  onStartScoring: () => _openScoring(context, innings, match),
                  onViewOvers: () => showOverHistorySheet(
                    context: context,
                    inningsId: innings.inningsId,
                  ),
                  onEdit: () => _editInnings(context, innings),
                  onDelete: () => _deleteInnings(context, innings),
                  onViewRecordings: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BallRecordingView(innings: innings),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  // ── Add innings ────────────────────────────────────────────────────────────

  Future<void> _addInnings(BuildContext context, MatchModel match) async {
    final teamViewModel = context.read<TeamViewModel>();
    final inningsViewModel = context.read<InningsViewModel>();

    final matchInnings = inningsViewModel.innings
        .where((i) => i.matchId == match.matchId)
        .toList();

    if (matchInnings.length == 2 && matchInnings.every((i) => i.isCompleted)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Match is complete. Both innings have finished.'),
        ),
      );
      return;
    }

    final existingTeamIds = matchInnings.map((i) => i.teamId).toSet();

    final candidates = teamViewModel.teams
        .where(
          (t) => t.teamId == match.homeTeamId || t.teamId == match.awayTeamId,
        )
        .toList();

    final available = candidates
        .where((t) => !existingTeamIds.contains(t.teamId))
        .toList();

    if (available.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Both teams already have an innings.')),
      );
      return;
    }

    Team? chosen;
    if (available.length == 1) {
      chosen = available.first;
    } else {
      if (!mounted) return;
      chosen = await showDialog<Team>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Choose batting team'),
          children: available
              .map(
                (t) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, t),
                  child: Text(t.teamName),
                ),
              )
              .toList(),
        ),
      );
    }

    if (chosen == null || !mounted) return;

    final newInnings = Innings(matchId: match.matchId, teamId: chosen.teamId);
    await inningsViewModel.addInnings(newInnings);
  }

  // ── Open scoring page ──────────────────────────────────────────────────────

  void _openScoring(BuildContext context, Innings innings, MatchModel match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateRecordingView(innings: innings, match: match),
      ),
    ).then((_) {
      if (context.mounted) {
        context.read<InningsViewModel>().loadInnings();
        context.read<MatchesViewModel>().loadMatches();
      }
    });
  }

  // ── Edit innings ───────────────────────────────────────────────────────────

  Future<void> _editInnings(BuildContext context, Innings innings) async {
    final runsController = TextEditingController(text: innings.runs.toString());
    final wicketsController =
        TextEditingController(text: innings.wickets.toString());
    final ballsController =
        TextEditingController(text: innings.balls.toString());
    final targetController = TextEditingController(
      text: innings.targetScore > 0 ? innings.targetScore.toString() : '0',
    );

    void disposeControllers() {
      runsController.dispose();
      wicketsController.dispose();
      ballsController.dispose();
      targetController.dispose();
    }

    final result = await showDialog<Innings>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Innings Data'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: runsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Runs Scored'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: wicketsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Wickets Lost'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ballsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Total Balls'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Target Score (0=none)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final r = int.tryParse(runsController.text.trim()) ?? 0;
              final w = int.tryParse(wicketsController.text.trim()) ?? 0;
              final b = int.tryParse(ballsController.text.trim()) ?? 0;
              final t = int.tryParse(targetController.text.trim()) ?? 0;

              Navigator.pop(
                ctx,
                Innings(
                  inningsId: innings.inningsId,
                  matchId: innings.matchId,
                  teamId: innings.teamId,
                  runs: r,
                  wickets: w,
                  balls: b,
                  targetScore: t,
                  isCompleted: innings.isCompleted,
                  createdAt: innings.createdAt,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    // ✅ Dispose AFTER dialog is fully closed — prevents "used after dispose" crash
    disposeControllers();

    if (result == null || !context.mounted) return;
    await context.read<InningsViewModel>().updateInnings(result);
  }

  // ── Delete innings ─────────────────────────────────────────────────────────

  Future<void> _deleteInnings(BuildContext context, Innings innings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete innings?'),
        content: const Text(
          'This will permanently delete the innings and its data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await context.read<InningsViewModel>().deleteInnings(innings.inningsId);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Innings card
// ─────────────────────────────────────────────────────────────────────────────

class _InningsCard extends StatelessWidget {
  final Innings innings;
  final MatchModel match;
  final Team? team;
  final VoidCallback onStartScoring;
  final VoidCallback onViewOvers;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewRecordings;

  const _InningsCard({
    required this.innings,
    required this.match,
    required this.team,
    required this.onStartScoring,
    required this.onViewOvers,
    required this.onEdit,
    required this.onDelete,
    required this.onViewRecordings,
  });

  bool _isComplete() {
    if (innings.wickets >= 10) return true;
    final bpo = match.ballsPerOver <= 0 ? 6 : match.ballsPerOver;
    final maxBalls = match.oversPerInnings * bpo;
    return innings.isCompleted && innings.balls >= maxBalls;
  }

  @override
  Widget build(BuildContext context) {
    final complete = _isComplete();
    final live = !complete;

    final hasWinner = (match.winnerTeamName ?? '').isNotEmpty;

    final bpo = match.ballsPerOver <= 0 ? 6 : match.ballsPerOver;
    final overs = innings.oversDisplayForMatch(bpo);
    final initials = (team?.teamName ?? '?')
        .trim()
        .split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join();

    final target = innings.targetScore;
    final runsNeeded = target > 0
        ? (target - innings.runs).clamp(0, target)
        : 0;

    final cardBorderColor = live ? Colors.orange.shade300 : Colors.green.shade300;
    final badgeColor = live ? Colors.orange.shade100 : Colors.green.shade100;
    final badgeTextColor = live ? Colors.orange.shade800 : Colors.green.shade800;

    String badgeLabel;
    Color? badgeLabelColor;
    if (live) {
      badgeLabel = 'LIVE';
    } else if (hasWinner) {
      if (match.winnerTeamName == 'Match Tied') {
        badgeLabel = 'TIED';
        badgeLabelColor = Colors.amber.shade800;
      } else if (match.winnerTeamName == team?.teamName) {
        badgeLabel = 'WON ✓';
        badgeLabelColor = Colors.green.shade800;
      } else {
        badgeLabel = 'LOST';
        badgeLabelColor = Colors.red.shade800;
      }
    } else {
      badgeLabel = 'COMPLETED';
    }

    final finalBadgeTextColor = badgeLabelColor ?? badgeTextColor;
    final avatarColor = live ? Colors.orange.shade100 : Colors.green.shade50;
    final avatarTextColor = live ? Colors.orange.shade700 : Colors.green.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: avatarColor,
                  backgroundImage: team?.teamLogo != null
                      ? FileImage(File(team!.teamLogo!))
                      : null,
                  child: team?.teamLogo == null
                      ? Text(
                          initials,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: avatarTextColor,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team?.teamName ?? 'Unknown Team',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${innings.runs}/${innings.wickets} - $overs Overs',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badgeLabel,
                    style: TextStyle(
                      color: finalBadgeTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Stats row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  _StatCell(
                    icon: Icons.sports_cricket,
                    value: '${innings.runs}',
                    label: 'Runs',
                  ),
                  _StatCell(
                    icon: Icons.close,
                    value: '${innings.wickets}',
                    label: 'Wickets',
                  ),
                  _StatCell(
                    icon: Icons.sports_baseball,
                    value: '${innings.balls}',
                    label: 'Balls',
                  ),
                  _StatCell(
                    icon: Icons.flag,
                    value: target > 0 ? '$target' : '0',
                    label: 'Target',
                  ),
                ],
              ),
            ),
          ),

          // ── Chase info / Match Result ─────────────────────────────────────
          if (hasWinner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                match.winnerTeamName == 'Match Tied'
                    ? '🎭 Match Tied'
                    : match.winnerTeamName == team?.teamName
                    ? '🏆 ${team?.teamName} won!'
                    : '❌ ${match.winnerTeamName} won',
                style: TextStyle(
                  color: match.winnerTeamName == 'Match Tied'
                      ? Colors.amber.shade700
                      : match.winnerTeamName == team?.teamName
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            )
          else if (target > 0 && live)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Need $runsNeeded more to win',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // ── View Overs button ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewOvers,
                icon: const Icon(Icons.trending_up, size: 18),
                label: const Text('View Overs'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade700,
                  side: BorderSide(color: Colors.orange.shade200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Edit / Delete row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Start Scoring button ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: hasWinner ? null : onStartScoring,
                icon: const Icon(Icons.sports_cricket),
                label: Text(
                  hasWinner
                      ? 'Match Complete'
                      : live
                      ? 'Start Scoring'
                      : 'View / Resume Scoring',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasWinner
                      ? Colors.grey.shade400
                      : live
                      ? Colors.orange.shade700
                      : Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── View Recordings button ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onViewRecordings,
                icon: const Icon(Icons.play_circle_outline),
                label: const Text('View Recordings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat cell
// ─────────────────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.orange, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}