// khs - Detail page
//
// Shows full KHS (Kartu Hasil Studi) data for a specific academic year.
// Displays GANJIL/GENAP tabs, each loading its own KHS data from cache.
// Layout follows flutter-use-column-row-first: Column for vertical,
// Row for horizontal, Expanded/Flexible for flexible children.

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/cache/academic_cache_service.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/khs/data/models/khs_model.dart';
import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';

/// Detail page for KHS data.
///
/// Receives [tahunAjaran] as route parameter.
/// Shows GANJIL/GENAP tab switching, each loading independently from cache.
class KhsDetailPage extends StatefulWidget {
  const KhsDetailPage({
    super.key,
    required this.tahunAjaran,
    required this.semester,
  });

  final String tahunAjaran;
  final String semester;

  @override
  State<KhsDetailPage> createState() => _KhsDetailPageState();
}

class _KhsDetailPageState extends State<KhsDetailPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Per-tab state
  KhsDataEntity? _ganjilData;
  KhsDataEntity? _genapData;
  bool _ganjilLoading = true;
  bool _genapLoading = true;
  String? _ganjilError;
  String? _genapError;

  @override
  void initState() {
    super.initState();
    // Start on the tab matching the route's semester parameter.
    final initialIndex = widget.semester.toUpperCase() == 'GENAP' ? 1 : 0;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────

  Future<void> _loadAllData() async {
    // Fire both loads concurrently.
    await Future.wait([
      _loadSemesterData(semester: 'GANJIL', setGanjil: true),
      _loadSemesterData(semester: 'GENAP', setGanjil: false),
    ]);
  }

  Future<void> _loadSemesterData({
    required String semester,
    required bool setGanjil,
  }) async {
    try {
      final cache = Services.get<AcademicCacheService>();
      final creds = await cache.loadCredentials();
      final npm = creds?['npm'];
      if (npm == null || npm.isEmpty) {
        setState(() {
          if (setGanjil) {
            _ganjilError = AppStrings.khsNpmTidakDitemukan;
            _ganjilLoading = false;
          } else {
            _genapError = AppStrings.khsNpmTidakDitemukan;
            _genapLoading = false;
          }
        });
        return;
      }

      final khsJson = await cache.loadKhsDataSemester(
        npm: npm,
        tahunAjaran: widget.tahunAjaran,
        semester: semester,
      );

      if (khsJson == null) {
        // Null means no cache for this semester — not an error, just empty.
        setState(() {
          if (setGanjil) {
            _ganjilLoading = false;
          } else {
            _genapLoading = false;
          }
        });
        return;
      }

      final khsModel = KhsModel.fromJson(khsJson);
      setState(() {
        if (setGanjil) {
          _ganjilData = khsModel.khs;
          _ganjilLoading = false;
        } else {
          _genapData = khsModel.khs;
          _genapLoading = false;
        }
      });
    } catch (e) {
      setState(() {
        if (setGanjil) {
          _ganjilError = AppStrings.khsGagalMemuat;
          _ganjilLoading = false;
        } else {
          _genapError = AppStrings.khsGagalMemuat;
          _genapLoading = false;
        }
      });
    }
  }

  Future<void> _onRefresh() async {
    setState(() {
      _ganjilLoading = true;
      _genapLoading = true;
      _ganjilError = null;
      _genapError = null;
    });
    await _loadAllData();
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${AppStrings.khsTitle} ${widget.tahunAjaran}',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.bold),
        ),
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: cs.primary,
          unselectedLabelColor: cs.onSurfaceVariant,
          indicatorColor: cs.primary,
          tabs: const [
            Tab(text: AppStrings.khsTabGanjil),
            Tab(text: AppStrings.khsTabGenap),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSemesterTab(
            cs: cs,
            isLoading: _ganjilLoading,
            error: _ganjilError,
            data: _ganjilData,
          ),
          _buildSemesterTab(
            cs: cs,
            isLoading: _genapLoading,
            error: _genapError,
            data: _genapData,
          ),
        ],
      ),
    );
  }

  // ── Tab content ─────────────────────────────────────────────

  Widget _buildSemesterTab({
    required ColorScheme cs,
    required bool isLoading,
    required String? error,
    required KhsDataEntity? data,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _buildError(cs, error);
    }

    if (data == null) {
      return _buildEmptyState(cs);
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: _buildContent(cs, data),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: AppDimens.iconXL,
              color: cs.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppDimens.space16),
            Text(
              AppStrings.khsNoData,
              style: TextStyle(
                fontSize: AppDimens.textLG,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(ColorScheme cs, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.space24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: AppDimens.space16),
            Text(
              message,
              style: TextStyle(
                fontSize: AppDimens.textLG,
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ColorScheme cs, KhsDataEntity data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Student Info Card ──
          _buildInfoCard(cs, data),
          const SizedBox(height: AppDimens.space24),

          // ── Courses Table ──
          _buildCoursesSection(cs, data.mataKuliah),
          const SizedBox(height: AppDimens.space24),

          // ── Summary Card ──
          _buildSummaryCard(cs, data.rekapitulasi),
        ],
      ),
    );
  }

  // ── Info Card ───────────────────────────────────────────────

  Widget _buildInfoCard(ColorScheme cs, KhsDataEntity data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, size: AppDimens.iconMD, color: cs.primary),
              const SizedBox(width: AppDimens.space12),
              Expanded(
                child: Text(
                  data.mahasiswa.nama,
                  style: TextStyle(
                    fontSize: AppDimens.textLG,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space12),
          _buildInfoRow(cs, Icons.badge, 'NPM', data.mahasiswa.npm),
          const SizedBox(height: AppDimens.space4),
          _buildInfoRow(
            cs,
            Icons.school,
            'Program Studi',
            data.mahasiswa.programStudi,
          ),
          const SizedBox(height: AppDimens.space4),
          _buildInfoRow(
            cs,
            Icons.calendar_today,
            'Tahun Ajaran',
            '${data.periode.tahunAjaran} - ${data.periode.semester}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ColorScheme cs,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDimens.space4),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppDimens.iconSM,
            color: cs.onPrimaryContainer.withValues(alpha: 0.7),
          ),
          const SizedBox(width: AppDimens.space8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: AppDimens.textSM,
              color: cs.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppDimens.textSM,
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Courses Section ─────────────────────────────────────────

  Widget _buildCoursesSection(
    ColorScheme cs,
    List<MataKuliahKhsEntity> mataKuliah,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.menu_book, size: AppDimens.iconMD, color: cs.primary),
            const SizedBox(width: AppDimens.space12),
            Text(
              AppStrings.khsDaftarMataKuliah,
              style: TextStyle(
                fontSize: AppDimens.textLG,
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimens.space16),
        if (mataKuliah.isEmpty)
          Text(
            AppStrings.khsBelumAdaDataMk,
            style: TextStyle(color: cs.onSurfaceVariant),
          )
        else
          ...mataKuliah.map((mk) => _buildCourseCard(cs, mk)),
      ],
    );
  }

  Widget _buildCourseCard(ColorScheme cs, MataKuliahKhsEntity mk) {
    final nilaiColor = _getNilaiColor(mk.nilai, cs);
    final isEmpty = _isNilaiEmpty(mk.nilai);

    return InkWell(
      onTap: () => _showCourseDetailSheet(context, cs, mk),
      borderRadius: BorderRadius.circular(AppDimens.radiusLG),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppDimens.space12),
        padding: const EdgeInsets.all(AppDimens.space16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLG),
          border: Border.all(
            color: isEmpty
                ? cs.outlineVariant.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: isEmpty ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // ── Nilai badge ──
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isEmpty
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
                    : nilaiColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimens.radiusMD),
                border: isEmpty
                    ? Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                        width: 1,
                      )
                    : null,
              ),
              child: Center(
                child: isEmpty
                    ? Icon(
                        Icons.remove,
                        size: AppDimens.iconMD,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                      )
                    : Text(
                        mk.nilai,
                        style: TextStyle(
                          fontSize: AppDimens.textLG,
                          fontWeight: FontWeight.bold,
                          color: nilaiColor,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: AppDimens.space16),
            // ── Course info ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mk.nama,
                    style: TextStyle(
                      fontSize: AppDimens.textMD,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimens.space4),
                  Text(
                    '${mk.kode} • ${mk.sks} SKS',
                    style: TextStyle(
                      fontSize: AppDimens.textSM,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // ── Mutu ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isEmpty ? '–' : '${mk.mutu}',
                  style: TextStyle(
                    fontSize: AppDimens.textXL,
                    fontWeight: FontWeight.bold,
                    color: isEmpty
                        ? cs.onSurfaceVariant.withValues(alpha: 0.5)
                        : cs.onSurface,
                  ),
                ),
                Text(
                  'mutu',
                  style: TextStyle(
                    fontSize: AppDimens.textXS,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Course Detail Bottom Sheet ──────────────────────────────

  void _showCourseDetailSheet(
    BuildContext context,
    ColorScheme cs,
    MataKuliahKhsEntity mk,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimens.radiusLG),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.space20,
            vertical: AppDimens.space16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDimens.space16),
              // ── Header ──
              Text(
                AppStrings.khsMataKuliah,
                style: TextStyle(
                  fontSize: AppDimens.textLG,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: AppDimens.space8),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: AppDimens.space8),
              // ── Detail rows ──
              _buildDetailRow(cs, 'Kode', mk.kode),
              _buildDetailRow(cs, 'Nama', mk.nama),
              _buildDetailRow(cs, 'Dosen', mk.dosen),
              _buildDetailRow(cs, 'SKS', '${mk.sks}'),
              _buildDetailRow(
                cs,
                'Nilai',
                _isNilaiEmpty(mk.nilai) ? 'Belum ada nilai' : mk.nilai,
                isEmpty: _isNilaiEmpty(mk.nilai),
              ),
              _buildDetailRow(
                cs,
                'Mutu',
                _isNilaiEmpty(mk.nilai) ? '–' : '${mk.mutu}',
                isEmpty: _isNilaiEmpty(mk.nilai),
              ),
              const SizedBox(height: AppDimens.space16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    ColorScheme cs,
    String label,
    String value, {
    bool isEmpty = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimens.space4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppDimens.textSM,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppDimens.textSM,
                fontWeight: FontWeight.w500,
                color: isEmpty
                    ? cs.onSurfaceVariant.withValues(alpha: 0.6)
                    : cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Card ────────────────────────────────────────────

  Widget _buildSummaryCard(ColorScheme cs, RekapitulasiEntity rekap) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.space20),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppDimens.radiusXL),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.summarize,
                size: AppDimens.iconMD,
                color: cs.onSecondaryContainer,
              ),
              const SizedBox(width: AppDimens.space12),
              Text(
                AppStrings.khsRekapitulasi,
                style: TextStyle(
                  fontSize: AppDimens.textLG,
                  fontWeight: FontWeight.bold,
                  color: cs.onSecondaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimens.space16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(cs, 'Total SKS', '${rekap.totalSks}'),
              ),
              Expanded(
                child: _buildSummaryItem(
                  cs,
                  'Total Mutu',
                  '${rekap.totalMutu}',
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  cs,
                  'IPK',
                  rekap.ipk.toStringAsFixed(2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(ColorScheme cs, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: AppDimens.text2XL,
            fontWeight: FontWeight.bold,
            color: cs.onSecondaryContainer,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: AppDimens.textXS,
            color: cs.onSecondaryContainer.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  Color _getNilaiColor(String nilai, ColorScheme cs) {
    if (nilai.trim().isEmpty) {
      return cs.onSurfaceVariant.withValues(alpha: 0.5);
    }
    switch (nilai.toUpperCase()) {
      case 'A':
        return const Color(0xFF2E7D32); // Green
      case 'B+':
        return const Color(0xFF558B2F); // Light green
      case 'B':
        return const Color(0xFFF9A825); // Yellow
      case 'C+':
        return const Color(0xFFEF6C00); // Orange
      case 'C':
        return const Color(0xFFE65100); // Deep orange
      case 'D':
        return const Color(0xFFC62828); // Red
      case 'E':
        return const Color(0xFF880E4F); // Dark red
      default:
        return cs.onSurfaceVariant;
    }
  }

  bool _isNilaiEmpty(String nilai) => nilai.trim().isEmpty;
}
