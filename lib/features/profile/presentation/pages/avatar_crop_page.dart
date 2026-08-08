// profile - Avatar Crop Page
//
// Halaman crop avatar buatan sendiri (tanpa package crop / uCrop):
// InteractiveViewer untuk geser + zoom manual, overlay lingkaran sebagai
// panduan area crop, dan tombol simpan yang me-render hasilnya menjadi PNG
// 256x256 lewat `dart:ui`.
//
// Posisi crop SEPENUHNYA ditentukan user — tidak ada auto-crop center.
// Child InteractiveViewer sengaja dibuat seukuran hasil BoxFit.cover (lebih
// besar dari viewport di satu sumbu) supaya geser sudah bisa sejak skala 1.
//
// Dipakai lewat Navigator.push dan mengembalikan Uint8List (PNG) atau null
// bila user membatalkan.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lonceng_unman_fe/core/constants/constants.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/avatar_crop_service.dart';

class AvatarCropPage extends StatefulWidget {
  const AvatarCropPage({super.key, required this.imageBytes});

  /// Bytes gambar sumber (hasil pilih dari galeri).
  final Uint8List imageBytes;

  @override
  State<AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<AvatarCropPage> {
  final TransformationController _controller = TransformationController();

  ui.Image? _image;
  String? _errorMessage;
  bool _saving = false;

  /// Sisi viewport crop terakhir yang dipakai LayoutBuilder.
  double _viewportSide = 0;

  /// Zoom maksimum relatif terhadap tampilan awal (BoxFit.cover).
  static const double _maxScale = 5;

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    try {
      final image = await AvatarCropService.decode(widget.imageBytes);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = AppStrings.avatarCropDecodeError);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _image?.dispose();
    super.dispose();
  }

  /// Memusatkan gambar saat viewport pertama kali diketahui atau berubah
  /// ukuran (rotasi layar). Hanya menetapkan titik AWAL; user tetap bebas
  /// menggeser setelahnya.
  ///
  /// Penetapan transform ditunda ke post-frame karena mengubah
  /// TransformationController akan memberi tahu InteractiveViewer, dan
  /// itu memicu setState — terlarang selama fase build.
  void _syncViewport(double side, Size imageSize) {
    if (side <= 0 || _viewportSide == side) return;
    _viewportSide = side;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _viewportSide != side) return;
      _controller.value = AvatarCropService.initialTransform(
        imageSize: imageSize,
        viewportSide: side,
      );
    });
  }

  Future<void> _save() async {
    final image = _image;
    if (image == null || _saving || _viewportSide <= 0) return;

    setState(() => _saving = true);
    try {
      final sourceRect = AvatarCropService.computeSourceRect(
        imageSize: Size(image.width.toDouble(), image.height.toDouble()),
        viewportSide: _viewportSide,
        transform: _controller.value,
      );
      final png = await AvatarCropService.renderCircularPng(
        image: image,
        sourceRect: sourceRect,
      );
      if (!mounted) return;
      if (png == null) {
        setState(() {
          _saving = false;
          _errorMessage = AppStrings.avatarCropRenderError;
        });
        return;
      }
      Navigator.of(context).pop<Uint8List>(png);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorMessage = AppStrings.avatarCropRenderError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text(AppStrings.avatarCropTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: AppStrings.avatarCropCancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.screenPaddingHorizontal,
                vertical: AppDimens.space12,
              ),
              child: Text(
                AppStrings.avatarCropHint,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: responsiveFontSize(context, 14),
                ),
              ),
            ),
            Expanded(child: _buildStage(cs)),
            Padding(
              padding: const EdgeInsets.all(AppDimens.screenPaddingHorizontal),
              child: _buildActions(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStage(ColorScheme cs) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimens.screenPaddingHorizontal),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.error),
          ),
        ),
      );
    }

    final image = _image;
    if (image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    return LayoutBuilder(
      builder: (context, constraints) {
        // Viewport crop selalu kotak agar hasilnya 1:1.
        final side = constraints.biggest.shortestSide;
        _syncViewport(side, imageSize);

        final display = AvatarCropService.displaySize(
          imageSize: imageSize,
          viewportSide: side,
        );

        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRect(
                    child: InteractiveViewer(
                      transformationController: _controller,
                      constrained: false,
                      minScale: 1,
                      maxScale: _maxScale,
                      boundaryMargin: EdgeInsets.zero,
                      child: SizedBox(
                        width: display.width,
                        height: display.height,
                        child: RawImage(image: image, fit: BoxFit.fill),
                      ),
                    ),
                  ),
                ),
                // Overlay lingkaran: area luar diredupkan, area dalam bersih.
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CircleMaskPainter(
                        overlayColor: cs.scrim.withValues(alpha: 0.55),
                        borderColor: cs.primary,
                        borderWidth: sp(context, 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context) {
    final canSave = _image != null && !_saving && _errorMessage == null;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.space16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radius3XL),
              ),
            ),
            child: const Text(AppStrings.avatarCropCancel),
          ),
        ),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: FilledButton(
            onPressed: canSave ? _save : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppDimens.space16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radius3XL),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: AppDimens.iconSM,
                    height: AppDimens.iconSM,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(AppStrings.avatarCropSave),
          ),
        ),
      ],
    );
  }
}

/// Menggelapkan area di luar lingkaran crop dan menggambar cincin panduan.
class _CircleMaskPainter extends CustomPainter {
  const _CircleMaskPainter({
    required this.overlayColor,
    required this.borderColor,
    required this.borderWidth,
  });

  final Color overlayColor;
  final Color borderColor;
  final double borderWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Offset.zero & size;
    final circle = Path()..addOval(full);
    final mask = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      circle,
    );

    canvas.drawPath(mask, Paint()..color = overlayColor);
    canvas.drawPath(
      circle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth
        ..color = borderColor
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_CircleMaskPainter oldDelegate) =>
      oldDelegate.overlayColor != overlayColor ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth;
}
