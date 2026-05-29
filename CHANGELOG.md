## 0.0.6

* Align all platforms to resvg **v0.42.0** (the version the iOS/macOS pod
  `resvg ~> 0.1.2` already ships via the `resvg.xcframework` published by
  `rustui/resvg_action`). No precompiled iOS xcframework exists for newer
  resvg releases yet, so the whole plugin is pinned to 0.42 for now.
* Rebuild Android `libresvg.so` (arm64-v8a, x86_64, armeabi-v7a) from
  resvg v0.42.0 source with the `text` feature enabled. The previous Maven
  AAR `io.github.rustui:resvg:0.3` was compiled without `--features text`,
  so every font-related call (`resvg_options_load_font_data`,
  `resvg_options_load_system_fonts`, `resvg_options_set_font_family`) was
  a silent no-op and `<text>` elements never rendered on Android.
* Drop the `io.github.rustui:resvg` Maven dependency; the native library is
  now shipped directly under `android/src/main/jniLibs/<abi>/libresvg.so`.
* Rebuild Linux `libresvg.so` from the same resvg v0.42.0 source.
* Restore `src/resvg.h` to the upstream v0.42.0 header (bit-identical to
  `ios/Classes/resvg.h`) and regenerate `lib/resvg_bindings_generated.dart`
  via `ffigen` so Dart bindings match the linked native library on every
  platform.

## 0.0.5

* Add Android(x86_64) support.

## 0.0.4

* Add MacOS support.

## 0.0.3

* Add Android support.

## 0.0.2

* Add `ReSvg` class.

## 0.0.1

* Initial release.
