import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerView extends StatefulWidget {
  final String videoPath;
  final String title;
  final String subtitle;
  final String? resultLabel;
  final Color? resultColor;

  const VideoPlayerView({
    super.key,
    required this.videoPath,
    required this.title,
    required this.subtitle,
    this.resultLabel,
    this.resultColor,
  });

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  VideoPlayerController? _controller;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  double playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    initializeVideo();
  }

  Future<void> initializeVideo() async {
    try {
      final file = File(widget.videoPath);

      if (!file.existsSync()) {
        setState(() {
          hasError = true;
          errorMessage = 'Video file not found';
          isLoading = false;
        });
        return;
      }

      _controller = VideoPlayerController.file(file);

      await _controller!.initialize();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    final minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Playback'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : hasError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (widget.resultLabel != null) ...[
                                Container(
                                  width: 30,
                                  height: 30,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        widget.resultColor ??
                                        const Color(0xFFE85D04),
                                  ),
                                  child: Text(
                                    widget.resultLabel!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
                              Expanded(
                                child: Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ValueListenableBuilder(
                                valueListenable: _controller!,
                                builder: (context, VideoPlayerValue value, _) {
                                  return Text(
                                    formatDuration(value.position),
                                  );
                                },
                              ),
                              Text(
                                formatDuration(
                                  _controller!.value.duration,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Playback Speed',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<double>(
                                  value: playbackSpeed,
                                  underline: const SizedBox(),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 0.25,
                                      child: Text('0.25x'),
                                    ),
                                    DropdownMenuItem(
                                      value: 0.5,
                                      child: Text('0.5x'),
                                    ),
                                    DropdownMenuItem(
                                      value: 0.75,
                                      child: Text('0.75x'),
                                    ),
                                    DropdownMenuItem(
                                      value: 1.0,
                                      child: Text('1x'),
                                    ),
                                    DropdownMenuItem(
                                      value: 1.5,
                                      child: Text('1.5x'),
                                    ),
                                    DropdownMenuItem(
                                      value: 2.0,
                                      child: Text('2x'),
                                    ),
                                  ],
                                  onChanged: (value) async {
                                    if (value == null) return;

                                    setState(() {
                                      playbackSpeed = value;
                                    });

                                    await _controller!.setPlaybackSpeed(value);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () async {
                                  final current =
                                      await _controller!.position ??
                                          Duration.zero;

                                  final newPosition =
                                      current - const Duration(seconds: 10);

                                  await _controller!.seekTo(
                                    newPosition < Duration.zero
                                        ? Duration.zero
                                        : newPosition,
                                  );
                                },
                                icon: const Icon(Icons.replay_10),
                                iconSize: 34,
                              ),
                              const SizedBox(width: 20),
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.orange,
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      if (_controller!.value.isPlaying) {
                                        _controller!.pause();
                                      } else {
                                        _controller!.play();
                                      }
                                    });
                                  },
                                  icon: Icon(
                                    _controller!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                  ),
                                  iconSize: 36,
                                ),
                              ),
                              const SizedBox(width: 20),
                              IconButton(
                                onPressed: () async {
                                  final current =
                                      await _controller!.position ??
                                          Duration.zero;

                                  final duration =
                                      _controller!.value.duration;

                                  final newPosition =
                                      current + const Duration(seconds: 10);

                                  await _controller!.seekTo(
                                    newPosition > duration
                                        ? duration
                                        : newPosition,
                                  );
                                },
                                icon: const Icon(Icons.forward_10),
                                iconSize: 34,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
