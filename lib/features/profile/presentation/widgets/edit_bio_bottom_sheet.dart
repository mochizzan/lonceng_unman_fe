// edit_bio_bottom_sheet.dart
//
// Bottom sheet for editing student bio.
// Contains TextField (max 1000 chars), Save button, Delete bio button.
// Dismiss confirmation when field is filled.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lonceng_unman_fe/core/di/di.dart';
import 'package:lonceng_unman_fe/core/utils/responsive.dart';
import 'package:lonceng_unman_fe/core/widgets/navbar_visibility_notifier.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:lonceng_unman_fe/features/profile/presentation/bloc/profile_event.dart';

/// Bottom sheet for editing student bio.
///
/// Shows a [TextField] with max 1000 characters, Save button,
/// and Delete bio button. Dismiss confirmation when field is filled.
class EditBioBottomSheet extends StatefulWidget {
  const EditBioBottomSheet({super.key, required this.currentBio});

  /// Current bio value (null if no bio exists).
  final String? currentBio;

  @override
  State<EditBioBottomSheet> createState() => _EditBioBottomSheetState();
}

class _EditBioBottomSheetState extends State<EditBioBottomSheet> {
  late TextEditingController _controller;
  late String _initialBio;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentBio ?? '');
    _initialBio = widget.currentBio ?? '';
    _controller.addListener(_onTextChanged);
    // Hide navbar when bottom sheet opens — defer to post-frame to avoid
    // setState during build (ListenableBuilder in MainShellScaffold).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Services.get<NavbarVisibilityNotifier>().hide();
      }
    });
  }

  void _onTextChanged() {
    final currentText = _controller.text;
    setState(() {
      _hasChanges = currentText != _initialBio;
    });
  }

  @override
  void dispose() {
    // Show navbar when bottom sheet closes — defer to post-frame to avoid
    // setState when widget tree is locked during finalizeTree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Services.get<NavbarVisibilityNotifier>().show();
    });
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<bool?> _showCancelConfirmation() async {
    final cs = Theme.of(context).colorScheme;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surfaceContainerHigh,
        title: const Text('Batalkan Perubahan?'),
        content: const Text('Perubahan belum disimpan. Yakin mau membatalkan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Tidak', style: TextStyle(color: cs.primary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Ya, Batalkan', style: TextStyle(color: cs.error)),
          ),
        ],
      ),
    );
  }

  void _onSave() {
    final bio = _controller.text.trim();
    if (bio.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bio tidak boleh kosong'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    context.read<ProfileBloc>().add(ProfileBioUpdated(bio: bio));
    Navigator.of(context).pop();
  }

  void _onDeleteBio() {
    context.read<ProfileBloc>().add(const ProfileBioDeleted());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final currentLength = _controller.text.length;
    final isOverLimit = currentLength > 1000;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirmed = await _showCancelConfirmation();
        if (confirmed == true && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(
          sp(context, 24),
          sp(context, 16),
          sp(context, 24),
          MediaQuery.of(context).viewInsets.bottom + sp(context, 24),
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(sp(context, 28)),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: sp(context, 40),
                height: sp(context, 4),
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(sp(context, 2)),
                ),
              ),
            ),
            SizedBox(height: sp(context, 16)),

            // Title
            Text(
              'Edit Bio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            SizedBox(height: sp(context, 16)),

            // Bio TextField
            TextFormField(
              controller: _controller,
              maxLines: 5,
              maxLength: 1000,
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: 'Tulis bio kamu di sini...',
                hintStyle: TextStyle(color: cs.onSurfaceVariant),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(sp(context, 16)),
                  borderSide: BorderSide(color: cs.outlineVariant, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(sp(context, 16)),
                  borderSide: BorderSide(color: cs.primaryContainer, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(sp(context, 16)),
                  borderSide: BorderSide(color: cs.error, width: 2),
                ),
                counterText: '$currentLength/1000',
                counterStyle: TextStyle(
                  color: isOverLimit ? cs.error : cs.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(height: sp(context, 16)),

            // Save button
            FilledButton(
              onPressed: isOverLimit ? null : _onSave,
              style: FilledButton.styleFrom(
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(sp(context, 24)),
                ),
                padding: EdgeInsets.symmetric(vertical: sp(context, 16)),
              ),
              child: const Text('Simpan'),
            ),
            SizedBox(height: sp(context, 12)),

            // Delete bio button
            if (_initialBio.isNotEmpty)
              OutlinedButton(
                onPressed: _onDeleteBio,
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(sp(context, 24)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: sp(context, 16)),
                ),
                child: const Text('Hapus Bio'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows the edit bio bottom sheet.
///
/// Returns the new bio value if saved, null if cancelled.
Future<void> showEditBioBottomSheet(
  BuildContext context, {
  required String? currentBio,
}) {
  // Capture the bloc from the calling context BEFORE showModalBottomSheet
  // creates a new route/overlay that doesn't have the provider.
  final profileBloc = context.read<ProfileBloc>();
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider.value(
      value: profileBloc,
      child: EditBioBottomSheet(currentBio: currentBio),
    ),
  );
}
