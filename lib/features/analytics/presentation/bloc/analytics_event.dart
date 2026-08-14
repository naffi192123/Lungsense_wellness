import 'package:equatable/equatable.dart';

/// Events for the Analytics feature.
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

/// Dispatched to load (or refresh) all analytics data from the backend.
/// Triggers concurrent fetches of score history, baseline status, and score bands.
class AnalyticsLoadEvent extends AnalyticsEvent {
  const AnalyticsLoadEvent();
}
