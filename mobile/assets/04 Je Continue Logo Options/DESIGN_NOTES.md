# Je continue — logo exploration

These four PNG concepts are selection candidates. They are not referenced by the Flutter app and
do not replace `assets/games icons/Je Continue.png` until a direction is approved.

## Design basis

- Player mechanic: maintain attention across a calm letter stream, first detect `X`, then detect
  `X` only when it immediately follows `A`.
- Real display sizes: 36 px in the games hub, 56 px in the game picker, 132 px on the cover and
  168 px on the format screen.
- Zennyt palette: navy `#071333` / `#26224D`, indigo `#4E46E8`, magenta `#D12E7D`, cyan
  `#00A9D6`, orange `#FF9F43`, white.
- Style: compact rounded vector-like mark, thick navy outline, transparent background, no embedded
  purple tile, no clinical or diagnostic imagery.

## Options

1. **AX Focus Gate** — explicit `A -> X` relationship, dominant focused `X`, strongest at 36 px.
2. **Signal Stream** — six stimulus capsules forming a calm continuous sequence around `A -> X`.
3. **Focus Relay** — abstract cue-target pair in a five-signal loop; best letter-free alternative.
4. **Continuity Loop** — the most abstract direction, emphasizing persistence and repetition.

Recommended order for product selection: **1**, then **3**, then **2**, then **4**.

## Shared generation prompt

```text
Use case: logo-brand
Asset type: square mobile serious-game logo used at 36, 56, 132 and 168 px
Style/medium: premium flat vector-like mobile game mark; serious and calm; chunky rounded geometry;
thick consistent deep-navy #071333 outline; white negative space; restrained solid accents
Composition/framing: one centered cohesive symbol occupying 78-82% of a square canvas; even padding;
strong silhouette readable at 36 px
Color palette: #071333, #26224D, #4E46E8, #D12E7D, #00A9D6, #FF9F43 and white; no green in subject
Scene/backdrop: perfectly flat solid #00FF00 chroma-key background for local removal
Constraints: crisp isolated edges; no background tile; no blur, glow, thin lines, micro-details,
watermark, mockup, photorealism or 3D
Avoid: brain, eye, medical symbol, clock, stopwatch, speedometer, lightning, airplane, trophy,
keyboard, hand, mascot, live score or correct/incorrect symbolism
```

### Option 1 — AX Focus Gate

```text
Create one bold open indigo focus ring. Center a large magenta capital X inside four short chunky
white focus brackets. Immediately before it on the lower-left arc, place one smaller cyan capital A,
joined to X by one short cyan-to-magenta rhythm stroke. Add three broad ring segments: indigo, cyan
and one small orange accent. Render exactly one A and one X and no other text.
```

### Option 2 — Signal Stream

```text
Create a compact flowing S-shaped stream made of broad rounded stimulus capsules. Most capsules are
white or pale indigo with navy outlines. Highlight one cyan capsule containing exactly A, immediately
followed by one magenta capsule containing exactly X. Join the pair with one short connector and use
one open indigo arc to indicate a continuing calm stream. No other text.
```

### Option 3 — Focus Relay

```text
Create one bold open circular relay path with exactly five large evenly spaced signal beads. A cyan
cue bead is immediately followed clockwise by a larger magenta target bead held inside four short
white focus brackets. Other beads are white or indigo. Integrate one compact directional notch into
the path. No text, letters or numbers.
```

### Option 4 — Continuity Loop

```text
Create a thick rounded asymmetric infinity-shaped ribbon with exactly four signal beads. Highlight
two consecutive beads: cyan cue first, magenta target second. Surround only the magenta target with
two broad opposing white focus brackets and integrate one subtle directional notch. Avoid a heart or
wellness appearance. No text, letters or numbers.
```

## Export and QA

- Generated with the built-in image generation workflow on a flat chroma background.
- Background removed locally with soft matte, despill and one-pixel edge contraction.
- Final deliverables normalized to 1024 x 1024 RGBA.
- All four corner pixels have alpha 0 and automated inspection found no green fringe.
- `Je Continue Logo Options - Comparison.png` checks each mark on white, on `#4E46E8`, and at the
  real 36 px / 56 px menu sizes.
