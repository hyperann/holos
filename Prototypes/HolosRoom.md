# Holos Room: "Point at the world"

## The idea in one line

The board is a room. Instead of a grid, the person looks at a familiar place: a hospital ward, then their own living room. A spotlight moves from object to object. One press on the bed brings up a ring of the things people say about the bed ("I'm in pain", "Help me sit up"), and the room itself becomes the cue for finding the word.

This is a visual scene display (VSD). Research on visual scene displays suggests that, for adults with severe aphasia, language anchored in a familiar scene is easier to find than the same words in a grid. The prototype makes that claim in those words and cites no numbers.

## Who it serves best

- **Yuriy, 48 (word-finding aphasia), best of all.** He can recognise his wife even when the word "wife" won't come. In the family photo he picks her, and the sentences about her ("Call my wife", "I miss my wife") appear next. He never has to recall the noun. Part 3 of the judged flow is built around this. (In the prototype the people are generic symbols with their names printed; see Risks.)
- **Mykola, 39 (stroke, reads only simple words, one-switch scanning).** Every object has a short name pill, and every phrase cell pairs a symbol with words. Scanning goes through about six large objects instead of dozens of cells, so a slow scan still reaches the bed quickly. The bed is second in the scan, which puts "I'm in pain" two presses from the top.
- **Oleksandr, 41 (head movement only).** Served as well as in every prototype. The whole room runs on one switch, and Core's head-turn panel is offered in part 3.
- **Families and therapists.** A room explains itself. A carer understands "the things on the bedside table" without any training in AAC categories.

**Who it serves worst:**

- People who need many different words or new sentences. Each object holds 3–4 phrases, so the two rooms together hold about 45. A grid or core-word board grows much further than this.
- People with low vision. A picture is busier than a grid of large cells. The spotlight helps, and auditory prompts read each lit object aloud, but the scene still has more visual noise.
- Anyone whose rooms look nothing like these. That lasts until scenes can come from the person's own photos (see "How it would grow").
- Urgent phrases are not always one press away. There are no "Yes", "No" or general "Help" cells yet; the nearest are "Call the nurse" and "Please wait" (at the nurse) and "Not now" (at the home fridge), reached through the room like everything else.

## What to try first (60-second tour for Anna)

1. Launch the app. The ward is dark, and only the nurse in the doorway is lit, asking "How are you feeling?". Your first press (Space, or a tap anywhere) gives a dull knock and an empty "…" bubble, and the lights come up on a room full of things you still can't say. Your second press starts the scan.
2. Watch the spotlight. Everything except the lit object dims, and the light glides from the window to the bed to the body chart. A yellow arrow sits over **Bed**. Press when the bed is lit.
3. Phrases appear around the bed, joined to it by dotted threads. Press when **I'm in pain** lights up. You hear it straight away, it appears in a warm speech bubble above the patient's head, and it is added to the message strip.
4. Do the same with the bedside table and **Medicine**. The nurse answers in a text bubble: "I'll bring your medicine right away."
5. Keep pressing through to Home and open the family photo. The people appear first, then the sentences about the person you choose.
6. In free mode afterwards, press **Ukrainian** (badge УКР) in the chip row (it is part of the scan). Every pill in the room changes language, and the chip then reads **Англійська** (badge EN). Then open Settings ▸ "Touch the pictures" and tap objects directly.
7. Try Reduce Motion: the spotlight fades between objects instead of gliding, and the phrase ring fades in. Try an iPhone portrait simulator: the phrase ring becomes a panel of cells that takes the place of the chips and message strip while it is open, and the top bar keeps to the title, the goal checklist and a two-line hint.

## The 3-minute judged flow

Timings assume the default scan speed: 1.4 s per step, with the first step after any press staying lit 2.1 s. The room's top level has 9 stops (6 objects, the room switch, language, message), so one full loop takes 13.3 s. Reading time is included. The "likely" column assumes the judge misses one pass in part 2 while reading the goal.

