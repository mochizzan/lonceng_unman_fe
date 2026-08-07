import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';

/// Abstract interface for the data initialization repository.
abstract class DataInitializationRepository {
  /// Run the full post-login data initialization pipeline.
  /// Returns a stream of status updates as the pipeline progresses.
  Stream<DataInitStatus> initialize({
    required String npm,
    required String password,
  });
}
