import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;
  Timer? _timer;
  int _elapsedSeconds = 0;
  
  final StreamController<int> _durationController = StreamController<int>.broadcast();
  Stream<int> get durationStream => _durationController.stream;
  int get elapsedSeconds => _elapsedSeconds;

  /// Check and request runtime microphone and storage permissions.
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      return true;
    }
    return false;
  }

  /// Check if microphone permission is permanently denied.
  Future<bool> isPermissionPermanentlyDenied() async {
    return await Permission.microphone.isPermanentlyDenied;
  }

  /// Open device app settings.
  Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// Start recording audio live to a local temporary file.
  Future<String?> startRecording() async {
    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      throw Exception('Microphone permission is required to record audio.');
    }

    if (await _audioRecorder.isRecording()) {
      await stopRecording();
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/lungsense_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentRecordingPath = filePath;

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 128000,
    );

    await _audioRecorder.start(config, path: filePath);

    _elapsedSeconds = 0;
    _durationController.add(0);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _durationController.add(_elapsedSeconds);
    });

    return filePath;
  }

  /// Pause current active recording.
  Future<void> pauseRecording() async {
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.pause();
      _timer?.cancel();
    }
  }

  /// Resume recording after pause.
  Future<void> resumeRecording() async {
    if (await _audioRecorder.isPaused()) {
      await _audioRecorder.resume();
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _elapsedSeconds++;
        _durationController.add(_elapsedSeconds);
      });
    }
  }

  /// Stop current recording and return the completed audio file path.
  Future<String?> stopRecording() async {
    _timer?.cancel();
    final path = await _audioRecorder.stop();
    _currentRecordingPath = null;
    return path;
  }

  /// Cancel and discard the current recording file.
  Future<void> cancelRecording() async {
    _timer?.cancel();
    try {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {}
    if (_currentRecordingPath != null) {
      try {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
    _currentRecordingPath = null;
    _elapsedSeconds = 0;
    _durationController.add(0);
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _durationController.close();
    await _audioRecorder.dispose();
  }
}
