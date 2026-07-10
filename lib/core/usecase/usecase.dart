import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import '../errors/failures.dart';

/// Base class for all UseCases in the application.
/// [Type] is the type returned by the usecase on success.
/// [Params] is the input arguments class needed by the usecase.
abstract class UseCase<Type, Params> {
  /// Executes the use case asynchronously.
  Future<Either<Failure, Type>> call(Params params);
}

/// Represents a scenario where a UseCase does not require any parameters.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
