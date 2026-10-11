# Team Roles

| Role | Owns | Key modules / docs |
|---|---|---|
| Product lead / pitch | Challenge choice, scope, README story, video, project page | `README.md`, `docs/PROJECT_PAGE_TEMPLATE.md`, `docs/VIDEO_SCRIPT_TEMPLATE.md` |
| Flutter lead | App shell, navigation, merges, release builds | `app/lib/features/`, CI |
| Sky / AR engineer | Sky map, AR view, Tonight's Sky accuracy | `app/lib/core/astro/`, `app/lib/core/sensors/` |
| Data engineer | NASA/open data clients, mocks, provenance, licenses | `app/lib/data/`, `app/lib/core/network/`, `docs/DATA_SOURCES.md` |
| UI/UX + accessibility | Screens, theme, night/high-contrast modes, a11y pass | `app/lib/core/theme/`, `app/lib/core/widgets/` |
| AI + science check (optional) | Grounded explanations, fact-checking copy | `docs/AI_GUIDELINES.md` |

## Combined-roles fallback

| Team size | Split |
|---|---|
| 2 | A: Product + UI/UX + Data · B: Flutter lead + Sky/AR (+ AI if time) |
| 3 | A: Product + UI/UX · B: Flutter lead + Data · C: Sky/AR + AI/science |
| 4 | A: Product · B: Flutter lead + UI/UX · C: Sky/AR · D: Data + AI/science |
| 5–6 | One person per role. The product lead also owns the submission checklist |

## Ownership grid (fill in on hackathon day)

| Feature / task | Owner | Reviewer | Status | Notes |
|---|---|---|---|---|
| Challenge + problem statement | | | | |
| App shell + navigation | | | | |
| Feature 1: | | | | |
| Feature 2: | | | | |
| Feature 3: | | | | |
| Data integration(s) | | | | |
| Accessibility pass | | | | |
| AI explanations (optional) | | | | |
| Demo video | | | | |
| Project page | | | | |
| Final submission | | | | |
