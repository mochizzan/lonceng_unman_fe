# DESIGN.md — Lonceng UnMan
### Aplikasi Pengingat Jadwal Kuliah Mahasiswa (Flutter)

## 1. Overview

**Lonceng UnMan** adalah aplikasi mobile Flutter yang membantu mahasiswa
memantau jadwal perkuliahan, memberikan pengingat (countdown) menuju kelas
berikutnya, dan mengelola profil akademik pribadi (NPM, Program Studi,
Semester). Nama *"Lonceng"* (bel) merepresentasikan fungsi inti aplikasi:
mengingatkan mahasiswa tepat waktu — sehingga elemen pengingat/notifikasi
menjadi motif yang konsisten di seluruh produk, bukan sekadar ikon lonceng
di app bar.

Desain mengikuti **Material 3 (Material You)** secara penuh: warna
dihasilkan secara sistematis dari satu *seed color* kuning menggunakan
algoritma HCT resmi Google, mendukung **Light Mode & Dark Mode**, dengan
tata letak **clean**, **corner radius besar**, dan **floating bottom
navigation bar**.

---

## 2. Design Principles

- **Clean & Minimal** — banyak whitespace, elemen tidak berlebihan.
- **Rounded & Soft** — semua kartu, tombol, input, dan navbar menggunakan
  radius besar (pill/blob style) sesuai Material You.
- **Personal & Dynamic Color** — primary color kuning yang hangat,
  mendukung tonal palette (container/on-container) khas M3, konsisten di
  light & dark mode.
- **Content First** — informasi penting (countdown, jadwal terdekat)
  ditempatkan di atas/hero section.
- **Consistent Navigation** — 3 menu utama, floating pill navbar dengan
  warna signature yang **tetap gelap di kedua tema** (lihat 3.6), selalu
  terlihat di semua halaman utama.
