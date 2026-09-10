import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';

class StopRecordingParams {
  final String sessionId;
  StopRecordingParams({required this.sessionId});
}

class StopRecording extends UseCase<void, StopRecordingParams> {
  StopRecording();

  @override
  Future<Either<Failure, void>> call(StopRecordingParams params) async {
    // Use case is a pass-through; actual orchestration is in the service.
    return const Right(null);
  }
}
