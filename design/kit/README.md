# Holos design kit

HTML and CSS stand-ins for the SwiftUI views in `Shared/HolosCore`, used to draw design mockups
of the five prototypes. The mockups are **not device screenshots**: nothing has been compiled
yet. They are recreated by hand from each prototype's Swift code — its layout, colours, copy,
vocabulary and scan states — and rendered with headless Chromium.

Three stand-ins mean a mockup can never be pixel-identical to the real app:

| On device | In the mockups | Licence |
| --- | --- | --- |
| SF Pro | Inter | OFL (system font here) |
| SF Rounded | Nunito (`fonts/`) | OFL, `fonts/Nunito-OFL.txt` |
| New York (serif) | Source Serif 4 (`fonts/`) | OFL, `fonts/SourceSerif4-OFL.txt` |
| SF Symbols | Phosphor Icons, plus four hand-drawn shapes (`icons.js`) | MIT, `Phosphor-LICENSE.txt` |

## Rendering

```sh
node design/kit/render.cjs design/HolosGrid/*.html
```

Each `page.html` becomes `page.png` beside it, at 2× (an iPad Retina screen: 2388×1668 for
landscape). A `WARN` line means something to fix — usually a missing icon.

## Writing a page

```html
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>Grid · Board</title>
<link rel="stylesheet" href="../kit/kit.css">
<style> /* this page's own layout */ </style></head>
<body data-device="ipad" data-statusbar="dark" style="background:#F6F7F9">
  <div class="safe"> … the screen, inside the safe area … </div>
  <script src="../kit/icons.js"></script><script src="../kit/kit.js"></script>
</body></html>
```

- `data-device`: `ipad` (1194×834 pt, an 11-inch iPad Pro in landscape — the primary canvas),
  `ipad-portrait` (834×1194) or `iphone` (393×852). One CSS px is one point.
- `data-statusbar`: `dark` text for light screens, `light` for dark ones, or `none`.
- `.safe` is the safe area (24 pt status bar, 20 pt home indicator on iPad). Paint backgrounds
  on `<body>` (they run under the status bar, as `.ignoresSafeArea()` does) and content in `.safe`.
- Icons: `<i data-sf="pills.fill"></i>` with the **SF Symbol name from the Swift code**. Size
  with `font-size` (icons are 1em square) or, inside a `.cell`, let the cell size them. An icon
  without a stand-in renders as a magenta "?" and `render.cjs` prints `WARN`.

## Components (copied from Core)

| Class | SwiftUI | Notes |
| --- | --- | --- |
| `.k-social` … `.k-control` | `WordKind` | sets `--tint` and `--kind-ink`; put on any tinted thing |
| `.cell` + `<i data-sf>` + `<b>label</b>` | `SymbolCell` | radius 18, 1.5 pt ink border at 35 %; `.small` / `.xsmall` shrink long labels |
| `.cell.backcell` | `BackCell` | "Go back" with `arrow.uturn.backward` |
| `.lit` | `.scanHighlight(true)` | 2 pt black · 7 pt yellow · 2 pt black ring, 1.04 lift (`.nolift` to skip the lift) |
| `.dim` | rows not in play | 45 % opacity |
| `.msgbar`, `.msg-sentence`, `.chip`, `.msg-ctl` (`.prominent`, `.back`) | `MessageBar` | add `.entered` to the bar while its row is entered |
| `.langtoggle` with two `<span>` (one `.on`) | `LanguageToggle` | EN · УКР |
| `.voicenotice` | `VoiceNotice` | |
| `.headpanel`, `.panelbtn`, `.headmeter` | `HeadTryPanel`, `HeadSwitchMeter` | |
| `.pressflash` | `.switchPressFlash()` | the ring that flashes on every press |
| `.dimmed`, `.formsheet`, `.navbar`, `.form*`, `.toggle`, `.slider` | iOS sheet and `Form` | for `SettingsSheet` |

Text styles are variables at the default Dynamic Type size: `--largeTitle` 34, `--title` 28,
`--title2` 22, `--title3` 20, `--headline` 17 (semibold), `--body` 17, `--callout` 16,
`--subheadline` 15, `--footnote` 13, `--caption` 12, `--caption2` 11. Fonts: `var(--sf)`,
`var(--rounded)` (`design: .rounded`), `var(--serif)` (`design: .serif`).
