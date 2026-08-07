// Shared metadata model for LMS document extraction.
//
// DTO layer for [MetadataEntity] — shared by KRS and KHS features.

import 'package:lonceng_unman_fe/core/domain/metadata_entity.dart';

class MetadataModel extends MetadataEntity {
  const MetadataModel({
    required super.extractedAt,
    required super.sourceFile,
    required super.fileSize,
  });

  factory MetadataModel.fromJson(Map<String, dynamic> json) {
    return MetadataModel(
      extractedAt: json['extracted_at'] as String? ?? '',
      sourceFile: json['source_file'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? 0,
    );
  }
}
