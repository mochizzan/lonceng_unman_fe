import 'package:lonceng_unman_fe/features/notification/data/datasources/notification_local_data_source.dart';
import 'package:lonceng_unman_fe/features/notification/data/models/scheduled_notification_model.dart';
import 'package:lonceng_unman_fe/features/notification/domain/entities/scheduled_notification_entity.dart';
import 'package:lonceng_unman_fe/features/notification/domain/repositories/notification_repository.dart';

/// Hive-backed implementation of [NotificationRepository].
///
/// Translates between domain entities and Hive models, delegates
/// storage operations to [NotificationLocalDataSource].
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required NotificationLocalDataSource localDataSource,
  }) : _localDataSource = localDataSource;

  final NotificationLocalDataSource _localDataSource;

  @override
  Future<List<ScheduledNotificationEntity>> getAll() async {
    final models = _localDataSource.getAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ScheduledNotificationEntity?> getById(int id) async {
    final model = _localDataSource.getById(id);
    return model?.toEntity();
  }

  @override
  Future<void> save(ScheduledNotificationEntity notification) async {
    final model = ScheduledNotificationModel.fromEntity(notification);
    await _localDataSource.save(model);
  }

  @override
  Future<void> saveAll(List<ScheduledNotificationEntity> notifications) async {
    final models = notifications
        .map((e) => ScheduledNotificationModel.fromEntity(e))
        .toList();
    await _localDataSource.saveAll(models);
  }

  @override
  Future<void> delete(int id) async {
    await _localDataSource.delete(id);
  }

  @override
  Future<void> deleteAll() async {
    await _localDataSource.deleteAll();
  }

  @override
  int getReminderInterval() {
    return _localDataSource.getReminderInterval();
  }

  @override
  void setReminderInterval(int minutes) {
    _localDataSource.setReminderInterval(minutes);
  }
}
