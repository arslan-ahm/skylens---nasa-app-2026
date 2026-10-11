# Data Sources

**api.nasa.gov limits:** `DEMO_KEY` allows 30 requests/hour and 50/day per IP. A personal key (free) allows 1,000/hour. Get one at https://api.nasa.gov.
Every fetched result must carry `DataProvenance` (source, url, license, fetchedAt, isMock), and the UI must show it.

**Always verify licenses and terms before the demo.** The entries below are our best understanding, not legal advice.

## NASA and space agencies

| What | Endpoint / URL | Key? | Rate limits | License / attribution | Status |
|---|---|---|---|---|---|
| APOD (Astronomy Picture of the Day) | `https://api.nasa.gov/planetary/apod` (site now at https://science.nasa.gov/apod/) | api.nasa.gov | See above | NASA content is generally public domain. Many APOD images are © their authors (check the `copyright` field) | **Wired in starter** — ⚠ as of 2026-10-11 the API returns the NASA logo + title "NASA Science" for every date (explanation is still correct); handled via `Apod.degraded` |
| NeoWs (near-Earth objects) | `https://api.nasa.gov/neo/rest/v1/feed` | api.nasa.gov | See above | NASA/JPL CNEOS, public domain | **Wired in starter** |
| DONKI (space weather) | `https://ccmc.gsfc.nasa.gov/DONKI/WS/get/{notifications,FLR,CME,GST,...}` | No | Not documented | NASA CCMC, public domain | **Wired in starter** — moved Sep 2026; the old `api.nasa.gov/DONKI` path now redirects to an HTML page |
| NASA Image & Video Library | `https://images-api.nasa.gov/search` | No | Not published. Be reasonable | Generally public domain. Check per-item metadata. "Courtesy NASA" | **Wired in starter** |
| NASA Sky Events / "What's Up" | https://science.nasa.gov/skywatching/ | No (web content, no API) | n/a | NASA. Link out rather than scrape | Candidate |
| JPL Horizons (ephemerides) | `https://ssd.jpl.nasa.gov/api/horizons.api` | No | Shared service. Cache results | NASA/JPL-Caltech SSD | Candidate |
| JPL SBDB (small bodies) | `https://ssd-api.jpl.nasa.gov/sbdb.api` | No | Shared service. Cache results | NASA/JPL-Caltech SSD | Candidate |
| CelesTrak TLEs (satellites/ISS) | `https://celestrak.org/NORAD/elements/gp.php?GROUP=stations&FORMAT=json` | No | Data updates ~every 2 h. Do not poll more often | CelesTrak (Dr. T.S. Kelso). Credit CelesTrak | Candidate |
| Where the ISS at | `https://api.wheretheiss.at/v1/satellites/25544` | No | ~1 req/s | wheretheiss.at. Credit the source | Candidate |

## Weather, sky quality, catalogs

| What | Endpoint / URL | Key? | Rate limits | License / attribution | Status |
|---|---|---|---|---|---|
| Open-Meteo (cloud cover, weather) | `https://api.open-meteo.com/v1/forecast` | No | Free non-commercial tier, < 10,000 calls/day | CC BY 4.0. "Weather data by Open-Meteo.com" | **Wired in starter** |
| Light pollution (World Atlas 2015 / lightpollutionmap.info) | https://www.lightpollutionmap.info, https://doi.org/10.5880/GFZ.1.4.2016.001 | Varies | Varies | **Licensing must be checked.** Tiles/API may forbid redistribution. Cite Falchi et al. 2016 | Candidate |
| HYG star database v4.0 | https://github.com/astronexus/HYG-Database | No (bundled) | n/a | CC BY-SA 4.0. "HYG Database by David Nash (astronexus)" | **Wired in starter** (`app/assets/catalog/stars.json`) |
| d3-celestial constellations | https://github.com/ofrohn/d3-celestial | No (bundled) | n/a | BSD-3-Clause, © Olaf Frohn | **Wired in starter** (`app/assets/catalog/constellations.json`) |

## Citizen science (link-out pathway)

| What | URL | Key? | Notes | Status |
|---|---|---|---|---|
| Globe at Night | https://globeatnight.org | No | Sky brightness observations. Report via their form/app | Candidate |
| GLOBE Observer | https://observer.globe.gov | No | NASA-supported app (clouds, land cover) | Candidate |
| AAVSO | https://www.aavso.org | Account to submit | Variable star observations | Candidate |
| IMO meteor reports | https://www.imo.net | Account to submit | Visual meteor counts, fireball reports | Candidate |
| NASA Citizen Science | https://science.nasa.gov/citizen-science/ | No | Directory of NASA projects | Candidate |

## Adding a new source

1. Add a mock fixture to `app/assets/mock/` first.
2. Implement the client in `app/lib/data/` using the cache-through fetcher.
3. Fill in `DataProvenance` with the license string from this table.
4. Update this table and README's "NASA and Open Data Used".
