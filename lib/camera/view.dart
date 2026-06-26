import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cric_snap/database/databaseHelper.dart';
import 'package:cric_snap/innings/model.dart';
import 'package:cric_snap/match/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class CameraRecordingView extends StatefulWidget {
  final Innings innings;
  final MatchModel matchModel;

  const CameraRecordingView({
    super.key,
    required this.innings,
    required this.matchModel,
  });

  @override
  State<CameraRecordingView> createState() => _CameraRecordingViewState();
}

class _CameraRecordingViewState extends State<CameraRecordingView> {
  CameraController? _controller;
  bool _isRecording = false;
  bool _isBusy = false;
  bool _isFlashOn = false;
  int _selectedCameraIndex = 0;
  int _recordDuration = 0;
  late Innings _displayInnings;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _displayInnings = widget.innings;
    _refreshInningsFromDb();
    _initializeCamera();
  }

  Future<void> _refreshInningsFromDb() async {
    final latest = await DatabaseHelper.instance.getInningsById(
      widget.innings.inningsId,
    );
    if (!mounted || latest == null) return;
    setState(() {
      _displayInnings = latest;
    });
  }

  Future<void> _initializeCamera() async {
    if (_cameras.isEmpty) {
      try {
        _cameras = await availableCameras();
      } catch (e) {
        debugPrint('Error getting available cameras: $e');
      }
    }

    if (_cameras.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No camera available on this device.')),
        );
      }
      return;
    }

    _controller = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
    );
    try {
      await _controller!.initialize();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
      return;
    }
    if (!mounted) return;
    final lock = widget.matchModel.recordOrientation == 'Landscape'
        ? DeviceOrientation.landscapeLeft
        : DeviceOrientation.portraitUp;
    try {
      await _controller!.lockCaptureOrientation(lock);
    } catch (_) {
      // Lock is unsupported on some devices; recording still proceeds.
    }
    setState(() {});
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    _isFlashOn = !_isFlashOn;
    await _controller!.setFlashMode(
      _isFlashOn ? FlashMode.torch : FlashMode.off,
    );
    setState(() {});
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = _selectedCameraIndex == 0 ? 1 : 0;
    await _controller?.dispose();
    await _initializeCamera();
  }

  Future<void> _startRecording() async {
    if (_isBusy) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isRecordingVideo) return;

    setState(() {
      _isBusy = true;
    });

    try {
      await _refreshInningsFromDb();
      if (!mounted) return;
      await _controller!.startVideoRecording();

      setState(() {
        _isRecording = true;
        _recordDuration = 0;
        _isBusy = false;
      });

      // Start timer
      _startTimer();
    } catch (e) {
      setState(() {
        _isBusy = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_isRecording) return false;
      setState(() {
        _recordDuration++;
      });
      return true;
    });
  }

  Future<void> _stopRecording() async {
    if (_isBusy) return;
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (!_controller!.value.isRecordingVideo) return;

    setState(() {
      _isBusy = true;
      _isRecording = false;
      _recordDuration = 0;
    });

    try {
      final file = await _controller!.stopVideoRecording();

      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(file.path);
      final savedFile = await File(file.path).copy('${appDir.path}/$fileName');

      if (!mounted) return;

      setState(() {
        _isBusy = false;
      });

      Navigator.pop(context, savedFile.path);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to stop recording: $e'),
        ),
      );
    }
  }

  String get formattedTime {
    final minutes = (_recordDuration ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordDuration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0, 0.42, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CameraToolButton(
                        icon: Icons.arrow_back,
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: _ScoreHud(
                            innings: _displayInnings,
                            ballsPerOver: widget.matchModel.ballsPerOver,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _CameraToolButton(
                            icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            onPressed: _toggleFlash,
                          ),
                          const SizedBox(height: 10),
                          _CameraToolButton(
                            icon: Icons.flip_camera_ios,
                            onPressed: _switchCamera,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.32),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.fiber_manual_record,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'REC $formattedTime',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_isBusy && !_isRecording)
                    const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Text(
                              'Balls left this over: ${_displayInnings.ballsRemainingThisOver(ballsPerOver: widget.matchModel.ballsPerOver)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              if (_isBusy) return;
                              if (_isRecording) {
                                await _stopRecording();
                              } else {
                                await _startRecording();
                              }
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (_isRecording
                                                    ? Colors.red
                                                    : Colors.white)
                                                .withValues(alpha: 0.22),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: _isRecording ? 28 : 58,
                                      height: _isRecording ? 28 : 58,
                                      decoration: BoxDecoration(
                                        color: _isRecording
                                            ? Colors.red
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          _isRecording ? 6 : 29,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _isRecording ? 'Stop' : 'Record',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraToolButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CameraToolButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.46),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: Colors.white, size: 25),
        ),
      ),
    );
  }
}

/// Live score overlay: current totals and which delivery this clip is for.
class _ScoreHud extends StatelessWidget {
  final Innings innings;
  final int ballsPerOver;

  const _ScoreHud({required this.innings, required this.ballsPerOver});

  @override
  Widget build(BuildContext context) {
    final overs = innings.oversDisplayForMatch(
      ballsPerOver > 0 ? ballsPerOver : 6,
    );
    final line = '${innings.runs}/${innings.wickets} ${overs}ov';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black.withValues(alpha: 0.62),
            Colors.black.withValues(alpha: 0.42),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            line,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            innings.currentBallText,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade200,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