| Step | What happens | Presses (golden path) | Est. seconds | Running total |
|---|---|---|---|---|
| 1a. The problem | Dark ward, only the nurse lit: "How are you feeling?" Card: "Imagine you are Mykola… You have one button. Press it." The press gives a dull knock and an empty "…" bubble, and the lights come up. | 1 | 9 | 0:09 |
| 1b. The silence | The lit room, still silent: "You can see everything you need. You just can't say it." The next press starts the scan. | 1 | 8 | 0:17 |
| 2. Scan the room | Goal: "Tell the nurse: 'I'm in pain. Medicine, please.'" Bed (2nd stop) → **I'm in pain** (1st in the ring) → bedside table (5th) → **Medicine** (2nd). Each choice is spoken at once. The nurse replies, then a card says "She understood you." | 4 + 1 | 35 (likely 48 with one missed pass) | 0:52 – 1:05 |
| 3a. Familiar places | Card: Yuriy, and what research on visual scene displays suggests. "Let's go home." The room crossfades to Home. | 1 | 14 | 1:06 – 1:19 |
| 3b. The photo offers the word | Goal: "Please call my wife." Photo (3rd stop) → **My wife** → **Call my wife**. Card: "The photo offered the word." | 3 + 1 | 20 (likely 30) | 1:26 – 1:49 |
| 3c. Head turn (optional) | Core's HeadTryPanel: Oleksandr's story and the camera toggle. Skip is lit first. | 1 | 11 | 1:37 – 2:00 |
| 4. Hear it in Ukrainian | The card stays in the judge's language. Until the message has been said, any press says it (**Say it in Ukrainian** shows lit): the whole board switches to Ukrainian and speaks "Мені боляче. Ліки, будь ласка." The card shows both languages, plus the voice notice if there is no Ukrainian voice. Then the card scan lights **Say it again** (2.1 s) and **Continue**. | 2 | 20 (with the voice notice) | 1:57 – 2:20 |
| Closing | Who Holos is for, the rehabilitation fact (Talk! NGO), and free / private / open source, about 100 words with the title and source line. **Keep talking** (lit first) or **Start again**; the card scan never pauses. | 1 | 22 | **2:19 – 2:42** |

Golden path: 16 presses, about 2:19. With a missed pass in parts 2 and 3 it comes to about 2:42. The worst realistic case is a judge who reads every word and misses twice in each guided step, which is about 3:05, just over. Cutting the 1b card (8 s) brings that to about 2:57, so if testing shows it running over, cut the 1b card first and keep the 1a press-into-silence beat. Never cut the arc.

## How one switch drives every screen

There is one owner, `Experience.refresh()`, and it routes every press for the current stage:

- **Narrative cards (1a, 1b, the two "done" cards, 3a):** a press means continue, but only after a 1.2 s minimum reading time. A double bounce therefore can never skip two cards. In scanning mode the card says "Press anywhere, or Space, to continue", and the line brightens once a press will count. In touch mode it becomes a real Continue button, which is also what VoiceOver users reach.
- **The room (parts 2 and 3, and the free room):** Core's `Scanner` walks the room. The top level holds the objects in reading order, then the room switch, the language chip, and `MessageBar.scanRow`. Each object is a `.group` whose children are its phrases. The photo nests one more level, with each person as a group of two sentences. Entering a group makes the ring appear. Every group ends with Core's "Go back" cell. Inside Clear, the strip draws both "No, keep it" (lit first) and "Yes, clear all", so the light is never on something you cannot see. Two quiet loops step back out on their own, and three quiet loops at the top pause the scan with a visible "Paused. Press to scan again." badge. Changing room, by the chip or by **Show me**, reloads the scan for the new room.
- **Head-turn panel:** Core's `HeadTryPanel` takes over routing while it is shown. Its `onDone` calls `headTryDone()`, which re-routes presses to the next card.
- **Ukrainian card:** until the message has been said, any press says it, so a mistimed press can never skip part 4. After that a small second `Scanner` walks **Say it again** and **Continue**.
- **Closing card:** the same small `Scanner` walks **Keep talking** and **Start again**. Both button cards keep the 1.2 s guard (an early press is ignored outright), and their scan never pauses, so "Keep talking" is always one press away however long the judge reads.
- **Auditory prompts:** each scanner is bound again whenever it takes over, because it also owns the speaker's "message finished" hook, which re-reads the lit item after every spoken choice.
- **Language without touch:** the **Ukrainian / Англійська** language chip (badge УКР / EN) is part of the room's scan. The `LanguageToggle` in the top bar is there for fingers.
- **Never stuck:** a yellow arrow marks the next thing to press on the way to the goal. It follows the person: if they open the wrong object it moves to that ring's "Go back" cell, and if they wander to the other room it moves to the room switch. The top bar says the same thing in words ("Press when … lights up": while scanning, a touch picks what is lit, not what is under the finger). Any spoken message of the goal's length is accepted, and a different sentence moves the story on with "You said it your way." After 45 s without progress a **Show me** chip appears and becomes the first stop in the scan, so one press performs the next part of the goal with the same speech and bubble.
- **Where a touch is a press:** the board, the top bar's words and every card are switch areas; each card carries its own, so a card long enough to scroll can still be dragged (there a tap that lifts without moving is the press). Settings and the top bar's `LanguageToggle` sit outside. Core's `SettingsSheet` holds the hub while it is open, so the room waits where it was.

## What makes it different

