import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/cache/credential_cache.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/shared/widgets/bloc_scaffold.dart';

class DataInitializationPage extends StatefulWidget {
  const DataInitializationPage({super.key, this.npm, this.password});

  final String? npm;
  final String? password;

  @override
  State<DataInitializationPage> createState() => _DataInitializationPageState();
}

class _DataInitializationPageState extends State<DataInitializationPage> {
  @override
  void initState() {
    super.initState();
    _startPipeline();
  }

  Future<void> _startPipeline() async {
    String npm = widget.npm ?? '';
    String password = widget.password ?? '';

    // If credentials not provided via constructor, load from DI-registered cache
    if (npm.isEmpty || password.isEmpty) {
      final cache = Services.get<CredentialCache>();
      final cached = await cache.load();
      if (cached != null) {
        npm = cached['npm'] ?? '';
        password = cached['password'] ?? '';
      }
    }

    if (npm.isNotEmpty && password.isNotEmpty && mounted) {
      context.read<DataInitBloc>().add(
        DataInitStarted(npm: npm, password: password),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DataInitBloc, DataInitBlocState>(
      listener: (context, state) {
        if (state is DataInitSuccess) {
          context.goNamed(RouteNames.home);
        } else if (state is DataInitFailure) {
          Fluttertoast.showToast(
            msg: state.message,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Theme.of(context).colorScheme.error,
            textColor: Theme.of(context).colorScheme.onError,
          );
        }
      },
      child: Scaffold(
        body: BlocBuilder<DataInitBloc, DataInitBlocState>(
          builder: (context, state) {
            if (state is DataInitFailure) {
              return _buildError(context, state);
            }
            return _buildLoading(context, state);
          },
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context, DataInitBlocState state) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final currentStatus = state is DataInitInProgress
        ? state.status
        : DataInitStatus.idle;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Skeleton circle avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 24),
          // Skeleton cards
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 6),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Status text
          Text(
            _statusText(currentStatus),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          CircularProgressIndicator(color: cs.primary),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, DataInitFailure state) {
    return AppErrorDisplay(
      message: state.message.isNotEmpty ? state.message : 'Terjadi kesalahan',
      onRetry: _startPipeline,
    );
  }

  String _statusText(DataInitStatus status) {
    switch (status) {
      case DataInitStatus.idle:
        return 'Menyiapkan...';
      case DataInitStatus.authenticating:
        return 'Memverifikasi akun...';
      case DataInitStatus.downloadingKrs:
        return 'Mengunduh KRS...';
      case DataInitStatus.fetchingSemesters:
        return 'Mengambil daftar semester...';
      case DataInitStatus.downloadingKhs:
        return 'Mengunduh KHS...';
      case DataInitStatus.extractingKrs:
        return 'Memproses KRS...';
      case DataInitStatus.extractingKhs:
        return 'Memproses KHS...';
      case DataInitStatus.fetchingKrsData:
        return 'Memuat data KRS...';
      case DataInitStatus.fetchingKhsData:
        return 'Memuat data KHS...';
      case DataInitStatus.completed:
        return 'Selesai!';
      case DataInitStatus.failed:
        return 'Gagal memuat data';
    }
  }
}
