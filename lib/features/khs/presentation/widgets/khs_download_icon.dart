import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/cubit/khs_detail_cubit.dart';
import 'package:lonceng_unman_fe/features/khs/presentation/cubit/khs_detail_state.dart';

/// Icon-only download button for saving KHS PDF.
///
/// Placed in the profile info card's header Row. Uses [Tooltip] for
/// accessibility. Shows a circular progress indicator while downloading.
class KhsDownloadIcon extends StatelessWidget {
  const KhsDownloadIcon({super.key, required this.semester});

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

        return Tooltip(
          message: AppStrings.khsDownloadButton,
          child: IconButton(
            key: const Key('khs_download_button'),
            icon: const Icon(Icons.download_outlined, size: AppDimens.iconMD),
            color: cs.onPrimaryContainer,
            onPressed: () => context.read<KhsDetailCubit>().downloadPdf(
              semester,
              context: context,
            ),
            splashRadius: AppDimens.avatarMD,
          ),
        );
      },
    );
  }
}
