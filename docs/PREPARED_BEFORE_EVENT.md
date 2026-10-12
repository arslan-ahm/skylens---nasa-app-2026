# Prepared Before the Event: Disclosure

NASA Space Apps Challenge allows teams to prepare **reusable infrastructure and skills** before the event. Challenge-specific implementation, the final submission, and the project page/pitch must be created during the event.

**In short:** the astronomy engine, AR/pointing math, `SkyDome` sky chart, UI kit, NASA/open-data clients and the Dev Lab test screens were built **before** the event (git tag `pre-event-baseline`). The challenge-specific product, its final features, the project page, video and submission are built **during** the hackathon. Compare any later commit with `git diff pre-event-baseline`.

This file is our transparent record. We link it from the README and summarise it on the project page.

> **Before the event opens, re-read the official rules and FAQ:** https://www.spaceappschallenge.org/resources/participant-faqs/
> If anything below conflicts with the current rules, the rules win. Remove or rebuild that piece during the event.

## Built before the event (generic, reusable)

| Module | Path | What it is |
|---|---|---|
| **Sky engine** ⚑ | `app/lib/core/astro/` | Pure-Dart astronomy library: time/sidereal, coordinate transforms + precession, Sun, Moon, planets (JPL approximate Keplerian elements), rise/set/twilight solver, star catalog loader. Unit-tested against Meeus examples. |
| **Pointing / AR test** ⚑ | `app/lib/core/sensors/`, `app/lib/features/lab/` | Location service with fallback, device orientation → az/alt, compass offset calibration, sky projector (world direction → screen point). |
| Network layer | `app/lib/core/network/` | dio client, TTL cache-through fetcher, `DataProvenance` metadata. |
| Storage | `app/lib/core/storage/` | Hive CE boxes (settings, cache, logbook). |
| Design system | `app/lib/core/theme/`, `app/lib/core/widgets/` (`design_components.dart`, `motion.dart`), `docs/DESIGN_TOKENS.md`, `CLAUDE.md` | "Observatory" tokens (three themes), Inter type scale, motion system (reveal, press, animated values, starfield) and generic components |
| Brand and app chrome | `app/tool/brand/`, `app/android/.../res`, `app/ios/.../AppIcon.appiconset`, `app/web/`, `app/lib/features/splash/`, `app/lib/features/shell/` | SkyLens logo, launcher icons, native and animated splash, reusable bottom-tab shell (`AppShell`) used to host the Dev Lab |
| UI kit | `app/lib/core/widgets/` | Cards, attribution badge, empty/error/loading states, object detail sheet, direction hint, observation form, **`SkyDome` all-sky chart** ⚑. |
| Data clients | `app/lib/data/` | NASA APOD, NeoWs, DONKI, Image & Video Library; Open-Meteo. Mock fixtures in `app/assets/mock/`. |
| Dev Lab | `app/lib/features/lab/` | Friendly test screens for each module (Explore, Sky map, Sky camera, Compass, Space news, Sky diary, Settings). |
| Offline catalog | `app/assets/catalog/`, `app/tool/` | HYG v4.0 stars (mag ≤ 5.5), d3-celestial constellations, plus the build script. |
| Repo tooling | `.github/`, `docs/` | CI (test, web, APK, Pages), templates, playbook. |

⚑ **Mention these explicitly on the project page** as pre-existing reusable libraries we wrote before the event. They are the largest pieces of prior work.

## Deliberately left for the event

- [ ] Choosing the challenge
- [ ] Problem statement, solution, and impact (README TODOs)
- [ ] The product's own sections, tabs and challenge-specific screens in `app/lib/features/` (the generic `AppShell` currently hosts the Dev Lab)
- [ ] Challenge-specific data integrations beyond the generic clients
- [ ] Any AI explanation feature and its prompts, applied to the challenge
- [ ] Final branding/copy for the chosen challenge
- [ ] Demo video (the template exists, the content does not)
- [ ] Project page text (the template exists, the content does not)
- [ ] Final pitch and submission

## How we disclose

1. On the project page, add a "Prior work" paragraph that lists the table above and links this file.
2. Keep git history intact. Commits before the event start time are visible to judges.
3. Tag the last pre-event commit, e.g. `git tag pre-event-baseline`.
