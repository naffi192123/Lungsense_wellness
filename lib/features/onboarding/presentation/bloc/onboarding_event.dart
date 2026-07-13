import 'package:equatable/equatable.dart';
import '../../domain/entities/onboarding_data.dart';

/// Base class for onboarding actions.
abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to fetch dynamic conditions lists from Supabase.
class OnboardingLoadConditionsEvent extends OnboardingEvent {
  const OnboardingLoadConditionsEvent();
}

/// Dispatched to check and load local cached onboarding progress drafts.
class OnboardingLoadDraftEvent extends OnboardingEvent {
  const OnboardingLoadDraftEvent();
}

/// Dispatched when form inputs are modified, updating current local cache.
class OnboardingUpdateDataEvent extends OnboardingEvent {
  final OnboardingData data;

  const OnboardingUpdateDataEvent(this.data);

  @override
  List<Object?> get props => [data];
}

/// Dispatched on final step to sync all data to Supabase.
class OnboardingSubmitEvent extends OnboardingEvent {
  const OnboardingSubmitEvent();
}

/// Dispatched to advance step counter and save draft locally.
class OnboardingNextStepEvent extends OnboardingEvent {
  const OnboardingNextStepEvent();
}

/// Dispatched to decrement step counter.
class OnboardingPreviousStepEvent extends OnboardingEvent {
  const OnboardingPreviousStepEvent();
}
