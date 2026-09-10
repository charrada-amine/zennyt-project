import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';

class StartRecordingParams {
  final String sessionId;
  final String storagePath;
  StartRecordingParams({
    required this.sessionId,
    required this.storagePath,
  });
}

class StartRecording extends UseCase<void, StartRecordingParams> {
  StartRecording();

  @override
  Future<Either<Failure, void>> call(StartRecordingParams params) async {
    // Use case is a pass-through; actual orchestration is in the service.
    return const Right(null);
  }
}
