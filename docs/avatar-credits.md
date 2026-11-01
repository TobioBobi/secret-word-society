# Avatar sources and licenses

Avatars use **Cutouts** by [DiceBear](https://www.dicebear.com), released under
[CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/).
The definition is imported from `dicebear_styles` **10.6.0**, exclusively through
`package:dicebear_styles/cutouts.dart`; no other styles or rendered face collection
are bundled. The package documents the artist and license in that file.

The engine `dicebear_core` **10.7.0** is MIT licensed. Flutter includes its license
and those of its dependencies, including `flutter_svg`, in the release license
bundle. The Cutouts notice is additionally bundled as `assets/licenses/cutouts.txt`
and registered with Flutter's `LicenseRegistry`.

SVGs are generated in process from the style defaults and a session-only random
seed. No remote image or avatar service is used. The pinned engine and definition
versions keep the same seed reproducible. SVG metadata may be ignored by the
Flutter renderer; artwork attribution is preserved separately above.
