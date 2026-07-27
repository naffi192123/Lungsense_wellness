import 'package:equatable/equatable.dart';

abstract class AudioRecordingEvent extends Equatable {
  const AudioRecordingEvent();

  @override
  List<Object?> get props => [];
}

class AudioStartRecordingEvent extends AudioRecordingEvent {
  final String recordingType; // 'cough' or 'breathing'

  const AudioStartRecordingEvent({required this.recordingType});

  @override
  List<Object?> get props => [recordingType];
}

class AudioPauseRecordingEvent extends AudioRecordingEvent {
  const AudioPauseRecordingEvent();
}

class AudioResumeRecordingEvent extends AudioRecordingEvent {
  const AudioResumeRecordingEvent();
}

class AudioStopRecordingEvent extends AudioRecordingEvent {
  const AudioStopRecordingEvent();
}

class AudioCancelRecordingEvent extends AudioRecordingEvent {
  const AudioCancelRecordingEvent();
}

class AudioPickFileEvent extends AudioRecordingEvent {
  final String recordingType;

  const AudioPickFileEvent({required this.recordingType});

  @override
  List<Object?> get props => [recordingType];
}

class AudioRemoveFileEvent extends AudioRecordingEvent {
  const AudioRemoveFileEvent();
}

class AudioUploadEvent extends AudioRecordingEvent {
  final String recordingType;

  const AudioUploadEvent({required this.recordingType});

  @override
  List<Object?> get props => [recordingType];
}

class AudioResetEvent extends AudioRecordingEvent {
  const AudioResetEvent();
}

class AudioTimerTickEvent extends AudioRecordingEvent {
  final int durationSeconds;

  const AudioTimerTickEvent(this.durationSeconds);

  @override
  List<Object?> get props => [durationSeconds];
}