- **Words are attached to things.** "Medicine, please" sits on the bedside table next to the pills, not under a category called Needs. Finding a phrase starts from where you look, not from how a category system is organised.
- **The spotlight is the scan highlight.** On a grid, a yellow ring around a cell is enough. In a picture a ring gets lost, so everything else dims instead (`SpotlightVeil`, an even-odd veil with an animatable hole). The yellow ring and the name pill still mark the lit object, so the highlight looks the same as in the other prototypes.
- **The photo's two steps.** People first, then sentences. This is the clearest demonstration of "the board offers the word instead of asking for it" across the five prototypes.
- **The story never leaves the room.** The nurse's question, the answer, the move home and the Ukrainian replay all happen in one continuous space. Cards come and go over the room, and the free room at the end is the same room.
- **Everything is drawn in code.** Both rooms are SwiftUI shapes, gradients and SF Symbols in a dusk palette: deep teal walls, warm lamp light, a wooden floor. There are no image assets, so there are no licences and the bundle stays tiny.

## Strengths

- It is the most visual and memorable of the five concepts. It reads as an app in its own right, not as a settings screen.
- It argues the aphasia case on screen, in part 3, instead of only describing it.
- It runs entirely on Core's shared scanner, feedback, speech, head switch and settings. Only the board differs, so the comparison with the other prototypes is fair.
- Every spoken choice gets all three signals: the select haptic and sound from `Scanner.bind`, the speech itself, and a speech bubble from the person in the picture.
- The layout adapts. On iPad landscape and portrait the ring appears inside the picture. Below 640 pt width it becomes a three-column panel of cells that takes the place of the chips and message strip while it is open, so the words stay large on a phone and nothing is pushed off screen; the top bar also shrinks to the title, the goal checklist and a two-line hint, with the words at full width under the controls. The room keeps its 10:7 proportions, scales to fit and never drops below 140 pt tall.
- Accessibility: each room has a one-sentence VoiceOver description, every object is a labelled button, Ukrainian text is language-tagged throughout, Reduce Motion swaps every movement for a fade, Increase Contrast darkens the veil and makes pills solid, and name pills are capped at xLarge Dynamic Type so they don't cover the picture (VoiceOver and the cells carry the larger sizes). The top bar, chips and strip controls stop growing at the first accessibility size and offer the Large Content Viewer instead, as Core's `MessageBar` does. While a story card is up, VoiceOver reads the card first and skips the room's objects, chips and strip, which cannot be used behind it. The Ukrainian card keeps its explanation, buttons and voice notice in the judge's own language.

## Risks and open questions

- **Not compiled.** There is no Swift toolchain in this container. The code avoids anything uncertain: iOS 17 APIs only, vetted SF Symbols only, Swift 6 isolation on every `@Observable`, no force unwraps. Still, expect a first build in Xcode to need a small fix or two. Watch for type-checker time on the long art `ZStack`s; if it is a problem, wrap groups of children in `Group {}`.
- **Phone legibility of the art.** At iPhone width the room is drawn at about 0.36 scale. The objects are big and simple and the pills are real-sized text, but this should be checked on a device.
- **The ring covers part of the room** on iPad, by design (it hangs off the object). The bed is large, so its ring sits partly over the bed itself.
- **Small vocabulary.** About 45 phrases across two rooms is enough to make the point, not enough for daily life. A real app needs a grid or core-word layer beside the scenes (see below).
- **No urgent row.** The product description wants "Help / Yes / No / I'm in pain" always within reach. In this concept, pain is two presses away (bed is the 2nd stop, pain is the 1st phrase), but Yes, No and a general Help do not exist yet.
- **The people in the photo are symbols.** The prototype's people are generic symbols with their names printed, so in the demo the word is offered by the label beside a figure. The recognition argument holds fully only with the person's own photos (How it would grow, 2).
- **Timing at the edge.** The worst realistic case (every word read, two missed passes in each guided step) is about 3:05. Cutting the 1b card is the planned trim.
- **Evidence.** The visual scene display research is promising, especially for severe aphasia, but it is not settled. The copy says "suggests" on purpose. A speech therapist (ideally through Talk! / Говори!) should review the scenes and phrases.
- **Custom message strip.** `MessageStrip` reuses `MessageBar`'s ids, scan row, `owns(_:)`, `perform` and the two-step Clear (drawing "No, keep it" and "Yes, clear all" while the scan is inside Clear). It has its own layout, because Core's bar leaves about 46 pt for the sentence on an iPhone. If Core's bar gains a compact or two-row mode, this file can go.
- **The nurse's reply is canned.** It depends only on whether medicine was asked for. That is enough for the story, but someone might read it as speech recognition. It is not: the nurse is text only, and the voice belongs to the person.

## How it would grow into the real app

