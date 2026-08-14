import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'network_info.dart';

/// Network Connectivity State.
class NetworkState extends Equatable {
  final bool isDisconnected;
  final bool isChecking;
  final bool justRestored;

  const NetworkState({
    required this.isDisconnected,
    this.isChecking = false,
    this.justRestored = false,
  });

  factory NetworkState.initial() => const NetworkState(isDisconnected: false);

  NetworkState copyWith({
    bool? isDisconnected,
    bool? isChecking,
    bool? justRestored,
  }) {
    return NetworkState(
      isDisconnected: isDisconnected ?? this.isDisconnected,
      isChecking: isChecking ?? this.isChecking,
      justRestored: justRestored ?? this.justRestored,
    );
  }

  @override
  List<Object?> get props => [isDisconnected, isChecking, justRestored];
}

/// Cubit managing real-time internet connectivity status.
class NetworkCubit extends Cubit<NetworkState> {
  final NetworkInfo _networkInfo;
  StreamSubscription<bool>? _subscription;

  NetworkCubit(this._networkInfo) : super(NetworkState.initial()) {
    _init();
  }

  void _init() {
    checkConnectivity();
    _subscription = _networkInfo.onConnectivityChanged.listen((connected) {
      if (!connected && !state.isDisconnected) {
        emit(state.copyWith(isDisconnected: true, isChecking: false, justRestored: false));
      } else if (connected && state.isDisconnected) {
        emit(state.copyWith(isDisconnected: false, isChecking: false, justRestored: true));
        // Reset justRestored flag after 3 seconds banner display
        Future.delayed(const Duration(seconds: 3), () {
          if (!isClosed) {
            emit(state.copyWith(justRestored: false));
          }
        });
      }
    });
  }

  /// Trigger instant internet verification.
  Future<void> checkConnectivity() async {
    emit(state.copyWith(isChecking: true));
    final connected = await _networkInfo.isConnected;
    final isDisconnected = !connected;

    if (state.isDisconnected && connected) {
      emit(state.copyWith(isDisconnected: false, isChecking: false, justRestored: true));
      Future.delayed(const Duration(seconds: 3), () {
        if (!isClosed) {
          emit(state.copyWith(justRestored: false));
        }
      });
    } else {
      emit(state.copyWith(isDisconnected: isDisconnected, isChecking: false));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
