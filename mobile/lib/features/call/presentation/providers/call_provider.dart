import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:zennyt/features/call/data/repositories/call_signaling_repository_impl.dart';
import 'package:zennyt/features/call/domain/repositories/call_signaling_repository.dart';
import '../../../../core/network/websocket_service.dart';
import '../../domain/entities/call.dart' as entity;
import '../../domain/usecases/get_call.dart';
import '../../domain/usecases/start_call.dart';
import '../../domain/usecases/end_call.dart';
import '../../data/datasources/call_remote_datasource.dart';
import '../../data/repositories/call_repository_impl.dart';
import '../../../../core/network/network_info.dart';
import 'call_state.dart';

final callRemoteDataSourceProvider = Provider<CallRemoteDataSource>((ref) {
  throw UnimplementedError('Provide a Dio instance');
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  throw UnimplementedError('Provide a NetworkInfo instance');
});

final callRepositoryProvider = Provider((ref) {
  return CallRepositoryImpl(
    remoteDataSource: ref.read(callRemoteDataSourceProvider),
    networkInfo: ref.read(networkInfoProvider),
  );
});

final getCallProvider = Provider((ref) {
  return GetCall(ref.read(callRepositoryProvider));
});

final startCallProvider = Provider((ref) {
  return StartCall(ref.read(callRepositoryProvider));
});

final endCallProvider = Provider((ref) {
  return EndCall(ref.read(callRepositoryProvider));
});

class CallNotifier extends StateNotifier<CallState> {
  final GetCall _getCall;
  final StartCall _startCall;
  final EndCall _endCall;

  CallNotifier({
    required GetCall getCall,
    required StartCall startCall,
    required EndCall endCall,
  })  : _getCall = getCall,
        _startCall = startCall,
        _endCall = endCall,
        super(const CallState());

  Future<void> getCall(String id) async {
    state = state.copyWith(status: CallStatus2.loading);
    final result = await _getCall(GetCallParams(id: id));
    result.fold(
      (failure) => state = state.copyWith(
        status: CallStatus2.error,
        errorMessage: failure.message,
      ),
      (call) => state = state.copyWith(
        status: CallStatus2.active,
        call: call,
      ),
    );
  }

  Future<void> startCall(entity.Call call) async {
    state = state.copyWith(status: CallStatus2.loading);
    final result = await _startCall(StartCallParams(call: call));
    result.fold(
      (failure) => state = state.copyWith(
        status: CallStatus2.error,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(
        status: CallStatus2.active,
        call: call,
      ),
    );
  }

  Future<void> endCall(String id) async {
    state = state.copyWith(status: CallStatus2.loading);
    final result = await _endCall(EndCallParams(id: id));
    result.fold(
      (failure) => state = state.copyWith(
        status: CallStatus2.error,
        errorMessage: failure.message,
      ),
      (_) => state = state.copyWith(status: CallStatus2.ended),
    );
  }
}

final callNotifierProvider =
    StateNotifierProvider<CallNotifier, CallState>((ref) {
  return CallNotifier(
    getCall: ref.read(getCallProvider),
    startCall: ref.read(startCallProvider),
    endCall: ref.read(endCallProvider),
  );
});

final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});
final callSignalingRepositoryProvider =
    Provider<CallSignalingRepository>((ref) {
  return CallSignalingRepositoryImpl(
    webSocketService: ref.read(webSocketServiceProvider),
  );
});