1. **The person's own rooms.** A carer takes a photo of the actual ward, home or rehab gym, draws hotspots with a finger, and records or chooses phrases for each one. This is how visual scene displays are used clinically ("just-in-time" scenes). The `Hotspot` / `RoomChoice` model already describes a photo plus rectangles plus phrases.
2. **Family photos as people.** Choosing a face in a photo leads to sentences about that person. The real app would use real faces (stored on device only), which is the strongest form of this concept for word-finding aphasia.
3. **A hybrid with a grid.** Pair the scene with a small always-visible core and urgent row (Yes, No, Help, Wait, More) for the words that do not belong to any object. Clinical VSD tools commonly combine a scene with a grid in this way.
4. **More rooms:** rehab gym, kitchen, car, church, the doctor's office. Plus a scene picker that is itself a scene: a "map" of the person's rooms.
5. **ARASAAC pictograms** in the phrase cells in place of SF Symbols.
6. **Apple Watch:** the last room's phrases as a short list, scanned with the Digital Crown or a tap.
7. **Open format:** export scenes as Open Board Format boards with hotspot regions, so other AAC apps can use the Ukrainian adult scenes.

## Files

All paths are inside `Prototypes/HolosRoom.swiftpm/`. `Core/` is the shared core and is untouched.

- `App/HolosRoomApp.swift`: `@main`. Creates the services and the `Experience` together and injects them.
- `App/RootView.swift`: the one screen: top bar, room, ring panel (in the bar's place on a phone), chips and strip, and the story cards. Owns the Settings sheet, the board's switch tap area and the VoiceOver order (card first).
- `App/Experience.swift`: the stage machine. Routes every press, binds each scanner as it takes over, handles choices, guided goals, room changes, "Show me", the Ukrainian replay and the timers.
- `App/Experience+Stage.swift`: the stages, what each one is (board mode, goal, card buttons, the Ukrainian card's reading language) and what it says.
- `App/Experience+Room.swift`: the room as the views see it: spotlight, guide marker target, hint text, lit card button, scan labels.
- `App/RoomTheme.swift`: dusk chrome colours for the backdrop, cards and chips, with Increase Contrast variants.
- `Copy.swift`: every prototype string as `Bilingual`, grouped by part of the story.
- `Room/RoomModel.swift`: room space, `ArtRect`/`ArtPoint`, `Hotspot`, `RoomChoice`, `RingItem`, `SpokenLine`, scan ids.
- `Room/RoomPlace.swift`: ward and home: names, VoiceOver descriptions, where the person sits, the room-switch chip.
- `Room/RoomBoardModel.swift`: the scanner, the scan tree, what is open, the ring's cells, the speech bubble timer.
- `Vocabulary/Vocabulary.swift`: the judged goals and the lookup tables (phrases, people in the photo, routes).
- `Vocabulary/Vocabulary+Ward.swift`: the ward's six objects and their phrases, in both languages.
- `Vocabulary/Vocabulary+Home.swift`: home's six objects, including the photo's people-then-sentences.
- `Art/ArtKit.swift`: the dusk palette, `artFrame` placement, and shared shapes (drape, lamp shade, blanket, quad, floorboards, glow, vignette).
- `Art/WardArt.swift`: the ward illustration.
- `Art/HomeArt.swift`: the home illustration.
- `Board/RoomCanvas.swift`: composes the room: picture, veil, hotspots, bubbles, ring, pause badge, all scaled to fit.
- `Board/SpotlightVeil.swift`: the animatable even-odd veil that is this concept's scan highlight.
- `Board/HotspotLayer.swift`: invisible buttons over the objects, and their name pills.
- `Board/PhraseRing.swift`: ring layout maths, the ring over the room, the narrow-screen panel, ring cells.
- `Board/SpeechBubble.swift`: the person's (spoken) and the nurse's (text-only) bubbles.
- `Board/GuideMarker.swift`: the yellow "next" arrow.
- `Board/TopBar.swift`: part dots, title, goal checklist, hint, language toggle, Settings; a shorter, full-width layout on a phone. Its words are part of the switch area.
- `Board/BottomBar.swift`: the Show me, room switch and language chips.
- `Board/MessageStrip.swift`: the message strip, laid out for the dusk room and for phones, using `MessageBar`'s ids, actions and two-step Clear.
- `Steps/StageCard.swift`: `CardShell` (with a pinned footer, so a switch user always sees the lit button, and its own switch area that still lets long text scroll), narrative card, continue footer, card button.
- `Steps/UkrainianCard.swift`: part 4: both languages, Say it in Ukrainian / Continue, and `MissingVoiceNotice` (Core's voice-notice words in the judge's reading language).
- `Steps/ClosingCard.swift`: the closing screen: Keep talking / Start again.
- `Steps/StageOverlay.swift`: picks the card for the current stage, including Core's `HeadTryPanel`.
