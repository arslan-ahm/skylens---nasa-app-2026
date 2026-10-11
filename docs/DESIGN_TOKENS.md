# SkyLens Design Tokens

The SkyLens visual system: a flat, near-black UI in which white type does most of the work. That suits an app used outdoors at night, where bright colour ruins dark adaptation. The code lives in `app/lib/core/theme/app_theme.dart` (tokens and Material theme) and `app/lib/core/widgets/design_components.dart` (components). Every component is shown in **Dev Lab → UI kit & settings**.

There are three variants of the system:
- **Space** (default): the tokens below.
- **Night-vision red:** a red-only palette that protects dark adaptation.
- **High contrast:** maximum contrast for accessibility.

## Colours

| Token | Value | Use |
|---|---|---|
| `sky` | `#000000` | Screen background (canvas) |
| `carbon` | `#181818` | App bar, bottom sheets, bars |
| `surface` (Graphite) | `#1e1f20` | Cards and panels: the only raised surface |
| `hairline` (Iron) | `#333333` | 1px borders, dividers, input outlines |
| `inkMuted` (Slate) | `#807f7f` | Secondary text and metadata. Use it only for real de-emphasis |
| `inkFaint` | `#666666` | Disabled text, very low emphasis |
| `ink` | `#ffffff` | Headings, body text, icons, button borders |
| `live` (Mint) | `#22e2a8` | **Only** for live data and active state (live dot, focused input). Never for buttons or decoration |
| `diagram` (Teal) | `#085556` | Strokes in diagrams: sky-chart rings, globe diagram |
| `wash` (Navy) | `#0a2142` | Soft background tint behind diagrams only |

## Typography

- **Typeface:** Geist (SIL OFL 1.1, bundled), in one weight, **400**. No bold, no italics.
- **Tracking:** always slightly positive. Use the `skyText(size, height, tracking)` helper.

| Role | Material style | Size | Line height | Tracking |
|---|---|---|---|---|
| Display | `displayLarge` | 60 | 1.13 | 2.4 |
| Heading | `headlineLarge` | 36 | 1.13 | 0.9 |
| Heading small | `headlineMedium` | 32 | 1.25 | 0.8 |
| Subheading | `titleLarge` | 24 | 1.33 | 0.6 |
| Body | `bodyLarge` | 16 | 1.6 | 0.4 |
| Body small | `bodyMedium` | 14 | 1.43 | 0.28 |
| Caption | `bodySmall` | 12 | 1.5 | 0.24 |

## Shape and spacing

- **Radius:** buttons are full pills (stadium). Cards use 20, sheets and large cards 30, images 10.
- **Padding:** cards 20, element gap 16, screen gutter 20, section gap 40.
- **Touch targets:** at least 48 px tall.

## Elevation

Flat. There are no shadows, glows, blur or gradients between surfaces. Depth comes only from tone: canvas `#000` → carbon `#181818` → card `#1e1f20`, plus 1px hairlines.

## Components

| Component | Widget | Notes |
|---|---|---|
| Ghost pill button | `GhostPillButton` (and every Material button theme) | Transparent fill, 1px white border, 30×10 padding, optional trailing › |
| Card | `SkyCard`, `Card` | Graphite, radius 20, no border. Optional `category` tag |
| Category tag | `CategoryTag` | 12 px uppercase Slate label: card categories, eyebrows |
| Section header | `SectionHeader` | Eyebrow + heading (or display when `large: true`) |
| Stat strip | `StatStrip` | White value followed by a Slate label, 30 px apart |
| Carousel dots | `CarouselDots` | 6 px dots, Slate inactive, white active |
| Live dot | `LiveDot` | Mint status dot with an optional pulse. Shows only on live data |
| Globe diagram | `GlobeDiagram` | Concentric Teal rings on a Navy wash, white nodes with uppercase labels. Hero art and empty states |
| Source badge | `SourceBadge` | Source, time and licence of every data card. Live, saved, sample or computed |
| States | `EmptyState`, `ErrorState`, `LoadingState` | Every error says what to do next |

## Do and don't

**Do:**
- Use white for text and icons. Use Slate only to de-emphasise.
- Keep every action a ghost pill.
- Keep Mint for live or active state only, so "live" always means live.
- Respect reduced motion: animations stop when the OS asks.

**Don't:**
- Use a second typeface, bold weights, or filled white buttons.
- Use coloured section backgrounds. Teal and Navy appear only inside diagrams.
- Add shadows, blur or gradients.
- Use default link blue. Links are white, underlined when needed.
