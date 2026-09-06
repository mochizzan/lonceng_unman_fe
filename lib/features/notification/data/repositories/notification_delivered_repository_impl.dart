import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_delivered_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/notification_delivered_model.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/notification_delivered_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_delivered_repository.dart';

/// Hive-backed implementation of [NotificationDeliveredRepository].
class NotificationDeliveredRepositoryImpl
    implements NotificationDeliveredRepository {
  NotificationDeliveredRepositoryImpl({required this.localDataSource});

  final NotificationDeliveredLocalDataSource localDataSource;

  @override
  Future<List<NotificationDeliveredEntity>> getAll() async {
    final models = localDataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> save(NotificationDeliveredEntity entity) async {
    final model = NotificationDeliveredModel.fromEntity(entity);
    await localDataSource.save(model);
  }

  @override
  Future<void> delete(int id) async {
    await localDataSource.delete(id);
  }

  @override
  Future<void> deleteAll() async {
    await localDataSource.deleteAll();
  }

  @override
  Future<void> markAsRead(int id) async {
    await localDataSource.markAsRead(id);
  }

  @override
  Future<void> markAllRead() async {
    await localDataSource.markAllRead();
  }

  @override
  int getUnreadCount() => localDataSource.getUnreadCount();

  @override
  bool containsKey(int id) => localDataSource.containsKey(id);
}
