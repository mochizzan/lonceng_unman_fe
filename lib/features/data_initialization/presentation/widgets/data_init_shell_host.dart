import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/cache/credential_cache.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/features/data_initialization/domain/entities/data_initialization_entity.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_bloc.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_event.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/bloc/data_initialization_state.dart';
import 'package:lonceng_unman_fe/features/data_initialization/presentation/widgets/data_init_status_text.dart';

/// Hosts background data-initialization for the main shell.
///
/// - Auto-starts the pipeline from [CredentialCache] when the shell mounts
/// - Surfaces progress / errors via [SnackBar] (dashboard stays visible)
/// - Does not block navigation or replace the home layout
class DataInitShellHost extends StatefulWidget {
  const DataInitShellHost({super.key, required this.child});

  final Widget child;

  @override
  State<DataInitShellHost> createState() => _DataInitShellHostState();
}

class _DataInitShellHostState extends State<DataInitShellHost> {
  DataInitStatus? _lastSnackStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;
    final bloc = context.read<DataInitBloc>();
    if (bloc.isRunning || bloc.state is DataInitSuccess) return;

    final cache = Services.get<CredentialCache>();
    final cached = await cache.load();

    if (!mounted) return;
    if (cached == null) {
      _showErrorSnack(context, 'Sesi tidak ditemukan. Silakan login ulang.');
      return;
    }

    final npm = cached['npm'] ?? '';
    final password = cached['password'] ?? '';
    if (npm.isEmpty || password.isEmpty) {
      _showErrorSnack(
        context,
        'Kredensial tidak lengkap. Silakan login ulang.',
      );
      return;
    }

    bloc.add(DataInitStarted(npm: npm, password: password));
  }

  void _retry() {
    final bloc = context.read<DataInitBloc>();
    bloc.add(const DataInitReset());
    _bootstrap();
  }

  void _showProgressSnack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Coba lagi', onPressed: _retry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DataInitBloc, DataInitBlocState>(
      listener: (context, state) {
        if (state is DataInitInProgress) {
          if (_lastSnackStatus == state.status) return;
          _lastSnackStatus = state.status;
          _showProgressSnack(context, dataInitStatusText(state.status));
        } else if (state is DataInitSuccess) {
          _lastSnackStatus = DataInitStatus.completed;
          _showProgressSnack(
            context,
            dataInitStatusText(DataInitStatus.completed),
          );
        } else if (state is DataInitFailure) {
          _lastSnackStatus = DataInitStatus.failed;
          _showErrorSnack(
            context,
            state.message.isNotEmpty
                ? state.message
                : 'Gagal memuat data akademik',
          );
        }
      },
      child: widget.child,
    );
  }
}
