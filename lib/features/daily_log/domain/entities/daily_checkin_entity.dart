import 'package:equatable/equatable.dart';

class DailyCheckInEntity extends Equatable {
  final String id;
  final int coughSeverity;
  final int shortnessOfBreath;
  final int fatigueLevel;
  final String? notes;
  final DateTime timestamp;

  const DailyCheckInEntity({
    required this.id,
    required this.coughSeverity,
    required this.shortnessOfBreath,
    required this.fatigueLevel,
    this.notes,
    required this.timestamp,
  });

  int get averageSeverity => ((coughSeverity + shortnessOfBreath + fatigueLevel) / 3).round();

  @override
  List<Object?> get props => [id, coughSeverity, shortnessOfBreath, fatigueLevel, notes, timestamp];
}
