import 'package:equatable/equatable.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

/// Status indicator for local storage actions.
enum WellnessStatus { 
  initial, 
  loading, 
  success, 
  error, 
  saving,
  saveSuccess
}

/// Represents current wellness logs states.
class WellnessState extends Equatable {
  final List<DailyLogEntity> dailyLogs;
  final List<AudioAnalysisEntity> audioAnalyses;
  final WellnessStatus status;
  final String? errorMessage;

  const WellnessState({
    required this.dailyLogs,
    required this.audioAnalyses,
    required this.status,
    this.errorMessage,
  });

  /// Initial empty state.
  factory WellnessState.initial() {
    return const WellnessState(
      dailyLogs: [],
      audioAnalyses: [],
      status: WellnessStatus.initial,
    );
  }

  WellnessState copyWith({
    List<DailyLogEntity>? dailyLogs,
    List<AudioAnalysisEntity>? audioAnalyses,
    WellnessStatus? status,
    String? errorMessage,
  }) {
    return WellnessState(
      dailyLogs: dailyLogs ?? this.dailyLogs,
      audioAnalyses: audioAnalyses ?? this.audioAnalyses,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [dailyLogs, audioAnalyses, status, errorMessage];
}
