import 'dart:typed_data';

import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';

/// Abstract interface for the data initialization repository.
abstract class DataInitializationRepository {
  /// Run the full post-login data initialization pipeline.
  /// Returns a stream of progress updates as the pipeline progresses.
  Stream<DataInitProgress> initialize({
    required String npm,
    required String password,
    bool forceRefresh = true,
    bool isPullRefresh = false,
  });

  /// M2 granular resume — continue pipeline from [failedStep] onward.
  /// Caller must hold [cachedPhotoBytes] from the first run if any.
  Stream<DataInitProgress> resumeFrom({
    required String failedStep,
    required String npm,
    required String password,
    bool forceRefresh = true,
    Uint8List? cachedPhotoBytes,
  });
}
