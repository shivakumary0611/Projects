import 'package:cric_snap/ballrecording/view.dart';
import 'package:cric_snap/innings/view_model.dart';
import 'package:cric_snap/teams/model.dart';
import 'package:cric_snap/teams/view_model.dart';
import 'package:cric_snap/widget/custom_app_bar.dart';
import 'package:cric_snap/widget/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RecordedInningsView extends StatefulWidget {
  const RecordedInningsView({super.key});

  @override
  State<RecordedInningsView> createState() => _RecordedInningsViewState();
}

class _RecordedInningsViewState extends State<RecordedInningsView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final inningsViewModel = context.read<InningsViewModel>();
      final teamViewModel = context.read<TeamViewModel>();

      await inningsViewModel.loadInnings();
      if (!mounted) return;
      await teamViewModel.loadTeams();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inningsViewModel = context.watch<InningsViewModel>();
    final teamViewModel = context.watch<TeamViewModel>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Recorded Innings'),
      body: inningsViewModel.innings.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.video_library,
              title: 'No Recorded Innings',
              subtitle: 'Start recording videos for innings.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: inningsViewModel.innings.length,
              itemBuilder: (context, index) {
                final innings = inningsViewModel.innings[index];

                Team? team;

                try {
                  team = teamViewModel.teams.firstWhere(
                    (team) => team.teamId == innings.teamId,
                  );
                } catch (_) {}

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BallRecordingView(innings: innings),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha((0.15 * 255).round()),
                            child: Text(
                              '${innings.runs}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
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
                                const SizedBox(height: 6),
                                Text(
                                  '${innings.runs}/${innings.wickets}',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Balls: ${innings.balls}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Target: ${innings.targetScore}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
