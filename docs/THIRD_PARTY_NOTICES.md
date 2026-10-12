# Third-Party Notices

Space Apps requires every source to be cited, including open-source and freely available material. This file lists everything SkyLens uses that we did not write. The app also shows the full licence texts under **Settings → Credits and licences** (Flutter's `showLicensePage`, which collects every package licence automatically, plus the bundled font and data registered in `app/lib/main.dart`).

SkyLens's own code is [MIT](../LICENSE). Last reviewed: 2026-10-11. Re-run the review if `pubspec.lock` changes.

## Dart and Flutter packages

All 121 resolved packages (direct, dev and transitive) are under permissive OSI licences: BSD-3-Clause (79, plus the 3 Flutter SDK packages), MIT (24), Apache-2.0 (7), BSD-2-Clause (5) and MPL-2.0 (3). There is no GPL or LGPL code.

| Package | Version | Licence | Use |
|---|---|---|---|
| flutter (SDK) | 3.47.2 | BSD-3-Clause | UI framework |
| flutter_riverpod | 3.4.3 | MIT | State management |
| go_router | 18.0.2 | BSD-3-Clause | Navigation |
| dio | 5.11.1 | MIT | HTTP client |
| hive_ce, hive_ce_flutter | 2.20.2, 2.4.0 | Apache-2.0 | Local storage and cache |
| sensors_plus | 7.1.1 | BSD-3-Clause | Accelerometer, magnetometer, gyroscope |
| geolocator | 14.1.1 | MIT | Location |
| camera | 0.12.1 | BSD-3-Clause | AR camera preview |
| intl | 0.20.3 | BSD-3-Clause | Date and number formatting |
| url_launcher | 6.3.3 | BSD-3-Clause | Opening source links |
| cached_network_image | 4.0.4 | MIT | Image caching |
| path_provider | 2.1.6 | BSD-3-Clause | Storage paths |
| cupertino_icons | 1.0.9 | MIT | Icon font |
| flutter_lints *(dev)* | 6.0.0 | BSD-3-Clause | Lint rules |
| mocktail *(dev)* | 1.0.5 | MIT | Test mocks |

**MPL-2.0 note:** `dbus`, `geoclue` and `gsettings` are pulled in by geolocator's Linux-desktop backend only. They are not compiled into the Android or web builds we submit. MPL-2.0 is file-level copyleft: using them unmodified places no obligation on our code.

## Bundled assets

| Asset | Path | Author | Licence | Obligation |
|---|---|---|---|---|
| Inter typeface (4 weights) | `app/assets/fonts/Inter-*.ttf` | Rasmus Andersson / The Inter Project Authors | SIL OFL 1.1 | Ship the licence with the font: `Inter-OFL.txt`, also shown on the in-app licence page |
| HYG star database v4.0 (subset, mag ≤ 5.5) | `app/assets/catalog/stars.json` | David Nash (astronexus) | CC BY-SA 4.0 | Attribute it; changes to the **data file** stay CC BY-SA |
| Constellation lines | `app/assets/catalog/constellations.json` | Olaf Frohn (d3-celestial) | BSD-3-Clause | Keep the copyright notice |
| Mock API fixtures | `app/assets/mock/` | NASA, Open-Meteo responses | Same as the live source (below) | Same as the source |
| Material Icons | Flutter SDK | Google | Apache-2.0 | Covered by the Flutter licence |
| Lucide icons (beginner-guide deck only, not the app) | `beginner-guide/` | Lucide contributors | ISC | Keep the notice |

## Data services

See [DATA_SOURCES.md](DATA_SOURCES.md) for endpoints, rate limits and status. Each card in the app shows its source through `SourceBadge`.

| Service | Licence / terms | Credit line to use |
|---|---|---|
| NASA APOD | NASA content is generally public domain. Some images are © their authors (the `copyright` field) | "Image: NASA APOD" or "© <author>, via NASA APOD" |
| NASA NeoWs | Public domain (NASA/JPL CNEOS) | "Data: NASA NeoWs" |
| NASA DONKI (CCMC) | Public domain | "Data: NASA CCMC DONKI" |
| NASA Image and Video Library | Generally public domain. Check the item's metadata | "Courtesy NASA" |
| Open-Meteo | CC BY 4.0 | "Weather data by Open-Meteo.com" |

NASA's name, logo ("meatball") and insignia are **not** public domain and must not be used to suggest endorsement. SkyLens is not endorsed by NASA.

## Before submission (event day)

- [ ] Add a row for every new package, dataset, image, model or AI provider the team adds.
- [ ] If an AI model or API generates any content, name the provider and model here and on the project page. See [AI_GUIDELINES.md](AI_GUIDELINES.md).
- [ ] Copy the "Data services" credit lines into the project page.
