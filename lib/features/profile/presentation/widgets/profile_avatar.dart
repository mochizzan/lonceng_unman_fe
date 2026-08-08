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
import 'package:go_router/go_router.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/routes/route_names.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/avatar_picker_service.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_cubit.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/cubit/avatar_state.dart';

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

    final cropped = await context.pushNamed<Uint8List?>(
      RouteNames.avatarCrop,
      extra: source,
    );

    if (!context.mounted) return;
    if (cropped == null) {
      cubit.cancelProcessing();
      return;
    }
    await cubit.save(cropped);
  }

  /// Menangani ketukan pada avatar: tampilkan opsi ganti/hapus bila sudah
  /// punya foto, atau langsung buka galeri bila belum.
  Future<void> _onAvatarTap(BuildContext context, bool hasPhoto) async {
    if (!hasPhoto) {
      await _pickAndCrop(context);
      return;
    }
    await _showPhotoSheet(context);
  }

  Future<void> _showPhotoSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  sp(sheetContext, 16),
                  0,
                  sp(sheetContext, 16),
                  sp(sheetContext, 12),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppStrings.avatarSheetTitle,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library, size: sp(sheetContext, 24)),
                title: const Text(AppStrings.avatarSheetChange),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pickAndCrop(context);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  size: sp(sheetContext, 24),
                  color: cs.error,
                ),
                title: Text(
                  AppStrings.avatarSheetRemove,
                  style: TextStyle(color: cs.error),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _confirmRemove(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text(AppStrings.avatarRemoveConfirmTitle),
          content: const Text(AppStrings.avatarRemoveConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(AppStrings.avatarRemoveConfirmNo),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: cs.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(AppStrings.avatarRemoveConfirmYes),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      if (!context.mounted) return;
      await context.read<AvatarCubit>().remove();
    }
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
        final hasPhoto = state.bytes != null && state.bytes!.isNotEmpty;

        return SizedBox(
          width: sp(context, size),
          height: sp(context, size),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Material(
                  color: cs.onPrimary.withValues(alpha: 0.12),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: busy ? null : () => _onAvatarTap(context, hasPhoto),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.surface,
                          width: sp(context, 4),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppDimens.radiusFull,
                        ),
                        child: _buildImage(context, state.bytes, cs),
                      ),
                    ),
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
                    onTap: busy ? null : () => _onAvatarTap(context, hasPhoto),
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
