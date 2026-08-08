//
// ImagePicker adalah kelas konkret dengan method pickImage yang memanggil
// platform channel. Kita mem-fake-nya dengan membuat subclass sendiri yang
// meng-override pickImage agar melempar PlatformException atau
// mengembalikan null sesuai skenario.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lonceng_unman_fe/core/constants/app_strings.dart';
import 'package:lonceng_unman_fe/features/profile/data/services/avatar_picker_service.dart';

/// Fake [ImagePicker] yang perilakunya bisa dikonfigurasi per test.
///
/// Secara default melempar [PlatformException] dengan [defaultCode].
/// Bila [returnsNull] true, `pickImage` mengembalikan null tanpa melempar.
class _FakeImagePicker extends ImagePicker {
  _FakeImagePicker({
    this.defaultCode = 'multiple_request',
    this.returnsNull = false,
  });

  /// Kode PlatformException yang akan dilempar.
  final String defaultCode;

  /// Bila true, pickImage mengembalikan null (user membatalkan).
  final bool returnsNull;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    if (returnsNull) return null;
    throw PlatformException(code: defaultCode);
  }
}

void main() {
  group('AvatarPickerService', () {
    test('PlatformException(code: photo_access_denied) melempar '
        'AvatarPermissionDeniedException', () async {
      final service = AvatarPickerService(
        picker: _FakeImagePicker(defaultCode: 'photo_access_denied'),
      );
      // Fungsi async: WAJIB di-await lewat expectLater agar future
      // benar-benar ditunggu sebelum test selesai.
      await expectLater(
        service.pickFromGallery(),
        throwsA(isA<AvatarPermissionDeniedException>()),
      );
    });

    test(
      'PlatformException dengan kode non-izin melempar '
      'AvatarPickFailedException, BUKAN AvatarPermissionDeniedException',
      () async {
        final service = AvatarPickerService(
          picker: _FakeImagePicker(defaultCode: 'multiple_request'),
        );
        // Untuk fungsi async, `isNot(throwsA(...))` adalah matcher yang rusak
        // karena evaluasinya asinkron. Cara yang benar: tangkap exception-nya
        // lalu periksa tipenya secara eksplisit.
        Object? caught;
        try {
          await service.pickFromGallery();
        } catch (e) {
          caught = e;
        }
        expect(caught, isA<AvatarPickFailedException>());
        expect(caught, isNot(isA<AvatarPermissionDeniedException>()));
      },
    );

    test('pickImage mengembalikan null -> pickFromGallery mengembalikan '
        'null dan TIDAK melempar (user membatalkan)', () async {
      final service = AvatarPickerService(
        picker: _FakeImagePicker(returnsNull: true),
      );
      final result = await service.pickFromGallery();
      expect(result, isNull);
    });
  });

  group('AppStrings avatar baru', () {
    // Semua string baru harus terdefinisi (tidak kosong).
    final strings = <String>[
      AppStrings.avatarPermissionDenied,
      AppStrings.avatarSheetTitle,
      AppStrings.avatarSheetChange,
      AppStrings.avatarSheetRemove,
      AppStrings.avatarRemoveConfirmTitle,
      AppStrings.avatarRemoveConfirmBody,
      AppStrings.avatarRemoveConfirmYes,
      AppStrings.avatarRemoveConfirmNo,
    ];

    for (var i = 0; i < strings.length; i++) {
      test('string avatar #${i + 1} tidak kosong', () {
        expect(strings[i].isNotEmpty, isTrue);
      });
    }

    test('avatarPermissionDenied memuat kata "Pengaturan"', () {
      expect(AppStrings.avatarPermissionDenied.contains('Pengaturan'), isTrue);
    });
  });
}
