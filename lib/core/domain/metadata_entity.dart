// Shared metadata entity for LMS document extraction.
//
// Used by both KRS and KHS features to represent
// extraction metadata from the LMS PDF parser.

class MetadataEntity {
  final String extractedAt;
  final String sourceFile;
  final int fileSize;

  const MetadataEntity({
    required this.extractedAt,
    required this.sourceFile,
    required this.fileSize,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetadataEntity &&
          runtimeType == other.runtimeType &&
          extractedAt == other.extractedAt &&
          sourceFile == other.sourceFile &&
          fileSize == other.fileSize;

  @override
  int get hashCode => Object.hash(extractedAt, sourceFile, fileSize);
}
