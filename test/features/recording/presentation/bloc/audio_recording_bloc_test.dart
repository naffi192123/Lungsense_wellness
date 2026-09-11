import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lungsense_wellness/features/recording/presentation/bloc/audio_recording_bloc.dart';
import 'package:lungsense_wellness/features/recording/presentation/bloc/audio_recording_event.dart';
import 'package:lungsense_wellness/features/recording/presentation/bloc/audio_recording_state.dart';
import 'package:lungsense_wellness/features/recording/data/services/audio_recorder_service.dart';
import 'package:lungsense_wellness/features/recording/data/services/file_picker_service.dart';
import 'package:lungsense_wellness/features/recording/domain/usecases/upload_audio_usecase.dart';
import 'package:lungsense_wellness/features/recording/domain/usecases/get_job_status_usecase.dart';
import 'package:lungsense_wellness/features/recording/domain/usecases/check_and_record_consent_usecase.dart';

class MockAudioRecorderService extends Mock implements AudioRecorderService {}
class MockFilePickerService extends Mock implements FilePickerService {}
class MockUploadAudioUseCase extends Mock implements UploadAudioUseCase {}
class MockGetJobStatusUseCase extends Mock implements GetJobStatusUseCase {}
class MockCheckAndRecordConsentUseCase extends Mock implements CheckAndRecordConsentUseCase {}

void main() {
  late AudioRecordingBloc bloc;
  late MockAudioRecorderService mockRecorderService;
  late MockFilePickerService mockFilePickerService;
  late MockUploadAudioUseCase mockUploadAudioUseCase;
  late MockGetJobStatusUseCase mockGetJobStatusUseCase;
  late MockCheckAndRecordConsentUseCase mockCheckAndRecordConsentUseCase;

  setUp(() {
    mockRecorderService = MockAudioRecorderService();
    mockFilePickerService = MockFilePickerService();
    mockUploadAudioUseCase = MockUploadAudioUseCase();
    mockGetJobStatusUseCase = MockGetJobStatusUseCase();
    mockCheckAndRecordConsentUseCase = MockCheckAndRecordConsentUseCase();

    when(() => mockRecorderService.durationStream).thenAnswer((_) => Stream.value(0));
    when(() => mockRecorderService.elapsedSeconds).thenReturn(0);
    when(() => mockRecorderService.dispose()).thenAnswer((_) async {});

    bloc = AudioRecordingBloc(
      recorderService: mockRecorderService,
      filePickerService: mockFilePickerService,
      uploadAudioUseCase: mockUploadAudioUseCase,
      getJobStatusUseCase: mockGetJobStatusUseCase,
      checkAndRecordConsentUseCase: mockCheckAndRecordConsentUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be AudioRecordingInitial', () {
    expect(bloc.state, equals(const AudioRecordingInitial()));
  });

  test('emits [AudioRecordingPermissionDenied] when microphone permission is denied', () async {
    when(() => mockRecorderService.requestMicrophonePermission()).thenAnswer((_) async => false);
    when(() => mockRecorderService.isPermissionPermanentlyDenied()).thenAnswer((_) async => false);

    bloc.add(const AudioStartRecordingEvent(recordingType: 'cough'));

    await expectLater(
      bloc.stream,
      emits(predicate<AudioRecordingState>((state) => state is AudioRecordingPermissionDenied)),
    );
  });

  test('emits [AudioRecordingInProgress] when recording starts successfully', () async {
    when(() => mockRecorderService.requestMicrophonePermission()).thenAnswer((_) async => true);
    when(() => mockRecorderService.startRecording()).thenAnswer((_) async => '/tmp/sample.m4a');

    bloc.add(const AudioStartRecordingEvent(recordingType: 'cough'));

    await expectLater(
      bloc.stream,
      emits(predicate<AudioRecordingState>((state) => state is AudioRecordingInProgress)),
    );
  });

  test('emits [AudioRecordingReady] when file is picked from device', () async {
    when(() => mockFilePickerService.pickAudioFile()).thenAnswer((_) async => FilePickerResultInfo(
      path: '/tmp/imported.m4a',
      name: 'imported.m4a',
      sizeBytes: 1024,
      extension: 'm4a',
    ));

    bloc.add(const AudioPickFileEvent(recordingType: 'breathing'));

    await expectLater(
      bloc.stream,
      emits(predicate<AudioRecordingState>((state) => state is AudioRecordingReady && state.isImported)),
    );
  });

  test('emits [AudioRecordingInitial] on AudioRemoveFileEvent', () async {
    bloc.add(const AudioRemoveFileEvent());

    await expectLater(
      bloc.stream,
      emits(const AudioRecordingInitial()),
    );
  });
}
