# SkyLens: rules for AI assistants and contributors

These rules are **mandatory** for every change, by any AI assistant or person. If a request conflicts with them, follow the rules and say so.

## 1. Experience rules (non-negotiable)

SkyLens must feel **simple, friendly, attractive and alive**, for everyone from a curious child to an adult stargazer.

1. **Everything animates.** Every screen, card, list, value and control has motion: entrances, press feedback, state changes, transitions. Nothing appears, disappears or changes instantly. That includes small things: pills, numbers, icons, toggles, empty states.
2. **Use the motion system. Never invent one-off timings.** Use `app/lib/core/widgets/motion.dart`:
   - `Reveal` / `staggered()` for entrances;
   - `Pressable` around anything tappable;
   - `AnimatedValue` for changing text and numbers;
   - `Float` for idle illustrations;
   - `Starfield` for sky backgrounds;
   - `Motion.fast / medium / slow` with `Motion.enter / exit` curves.
3. **Respect reduced motion.** Every animation must check `Motion.reduced(context)` (or use a widget that does) and show its final state instantly when the OS asks.
4. **Technical details never come first.** API names, keys, data modes, timestamps, licences, raw errors and coordinate jargon live **behind a tap**:
   - source details: `SourceBadge`, which opens `showSourceDetails`;
   - error details: the "Show details" link in `ErrorState`;
   - developer info: the "For developers" sheet on the Lab home.

   The front shows plain words: "From NASA", "Saved earlier", "Can't reach space right now".
5. **Plain, friendly language.** Short sentences a 10-year-old understands:
   - name features by what they do ("Sky map", "Space news", "Sky diary"), not how they work;
   - explain units ("× Moon distance", "fists above the horizon").
6. **Simple screens.** One main idea per screen and big tap targets (≥ 48 dp). Use cards and tiles, not dense tables. Use progressive disclosure for anything advanced.
7. **Interactive and delightful.** Where it fits, let people play: tap the sky to sparkle, tap the logo to spin, drag time, follow the phone's movement.
8. **Professional polish.**
   - Use design tokens only: `SkyTokens.of(context)`, `Space`, `Radii`, `Theme.of(context).textTheme`.
   - Never hard-code colours, sizes or fonts in screens.
   - Use one icon family (Material Symbols, outlined style).
   - No emoji as icons.
9. **Accessible by default.**
   - Text contrast ≥ 4.5:1 and control borders ≥ 3:1. The tokens already meet this; don't override them.
   - Colour never carries meaning alone: pair it with an icon or a word.
   - Give everything tappable a semantic label.
   - Every swipe or drag needs a button alternative.
   - Layouts must survive 160% text size.
10. **Night friendly.** Every screen must work in all three themes: Standard, Night vision (red) and High contrast. Nothing bright or white should flash at night.

Full system: [docs/DESIGN_TOKENS.md](docs/DESIGN_TOKENS.md). Component gallery: Dev Lab → Settings.

## 2. Definition of done for any UI change

- [ ] Uses existing components and tokens. Any new component goes in `core/widgets/`, animated and themed.
- [ ] Entrance, press and state-change animations are present, and reduced motion is respected.
- [ ] No technical detail is on the main surface.
- [ ] Copy is plain and friendly.
- [ ] `cd app && dart format lib test && flutter analyze && flutter test` all pass.
- [ ] Checked on a real phone (`flutter run`) or at least at phone size in the web build, in all three themes.

## 3. Project scope (NASA Space Apps 2026)

- Before the event (Nov 14–15, 2026), add **only reusable infrastructure**: engine, sensors, data clients, design system, Dev Lab. Challenge-specific features wait for the event. See [docs/PREPARED_BEFORE_EVENT.md](docs/PREPARED_BEFORE_EVENT.md).
- **Never commit secrets.** `app/.env.json` is git-ignored; `app/.env.example.json` is the template.
- **Git identity:** commit as the GitHub no-reply address. Push over SSH to `git@github.com:arslan-ahm/skylens---nasa-app-2026.git`. `main` is protected; see [docs/REPO_SECURITY.md](docs/REPO_SECURITY.md).

## 4. Where things live

| Path | What |
|---|---|
| `app/lib/core/theme/app_theme.dart` | Tokens (`SkyTokens`, `Space`, `Radii`), type scale, Material theme |
| `app/lib/core/widgets/motion.dart` | Motion tokens and animated building blocks |
| `app/lib/core/widgets/design_components.dart` | Logo (`SkyLensMark`, `MarkPainter`), tiles, pills, metrics, groups |
| `app/lib/core/widgets/` | Cards, source credits, states, sky chart, forms |
| `app/lib/features/splash/` | Animated, interactive welcome screen |
| `app/lib/features/lab/` | Dev Lab screens (friendly front ends for each module) |
| `app/tool/brand/make_icons.py` | Regenerates the launcher icons, splash and web icons from the logo geometry |
