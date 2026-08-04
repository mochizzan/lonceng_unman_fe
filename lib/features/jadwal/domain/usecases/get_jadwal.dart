// jadwal - Usecase
//
// Business-logic entry point for retrieving weekly schedule data.
// Follows the same pattern as home's [GetHome] usecase.

import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';
import 'package:lonceng_unman_fe/features/jadwal/domain/repositories/jadwal_repository.dart';

/// Retrieves the weekly schedule (jadwal) data for the authenticated user.
class GetJadwal {
  final JadwalRepository repository;

  const GetJadwal(this.repository);

  Future<JadwalEntity> call() => repository.getJadwal();
}
