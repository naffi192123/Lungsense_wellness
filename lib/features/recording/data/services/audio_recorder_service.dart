import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:record/record.dart';

class AudioRecorderService {
  AudioRecorder? _audioRecorder;
  String? _currentRecordingPath;
  Timer? _timer;
  int _elapsedSeconds = 0;
  
  StreamController<int>? _durationController;

  Stream<int> get durationStream {
    if (_durationController == null || _durationController!.isClosed) {
      _durationController = StreamController<int>.broadcast();
    }
    return _durationController!.stream;
  }

  int get elapsedSeconds => _elapsedSeconds;

  AudioRecorder _ensureRecorder() {
    _audioRecorder ??= AudioRecorder();
    return _audioRecorder!;
  }

  /// Check and request runtime microphone permissions.
  /// Checks and requests using the record package's native permission handler first
  /// (which directly uses AVAudioSession on iOS and RECORD_AUDIO on Android),
  /// with permission_handler as an optional fallback, safely catching MissingPluginException.
  Future<bool> requestMicrophonePermission() async {
    try {
      final recorder = _ensureRecorder();
      final hasPerm = await recorder.hasPermission();
      if (hasPerm) return true;
    } catch (_) {}

    try {
      final status = await ph.Permission.microphone.request();
      return status.isGranted;
    } catch (_) {
      // If permission_handler method channel is not available or throws MissingPluginException,
      // fallback to checking the recorder directly.
      try {
        return await _ensureRecorder().hasPermission();
      } catch (_) {
        return false;
      }
    }
  }

  /// Check if microphone permission is permanently denied.
  Future<bool> isPermissionPermanentlyDenied() async {
    try {
      return await ph.Permission.microphone.isPermanentlyDenied;
    } catch (_) {
      return false;
    }
  }

  /// Open device app settings.
  Future<bool> openAppSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Start recording audio live to a local temporary file.
  Future<String?> startRecording() async {
    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      throw Exception('Microphone permission is required to record audio.');
    }

    final recorder = _ensureRecorder();

    try {
      if (await recorder.isRecording()) {
        await stopRecording();
      }
    } catch (_) {
      // If previous recorder was in invalid state, re-instantiate
      _audioRecorder = AudioRecorder();
    }

    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/lungsense_record_${DateTime.now().millisecondsSinceEpoch}.m4a';
    _currentRecordingPath = filePath;

    const config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      bitRate: 128000,
    );

    await _ensureRecorder().start(config, path: filePath);

    _elapsedSeconds = 0;
    _emitDuration(0);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      _emitDuration(_elapsedSeconds);
    });

    return filePath;
  }

  void _emitDuration(int seconds) {
    if (_durationController != null && !_durationController!.isClosed) {
      _durationController!.add(seconds);
    }
  }

  /// Pause current active recording.
  Future<void> pauseRecording() async {
    final recorder = _audioRecorder;
    if (recorder != null) {
      try {
        if (await recorder.isRecording()) {
          await recorder.pause();
          _timer?.cancel();
        }
      } catch (_) {}
    }
  }

  /// Resume recording after pause.
  Future<void> resumeRecording() async {
    final recorder = _audioRecorder;
    if (recorder != null) {
      try {
        if (await recorder.isPaused()) {
          await recorder.resume();
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
            _elapsedSeconds++;
            _emitDuration(_elapsedSeconds);
          });
        }
      } catch (_) {}
    }
  }

  /// Stop current recording and return the completed audio file path.
  Future<String?> stopRecording() async {
    _timer?.cancel();
    final recorder = _audioRecorder;
    String? path;
    if (recorder != null) {
      try {
        path = await recorder.stop();
      } catch (_) {}
    }
    _currentRecordingPath = null;
    return path;
  }

  /// Cancel and discard the current recording file.
  Future<void> cancelRecording() async {
    _timer?.cancel();
    final recorder = _audioRecorder;
    if (recorder != null) {
      try {
        final path = await recorder.stop();
        if (path != null) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
          }
        }
      } catch (_) {}
    }
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
    _emitDuration(0);
  }

  Future<void> dispose() async {
    _timer?.cancel();
    if (_durationController != null && !_durationController!.isClosed) {
      await _durationController!.close();
      _durationController = null;
    }
    if (_audioRecorder != null) {
      try {
        await _audioRecorder!.dispose();
      } catch (_) {}
      _audioRecorder = null;
    }
  }
}
