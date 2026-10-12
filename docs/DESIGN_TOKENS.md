# SkyLens Design System ("Observatory")

SkyLens should feel **simple, friendly, alive and professional**: a child can use it, and an adult stargazer trusts it. Everything is dark (bright screens ruin night vision) and everything moves.

- Code: [`app_theme.dart`](../app/lib/core/theme/app_theme.dart) (tokens and Material theme), [`motion.dart`](../app/lib/core/widgets/motion.dart) (motion), [`design_components.dart`](../app/lib/core/widgets/design_components.dart) (components).
- Live gallery: **Settings → Design gallery**.
- Mandatory rules for any change: [CLAUDE.md](../CLAUDE.md).

## Principles

1. **Alive:** every element animates in, responds to touch and animates its changes.
2. **Friendly first:** plain words, big tiles, one idea per screen. Technical details sit one tap away.
3. **Night-safe:** all three themes always work, and nothing flashes bright.
4. **Accessible:** contrast AA, semantic labels, reduced motion and large text all respected.

## Themes

| Theme | For | Character |
|---|---|---|
| Standard (`space`) | Everyday | Deep blue-black, starlight-blue accent, warm planets |
| Night vision (`nightRed`) | Outdoors at night | Red only, low brightness |
| High contrast | Low vision, bright sun | Black, white and yellow, 2 px borders |

## Colour roles (`SkyTokens`)

Values below are for Standard; the other themes map the same roles.

| Role | Value | Use |
|---|---|---|
| `bg` | `#070A12` | Screen background |
| `surface` | `#0E1424` | Cards, tiles |
| `surfaceHigh` | `#161D30` | Sheets, inputs, selected options |
| `outline` | `#26304A` | Card outlines, dividers |
| `border` | `#5B6886` | Control boundaries (3.3:1) |
| `text` / `textMuted` / `textFaint` | `#EDF1F8` / `#9AA5BA` / `#6A7590` | Primary (16:1) / secondary (7.4:1) / disabled only |
| `primary` | `#7EA6FF` | Main actions, selection, links |
| `primaryContainer` | `#18284D` | Tonal fills, icon badges |
| `success` / `warning` / `danger` | `#45D49A` / `#F5C15C` / `#FF8080` | Status. Always with an icon or a word |
| `accents[]` | blue, violet, teal, amber, pink, green | One friendly hue per feature tile. Decorative only |
| `chartBg`, `chartGrid`, `star`, `planet`, `moon`, `sun`, `constellation`, `horizon` | | Sky chart, AR overlay, illustrations |

## Typography

**Inter** (SIL OFL 1.1, bundled), in four weights. Numbers that change use tabular figures (`kTabularFigures`).

| Style | Size / line height | Weight | Use |
|---|---|---|---|
| `displaySmall` | 32 / 40 | 600 | Splash title |
| `headlineMedium` | 28 / 36 | 600 | Screen hero ("What shall we explore?") |
| `headlineSmall` | 24 / 32 | 600 | Sheet titles |
| `titleLarge` | 20 / 28 | 600 | App bar, card heroes |
| `titleMedium` / `titleSmall` | 16 / 24, 14 / 20 | 600 | Card and tile titles |
| `bodyLarge` / `bodyMedium` | 16 / 24, 14 / 20 | 400 | Reading text |
| `bodySmall` | 12 / 16 | 400 | Captions, credits |
| `labelLarge` | 14 / 20 | 600 | Buttons |
| `labelSmall` | 11 / 16 | 600, +0.8 tracking | Uppercase section labels |

## Space and shape

- **Spacing:** `Space` uses a 4-pt scale (4, 8, 12, 16, 24, 32). The screen gutter is 20.
- **Radius:** `Radii` is 8, 12, 16 and 24. Tiles and hero cards use 24; buttons and inputs use 12; the splash button is a pill.
- **Touch targets:** at least 48 dp. Primary buttons are 48–56 dp tall.
- **Elevation:** none. Depth comes from tone and 1 px outlines, never shadows.

## Motion (`motion.dart`)

**Rule:** nothing appears, disappears or changes instantly, and every animation respects reduced motion.

| Token | Value | Use |
|---|---|---|
| `Motion.fast` | 140 ms | Press feedback, toggles |
| `Motion.medium` | 280 ms | Value changes, tab switches, expand/collapse |
| `Motion.slow` | 520 ms | Entrances, page choreography |
| `Motion.stagger` | 55 ms | Delay between items in a list entrance |
| `Motion.enter` / `exit` / `emphasized` | easeOutCubic / easeInCubic / easeOutBack | Curves |

| Building block | What it does | Use it for |
|---|---|---|
| `Reveal`, `staggered()` | Fade and slide in, one item after another | Every screen's content |
| `Pressable` | Gently shrinks while pressed | Anything tappable (tiles, cards, buttons) |
| `AnimatedValue` | Cross-fades and slides text when it changes | Numbers, labels, status |
| `Float` | Slow bob | Empty-state icons, small illustrations |
| `Starfield` | Twinkling stars, shooting stars, tap-to-sparkle | Splash, home header, hero cards |
| `MarkPainter` | The logo, drawable in parts | Splash choreography |
| `AppShell` | Tab cross-fade, bouncing tab icon, haptic tick | Bottom navigation |

The splash (`features/splash/`) shows the full vocabulary:
1. a warp-speed star rush;
2. the logo star popping, then gliding up while a satellite orbits it;
3. the title bouncing in letter by letter;
4. a constellation drawing itself;
5. a rocket button that blasts off.

## Components

| Component | Notes |
|---|---|
| `SkyLensMark`, `BrandLockup` | Logo; same geometry as the launcher icon (`tool/brand/make_icons.py`) |
| Feature tile (Explore) | Accent-tinted icon circle, title, one-line subtitle, presses in |
| `SkyCard` | Icon badge, title, subtitle, body, quiet `SourceBadge` footer |
| `GroupCard` + `ModuleTile` | Settings-style grouped rows with chevrons |
| `MetricTile`, `MetricRow` | Small label and animated value |
| `StatusPill` | Icon plus word, tinted by `Tone` |
| `SourceBadge` | "From NASA APOD · saved earlier ⓘ". Details open in a sheet |
| `EmptyState`, `ErrorState`, `LoadingState` | Friendly words, floating icon. Raw errors behind "Show details" |
| `MoonPhaseIcon` | The Moon drawn at its real phase |
| Buttons | Filled (primary), Elevated (tonal), Outlined (secondary), Text |

## Copy

- Name features by what they do: Sky map, Sky camera, Compass, Space news, Sky diary.
- Explain units in human terms: "× Moon distance", "fists above the horizon".
- Errors say what happened and what to do: "Can't reach space right now. Check your internet connection."
- Never put API names, keys, data modes or raw errors on a main surface.