- **Reminder-First** — status waktu (countdown, "akan datang", "sedang
  berlangsung") selalu mendapat prioritas visual tertinggi di setiap layar.

---

## 3. Design System (Material 3 — Seed Color: Yellow `#FFC107`)

### 3.1 Metode Pembuatan Palet

Alih-alih menebak hex secara manual, seluruh palet di bawah ini dihasilkan
dari satu **seed color `#FFC107`** melalui algoritma **HCT (Hue-Chroma-Tone)**
resmi Material Color Utilities milik Google — algoritma yang sama yang
dipakai `ColorScheme.fromSeed()` di Flutter dan Material Theme Builder.

Ada beberapa varian generasi warna (*dynamic color variant*) di M3: default
Flutter (**Tonal Spot**) sengaja **meredam saturasi** primary color demi
tampilan yang lebih tenang — untuk kuning, ini membuat primary berubah jadi
cokelat-mustard, bukan kuning cerah. Karena brief ini secara eksplisit minta
kuning tetap terasa sebagai primary, palet ini dibangun dengan varian
**Fidelity**, yang menjaga saturasi & terang seed color asli sedekat
mungkin — hasilnya, `PrimaryContainer` menjadi **persis `#FFC107`**, tetap
konsisten di light maupun dark mode, sementara seluruh pasangan
warna/teks tetap otomatis memenuhi rasio kontras minimum WCAG yang
disyaratkan role masing-masing oleh spesifikasi M3 (dicek: Primary/On
Primary 6.5:1, Primary Container/On Primary Container 4.56:1, Background/On
Background 16:1 — semuanya lolos AA, sebagian besar lolos AAA).

### 3.2 Color Roles — Light Mode

| Role | Hex | Keterangan |
|---|---|---|
| Primary | `#785900` | Teks/ikon interaktif (link, selected state) di atas Surface |
| On Primary | `#FFFFFF` | Teks/ikon di atas Primary |
| Primary Container | `#FFC107` | **Kuning brand asli** — hero card, CTA utama, active tab |
| On Primary Container | `#6D5100` | Teks/ikon di atas Primary Container |
| Secondary | `#745B1F` | Warna pendukung (ikon sekunder) |
| On Secondary | `#FFFFFF` | Teks di atas Secondary |
| Secondary Container | `#FFDB92` | Chip/badge SKS, tag ringan |
| On Secondary Container | `#795F23` | Teks di atas Secondary Container |
| Tertiary | `#006877` | Aksen kontras opsional (ilustrasi, grafik, empty state) |
| On Tertiary | `#FFFFFF` | Teks di atas Tertiary |
| Tertiary Container | `#00DEFD` | Highlight dekoratif, dipakai terbatas & untuk elemen besar/ikon |
| On Tertiary Container | `#005E6C` | Teks di atas Tertiary Container |
| Error | `#BA1A1A` | Validasi form gagal |
| On Error | `#FFFFFF` | Teks di atas Error |
| Error Container | `#FFDAD6` | Background pesan error |
| On Error Container | `#93000A` | Teks di atas Error Container |
| Background / Surface | `#FFF8F2` | Background layar (warm off-white) |
| On Background / On Surface | `#201B11` | Teks utama |
| Surface Variant | `#F0E1C6` | Fill sekunder (jarang dipakai langsung, lihat surface container) |
| On Surface Variant | `#4F4632` | Teks sekunder/caption |
| Surface Container Lowest | `#FFFFFF` | Elemen "terbenam" (mis. dasar search bar) |
| Surface Container Low | `#FEF2E1` | Elevasi tipis |
| Surface Container | `#F8ECDB` | **Card item** (list jadwal), elevasi standar |
| Surface Container High | `#F2E7D6` | Stat card, elemen sedikit lebih menonjol |
| Surface Container Highest | `#ECE1D0` | Fill input field, elemen paling menonjol dari base surface |
| Outline | `#827660` | Border tipis pada komponen (outlined button, dsb) |
| Outline Variant | `#D4C5AB` | Divider halus |
| Inverse Surface | `#363024` | Snackbar, tooltip |
| Inverse On Surface | `#FBEFDE` | Teks di atas Inverse Surface |
| Shadow / Scrim | `#000000` | Bayangan kartu, overlay modal |
| Surface Tint | `#785900` | Tint overlay tipis di atas elevasi Material 3 |

### 3.3 Color Roles — Dark Mode

| Role | Hex | Keterangan |
|---|---|---|
| Primary | `#FFE4AF` | Teks/ikon interaktif di atas Surface gelap |
| On Primary | `#3F2E00` | Teks/ikon di atas Primary |
| Primary Container | `#FFC107` | **Tetap kuning brand asli** — tidak meredup di dark mode |
| On Primary Container | `#6D5100` | Sama seperti light mode, kontras tetap terjaga (4.56:1) |
| Secondary | `#E4C27C` | Warna pendukung di dark mode |
| On Secondary | `#3F2E00` | Teks di atas Secondary |
| Secondary Container | `#5D460A` | Chip/badge SKS versi gelap |
| On Secondary Container | `#D5B46F` | Teks di atas Secondary Container |
| Tertiary | `#B4F0FF` | Aksen kontras di dark mode |
| On Tertiary | `#00363F` | Teks di atas Tertiary |
| Tertiary Container | `#00DEFD` | Tetap konsisten dengan light mode |
| On Tertiary Container | `#005E6C` | Teks di atas Tertiary Container |
| Error | `#FFB4AB` | Validasi form gagal (dark) |
| On Error | `#690005` | Teks di atas Error |
| Error Container | `#93000A` | Background pesan error (dark) |
| On Error Container | `#FFDAD6` | Teks di atas Error Container |
| Background / Surface | `#181309` | Background layar gelap (warm near-black, bukan hitam pekat) |
| On Background / On Surface | `#ECE1D0` | Teks utama di dark mode |
| Surface Variant | `#4F4632` | Fill sekunder gelap |
| On Surface Variant | `#D4C5AB` | Teks sekunder/caption gelap |
| Surface Container Lowest | `#120E05` | Elemen "terbenam" |
| Surface Container Low | `#201B11` | Elevasi tipis |
| Surface Container | `#241F14` | **Card item** (list jadwal) versi dark |
| Surface Container High | `#2F291E` | Stat card versi dark |
| Surface Container Highest | `#3A3428` | Fill input field versi dark |
| Outline | `#9C8F78` | Border tipis dark mode |
| Outline Variant | `#4F4632` | Divider halus dark mode |
| Inverse Surface | `#ECE1D0` | Snackbar, tooltip di dark mode |
| Inverse On Surface | `#363024` | Teks di atas Inverse Surface |
| Shadow / Scrim | `#000000` | Bayangan & overlay tetap hitam |
| Surface Tint | `#FABD00` | Tint overlay di dark mode |

> Pattern penting: karena `Primary Container` fixed di kedua tema, seluruh
> elemen "brand moment" (hero countdown, tombol utama, active tab) **tidak
> perlu logika kondisional warna** antara light/dark — cukup satu token.

### 3.4 Custom Semantic Color — Success

Status **"Sedang Berlangsung"** butuh warna hijau yang jelas maknanya secara
universal, sehingga **tidak** di-*harmonize* ke hue kuning (sama seperti
`Error` di M3 yang selalu merah apa pun seed color-nya). Dibuat dengan
metode HCT yang sama agar konsisten secara sistem:

| Role | Light | Dark |
|---|---|---|
| Success | `#006E1B` | `#7BDC78` |
| On Success | `#FFFFFF` | `#003909` |
| Success Container | `#97F991` | `#005312` |
| On Success Container | `#002204` | `#97F991` |

Dipakai khusus untuk: status "Sedang Berlangsung" pada card jadwal, dan
indikator sukses (mis. toast "Data berhasil diperbarui").

### 3.5 Referensi Tonal Palette Lengkap

Tabel ini untuk kebutuhan development (custom shade, state layer opacity,
dsb) — bukan untuk dipakai langsung di UI, cukup pakai role di 3.2–3.4.

| Tone | Primary | Secondary | Tertiary | Success | Neutral | Neutral Var. |
|---|---|---|---|---|---|---|
| 10 | `#261A00` | `#261A00` | `#001F25` | `#002204` | `#201B11` | `#221B0A` |
| 20 | `#3F2E00` | `#3F2E00` | `#00363F` | `#003909` | `#363024` | `#382F1D` |
| 30 | `#5B4300` | `#5A4307` | `#004E5A` | `#005312` | `#4C463C`* | `#4F4632` |
| 40 | `#785900` | `#745B1F` | `#006877` | `#006E1B` | `#645E53`* | `#685D48` |
| 50 | `#977100` | `#8F7335` | `#008396` | `#278930` | `#7D766B`* | `#827660` |
| 60 | `#B78A00` | `#AB8D4C` | `#009FB6` | `#45A448` | `#979084`* | `#9C8F78` |
| 70 | `#D8A300` | `#C7A763` | `#00BCD6` | `#60BF60` | `#B2AA9E`* | `#B7AA91` |
| 80 | `#FABD00` | `#E4C27C` | `#00DAF8` | `#7BDC78` | `#CEC5B8`* | `#D4C5AB` |
| 90 | `#FFDF9E` | `#FFDF9E` | `#A5EEFF` | `#97F991` | `#EBE1D4`* | `#F0E1C6` |
| 98 | — | — | — | — | `#FFF8F2` | — |

<sub>*Neutral tone diambil dari palet referensi umum M3; digunakan untuk
Background/Surface/Outline pada 3.2–3.3.</sub>

### 3.6 Elemen Signature (Fixed di Kedua Tema)

Floating navbar & FAB **sengaja tidak mengikuti Light/Dark mode** — ini
identitas visual "Lonceng UnMan" yang konsisten, sama seperti pola
bottom-nav gelap pada banyak aplikasi consumer modern:

| Role | Hex | Keterangan |
|---|---|---|
| Navbar Surface (fixed) | `#201B11` | Neutral tone 10 — dipakai di light **dan** dark mode |
| On Navbar Surface (fixed) | `#FBEFDE` | Ikon/label item non-aktif |
| Navbar Active Pill | `#FFC107` (Primary Container) | Background pill di sekitar ikon aktif |
| On Navbar Active Pill | `#6D5100` (On Primary Container) | Ikon/label item aktif |

### 3.7 Typography

Menggunakan **type scale resmi M3**. Font: **Roboto** (body/label — bawaan
M3, aman untuk kontras & keterbacaan kecil) dipasangkan dengan
**Plus Jakarta Sans** (display/headline/title — geometris & sedikit
membulat, senada dengan bentuk pill/rounded di seluruh UI).
Catatan: *Google Sans* pada draf sebelumnya bukan font publik/tidak
tersedia di Google Fonts untuk aplikasi pihak ketiga, sehingga diganti agar
bisa langsung dipakai lewat package `google_fonts` di Flutter.

| M3 Token | Size/Line-height | Weight | Font | Dipakai untuk |
|---|---|---|---|---|
| Display Large | 57sp / 64sp | Regular | Plus Jakarta Sans | Angka countdown besar |
| Headline Small | 24sp / 32sp | SemiBold | Plus Jakarta Sans | Judul halaman ("Jadwal Kuliah") |
| Title Large | 22sp / 28sp | SemiBold | Plus Jakarta Sans | Nama lengkap user (Profile header) |
| Title Medium | 16sp / 24sp | Medium | Plus Jakarta Sans | Nama matakuliah |
| Body Medium | 14sp / 20sp | Regular | Roboto | Deskripsi, bio |
| Body Small | 12sp / 16sp | Regular | Roboto | Caption sekunder |
| Label Large | 14sp / 20sp | Medium | Roboto | Teks tombol |
| Label Medium | 12sp / 16sp | Medium | Roboto | Chip, timestamp |

### 3.8 Shape (M3 Shape Scale)

| M3 Token | Radius | Elemen |
|---|---|---|
| Extra Large | 32px | Hero card (countdown, profile header) |
| Large | 20–24px | Card item (jadwal, list), Button filled/tonal |
| Medium | 16px | Input field |
| Full (pill) | 999px | Chip/Badge, Floating Navbar, tombol CTA utama |
| Full (circle) | — | Avatar |

### 3.9 Elevation

M3 memakai **tonal elevation** (permukaan makin tinggi → makin dekat ke
warna Primary lewat `Surface Tint`) sebagai sinyal utama, bukan cuma
bayangan:

| Level | Role Surface | Dipakai untuk |
|---|---|---|
| 0 | Surface / Background | Layar dasar |
| 1 | Surface Container | Card item |
| 2 | Surface Container High | Stat card |
| 3 | Surface Container Highest | Input field, dialog |

Untuk elemen yang benar-benar "mengambang" di atas konten (navbar, hero
card, FAB), tetap dikombinasikan dengan drop-shadow lembut sesuai brief
awal:

- Kartu: `0px 4px 12px rgba(0,0,0,0.06)`
- Floating navbar: `0px 8px 20px rgba(0,0,0,0.25)`

### 3.10 Implementasi Flutter

```dart
// theme/color_scheme.dart
import 'package:flutter/material.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF785900),
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFFFC107),
  onPrimaryContainer: Color(0xFF6D5100),
  secondary: Color(0xFF745B1F),
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFFFFDB92),
  onSecondaryContainer: Color(0xFF795F23),
  tertiary: Color(0xFF006877),
  onTertiary: Color(0xFFFFFFFF),
  tertiaryContainer: Color(0xFF00DEFD),
  onTertiaryContainer: Color(0xFF005E6C),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFFFDAD6),
  onErrorContainer: Color(0xFF93000A),
  surface: Color(0xFFFFF8F2),
  onSurface: Color(0xFF201B11),
  surfaceContainerLowest: Color(0xFFFFFFFF),
  surfaceContainerLow: Color(0xFFFEF2E1),
  surfaceContainer: Color(0xFFF8ECDB),
  surfaceContainerHigh: Color(0xFFF2E7D6),
  surfaceContainerHighest: Color(0xFFECE1D0),
  onSurfaceVariant: Color(0xFF4F4632),
  outline: Color(0xFF827660),
  outlineVariant: Color(0xFFD4C5AB),
  inverseSurface: Color(0xFF363024),
  onInverseSurface: Color(0xFFFBEFDE),
  inversePrimary: Color(0xFFFABD00),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFF785900),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFFFE4AF),
  onPrimary: Color(0xFF3F2E00),
  primaryContainer: Color(0xFFFFC107),
  onPrimaryContainer: Color(0xFF6D5100),
  secondary: Color(0xFFE4C27C),
  onSecondary: Color(0xFF3F2E00),
  secondaryContainer: Color(0xFF5D460A),
  onSecondaryContainer: Color(0xFFD5B46F),
  tertiary: Color(0xFFB4F0FF),
  onTertiary: Color(0xFF00363F),
  tertiaryContainer: Color(0xFF00DEFD),
  onTertiaryContainer: Color(0xFF005E6C),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF93000A),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF181309),
  onSurface: Color(0xFFECE1D0),
  surfaceContainerLowest: Color(0xFF120E05),
  surfaceContainerLow: Color(0xFF201B11),
  surfaceContainer: Color(0xFF241F14),
  surfaceContainerHigh: Color(0xFF2F291E),
  surfaceContainerHighest: Color(0xFF3A3428),
  onSurfaceVariant: Color(0xFFD4C5AB),
  outline: Color(0xFF9C8F78),
  outlineVariant: Color(0xFF4F4632),
  inverseSurface: Color(0xFFECE1D0),
  onInverseSurface: Color(0xFF363024),
  inversePrimary: Color(0xFF785900),
  shadow: Color(0xFF000000),
  scrim: Color(0xFF000000),
  surfaceTint: Color(0xFFFABD00),
);

// Warna semantik "Success" & navbar signature tidak ada di ColorScheme
// bawaan Flutter -> daftarkan lewat ThemeExtension.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.navbarSurface,
    required this.onNavbarSurface,
  });

  final Color success, onSuccess, successContainer, onSuccessContainer;
  final Color navbarSurface, onNavbarSurface;

  static const light = AppColors(
    success: Color(0xFF006E1B),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFF97F991),
    onSuccessContainer: Color(0xFF002204),
    navbarSurface: Color(0xFF201B11),   // fixed, sama di dark mode
    onNavbarSurface: Color(0xFFFBEFDE),
  );

  static const dark = AppColors(
    success: Color(0xFF7BDC78),
    onSuccess: Color(0xFF003909),
    successContainer: Color(0xFF005312),
    onSuccessContainer: Color(0xFF97F991),
    navbarSurface: Color(0xFF201B11),   // fixed, sama di light mode
    onNavbarSurface: Color(0xFFFBEFDE),
  );

  @override
  AppColors copyWith({Color? success, Color? onSuccess,
      Color? successContainer, Color? onSuccessContainer,
      Color? navbarSurface, Color? onNavbarSurface}) => AppColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    navbarSurface: navbarSurface ?? this.navbarSurface,
    onNavbarSurface: onNavbarSurface ?? this.onNavbarSurface,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      other is AppColors
          ? AppColors(
              success: Color.lerp(success, other.success, t)!,
              onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
              successContainer:
                  Color.lerp(successContainer, other.successContainer, t)!,
              onSuccessContainer: Color.lerp(
                  onSuccessContainer, other.onSuccessContainer, t)!,
              navbarSurface: Color.lerp(navbarSurface, other.navbarSurface, t)!,
              onNavbarSurface:
                  Color.lerp(onNavbarSurface, other.onNavbarSurface, t)!,
            )
          : this;
}

// theme/app_theme.dart
ThemeData buildTheme(ColorScheme scheme, AppColors appColors) {
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).copyWith(
      bodyMedium: GoogleFonts.roboto(textStyle: base.textTheme.bodyMedium),
      labelLarge: GoogleFonts.roboto(textStyle: base.textTheme.labelLarge),
    ),
    extensions: [appColors],
  );
}

// main.dart
MaterialApp(
  theme: buildTheme(lightColorScheme, AppColors.light),
  darkTheme: buildTheme(darkColorScheme, AppColors.dark),
  themeMode: ThemeMode.system, // bisa dioverride manual, lihat 5.4
)
```

Package tambahan yang dibutuhkan: `google_fonts` (untuk Roboto & Plus
Jakarta Sans tanpa bundling font manual).

---

## 4. Navigation Structure

Floating Bottom Navigation Bar (pill, `Navbar Surface` fixed `#201B11`),
berisi **3 menu**:

1. 🏠 **Home** — ringkasan & countdown
2. 📅 **Jadwal** — jadwal kuliah mingguan
3. 👤 **Profile** — data diri mahasiswa

Item aktif ditandai dengan background **Navbar Active Pill** (`Primary
Container`, kuning `#FFC107`) berbentuk pill di sekitar ikon, ikon lain
memakai `On Navbar Surface` (putih hangat transparan).

---

## 5. Screens

### 5.1 Login Screen

**Tujuan:** Autentikasi mahasiswa menggunakan NPM.

**Layout:**
- Background: warm gradient (`Background` → `Primary Container` tipis —
  karena Primary Container fixed, gradient ini terasa sama persis di kedua
  tema, hanya titik awalnya yang berganti)
- Logo aplikasi di atas: ikon lonceng (bell) sederhana + wordmark "Lonceng UnMan"
- Ilustrasi sederhana (mahasiswa/kalender) opsional
- Card besar (radius 32px, `Surface Container Lowest`) berisi:
  - Judul "Masuk ke Akun"
  - Input field **NPM** (outlined, radius 16px, fill `Surface Container
    Highest`, icon id-card)
  - Input field **Password** (sama, icon lock, toggle show/hide)
  - Checkbox "Ingat saya"
  - Button **"Masuk"** — filled, `Primary Container`/`On Primary Container`,
    full width, radius 24px
  - Text link "Lupa NPM/Password?" — warna `Primary`
- Tidak ada navbar (halaman auth)

---

### 5.2 Home Screen

**Tujuan:** Ringkasan cepat & pengingat countdown jadwal terdekat.

**Layout (top → bottom):**
1. **App Bar**
   - Sapaan: "Halo, [Nama Mahasiswa] 👋"
   - Ikon lonceng notifikasi (kanan atas, bulat, background `Surface
     Container High`) — badge merah (`Error`) jika ada pengingat baru

2. **Hero Countdown Card** (radius 32px, background `Primary Container`)
   - Label kecil: "Kelas berikutnya dalam"
   - Angka countdown besar (format `02:15:30`), style Display Large
   - Nama Matakuliah (Title Large)
   - Info baris: Nama Dosen (avatar bulat kecil + nama), Ruangan, Badge
     **SKS** (chip pill `Secondary Container`, contoh "3 SKS")

3. **Ringkasan Cepat** (3 small stat card sejajar, radius 20px, `Surface
   Container High`)
   - Total SKS Semester
   - Jumlah Matkul Hari Ini
   - Semester Berjalan

4. **List "Jadwal Hari Ini"**
   - Card per matakuliah (radius 20px, `Surface Container`):
     - Waktu mulai–selesai
     - Nama matakuliah (Title Medium)
     - Nama dosen + avatar
     - Chip SKS
     - Status: "Sedang Berlangsung" (`Success Container`) / "Akan Datang"
       (`Surface Variant`) / "Selesai" (`Outline Variant`, teks pudar)

5. **Floating Bottom Navbar** (Home aktif)

---

### 5.3 Jadwal Screen

**Tujuan:** Melihat seluruh jadwal kuliah mingguan.

**Layout:**
1. **App Bar**: Judul "Jadwal Kuliah" + ikon kalender (kanan)
2. **Day Selector** — scroll horizontal pill (Sen, Sel, Rab, Kam, Jum),
   hari aktif diberi background `Primary Container` penuh, teks `On
   Primary Container`
3. **Timeline List**
   - Garis vertikal penghubung waktu
   - Card jadwal (radius 20px, `Surface Container`):
     - Ikon jam + waktu (mulai–selesai)
     - Nama matakuliah (Title Medium, bold)
     - Ruangan
     - Avatar + nama dosen
     - Chip SKS (contoh: "2 SKS")
   - Kelas yang sedang berlangsung → card full berwarna **`Success`**
     dengan teks `On Success` (dipisah jelas dari brand color Primary agar
     makna status tidak tertukar dengan aksen brand)
4. **Floating Bottom Navbar** (Jadwal aktif)

---

### 5.4 Profile Screen

**Tujuan:** Menampilkan & mengelola data pribadi mahasiswa, termasuk
preferensi pengingat & tema.

**Layout:**
1. **App Bar**
   - Judul "Profil Saya"
   - Ikon **Edit** (pensil, custom profile — foto, bio)
   - Ikon **Refresh/Sync** (tombol **Pembaruan Data**)

2. **Profile Header Card** (radius 32px, background `Primary Container`)
   - Avatar besar (bulat, overlay ikon kamera untuk edit foto)
   - Nama Lengkap (Title Large)
   - Badge Program Studi (chip pill)

3. **Info Akademik** (list/grid card, radius 20px, `Surface Container`)
   - 🎓 Program Studi
   - 🆔 NPM
   - 📘 Semester
   (masing-masing baris: ikon + label + value, divider `Outline Variant`)

4. **Pengaturan Pengingat & Tema** (list card, radius 20px, `Surface
   Container`) — bagian baru, sejalan dengan nama "Lonceng":
   - 🔔 "Ingatkan saya" — dropdown 5 / 10 / 15 / 30 menit sebelum kelas
   - 🌗 "Tema Aplikasi" — segmented control Light / Dark / Ikuti Sistem
     (default: Ikuti Sistem → `ThemeMode.system`)

5. **Tab Section**: "Tentang" | "Aktivitas"
   - **Tentang**: bio singkat mahasiswa (editable text)
   - **Aktivitas**: riwayat/nilai/aktivitas akademik (list card kecil,
     opsional)

6. **Button "Perbarui Data"**
   - Full width, tonal button (`Secondary Container`), radius 24px
   - Icon refresh + teks "Perbarui Data Terbaru"
   - Fungsi: sinkronisasi jadwal baru / kenaikan semester dari server kampus

7. **Floating Bottom Navbar** (Profile aktif)

---

## 6. Components Library

| Komponen | Role Warna | Deskripsi |
|---|---|---|
| **Filled Button** | `Primary Container` / `On Primary Container` | Radius 24px, CTA utama |
| **Tonal Button** | `Secondary Container` / `On Secondary Container` | Radius 24px |
| **Outlined Button** | Border `Outline`, teks `Primary` | Transparan |
| **Text Field** | Fill `Surface Container Highest`, label `On Surface Variant` | Radius 16px |
| **Chip / Badge (SKS)** | `Secondary Container` / `On Secondary Container` | Radius full |
| **Status Chip — Berlangsung** | `Success` / `On Success` | Radius full |
| **Status Chip — Selesai** | `Outline Variant` / `On Surface Variant` | Radius full |
| **Card (Hero)** | `Primary Container` / `On Primary Container` | Radius 32px, countdown & profile header |
| **Card (Item)** | `Surface Container` / `On Surface` | Radius 20px, list jadwal |
| **Stat Card** | `Surface Container High` / `On Surface` | Radius 20px |
| **Avatar** | Border `Surface` tipis saat overlap dengan card berwarna | Full circle |
| **Floating Navbar** | `Navbar Surface` fixed / `On Navbar Surface` | Pill radius full, tidak berubah antar tema |
| **Countdown Widget** | `On Primary Container` | Angka besar, dipisah `:` |

---

## 7. Spacing & Grid

- Base spacing unit: **8px**
- Padding layar: 20–24px (kiri-kanan)
- Jarak antar card: 12–16px
- Margin floating navbar dari tepi bawah: 20px, dari tepi kiri-kanan: 24px

---

## 8. Catatan Aksesibilitas

Beberapa pasangan warna kunci sudah diverifikasi terhadap WCAG 2.1:

| Pasangan | Rasio Kontras | Standar |
|---|---|---|
| Primary / On Primary (light) | 6.51:1 | AA & AAA (teks normal) |
| Primary Container / On Primary Container | 4.56:1 | AA (teks normal) |
| Background / On Background (light) | 16.28:1 | AAA |
| Primary / On Primary (dark) | 10.59:1 | AAA |
| Success / On Success | 6.47:1 | AA & AAA |

Karena seluruh role dihasilkan lewat algoritma HCT resmi M3 (bukan hex
manual), setiap pasangan role/on-role otomatis memenuhi kurva kontras
minimum yang didefinisikan spesifikasi untuk role tersebut — tabel di atas
adalah sampel verifikasi, bukan daftar lengkap.