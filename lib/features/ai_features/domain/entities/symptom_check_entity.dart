import 'package:equatable/equatable.dart';

class SymptomCheckResult extends Equatable {
  final List<String> possibleConditions;
  final String suggestedSpecialty;
  final String urgencyLevel;
  final List<String> nextSteps;

  const SymptomCheckResult({
    required this.possibleConditions,
    required this.suggestedSpecialty,
    required this.urgencyLevel,
    required this.nextSteps,
  });

  @override
  List<Object> get props => [suggestedSpecialty, urgencyLevel];
}
