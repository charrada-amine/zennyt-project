import 'package:equatable/equatable.dart';

enum ChunkStatus {
  pending,
  uploading,
  sent,
  failed,
}

class RecordingChunk extends Equatable {
  final int id;
  final String sessionId;
  final int sequenceNumber;
  final String localFilePath;
  final ChunkStatus status;
  final DateTime createdAt;

  const RecordingChunk({
    this.id = 0,
    required this.sessionId,
    required this.sequenceNumber,
    required this.localFilePath,
    this.status = ChunkStatus.pending,
    required this.createdAt,
  });

  RecordingChunk copyWith({
    int? id,
    String? sessionId,
    int? sequenceNumber,
    String? localFilePath,
    ChunkStatus? status,
    DateTime? createdAt,
  }) {
    return RecordingChunk(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      localFilePath: localFilePath ?? this.localFilePath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, sessionId, sequenceNumber, localFilePath, status, createdAt];
}
