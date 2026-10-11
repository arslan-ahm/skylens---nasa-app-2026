# Contributing

## Branches
`feat/<short-name>`, `fix/<short-name>`, `docs/<short-name>`, `chore/<short-name>`. Branch from `main` and merge back often (at least every 3 h on hackathon day).

## Commits
Use Conventional-style messages: `feat(astro): add moon phase`, `fix(sensors): clamp altitude`, `docs: update data sources`. Keep commits small and focused.

## Before opening a PR
```bash
cd app
dart format lib test
flutter analyze
flutter test
```
CI runs the same checks. A red CI blocks the merge.

## Where things go

| Path | Put here | Rule |
|---|---|---|
| `app/lib/core/` | Reusable engine code: astro, sensors, network, storage, theme, widgets | No feature imports. Pure Dart where possible, with unit tests |
| `app/lib/data/` | API clients + models, mock fixtures in `app/assets/mock/` | Every result carries `DataProvenance` |
| `app/lib/features/` | Screens and feature state | May import `core/` and `data/`, never each other's internals |
| `app/lib/features/lab/` | Dev Lab debug screens | Keep working, as it is the device smoke test |
| `docs/` | Process docs, data-source registry | Update `DATA_SOURCES.md` when adding a source |

## Secrets
**Never commit API keys.** Pass them at run time:

```bash
flutter run --dart-define=NASA_API_KEY=xxxx
# or
cp app/.env.example.json app/.env.json   # gitignored
flutter run --dart-define-from-file=.env.json
```

Keys for LLMs or paid services must live behind a serverless proxy and never in the client (see [docs/AI_GUIDELINES.md](docs/AI_GUIDELINES.md)).
