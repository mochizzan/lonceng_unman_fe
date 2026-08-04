// jadwal - Repository interface
//
// Defines the contract for retrieving jadwal (schedule) data.
// Clean Architecture: presentation/domain depend on this interface,
// not on concrete data sources.

import 'package:lonceng_unman_fe/features/jadwal/domain/entities/jadwal_entity.dart';

abstract class JadwalRepository {
  /// Fetches the complete jadwal (weekly schedule) data for the authenticated user.
  Future<JadwalEntity> getJadwal();
}
