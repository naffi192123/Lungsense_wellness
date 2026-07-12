import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// UseCase to observe authentication status changes reactively.
class ObserveUserUseCase {
  final AuthRepository repository;

  ObserveUserUseCase(this.repository);

  Stream<UserEntity?> call() {
    return repository.userStream;
  }
}
