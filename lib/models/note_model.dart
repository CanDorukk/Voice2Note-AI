class NoteModel {
  const NoteModel({
    this.id,
    required this.audioPath,
    required this.transcript,
    required this.summary,
    required this.duration,
    required this.createdAt,
  });

  final int? id;
  final String audioPath;
  final String transcript;
  final String summary;

  /// Recording length in seconds.
  final int duration;

  /// Unix timestamp (seconds) when created.
  final int createdAt;

  static const String tableName = 'notes';

  static const String colId = 'id';
  static const String colAudioPath = 'audio_path';
  static const String colTranscript = 'transcript';
  static const String colSummary = 'summary';
  static const String colDuration = 'duration';
  static const String colCreatedAt = 'created_at';

  Map<String, Object?> toMap() {
    return <String, Object?>{
      colId: id,
      colAudioPath: audioPath,
      colTranscript: transcript,
      colSummary: summary,
      colDuration: duration,
      colCreatedAt: createdAt,
    };
  }

  factory NoteModel.fromMap(Map<String, Object?> map) {
    return NoteModel(
      id: map[colId] as int?,
      audioPath: map[colAudioPath] as String? ?? '',
      transcript: map[colTranscript] as String? ?? '',
      summary: map[colSummary] as String? ?? '',
      duration: (map[colDuration] as num?)?.toInt() ?? 0,
      createdAt: (map[colCreatedAt] as num?)?.toInt() ?? 0,
    );
  }
}
