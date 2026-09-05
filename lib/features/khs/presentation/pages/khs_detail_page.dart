// khs - Detail page
//
// Shows full KHS (Kartu Hasil Studi) data for a specific academic year.
// Displays GANJIL/GENAP tabs, each loading its own KHS data from cache.
// Layout follows flutter-use-column-row-first: Column for vertical,
// Row for horizontal, Expanded/Flexible for flexible children.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/khs/domain/entities/khs_entity.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/cubit/khs_detail_cubit.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/cubit/khs_detail_state.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/widgets/khs_app_bar_title.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/widgets/khs_download_icon.dart';
import 'package:open_filex/open_filex.dart';

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
    _tabController.addListener(_onTabChanged);
    // Serialize: loadAvailableYears then loadAll to avoid race
    Future.microtask(() async {
      // ignore: use_build_context_synchronously
      final cubit = context.read<KhsDetailCubit>();
      await cubit.loadAvailableYears();
      if (!mounted) return;
      await cubit.loadAll();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Map cubit state to per-tab data for ganjil semester.
  _TabData _getGanjilData(KhsDetailState state) {
    if (state is KhsDetailLoading) {
      return _TabData(isLoading: true);
    }
    if (state is KhsDetailError) {
      return _TabData(error: state.ganjilError);
    }
    if (state is KhsDetailLoaded) {
      return _TabData(data: state.ganjilData);
    }
    return _TabData(isLoading: true);
  }

  /// Map cubit state to per-tab data for genap semester.
  _TabData _getGenapData(KhsDetailState state) {
    if (state is KhsDetailLoading) {
      return _TabData(isLoading: true);
    }
    if (state is KhsDetailError) {
      return _TabData(error: state.genapError);
    }
    if (state is KhsDetailLoaded) {
      return _TabData(data: state.genapData);
    }
    return _TabData(isLoading: true);
  }

  // ── Build ───────────────────────────────────────────────────

  void _showSuccessDialog(
    BuildContext context,
    String? fileName,
    String? filePath,
  ) {
    debugPrint(
      '[KhsDetailPage] _showSuccessDialog called: fileName=$fileName filePath=$filePath mounted=${context.mounted} isCurrent=${ModalRoute.of(context)?.isCurrent}',
    );
    if (!context.mounted) {
      debugPrint('[KhsDetailPage] _showSuccessDialog abort: not mounted');
      return;
    }
    final isCurrent = ModalRoute.of(context)?.isCurrent;
    debugPrint('[KhsDetailPage] _showSuccessDialog isCurrent=$isCurrent');
    if (isCurrent != true) {
      debugPrint(
        '[KhsDetailPage] _showSuccessDialog abort: route not current (isCurrent=$isCurrent) — notification still shows',
      );
      return;
    }
    if (fileName == null || filePath == null) {
      debugPrint(
        '[KhsDetailPage] _showSuccessDialog abort: fileName=$fileName filePath=$filePath',
      );
      return;
    }
    debugPrint('[KhsDetailPage] showing success dialog: $fileName → $filePath');
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.check_circle, color: cs.primary, size: 48),
          title: const Text(AppStrings.khsDownloadDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fileName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.khsDownloadDialogLocation,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.khsDownloadDialogHint,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                debugPrint('[KhsDetailPage] dialog Tutup pressed');
                Navigator.of(dialogContext).pop();
              },
              child: const Text(AppStrings.khsDownloadDialogClose),
            ),
            FilledButton(
              onPressed: () async {
                debugPrint('[KhsDetailPage] dialog Buka pressed: $filePath');
                Navigator.of(dialogContext).pop();
                final exists = File(filePath).existsSync();
                debugPrint(
                  '[KhsDetailPage] dialog Buka existsSync=$exists path=$filePath',
                );
                if (!exists) {
                  debugPrint(
                    '[KhsDetailPage] dialog Buka file not found: $filePath',
                  );
                  Fluttertoast.showToast(
                    msg: AppStrings.khsDownloadFileNotFound,
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                  );
                  return;
                }
                try {
                  debugPrint(
                    '[KhsDetailPage] dialog Buka → OpenFilex.open: $filePath',
                  );
                  final result = await OpenFilex.open(filePath);
                  debugPrint(
                    '[KhsDetailPage] dialog Buka result: type=${result.type} message=${result.message} path=$filePath',
                  );
                  if (result.type != ResultType.done) {
                    debugPrint(
                      '[KhsDetailPage] dialog Buka no app to handle: type=${result.type} $filePath',
                    );
                    Fluttertoast.showToast(
                      msg: AppStrings.khsDownloadNoViewer,
                      toastLength: Toast.LENGTH_LONG,
                      gravity: ToastGravity.BOTTOM,
                    );
                  } else {
                    debugPrint(
                      '[KhsDetailPage] dialog Buka success: $filePath',
                    );
                  }
                } catch (e, st) {
                  debugPrint(
                    '[KhsDetailPage] dialog Buka failed: $e\n$st path=$filePath',
                  );
                  Fluttertoast.showToast(
                    msg: AppStrings.khsDownloadNoViewer,
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.BOTTOM,
                  );
                }
              },
              child: const Text(AppStrings.khsDownloadActionOpen),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocListener<KhsDetailCubit, KhsDetailState>(
      listenWhen: (previous, current) {
        final should =
            previous.downloadStatus != current.downloadStatus &&
            current.downloadStatus == DownloadStatus.success;
        debugPrint(
          '[KhsDetailPage] BlocListener listenWhen: ${previous.downloadStatus} → ${current.downloadStatus} fileName=${current.downloadedFileName} shouldTrigger=$should',
        );
        return should;
      },
      listener: (context, state) {
        debugPrint(
          '[KhsDetailPage] BlocListener triggered: success fileName=${state.downloadedFileName} filePath=${state.downloadedFilePath}',
        );
        _showSuccessDialog(
          context,
          state.downloadedFileName,
          state.downloadedFilePath,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<KhsDetailCubit, KhsDetailState>(
            builder: (context, state) {
              return KhsAppBarTitle(
                key: const Key('khs_app_bar_title'),
                tahunAjaran: state.selectedTahunAjaran,
                availableYears: state.availableYears,
                isFetching: state.isFetching,
                onYearSelected: (year) =>
                    context.read<KhsDetailCubit>().selectYear(year),
              );
            },
          ),
          backgroundColor: cs.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: cs.onSurface),
            onPressed: () => context.pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.space16,
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                indicatorColor: cs.primary,
                dividerColor: Colors.transparent,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: cs.primary, width: 2),
                ),
                tabs: const [
                  Tab(text: AppStrings.khsTabGanjil),
                  Tab(text: AppStrings.khsTabGenap),
                ],
              ),
            ),
          ),
        ),
        body: BlocBuilder<KhsDetailCubit, KhsDetailState>(
          builder: (context, state) {
            final ganjil = _getGanjilData(state);
            final genap = _getGenapData(state);
            return TabBarView(
              controller: _tabController,
              children: [
                _buildSemesterTab(
                  cs: cs,
                  isLoading: ganjil.isLoading,
                  error: ganjil.error,
                  data: ganjil.data,
                  semester: 'GANJIL',
                  selectedTahunAjaran: state.selectedTahunAjaran,
                  isFetching: state.isFetching,
                ),
                _buildSemesterTab(
                  cs: cs,
                  isLoading: genap.isLoading,
                  error: genap.error,
                  data: genap.data,
                  semester: 'GENAP',
                  selectedTahunAjaran: state.selectedTahunAjaran,
                  isFetching: state.isFetching,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Tab content ─────────────────────────────────────────────

  Widget _buildSemesterTab({
    required ColorScheme cs,
    required bool isLoading,
    required String? error,
    required KhsDataEntity? data,
    required String semester,
    required String selectedTahunAjaran,
    required bool isFetching,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return _buildError(cs, error);
    }

    if (data == null) {
      return _buildEmptyState(
        cs,
        selectedTahunAjaran: selectedTahunAjaran,
        isFetching: isFetching,
      );
    }

    return _buildContent(cs, data, semester);
  }

  Widget _buildEmptyState(
    ColorScheme cs, {
    required String selectedTahunAjaran,
    required bool isFetching,
  }) {
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
            const SizedBox(height: AppDimens.space16),
            FilledButton(
              key: const Key('khs_fetch_year_button'),
              onPressed: isFetching
                  ? null
                  : () => context.read<KhsDetailCubit>().fetchMissingYear(
                      context: context,
                    ),
              child: isFetching
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.onPrimary,
                      ),
                    )
                  : Text('Muat KHS $selectedTahunAjaran'),
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

  Widget _buildContent(ColorScheme cs, KhsDataEntity data, String semester) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Student Info Card ──
          _buildInfoCard(cs, data, semester),
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

  Widget _buildInfoCard(ColorScheme cs, KhsDataEntity data, String semester) {
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
              KhsDownloadIcon(semester: semester),
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

/// Helper to pass per-tab data from cubit state to the tab builder.
class _TabData {
  const _TabData({this.isLoading = false, this.error, this.data});
  final bool isLoading;
  final String? error;
  final KhsDataEntity? data;
}
