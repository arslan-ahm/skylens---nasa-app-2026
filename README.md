# SkyLens

[![CI](https://github.com/arslan-ahm/skylens---nasa-app-2026/actions/workflows/ci.yml/badge.svg)](https://github.com/arslan-ahm/skylens---nasa-app-2026/actions/workflows/ci.yml)

A free, cross-platform personal observatory: sky map, AR sky view, Tonight's Sky, observation planner and logbook, NASA data, and a pathway into citizen science.

> **Pre-hackathon status:** This repo holds only reusable infrastructure built before NASA Space Apps Challenge 2026. Challenge-specific work starts when the event opens. See [docs/PREPARED_BEFORE_EVENT.md](docs/PREPARED_BEFORE_EVENT.md) for the full disclosure, and [docs/PRE_EVENT_CHECKLIST.md](docs/PRE_EVENT_CHECKLIST.md) for what's left to test before the event.

**Honest positioning:** SkyLens is not a telescope and makes no discovery claims. Any AI feature only explains verified data and cites its sources.

---

## Problem

> TODO (hackathon day): State the chosen challenge and the problem it addresses, in 2–3 sentences.

## Solution

> TODO (hackathon day): Describe how SkyLens addresses the challenge.

## Key Features

Infrastructure available in the starter (verified in the in-app **Dev Lab**):

- Offline sky engine: Sun, Moon, planets, 2,865 stars (mag ≤ 5.5), constellation lines
- Rise/set and twilight times for any location
- Device pointing: accelerometer + magnetometer → azimuth/altitude, compass calibration
- AR overlay projection (sky direction → screen point)
- NASA data: APOD, NeoWs, DONKI, NASA Image & Video Library
- Weather (cloud cover) from Open-Meteo
- Local observation logbook (Hive)
- Flat dark design system ([docs/DESIGN_TOKENS.md](docs/DESIGN_TOKENS.md)), plus night-vision red and high-contrast themes

> TODO (hackathon day): List the user-facing features built for the chosen challenge.

## How It Works

1. Location comes from GPS, or a fallback location if permission is denied.
2. The pure-Dart astronomy engine computes positions for the current time and place.
3. Device sensors turn the phone's orientation into a sky direction; the projector maps objects onto the camera/screen.
4. Network data is fetched through a cache with a TTL. Each result carries a `DataProvenance` record (source, URL, license, fetchedAt, isMock), and the UI shows it as an attribution badge.
5. If live data fails, the app falls back to cached data and then to bundled mock fixtures.

## NASA and Open Data Used

| Source | Use | Status |
|---|---|---|
| NASA APOD | Daily astronomy image | Wired in starter |
| NASA NeoWs | Near-Earth objects | Wired in starter |
| NASA DONKI | Space weather events | Wired in starter |
| NASA Image & Video Library | Media search | Wired in starter |
| Open-Meteo | Cloud cover / weather | Wired in starter |
| HYG v4.0 | Star catalog (CC BY-SA 4.0) | Wired in starter |
| d3-celestial | Constellation lines (BSD-3-Clause) | Wired in starter |

Full list of candidate sources, licenses and rate limits: [docs/DATA_SOURCES.md](docs/DATA_SOURCES.md).

## Technology Stack

| Layer | Choice |
|---|---|
| App | Flutter 3.47 / Dart 3.13 (Android, iOS, Web) |
| Astronomy | Pure-Dart engine (Meeus algorithms, JPL approximate Keplerian elements) |
| Sensors | `geolocator`, `sensors_plus` |
| Networking | `dio` + TTL cache-through fetcher |
| Storage | Hive CE (settings, cache, logbook) |
| CI/CD | GitHub Actions → web build on GitHub Pages, debug APK artifact |

## Architecture

```
app/lib/
  core/
    astro/      Pure-Dart astronomy engine: time/sidereal, coordinates + precession,
                Sun, Moon, planets, rise/set/twilight, star catalog loader
    sensors/    Location, device orientation, sky projector (AR)
    network/    dio client, TTL cache fetcher, DataProvenance
    storage/    Hive CE boxes
    theme/      Design system (docs/DESIGN_TOKENS.md), night-vision red, high-contrast
    widgets/    UI kit: cards, attribution badge, states, sheets, observation form
  data/         NASA clients (APOD, NeoWs, DONKI, Image Library), Open-Meteo
  features/
    lab/        Dev Lab: screens that check each module on a real device
app/assets/
  catalog/      stars.json, constellations.json
  mock/         Offline fixtures for NASA APIs
app/tool/       build_sky_catalog.mjs
```

The Dev Lab stays in the app as a debug menu. The product shell is built on top in `features/` on hackathon day.

## Getting Started

Prerequisites: Flutter 3.47.x (stable), plus Android Studio/Xcode for device builds.

```bash
git clone git@github.com:arslan-ahm/skylens---nasa-app-2026.git && cd skylens---nasa-app-2026
cd app && flutter pub get && flutter run          # run on a connected device
flutter run -d chrome --dart-define=DATA_MODE=mock # web, offline mock data
flutter test                                       # unit tests (astro engine vs. Meeus examples)
```

### Configuration (`--dart-define`)

| Key | Values | Default |
|---|---|---|
| `NASA_API_KEY` | your api.nasa.gov key | `DEMO_KEY` |
| `DATA_MODE` | `mock` \| `live` | `live` (falls back to cache, then mock) |

Use a local file instead of inline flags. `app/.env.json` is gitignored:

```bash
cp app/.env.example.json app/.env.json   # edit the key
flutter run --dart-define-from-file=.env.json
```

### Regenerate the star catalog

```bash
node app/tool/build_sky_catalog.mjs <hyg.csv> <lines.json> <constellations.json> 5.5
```

## Demo

- **Live web build (Dev Lab, mock data):** https://arslan-ahm.github.io/skylens---nasa-app-2026/
- **Android APK:** [latest CI run](https://github.com/arslan-ahm/skylens---nasa-app-2026/actions/workflows/ci.yml) → Artifacts → `skylens-debug-apk`
- **Pre-event baseline:** [`pre-event-baseline`](https://github.com/arslan-ahm/skylens---nasa-app-2026/tree/pre-event-baseline). Compare: [`pre-event-baseline...main`](https://github.com/arslan-ahm/skylens---nasa-app-2026/compare/pre-event-baseline...main)

> TODO (hackathon day): Link to the demo video.

## Impact

> TODO (hackathon day): Who benefits and how. Use measurable outcomes where possible.

## Accessibility

- High-contrast theme and night-vision red mode (keeps dark adaptation)
- Works offline for core sky data

> TODO (hackathon day): Screen-reader labels and text-scaling checks for the final screens.

## Privacy

- Location is used on the device only, to compute the sky. It is not sent anywhere except as coordinates in weather requests to Open-Meteo.
- The logbook is stored locally (Hive). There are no accounts and no analytics.
- API keys never ship in the client for production builds. See [docs/AI_GUIDELINES.md](docs/AI_GUIDELINES.md).

## Limitations

- Positions use approximate algorithms (arcminute-level). Fine for naked-eye use, not for precise telescope pointing.
- Phone compasses drift and suffer magnetic interference, so AR alignment needs calibration.
- `DEMO_KEY` is heavily rate-limited (30/hour, 50/day per IP).
- SkyLens is not a telescope and does not make discoveries.

## Future Roadmap

> TODO (hackathon day): Post-event roadmap.

## Team

See [docs/TEAM_ROLES.md](docs/TEAM_ROLES.md).

> TODO (hackathon day): Names and roles.

## License and Attribution

- Code: [MIT](LICENSE) © 2026 SkyLens contributors
- Star data: HYG Database v4.0 (David Nash / astronexus), CC BY-SA 4.0
- Constellation data: d3-celestial (Olaf Frohn), BSD-3-Clause
- NASA data and imagery: courtesy of NASA. Individual APOD images may be copyrighted by their authors, as noted in the API response.
- Weather data: Open-Meteo.com, CC BY 4.0
- Typeface: Geist by Vercel, SIL Open Font License 1.1 (`app/assets/fonts/Geist-OFL.txt`)
- Icons in the beginner guide deck: Lucide, ISC License
- Full package, asset and data licence review: [docs/THIRD_PARTY_NOTICES.md](docs/THIRD_PARTY_NOTICES.md). Licence texts are also in the app (Dev Lab → UI kit → Open-source licences).
- This project is not endorsed by NASA.
