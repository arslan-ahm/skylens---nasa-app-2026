# AI Guidelines: Grounded Explanations

AI in SkyLens is **optional** and only **explains verified data**. It never produces facts on its own.

## Rules

| # | Rule |
|---|---|
| 1 | **Retrieval only from provided data.** The model's context contains only data the app fetched or computed (sky engine output, NASA API responses with `DataProvenance`). Nothing else counts as a source. |
| 2 | **Cite every claim.** Each factual sentence references a source ID from the context. If a claim has no source, it is not shown. |
| 3 | **No discovery claims.** Never suggest the user found a new object, an anomaly, or a "possible discovery". Point them to citizen-science channels instead. |
| 4 | **Separate verified data from AI text.** Verified values (times, positions, magnitudes) appear in normal data cards. AI text appears in a visually distinct block labelled "AI explanation" with its citations. |
| 5 | **Say "I don't know".** If the context does not answer the question, say so and link the source. |
| 6 | **Report-incorrect flow.** Every AI block has a "Report incorrect" action that captures the question, context IDs, and answer, stored locally or sent to the team endpoint. |
| 7 | **No keys in the client.** LLM and paid API keys must never ship in the app binary or web bundle. Call a serverless proxy (e.g. Cloudflare Worker, Vercel/Netlify function) that holds the key, rate-limits, and adds the system prompt. |

## Prompt pattern

```text
SYSTEM:
You are SkyLens's explainer. Explain ONLY using the facts in <context>.
- Every factual sentence must end with a citation like [S1].
- If <context> does not contain the answer, reply: "I don't have verified data for that." and stop.
- Never claim or imply a discovery, a new object, or an anomaly.
- Do not invent numbers, dates, names, or positions.
- Plain language, ≤ 120 words, suitable for a beginner.

USER:
<context>
[S1] source=NASA NeoWs url=https://api.nasa.gov/neo/rest/v1/feed fetchedAt=2026-10-04T20:00Z
     {"name":"(2026 AB)","close_approach_date":"2026-10-05","miss_distance_km":"4512000", ...}
[S2] source=SkyLens sky engine (Meeus) computedAt=2026-10-04T20:00Z location=user
     {"object":"Jupiter","alt_deg":34.2,"az_deg":118.7,"rise":"19:42","set":"07:15"}
</context>
Question: Is this asteroid dangerous, and can I see Jupiter right now?
```

The app then:
1. Checks that every sentence has a `[S#]` that exists in the context. Sentences without one are dropped.
2. Renders the answer in the "AI explanation" block, with citations linking to the provenance badges.

## Checklist before demo
- [ ] No key in `app/` (search the repo for `sk-`, `key=`)
- [ ] Proxy rate-limited
- [ ] AI block visually distinct and labelled
- [ ] Report-incorrect works
- [ ] "Use of AI" filled in on the project page
