// profile - Profile Avatar widget
//
// Avatar lingkaran + tombol kamera yang aktif. Alur saat tombol ditekan:
// pilih dari galeri -> AvatarCropPage (geser/zoom manual) -> simpan PNG
// 256x256 ke Hive box `avatar` lewat AvatarCubit.
//
// Sumber gambar yang ditampilkan, berurutan:
// 1. bytes lokal dari box `avatar` (hasil crop user)
// 2. avatarUrl dari server, bila ada
// 3. ikon person sebagai fallback

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/avatar_picker_service.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_state.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/pages/avatar_crop_page.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.avatarUrl,
    this.picker,
    this.size = 112,
    this.buttonSize = 40,
  });

  /// URL avatar dari server (fallback bila belum ada foto lokal).
  final String avatarUrl;

  /// Diinjeksi pada test; produksi memakai AvatarPickerService default.
  final AvatarPickerService? picker;

  final double size;
  final double buttonSize;

  Future<void> _pickAndCrop(BuildContext context) async {
    final cubit = context.read<AvatarCubit>();
    final service = picker ?? AvatarPickerService();

    cubit.markProcessing();

    Uint8List? source;
    try {
      source = await service.pickFromGallery();
    } catch (_) {
      cubit.reportFailure(AppStrings.avatarPickError);
      return;
    }

    if (source == null) {
      cubit.cancelProcessing();
      return;
    }
    if (!context.mounted) return;

    final cropped = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => AvatarCropPage(imageBytes: source!),
        fullscreenDialog: true,
      ),
    );

    if (cropped == null) {
      cubit.cancelProcessing();
      return;
    }
    await cubit.save(cropped);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return BlocConsumer<AvatarCubit, AvatarState>(
      listenWhen: (previous, current) => current is AvatarFailure,
      listener: (context, state) {
        if (state is AvatarFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final busy = state is AvatarProcessing;

        return SizedBox(
          width: sp(context, size),
          height: sp(context, size),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.onPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: cs.surface,
                      width: sp(context, 4),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusFull),
                    child: _buildImage(context, state.bytes, cs),
                  ),
                ),
              ),
              // Tombol kamera — pojok kanan bawah avatar.
              Positioned(
                bottom: 0,
                right: 0,
                child: Material(
                  color: cs.primary,
                  shape: CircleBorder(
                    side: BorderSide(
                      color: cs.primaryContainer,
                      width: sp(context, 2),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: busy ? null : () => _pickAndCrop(context),
                    child: Tooltip(
                      message: AppStrings.avatarChangeTooltip,
                      child: SizedBox(
                        width: sp(context, buttonSize),
                        height: sp(context, buttonSize),
                        child: busy
                            ? Padding(
                                padding: EdgeInsets.all(sp(context, 10)),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Icon(
                                Icons.camera_alt,
                                size: sp(context, 20),
                                color: cs.onPrimary,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(BuildContext context, Uint8List? bytes, ColorScheme cs) {
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _fallbackIcon(context, cs),
      );
    }
    if (avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackIcon(context, cs),
      );
    }
    return _fallbackIcon(context, cs);
  }

  Widget _fallbackIcon(BuildContext context, ColorScheme cs) =>
      Icon(Icons.person, size: sp(context, 48), color: cs.onPrimaryContainer);
}
