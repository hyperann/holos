# Holos — prototypes

**Holos** (Голос, "voice") is a free, private, open-source communication board for Ukrainian
adults who have lost speech through stroke, brain injury or war trauma — people who may not be
able to type, read easily, or tap a small screen. Every part of it works with **one switch**: a tap
anywhere, the Space or Enter key, any game-controller button, or a deliberate turn of the head.

This repository holds **five prototypes** of the Swift Student Challenge 2027 app playground. Each
is a complete answer to the same brief, written to run as is (none has been compiled yet; see
below), built on the same shared engine, so that the concept can be chosen by trying them rather
than by imagining them.

| Prototype | The idea in one line |
| --- | --- |
| [Holos Grid](Prototypes/HolosGrid.md) | The description built faithfully: a topic grid with row-column scanning, quick phrases and a message bar. |
| [Holos Bedside](Prototypes/HolosBedside.md) | A conversation, not a keyboard: the carer asks, and the board offers only the answers that fit. |
| [Holos Room](Prototypes/HolosRoom.md) | Point at the world: an illustrated room is the board, and the scan sweeps a spotlight across it. |
| [Holos Compass](Prototypes/HolosCompass.md) | Four huge choices at the compass points — and the head can point at them, no scanning at all. |
| [Holos Words](Prototypes/HolosWords.md) | Find the word: sentence starters, and a way to *describe* a word you cannot recall. |

**[PROTOTYPES.md](PROTOTYPES.md)** compares them side by side and suggests what to look for.

## Running a prototype

Each prototype is a self-contained App Playground (`.swiftpm`), iOS/iPadOS 17 or later.

- **Start in Xcode 16 or later on a Mac:** open `Prototypes/<Name>.swiftpm` (double-click it, or
  File › Open), pick an iPad simulator, and Run. Because nothing has been built yet, fix any
  first-build errors here, where Xcode reports them clearly.
- **On a connected device:** Xcode signs with the team named in `Package.swift`; if it is not
  yours, choose your own team under Signing & Capabilities.
- **iPad or Mac, Swift Playgrounds with Swift 6 support** (4.6 or later, as far as I know — check
  the release notes): once a prototype builds, copy its `.swiftpm` folder into iCloud Drive (or
  AirDrop it), open it in Swift Playgrounds, and tap Run.

Things the simulator cannot show:

- **Haptics** need an iPhone — iPads and Macs have no Taptic Engine. Every step also clicks on
  every device, so nothing is lost without them. To feel them: connect an iPhone, turn on
  Settings › Privacy & Security › Developer Mode, choose it as the run destination in Xcode, and
  Run. (Swift Playgrounds is not available on iPhone.)
- **Head control** needs a real front camera. It is off until you turn it on, and Holos asks for
  camera permission only then.
- **Ukrainian speech** needs a Ukrainian voice on the device. On iPad: Settings › Accessibility ›
  Spoken Content › Voices › Ukrainian. On a Mac: System Settings › Accessibility › Spoken
  Content › System voice › Manage Voices. Without one, the board stays in Ukrainian and speaks
  English, and says so on screen. (Holos Words' step 4 instead shows its sentences in Ukrainian,
  plays nothing, and explains why.)

To try the switch the way its users would, use a Bluetooth keyboard's Space bar, a game
controller, or just tap anywhere on the board.

> **Not yet compiled.** These prototypes were written and reviewed in a Linux environment with no
> Swift toolchain, so nothing here has been built yet. Every file went through independent review
> passes for Swift 6 and API correctness, then a final audit that found no errors by reading —
> but reading is not compiling, so expect the first build in Xcode to surface a few things to fix
> anyway (each prototype's doc lists its own risks).
>
> One expected warning: each `Package.swift` uses `swiftLanguageVersions:`, which SwiftPM 6
> deprecates in favour of `swiftLanguageModes:`. It is left as is on purpose, because that is the
> line Xcode and Swift Playgrounds themselves write into an app playground's generated manifest.

## How the code is organised

```
Shared/HolosCore/       The engine every prototype shares (edit here, never in a prototype)
  Switch/               Tap, key, game controller and head turn → one "press"
  Scanning/             The single-switch scanner, and its standard feel
  Speech/               Ukrainian and English voices, with a safe English fallback
  Language/             English and Ukrainian, bilingual strings and gendered Ukrainian forms
  Feedback/             Core Haptics patterns and synthesised clicks
  Settings/             Everything a person, carer or therapist can tune
  Vocabulary/           Phrases (picture + word + what to say) and the message being built
  UI/                   Cells, message bar, settings, language toggle, head-turn panel
Prototypes/
  <Name>.swiftpm/       One app playground per concept; Core/ is a copy of Shared/HolosCore
  <Name>.md             What the prototype is, who it serves, its 3-minute flow and timing
tools/sync-core.sh      Copies Shared/HolosCore into every prototype's Core/
```

App playgrounds must be self-contained — Swift Playgrounds and the challenge's ZIP cannot follow
a symlink or a local package — so each prototype carries its own copy of the core. Change
`Shared/HolosCore`, then run `tools/sync-core.sh`.

The core's central idea is the one in the product description: every input becomes the same
switch press (`SwitchHub`), and one scanner (`Scanner`) turns presses into choices. A new input
only has to produce a press to work everywhere at once.

## Privacy

No account, no analytics, no network. The optional head switch reads camera frames on the device
and never records, saves or sends them.

## Licence

Not chosen yet. The closing screens call Holos open source, which needs a licence file at the
repository root before submission.

## Symbols

The prototypes use SF Symbols as placeholders. The real app is planned to use
[ARASAAC](https://arasaac.org) pictograms (CC BY-NC-SA), credited on an About screen.
