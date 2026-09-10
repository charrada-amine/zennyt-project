import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/recording_chunk.dart';

class RecordingLocalDataSource {
  final Box _box;
  static const String _boxName = 'call_recording_chunks';

  RecordingLocalDataSource(this._box);

  static Future<Box> openBox() => Hive.openBox(_boxName);

  int _nextId() {
    final current = _box.get('_nextId', defaultValue: 1) as int;
    _box.put('_nextId', current + 1);
    return current;
  }

  Future<void> insertChunk(RecordingChunk chunk) async {
    final id = _nextId();
    final data = _serialize(chunk.copyWith(id: id));
    await _box.put('chunk_$id', data);
  }

  Future<List<RecordingChunk>> getChunksByStatus(ChunkStatus status) async {
    final results = <RecordingChunk>[];
    for (final key in _box.keys) {
      if (key is! String || !key.startsWith('chunk_')) continue;
      final data = _box.get(key) as String?;
      if (data == null) continue;
      final chunk = _deserialize(data);
      if (chunk.status == status) {
        results.add(chunk);
      }
    }
    results.sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
    return results;
  }

  Future<List<RecordingChunk>> getAllChunks() async {
    final results = <RecordingChunk>[];
    for (final key in _box.keys) {
      if (key is! String || !key.startsWith('chunk_')) continue;
      final data = _box.get(key) as String?;
      if (data == null) continue;
      results.add(_deserialize(data));
    }
    results.sort((a, b) => a.sequenceNumber.compareTo(b.sequenceNumber));
    return results;
  }

  Future<void> updateStatus(int chunkId, ChunkStatus status) async {
    final key = 'chunk_$chunkId';
    final data = _box.get(key) as String?;
    if (data == null) return;
    final chunk = _deserialize(data);
    await _box.put(key, _serialize(chunk.copyWith(status: status)));
  }

  Future<void> deleteChunk(int chunkId) async {
    await _box.delete('chunk_$chunkId');
  }

  String _serialize(RecordingChunk chunk) => jsonEncode({
        'id': chunk.id,
        'sessionId': chunk.sessionId,
        'sequenceNumber': chunk.sequenceNumber,
        'localFilePath': chunk.localFilePath,
        'status': chunk.status.name,
        'createdAt': chunk.createdAt.toIso8601String(),
      });

  RecordingChunk _deserialize(String data) {
    final map = jsonDecode(data) as Map<String, dynamic>;
    return RecordingChunk(
      id: map['id'] as int,
      sessionId: map['sessionId'] as String,
      sequenceNumber: map['sequenceNumber'] as int,
      localFilePath: map['localFilePath'] as String,
      status: ChunkStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ChunkStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
