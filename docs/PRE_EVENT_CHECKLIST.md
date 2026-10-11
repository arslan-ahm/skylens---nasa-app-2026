# Pre-Event Checklist

Between now and the event we harden what already exists. We do **not** add features. Priority order:

1. Real-phone AR testing
2. API resilience
3. Clean build and deployment
4. Licensing and attribution

| Date (2026) | Milestone |
|---|---|
| **Oct 28** | Challenge statements published. Read them, but don't start challenge work. |
| **Nov 13** | Project Submission Guide published. Freeze day (see below). |
| **Nov 14–15** | Event. Challenge work starts. |

Tick items in a PR or in this file. Put each result next to its item (date, phone, notes).

## 1. Real-phone AR test (highest priority)

Install the APK **from the CI artifact** (Actions → latest run → `skylens-debug-apk`), not from a local build. Test outdoors at night under a clear sky, away from cars and steel railings, which bend the compass.

**Setup**
- [ ] Fresh install. Grant the location and camera permission prompts. Then deny them once, reinstall, and check that the app still works using the Greenwich fallback with a clear label.
- [ ] Dev Lab → Sensors: location source shows `gps`, accuracy under ~100 m, pose updates smoothly.
- [ ] Dev Lab → Sky engine: note the Moon's and the brightest planet's azimuth/altitude. Check them against Stellarium or timeanddate.com for the same time and place. They should agree to within 1°.

**Alignment** (Dev Lab → Pointing / AR test)
- [ ] Before calibrating, point at the Moon. Record how far the marker is off: ____°
- [ ] Calibrate by centring the Moon, then re-point. Error is now ____° (target ≤ 3°).
- [ ] A bright planet or star (Jupiter, Saturn, Sirius, Capella…) lands within ~3°.
- [ ] Tap the object. The detail sheet opens. No crash.
- [ ] Sweep slowly through 360°. Labels follow without jumping or lagging more than about half a second.
- [ ] Walk 20 m and check again: does the compass drift? ____
- [ ] Hold the phone near a laptop or speaker. Does the calibration hint appear, or does the marker visibly jump? ____

**Comfort**
- [ ] Night-vision red theme: nothing white or bright flashes when switching screens.
- [ ] Minimum screen brightness: text still readable.
- [ ] One-handed use: main controls within thumb reach.
- [ ] Battery drop over 10 minutes of AR: ____ %.

**Second phone** (older Android or weaker compass if possible)
- [ ] Repeat the alignment block and record the results.

**Pass:** you can point at the Moon or a bright planet, see the marker reasonably aligned, and tap it to open details without a crash.

| Date | Phone / Android | Pre-cal error | Post-cal error | Drift / lag notes | Crashes |
|---|---|---|---|---|---|
| | | | | | |

## 2. NASA and open-data resilience

- [ ] Each developer has a personal key from https://api.nasa.gov in `app/.env.json`, copied from `.env.example.json`. Check with `git status` that the file is untracked.
- [ ] Dev Lab home shows **NASA key: Own**, not Demo.
- [ ] Dev Lab → NASA & open data: APOD, NeoWs, DONKI, Image Library and Open-Meteo each load and show source, time and licence.
- [ ] Airplane mode with a warm cache: cards show **"Offline — showing saved data"** with the saved time.
- [ ] Airplane mode on a fresh install (no cache): cards show **sample data**, labelled as such, or a clear error with Retry.
- [ ] Bad key (`NASA_API_KEY=wrong`): cards say **"API key rejected"** and fall back.
- [ ] Slow network (Android developer options → network throttling, or a weak hotspot): cards say **"Network too slow"** after about 8 s, not a frozen spinner.
- [ ] Nothing stale is ever shown as live: no Mint live dot on cached or sample data.
- [ ] **Week of Nov 9:** re-check the DONKI/CCMC endpoint and the APOD breakage (`Apod.degraded`). Update [DATA_SOURCES.md](DATA_SOURCES.md).

The automated part is already covered in `app/test/data/data_layer_test.dart`: 401/403/429/5xx, timeout, stale-not-live, first launch offline, and keys never cached. These manual checks confirm the UI shows those results correctly.

## 3. Astronomy correctness

Already automated (`flutter test`): Meeus worked examples, Greenwich solstice rise/set, an Islamabad rise/set check, local-vs-UTC time, midnight sun, Polaris altitude, implausible GPS fixes rejected, and a full-sky snapshot under 100 ms.

- [ ] For one evening in Islamabad, compare sunrise/sunset, Moon phase, civil/astronomical twilight and two planet positions with timeanddate.com or Stellarium. Write the differences here.
- [ ] Change the phone's timezone and date by hand while the app is open. Positions update and don't freeze.
- [ ] On a mid-range phone, Sky engine refresh stays well under 1 s. The test asserts < 100 ms on desktop.

## 4. Offline and poor network

- [ ] Airplane mode: sky engine, sky chart and AR all still work, because they are fully offline.
- [ ] Every error state says what to do next (enable location, retry, check key).

## 5. Build and deployment

- [ ] **Push to GitHub.** No remote exists yet. Create an empty repository, then run `git remote add origin <url> && git push -u origin main --tags`.
- [ ] Settings → Pages → Source: **GitHub Actions**.
- [ ] CI is green on `main`: analyze, test, web, APK, Pages.
- [ ] Open the Pages URL on a phone and on a desktop.
- [ ] A teammate does a fresh clone on their machine, then runs `flutter pub get && flutter analyze && flutter test && flutter build web && flutter build apk --debug`. Nothing should depend on local files or keys.

Clean-clone build verified locally on 2026-10-11: analyze, 39 tests, web release and debug APK all passed from a fresh `git clone`. The changes made after that clone also pass analyze and all 50 tests, but haven't had their own clean-clone build.

## 6. Privacy, licensing, attribution

- [x] Licence: MIT (OSI-approved).
- [x] Package and asset licences reviewed: [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). No GPL.
- [x] Git history scanned for keys, personal paths and phone numbers. None found.
- [ ] **Commit author identity:** history currently shows one personal work email. Decide whether that's fine for a public repo **before the first push**.
- [ ] `DESIGN.md` describes a third party's visual style. Decide whether it stays in the public repo or gets renamed to a neutral "SkyLens design tokens".
- [ ] [PREPARED_BEFORE_EVENT.md](PREPARED_BEFORE_EVENT.md) is accurate and linked from the README.

## 7. Submission readiness

- [ ] All teammates registered for the **same** Local Event or the Universal Event.
- [ ] Team size ≤ 6. One challenge only.
- [ ] Draft project page from [PROJECT_PAGE_TEMPLATE.md](PROJECT_PAGE_TEMPLATE.md), with placeholders for challenge, demo link, video, screenshots, data sources and licences.
- [ ] Practise the 60-second demo from [VIDEO_SCRIPT_TEMPLATE.md](VIDEO_SCRIPT_TEMPLATE.md). Record one rehearsal.
- [ ] No recognisable names, voices or faces of anyone under 18 in any submission material.

## Freeze day: Nov 13

- [ ] Read the Project Submission Guide and the Judging guide.
- [ ] CI green. The APK from CI installs cleanly. The Pages site works.
- [ ] Docs and disclosure final.
- [ ] Move the baseline tag to the final pre-event commit and push it:
  `git tag -fa pre-event-baseline -m "Reusable pre-hackathon infrastructure only" && git push -f origin pre-event-baseline`
- [ ] **After this point: no new packages, no refactors, no experiments.**
