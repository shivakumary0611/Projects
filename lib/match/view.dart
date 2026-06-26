import 'dart:io';
import 'package:cric_snap/innings/model.dart';
import 'package:cric_snap/match/model.dart';
import 'package:cric_snap/innings/view.dart';
import 'package:cric_snap/innings/view_model.dart';
import 'package:cric_snap/match/view_model.dart';
import 'package:cric_snap/teams/model.dart';
import 'package:cric_snap/teams/view.dart';
import 'package:cric_snap/teams/view_model.dart';
import 'package:cric_snap/widget/custom_text_field.dart';
import 'package:cric_snap/widget/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// Lightweight, self-contained match view helpers used by the app.
// This file intentionally exposes only UI components; higher-level
// screens should call `_showEditMatchBottomSheet` when needed.

class MatchesView extends StatefulWidget {
  const MatchesView({super.key});

  @override
  State<MatchesView> createState() => _MatchesViewState();
}

class _MatchesViewState extends State<MatchesView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final matchesViewModel = context.read<MatchesViewModel>();
      final teamViewModel = context.read<TeamViewModel>();
      final inningsViewModel = context.read<InningsViewModel>();

      await matchesViewModel.loadMatches();
      if (!mounted) return;
      await teamViewModel.loadTeams();
      if (!mounted) return;
      await inningsViewModel.loadInnings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final matchesViewModel = context.watch<MatchesViewModel>();
    final teamViewModel = context.watch<TeamViewModel>();
    final inningsViewModel = context.watch<InningsViewModel>();

    final matches = matchesViewModel.matches;

    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: matches.isEmpty
          ? const Center(child: Text('No matches found.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: matches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final match = matches[index];
                Team? homeTeam;
                Team? awayTeam;
                try {
                  homeTeam = teamViewModel.teams.firstWhere(
                    (team) => team.teamId == match.homeTeamId,
                  );
                } catch (_) {}
                try {
                  awayTeam = teamViewModel.teams.firstWhere(
                    (team) => team.teamId == match.awayTeamId,
                  );
                } catch (_) {}

                final matchInnings = inningsViewModel.innings
                    .where((innings) => innings.matchId == match.matchId)
                    .toList();

                return _MatchCard(
                  match: match,
                  homeTeam: homeTeam,
                  awayTeam: awayTeam,
                  homeScore: match.homeTeamScore ?? '0/0',
                  awayScore: match.awayTeamScore ?? '0/0',
                  homeOvers: match.homeTeamOvers ?? '0.0',
                  awayOvers: match.awayTeamOvers ?? '0.0',
                  onEdit: () {
                    _showEditMatchBottomSheet(
                      context,
                      match: match,
                      homeTeam: homeTeam,
                      awayTeam: awayTeam,
                      matchInnings: matchInnings,
                    );
                  },
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Delete match'),
                        content: const Text('Delete this match permanently?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(dialogContext, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true || !context.mounted) return;
                    await context.read<MatchesViewModel>().deleteMatch(
                      match.matchId,
                    );
                  },
                  onOpen: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InningsView(match: match),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _EditMatchSheet extends StatefulWidget {
  final MatchModel match;
  final Team? homeTeam;
  final Team? awayTeam;
  final List<Innings> matchInnings;
  final BuildContext rootContext;

  const _EditMatchSheet({
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
    required this.matchInnings,
    required this.rootContext,
  });

  @override
  State<_EditMatchSheet> createState() => _EditMatchSheetState();
}

class _EditMatchSheetState extends State<_EditMatchSheet> {
  late TextEditingController oversController;
  late TextEditingController ballsPerOverController;
  late bool rebowlWides;
  late bool rebowlNoBalls;
  late String orientation;
  Team? home;
  Team? away;

  @override
  void initState() {
    super.initState();
    oversController = TextEditingController(
      text: widget.match.oversPerInnings.toString(),
    );
    ballsPerOverController = TextEditingController(
      text: widget.match.ballsPerOver.toString(),
    );
    rebowlWides = widget.match.rebowlWides;
    rebowlNoBalls = widget.match.rebowlNoBalls;
    orientation = widget.match.recordOrientation;
    home = widget.homeTeam;
    away = widget.awayTeam;
  }

  @override
  void dispose() {
    oversController.dispose();
    ballsPerOverController.dispose();
    super.dispose();
  }

  void showError(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: widget.rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scoringStarted = widget.matchInnings.any(
      (i) => i.balls > 0 || i.runs > 0 || i.wickets > 0 || i.isCompleted,
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Edit Match',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (scoringStarted)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'Teams are locked because scoring has started for this match.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.35,
                  ),
                ),
              ),
            _TeamPickerTile(
              label: 'Select Home Team',
              selectedTeam: home,
              locked: scoringStarted && home != null,
              onChoose: () async {
                final selected = await showDialog<Team>(
                  context: context,
                  builder: (_) =>
                      Dialog(child: TeamView(isSelectionMode: true)),
                );
                if (selected == null) return;
                if (selected.teamId == away?.teamId) {
                  showError('Home and away teams cannot be the same.');
                  return;
                }
                setState(() => home = selected);
              },
            ),
            const SizedBox(height: 14),
            _TeamPickerTile(
              label: 'Select Away Team',
              selectedTeam: away,
              locked: scoringStarted && away != null,
              onChoose: () async {
                final selected = await showDialog<Team>(
                  context: context,
                  builder: (_) =>
                      Dialog(child: TeamView(isSelectionMode: true)),
                );
                if (selected == null) return;
                if (selected.teamId == home?.teamId) {
                  showError('Home and away teams cannot be the same.');
                  return;
                }
                setState(() => away = selected);
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: oversController,
                    hint: 'Overs per innings',
                    prefixIcon: Icons.sports_score,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
            const SizedBox(height: 14),
            SwitchListTile(
              value: rebowlWides,
              onChanged: (v) => setState(() => rebowlWides = v),
              title: const Text('Re-Bowl Wides'),
            ),
            SwitchListTile(
              value: rebowlNoBalls,
              onChanged: (v) => setState(() => rebowlNoBalls = v),
              title: const Text('Re-Bowl No Balls'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: orientation,
              decoration: const InputDecoration(
                labelText: 'Recording orientation',
                helperText:
                    'Used when you record video from an innings (portrait vs landscape).',
              ),
              items: ['Portrait', 'Landscape']
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => orientation = value!),
            ),
            const SizedBox(height: 24),
            CustomButton(
              title: 'Save Changes',
              icon: Icons.save,
              onPressed: () async {
                if (home == null || away == null) {
                  showError('Both home and away teams are required.');
                  return;
                }
                if (home!.teamId == away!.teamId) {
                  showError('Home and away teams cannot be the same.');
                  return;
                }
                final oText = oversController.text.trim();
                final bpoText = ballsPerOverController.text.trim();

                if (oText.isEmpty) {
                  showError('Please enter number of overs.');
                  return;
                }
                final newOvers = int.tryParse(oText);
                if (newOvers == null || newOvers <= 0) {
                  showError('Please enter a valid number of overs.');
                  return;
                }

                if (bpoText.isEmpty) {
                  showError('Please enter balls per over.');
                  return;
                }
                final newBpo = int.tryParse(bpoText);
                if (newBpo == null || newBpo <= 0) {
                  showError('Please enter a valid balls per over.');
                  return;
                }

                final cap = newOvers * newBpo;
                for (final inn in widget.matchInnings) {
                  if (inn.balls > cap) {
                    showError(
                      'At least one innings has already exceeded the new limit ($newOvers overs of $newBpo balls). '
                      'Choose a higher limit or undo balls in that innings.',
                    );
                    return;
                  }
                }

                final updated = MatchModel(
                  matchId: widget.match.matchId,
                  homeTeamId: home!.teamId,
                  awayTeamId: away!.teamId,
                  oversPerInnings: newOvers,
                  ballsPerOver: newBpo,
                  rebowlWides: rebowlWides,
                  rebowlNoBalls: rebowlNoBalls,
                  recordOrientation: orientation,
                  createdAt: widget.match.createdAt,
                  homeTeamScore: widget.match.homeTeamScore,
                  awayTeamScore: widget.match.awayTeamScore,
                  homeTeamOvers: widget.match.homeTeamOvers,
                  awayTeamOvers: widget.match.awayTeamOvers,
                  winnerTeamName: widget.match.winnerTeamName,
                );

                if (mounted) Navigator.pop(context);

                final inningsVm = widget.rootContext.read<InningsViewModel>();
                await widget.rootContext.read<MatchesViewModel>().updateMatch(
                  updated,
                  inningsViewModel: inningsVm,
                );
                // loadInnings already called inside updateMatch when overs changed;
                // call again to be safe in all cases.
                try {
                  await inningsVm.loadInnings();
                } catch (_) {}

                if (widget.rootContext.mounted) {
                  ScaffoldMessenger.of(widget.rootContext).showSnackBar(
                    const SnackBar(
                      content: Text('Match updated.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Helper: show an edit bottom sheet that uses the above widget.
void _showEditMatchBottomSheet(
  BuildContext rootContext, {
  required MatchModel match,
  required Team? homeTeam,
  required Team? awayTeam,
  required List<Innings> matchInnings,
}) {
  showModalBottomSheet<void>(
    context: rootContext,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _EditMatchSheet(
      match: match,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      matchInnings: matchInnings,
      rootContext: rootContext,
    ),
  );
}

// ─── Match Card Widget ──────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final MatchModel match;
  final Team? homeTeam;
  final Team? awayTeam;
  final String homeScore;
  final String awayScore;
  final String homeOvers;
  final String awayOvers;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  const _MatchCard({
    required this.match,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.homeOvers,
    required this.awayOvers,
    required this.onEdit,
    required this.onDelete,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final hasWinner = (match.winnerTeamName ?? '').isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      shadowColor: Colors.black12,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd MMM yyyy, hh:mm a').format(match.createdAt),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${match.oversPerInnings} Overs',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.orange.shade800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _TeamScoreColumn(
                      team: homeTeam,
                      score: homeScore,
                      overs: homeOvers,
                      isHome: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'VS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.grey.shade600,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _TeamScoreColumn(
                      team: awayTeam,
                      score: awayScore,
                      overs: awayOvers,
                      isHome: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (hasWinner)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      match.winnerTeamName == 'Match Tied'
                          ? 'Match Tied'
                          : '${match.winnerTeamName} won the match',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DetailChip(
                    icon: Icons.sports_baseball_outlined,
                    label: '${match.ballsPerOver} balls/over',
                  ),
                ),
                Expanded(
                  child: _DetailChip(
                    icon: match.rebowlWides
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    label: 'Wide re-bowl',
                    active: match.rebowlWides,
                  ),
                ),
                Expanded(
                  child: _DetailChip(
                    icon: match.rebowlNoBalls
                        ? Icons.check_circle_outline
                        : Icons.cancel_outlined,
                    label: 'No-ball re-bowl',
                    active: match.rebowlNoBalls,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                OutlinedButton(
                  onPressed: hasWinner ? null : onEdit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: Icon(
                    hasWinner ? Icons.lock : Icons.edit_outlined,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(48, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Icon(Icons.delete_outline, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    title: 'Open Match',
                    icon: Icons.arrow_forward,
                    onPressed: onOpen,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamScoreColumn extends StatelessWidget {
  final Team? team;
  final String score;
  final String overs;
  final bool isHome;

  const _TeamScoreColumn({
    required this.team,
    required this.score,
    required this.overs,
    required this.isHome,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHome ? Colors.deepOrange : Colors.indigo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.08),
            backgroundImage: team?.teamLogo != null
                ? FileImage(File(team!.teamLogo!))
                : null,
            child: team?.teamLogo == null
                ? Icon(Icons.groups, color: color, size: 26)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          team?.teamName ?? 'Unknown',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            isHome ? 'HOME' : 'AWAY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          score,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          overs,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool? active;
  const _DetailChip({required this.icon, required this.label, this.active});

  @override
  Widget build(BuildContext context) {
    final Color iconColor = active == null
        ? Colors.grey.shade600
        : (active! ? Colors.green.shade600 : Colors.red.shade400);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _TeamPickerTile extends StatelessWidget {
  final String label;
  final Team? selectedTeam;
  final bool locked;
  final VoidCallback onChoose;

  const _TeamPickerTile({
    required this.label,
    required this.selectedTeam,
    required this.onChoose,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedTeam == null ? label : selectedTeam!.teamName,
              style: TextStyle(
                fontSize: 16,
                color: selectedTeam == null
                    ? Colors.grey.shade600
                    : Colors.black,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: locked ? null : onChoose,
            icon: const Icon(Icons.groups),
            label: const Text('Choose'),
          ),
        ],
      ),
    );
  }
}
