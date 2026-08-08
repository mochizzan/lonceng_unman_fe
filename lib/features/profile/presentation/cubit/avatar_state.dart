// profile - Avatar State
//
// State untuk foto profil lokal. Sengaja memakai Cubit (bukan Bloc) karena
// transisi state-nya sederhana: muat, sedang proses, tampil, gagal.

import 'dart:typed_data';

sealed class AvatarState {
  const AvatarState();

  /// Bytes avatar yang harus ditampilkan UI, null bila belum ada foto.
  ///
  /// State sibuk dan state gagal tetap membawa avatar sebelumnya agar UI
  /// tidak berkedip kosong saat operasi berlangsung atau gagal.
  Uint8List? get bytes;
}

/// State awal sebelum cache dibaca.
class AvatarInitial extends AvatarState {
  const AvatarInitial();

  @override
  Uint8List? get bytes => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AvatarInitial;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Sedang memilih, memproses crop, atau menyimpan.
class AvatarProcessing extends AvatarState {
  const AvatarProcessing({this.bytes});

  @override
  final Uint8List? bytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarProcessing &&
          runtimeType == other.runtimeType &&
          bytes == other.bytes;

  @override
  int get hashCode => Object.hash(runtimeType, bytes);
}

/// Avatar siap ditampilkan. [bytes] null berarti belum ada foto tersimpan.
class AvatarReady extends AvatarState {
  const AvatarReady(this.bytes);

  @override
  final Uint8List? bytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarReady &&
          runtimeType == other.runtimeType &&
          bytes == other.bytes;

  @override
  int get hashCode => Object.hash(runtimeType, bytes);
}

/// Operasi terakhir gagal; [bytes] adalah avatar yang tetap ditampilkan.
class AvatarFailure extends AvatarState {
  const AvatarFailure(this.message, {this.bytes});

  final String message;

  @override
  final Uint8List? bytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvatarFailure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          bytes == other.bytes;

  @override
  int get hashCode => Object.hash(runtimeType, message, bytes);
}
