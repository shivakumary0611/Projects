import 'package:cric_snap/ballrecording/model.dart';
import 'package:cric_snap/ballrecording/view_model.dart';
import 'package:cric_snap/innings/model.dart';
import 'package:cric_snap/innings/over_history_sheet.dart';
import 'package:cric_snap/videoplayer/video_player.dart';
import 'package:cric_snap/widget/custom_app_bar.dart';
import 'package:cric_snap/widget/custom_button.dart';
import 'package:cric_snap/widget/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BallRecordingView extends StatefulWidget {
  final Innings innings;

  const BallRecordingView({super.key, required this.innings});

  @override
  State<BallRecordingView> createState() => _BallRecordingViewState();
}

class _BallRecordingViewState extends State<BallRecordingView> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<BallRecordingViewModel>().loadRecordings(
        widget.innings.inningsId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final recordingViewModel = context.watch<BallRecordingViewModel>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Ball Recordings'),
      body: recordingViewModel.recordings.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.video_library,
              title: 'No Recordings Found',
              subtitle: 'Record your first cricket ball video.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recordingViewModel.recordings.length,
              itemBuilder: (context, index) {
                final recording = recordingViewModel.recordings[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.play_circle_fill,
                                size: 40,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recording.overBallLabel,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      DeliveryTrail(
                                        events: [
                                          DeliveryEvent(
                                            label: recording.resultLabel,
                                            color: _resultColor(recording),
                                            overIndex: recording.overIndex,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _recordingSummary(recording),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    DateFormat(
                                      'dd MMM yyyy, hh:mm a',
                                    ).format(recording.createdAt),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (recording.isWicket)
                              Chip(
                                label: const Text('Wicket'),
                                backgroundColor: Colors.red.shade100,
                              ),
                            if (recording.isHighlight)
                              Chip(
                                label: const Text('Highlight'),
                                backgroundColor: Colors.orange.shade100,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final shouldDelete = await showDialog<bool>(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Delete Recording'),
                                        content: const Text(
                                          'Are you sure you want to delete this recording?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context, false);
                                            },
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.pop(context, true);
                                            },
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (shouldDelete == true) {
                                    await recordingViewModel.deleteRecording(
                                      recording.recordingId,
                                      widget.innings.inningsId,
                                    );
                                  }
                                },
                                icon: const Icon(Icons.delete),
                                label: const Text('Delete'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: CustomButton(
                                title: 'Play Video',
                                icon: Icons.play_arrow,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => VideoPlayerView(
                                        videoPath: recording.videoPath,
                                        title: recording.overBallLabel,
                                        subtitle: _recordingSummary(recording),
                                        resultLabel: recording.resultLabel,
                                        resultColor: _resultColor(recording),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _recordingSummary(BallRecording recording) {
    if (recording.isWicket) return 'Wicket';
    if (recording.extraType == 'Wide') {
      return recording.runs > 0
          ? 'Wide + ${recording.runs} extra runs'
          : 'Wide';
    }
    if (recording.extraType == 'No Ball') {
      return recording.runs > 0
          ? 'No Ball + ${recording.runs} off bat'
          : 'No Ball';
    }
    return recording.runs == 0 ? 'Dot ball' : '${recording.runs} runs';
  }

  Color _resultColor(BallRecording recording) {
    if (recording.isWicket) return const Color(0xFFDC2626);
    if (recording.extraType == 'Wide') return const Color(0xFF2563EB);
    if (recording.extraType == 'No Ball') return const Color(0xFFF59E0B);
    if (recording.runs >= 4) return const Color(0xFF16A34A);
    return const Color(0xFFE85D04);
  }
}
