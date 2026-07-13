import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lungsense_wellness/core/usecase/usecase.dart';
import 'package:lungsense_wellness/features/onboarding/domain/entities/onboarding_data.dart';
import 'package:lungsense_wellness/features/onboarding/domain/usecases/clear_onboarding_draft_usecase.dart';
import 'package:lungsense_wellness/features/onboarding/domain/usecases/fetch_conditions_usecase.dart';
import 'package:lungsense_wellness/features/onboarding/domain/usecases/load_onboarding_draft_usecase.dart';
import 'package:lungsense_wellness/features/onboarding/domain/usecases/save_onboarding_draft_usecase.dart';
import 'package:lungsense_wellness/features/onboarding/domain/usecases/save_onboarding_usecase.dart';
import 'package:lungsense_wellness/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:lungsense_wellness/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:lungsense_wellness/features/onboarding/presentation/bloc/onboarding_state.dart';

class MockSaveOnboardingUseCase extends Mock implements SaveOnboardingUseCase {}
class MockFetchConditionsUseCase extends Mock implements FetchConditionsUseCase {}
class MockSaveOnboardingDraftUseCase extends Mock implements SaveOnboardingDraftUseCase {}
class MockLoadOnboardingDraftUseCase extends Mock implements LoadOnboardingDraftUseCase {}
class MockClearOnboardingDraftUseCase extends Mock implements ClearOnboardingDraftUseCase {}

void main() {
  late OnboardingBloc bloc;
  late MockSaveOnboardingUseCase mockSaveOnboardingUseCase;
  late MockFetchConditionsUseCase mockFetchConditionsUseCase;
  late MockSaveOnboardingDraftUseCase mockSaveOnboardingDraftUseCase;
  late MockLoadOnboardingDraftUseCase mockLoadOnboardingDraftUseCase;
  late MockClearOnboardingDraftUseCase mockClearOnboardingDraftUseCase;

  setUpAll(() {
    registerFallbackValue(OnboardingData.empty());
    registerFallbackValue(const NoParams());
  });

  setUp(() {
    mockSaveOnboardingUseCase = MockSaveOnboardingUseCase();
    mockFetchConditionsUseCase = MockFetchConditionsUseCase();
    mockSaveOnboardingDraftUseCase = MockSaveOnboardingDraftUseCase();
    mockLoadOnboardingDraftUseCase = MockLoadOnboardingDraftUseCase();
    mockClearOnboardingDraftUseCase = MockClearOnboardingDraftUseCase();

    bloc = OnboardingBloc(
      saveOnboardingUseCase: mockSaveOnboardingUseCase,
      fetchConditionsUseCase: mockFetchConditionsUseCase,
      saveOnboardingDraftUseCase: mockSaveOnboardingDraftUseCase,
      loadOnboardingDraftUseCase: mockLoadOnboardingDraftUseCase,
      clearOnboardingDraftUseCase: mockClearOnboardingDraftUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be OnboardingState.initial()', () {
    expect(bloc.state, equals(OnboardingState.initial()));
  });

  group('OnboardingUpdateDataEvent', () {
    test('should calculate BMI correctly in real-time when height and weight are updated', () {
      final testData = OnboardingData.empty().copyWith(height: 180, weight: 81);
      
      bloc.add(OnboardingUpdateDataEvent(testData));
      
      expect(
        bloc.stream,
        emits(
          OnboardingState.initial().copyWith(
            data: testData.copyWith(bmi: 25.0),
          ),
        ),
      );
    });
  });

  group('OnboardingSteps', () {
    test('should increment step counter and save draft on NextStep, and decrement on PreviousStep', () async {
      when(() => mockSaveOnboardingDraftUseCase.call(any())).thenAnswer((_) async => const Right(null));

      final expectedStates = [
        OnboardingState.initial().copyWith(currentStep: 2),
        OnboardingState.initial().copyWith(currentStep: 1),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const OnboardingNextStepEvent());
      bloc.add(const OnboardingPreviousStepEvent());
    });
  });

  group('OnboardingSubmitEvent', () {
    test('should emit submitting and submitSuccess when save is successful', () async {
      when(() => mockSaveOnboardingUseCase.call(any())).thenAnswer((_) async => const Right(null));
      when(() => mockClearOnboardingDraftUseCase.call(any())).thenAnswer((_) async => const Right(null));

      final expectedStates = [
        OnboardingState.initial().copyWith(status: OnboardingStatus.submitting),
        OnboardingState.initial().copyWith(status: OnboardingStatus.submitSuccess),
      ];

      expectLater(bloc.stream, emitsInOrder(expectedStates));

      bloc.add(const OnboardingSubmitEvent());
    });
  });
}
