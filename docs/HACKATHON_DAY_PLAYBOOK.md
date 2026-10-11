# Hackathon Day Playbook (48 h)

## First 30 minutes

```bash
git pull
cd app
flutter pub get
flutter test                                   # must be green before anyone builds features
flutter devices
flutter run -d <device-id> --dart-define-from-file=.env.json
flutter run -d chrome --dart-define=DATA_MODE=mock
```

- [ ] Each dev has a personal NASA key from https://api.nasa.gov in `app/.env.json` (copy `app/.env.example.json`). Never commit it.
- [ ] Open the Dev Lab on at least one Android and one iOS/web target. Check sensors, sky table, pointing, and NASA data.
- [ ] CI is green on `main` and GitHub Pages deploys.
- [ ] Tag the pre-event baseline: `git tag pre-event-baseline && git push --tags`.
- [ ] Fill in the ownership grid in [TEAM_ROLES.md](TEAM_ROLES.md).

## Timeline (from the SkyLens plan, mapped to this repo)

| Hours | Goal | Deliverable | Checklist |
|---|---|---|---|
| 0–2 | Understand and decide | Final scope + user story | - [ ] Read every official challenge statement and its resources<br>- [ ] Pick the challenge SkyLens fits best; confirm allowed data/rules<br>- [ ] One primary user, one core workflow, one-sentence problem → `README.md` |
| 2–6 | Data and core logic | App knows what should be visible | - [ ] Pick exact datasets from [DATA_SOURCES.md](DATA_SOURCES.md); capture a mock fixture for each new API **first**<br>- [ ] `SkyEngine.compute()` already gives positions — add only challenge-specific objects/data |
| 6–14 | Core app (non-AR) | Usable SkyLens without AR | - [ ] Product shell at `/`, Lab moved behind a debug entry (`app.dart`)<br>- [ ] Home / Tonight's Sky, `SkyDome` sky map, `showSkyObjectSheet` details<br>- [ ] NASA cards with `SourceBadge`; search + filters |
| 14–24 | AR + observation coach | Point at the sky and identify objects | - [ ] Promote `features/lab/pointing_screen.dart` into the real AR view<br>- [ ] "Where to look" via `directionSentence()` / `DirectionHint`<br>- [ ] Logbook using `ObservationForm` + `LogbookRepository` |
| 24–32 | Differentiators | Feels useful, not a demo | - [ ] Tonight's recommendations (rise/set + twilight + Open-Meteo `clearSkyScore`)<br>- [ ] ISS passes only if a reliable source is settled (see Known gaps)<br>- [ ] Grounded AI explanations per [AI_GUIDELINES.md](AI_GUIDELINES.md); citizen-science links |
| 32–40 | Polish and reliability | Stable demo build | - [ ] Empty/error/offline states (`AsyncView`, `DATA_MODE=mock` run-through)<br>- [ ] Test on real phones outdoors at night; tune FOV/compass defaults<br>- [ ] README + technical docs; rotate sleep |
| 40–46 | Submission assets | Complete submission | - [ ] 60-s video ([VIDEO_SCRIPT_TEMPLATE.md](VIDEO_SCRIPT_TEMPLATE.md)), screenshots<br>- [ ] Project page ([PROJECT_PAGE_TEMPLATE.md](PROJECT_PAGE_TEMPLATE.md)) incl. prior-work disclosure<br>- [ ] Attributions, rehearse pitch, **submit early** |
| 46–48 | Final hours | Verified submission | - [ ] No new features — bug fixes, copy, links only; verify everything in an incognito window |

## Known gaps (decide on the day)

| Gap | Options |
|---|---|
| ISS / satellite passes | No maintained Dart SGP4 package on pub (all pre-null-safety). Port satellite.js's SGP4 (~600 lines) with CelesTrak GP JSON, or use a pass-prediction API (e.g. N2YO, key required) behind a proxy. |
| Magnetic declination | Compass offset is manual or calibrated on a bright object (Pointing screen). A WMM model could compute it automatically. |
| Web has no compass | Browsers rarely expose a magnetometer: on web use `SkyDome` (drag/tap) instead of AR. |
| Sky chart label overlap | `SkyDome` draws labels naively; add collision avoidance if it's in the demo. |
| APOD API degraded | Since APOD moved to science.nasa.gov the API returns the logo + "NASA Science" title (explanation still OK). `Apod.degraded` handles it; re-check on the day. |

## Feature-to-module map

| Feature | Modules to reuse |
|---|---|
| Sky map | `core/astro` (catalog, transforms), `core/theme` |
| AR sky view | `core/sensors` (orientation, projector), `core/astro` |
| Tonight's Sky | `core/astro` (rise/set/twilight), `data/` Open-Meteo |
| Observation planner/log | `core/storage` (logbook), `core/widgets` (observation form) |
| NASA data cards | `data/` NASA clients, `core/network` (cache, provenance), `core/widgets` |
| Citizen-science pathway | `core/widgets` + external links (see DATA_SOURCES.md) |

## Cut list (drop in this order if behind)

1. AI explanations
2. Extra NASA feeds beyond the one the challenge needs
3. AR camera background. Keep the AR overlay on a black sky
4. iOS build. Demo on Android + web
5. Logbook sync/export. Keep local-only

Never cut: the core user flow, data attribution, the honest-positioning copy.

## Final 2 hours rule

**No new features.** Only fix crashes, fix copy, and fix submission links. If it is not merged and working by hour 46, it is not in the demo.
