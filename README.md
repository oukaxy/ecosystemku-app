# EcosystemKu — Native Android App

Flutter super app: Asisten (Rem, Live2D), Apps Hub (Daily OS, IdeKu, Kronik,
CuciMoney+, LinkKu), dan Setelan. Data tersimpan lokal (Drift/SQLite), backup
ZIP v3 kompatibel dengan web versi lama.

Repo ini hasil split dari [`oukaxy/ecosystemku`](https://github.com/oukaxy/ecosystemku)
(PWA). Riwayat commit app dipertahankan; PWA tetap live di repo lama.

## Build

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Folder `android/` tidak di-commit. Generate sekali dengan:

```bash
bash tool/bootstrap_android.sh
```

CI (`.github/workflows/android.yml`) menjalankan hal yang sama: bootstrap,
build_runner, format, analyze, test, build APK debug.

## Aset Live2D

- Model Rem ada di `assets/live2d/rem/` — **sumber kanonik** untuk repo ini.
  Jangan edit salinan app langsung; perubahan model dilakukan di sini.
- Runtime (`vendor/`: Cubism Core, Pixi 6.5.10, pixi-live2d-display 0.4.0)
  di-vendor offline; halaman adapter di `assets/live2d/` (documentRoot server localhost).
- `assets/live2d/rem/checksums.sha256` diverifikasi oleh
  `test/features/assistant/live2d_assets_test.dart`.

## Lisensi

Aset Live2D dan `live2dcubismcore.min.js` milik Live2D Inc. — penggunaan
mengikuti lisensi Cubism SDK (lihat pertanyaan terbuka #1 di `mahfud.md`).
Jangan distribusikan APK tanpa menyelesaikan lisensi ini.
