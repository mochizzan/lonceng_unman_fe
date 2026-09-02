import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/cubit/khs_detail_cubit.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/cubit/khs_detail_state.dart';

/// Download button for saving KHS PDF.
///
/// Placed in each tab (GANJIL/GENAP). Shows a progress indicator while
/// downloading and is disabled during an active download.
class KhsDownloadButton extends StatelessWidget {
  const KhsDownloadButton({super.key, required this.semester});

  final String semester;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocBuilder<KhsDetailCubit, KhsDetailState>(
      buildWhen: (previous, current) =>
          previous.downloadStatus != current.downloadStatus,
      builder: (context, state) {
        final isDownloading =
            state.downloadStatus == DownloadStatus.downloading;

        if (isDownloading) {
          return SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
          );
        }

        return FilledButton.icon(
          key: const Key('khs_download_button'),
          onPressed: () => context.read<KhsDetailCubit>().downloadPdf(
            semester,
            context: context,
          ),
          icon: const Icon(Icons.download, size: AppDimens.iconSM),
          label: const Text(AppStrings.khsDownloadButton),
          style: FilledButton.styleFrom(
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radius3XL),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.space16,
              vertical: AppDimens.space8,
            ),
          ),
        );
      },
    );
  }
}
