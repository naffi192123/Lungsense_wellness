import 'dart:async';
import 'dart:io';
import '../constants/app_constants.dart';

/// Abstract contract for checking true internet connectivity.
abstract class NetworkInfo {
  /// Returns true if the device has actual, working internet access.
  Future<bool> get isConnected;

  /// Stream emitting connectivity status changes in real-time.
  Stream<bool> get onConnectivityChanged;
}

class NetworkInfoImpl implements NetworkInfo {
  final String primaryHost;
  final String fallbackHost;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  Timer? _timer;
  bool? _lastState;

  NetworkInfoImpl({
    this.primaryHost = AppConstants.apiHost,
    this.fallbackHost = '8.8.8.8',
  }) {
    _startMonitoring();
  }

  void _startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final connected = await isConnected;
      if (_lastState != connected) {
        _lastState = connected;
        _controller.add(connected);
      }
    });
  }

  @override
  Future<bool> get isConnected async {
    try {
      // 1. Primary check: Lookup domain address of backend API
      final result = await InternetAddress.lookup(primaryHost).timeout(const Duration(seconds: 4));
      if (result.isNotEmpty && result.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      // 2. Fallback check: Lookup standard public DNS host
      final fallback = await InternetAddress.lookup(fallbackHost).timeout(const Duration(seconds: 3));
      if (fallback.isNotEmpty && fallback.first.rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      // 3. Socket test fallback to port 53 (DNS)
      final socket = await Socket.connect(fallbackHost, 53, timeout: const Duration(seconds: 3));
      socket.destroy();
      return true;
    } catch (_) {}

    return false;
  }

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
