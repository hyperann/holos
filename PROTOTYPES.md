# Choosing a Holos

Five prototypes, one brief. Each is a complete app playground with the same four-step judged
experience — feel the problem, give one press a voice, see how the board helps with aphasia,
hear it in Ukrainian (Compass swaps step 3 for head pointing and moves aphasia into its
closing) — and each answers the question *what should a Holos board be?* differently.

They all run on the same shared engine (`Shared/HolosCore`), so the *feel* of a switch press,
the voices, the haptics, the settings and the privacy model are identical. What differs is the
board and the story around it, which is exactly what is being chosen.

> None of the five has been compiled yet (there was no Swift toolchain where they were written).
> Every timing below is an estimate from counting scan steps at the default 1.4 s per step plus
> reading time, taken from each prototype's own doc. Try them on a device before trusting any of it.

## At a glance

| | [Grid](Prototypes/HolosGrid.md) | [Bedside](Prototypes/HolosBedside.md) | [Room](Prototypes/HolosRoom.md) | [Compass](Prototypes/HolosCompass.md) | [Words](Prototypes/HolosWords.md) |
| --- | --- | --- | --- | --- | --- |
| **The board is…** | a topic grid with quick phrases | a chat: the carer asks, the board answers | an illustrated ward and living room | four choices at the compass points | sentence starters and a word finder |
| **Scanning** | row, then cell | one answer at a time (≤ 11 stops, 12 with Show me); row, then cell on the "Something else" board | object, then a ring of phrases | a ring of 6–7 stops per level | row, then cell; linear in Find a word |
| **Best for** | Mykola; therapists who know grids | Yuriy and Mykola; carers | Yuriy | Oleksandr; low vision; from a bed | Yuriy; therapists |
| **Weakest for** | anyone needing speed | starting a conversation unprompted | broad or new sentences; low vision | broad vocabulary | Mykola (reading-heavy); slow by head switch |
| **Head control** | head turn = switch | head turn = switch | head turn = switch | **head points directly**, no scan (step 3 panel and free board; in step 2 a head turn is the switch) | head turn = switch |
| **Vocabulary in the prototype** | 60 cells + 5 quick phrases | 7 answer sets (4–6 answers each, plus Yes · No · Not sure · Something else) + a 3-topic × 8-word mini board | about 45 phrases across 2 rooms | about 30 finished sentences in a tree | 6 starters × 8 words + Find a word |
| **Novelty for judges** | lowest, by design | high (story and emotion) | highest (visual) | high (head pointing) | high (language insight) |
| **Judged flow (estimate)** | ~2:11 | ~2:22 (2:35 with a missed pass) | ~2:19 (2:42 likely) | ~2:03–2:32 (~2:24–2:53 with head pointing tried) | ~2:44 (up to ~3:00) |
| **Own code** (Swift, excluding Core/ and Package.swift) | 20 files, ~3,700 lines | 22 files, ~3,800 lines | 29 files, ~4,700 lines | 25 files, ~4,200 lines | 26 files, ~3,800 lines |

The shared engine adds 27 files and about 3,400 lines to each.

## The five, in a paragraph each

**Holos Grid — the board, as specified.** Your description built faithfully: a message bar, a
row of urgent quick phrases that speak at once, six adult topic boards, row-column scanning with
a "go back" cell on every row, and Fitzgerald colour coding. It is the baseline: calm, clinical,
legible at a glance, and instantly familiar to any speech therapist. Its honesty is also its
limit — row-column scanning is slow, and a judge looking for something new will find it the
least surprising. Its doc makes a good argument for why "Wife" is one cell that says the whole
sentence: Ukrainian's dative cannot be glued on afterwards.

**Holos Bedside — a conversation, not a keyboard.** Modelled on Supported Conversation for
Adults with Aphasia: the partner asks, and the board offers only the four to six answers that
fit *that* question. "Where does it hurt?" becomes a drawn body; "How bad?" becomes a face scale;
Yes, No, Not sure and Something else are always there. The person's answers appear as their own
chat bubbles and are spoken; the nurse's lines are only ever text, because the voice belongs to
the person. In free mode a carer taps question cards and the board adapts. It is the most
emotional judged story and the lightest cognitive load — but it is reactive by design, and the
"Something else" board is small.

**Holos Room — point at the world.** A visual scene display: a hospital ward and a living room
drawn entirely in SwiftUI, with a spotlight that glides from the window to the bed to the body
chart. One press on an object blooms a ring of the things people say about it. The family photo
offers "My wife" as a person to pick rather than a word to recall; in the prototype she is a
generic figure with her name printed, so the argument lands fully only once the photo is the
person's own. It is the most original and the most beautiful on paper; it is also the narrowest
(each object holds three or four phrases), the busiest for low vision, and it has no Yes, No or
general Help cells at all yet (pain is two presses away). Its worst case runs slightly over three
minutes; the doc names the card to cut.

**Holos Compass — four choices, any body.** Never more than four huge choices, at north, east,
south and west, around a hub that shows the sentence being built. The path is the sentence ("I
feel → Pain → Head → A lot" says "My head hurts a lot."), and Yes or No are always one press
from home. Because there are only four directions, the head can *point*: turn or tip and hold,
with no scan at all — the only prototype that gives Oleksandr direct choice (in its step 3 panel
and on the free board). Four choices also fit an Apple Watch face, which is the roadmap. The cost
is depth: a four-way tree grows deep fast, and the aphasia beat moves from its own step into the
closing.

**Holos Words — find the word.** Built around anomia. Pick "I need…", "Call my…" or another
starter and the board offers the words that fit it, so a sentence takes two choices. When the
word isn't there, *describe* it — a person, family, my generation — until it is offered with its
first letter as a cue, in the spirit of semantic feature analysis. Step 4 shows judges why this
is hard in Ukrainian: every starter-and-word pair stores its own whole inflected sentence,
because «Подзвоніть моїй дружині» cannot be built by concatenation. It is the most
language-rich and most clearly adult prototype, and the most reading-heavy; its timing is the
tightest of the five.

## What to look for when you try them

Settings are saved per prototype (language, touch or scanning, scan speed, read-aloud). Do the
timed run first — or before it, choose Settings › Reset to defaults and switch the language back
to EN (reset keeps the language on purpose) — so every prototype is timed from the same start.

1. **Run each judged flow once with only the Space bar,** as a judge with no context would. Note
   where you hesitated and, with a stopwatch (the prototypes show no clock), the time when the
   closing screen appears.
2. **Then run it as Mykola:** Settings › Read each cell aloud quietly, eyes half closed. Which
   board can you still use by sound alone?
3. **Then as Oleksandr:** turn on Settings › Switches › Turn your head and try to say one thing.
   (Compass also lets the head point, in its step 3 panel and on its free board.)
4. **Then switch to Ukrainian** and read every label. All Ukrainian was written and reviewed with
   care, but it still needs your eye and, before submission, a speech therapist's.
5. **Ask which one you would want a judge to remember tomorrow** — and which one a ward in Kyiv
   would actually use next year. If those are different prototypes, that is useful to know.

## Things that are the same in all five

- One switch completes everything: tap anywhere (on the boards it presses on touch-down, for
  tremor; on Grid's reading screens and on scrolling text in Bedside, Room and Words a tap presses
  when the finger lifts, so the text can still scroll), Space or Enter, any game-controller
  button, or a deliberate, held head turn measured from the person's own resting position.
- When VoiceOver, Switch Control or AssistiveTouch (which is how iPadOS Eye Tracking clicks) is
  running, Holos stops its own scanning and lets the cells be chosen directly.
- A haptic, a synthesised click and a visual highlight on every step; speech that the ringer
  switch cannot mute.
- English by default, Ukrainian one tap or one scanned cell away, gendered Ukrainian forms
  ("я втомився" / "я втомилася"), and an English fallback that explains itself when no
  Ukrainian voice is installed (Words' step 4 instead shows the Ukrainian, plays nothing and
  says why).
- Settings for scan speed, ignoring repeat presses, auditory prompts, head-turn angle and hold
  time, speech rate, vibration and sound. Opening Settings holds every press and stops the scan
  where it is. While scanning, Clear needs a second press ("No, keep it" lights first); a finger
  tap on Clear clears at once, and Bedside has no message to clear.
- No account, no analytics, no network. The camera, when asked for, is read on the device and
  nothing is recorded.

## Combining them

Because everything shares one engine, the concepts are not mutually exclusive. Some
combinations follow naturally from the docs:

- **Bedside + Grid:** the conversation as the front door, the full grid as "Something else".
  Bedside already contains a small version of this.
- **Any board + Compass's head pointing:** `Board/HeadPointer.swift` turns calibrated yaw and
  pitch into four directions. Any board that offers four choices at a time could use it.
- **Words' frame-by-word storage everywhere:** all five already store each finished sentence
  whole in both languages; Words goes further and stores a separate whole sentence for every
  starter-and-word pair (`SentenceFrame`), the model any board that combines two choices will
  need in Ukrainian.
- **Room's photo-first families:** in the real app, a person's own family photos could be the
  "people" level of any board.

## Known gaps across all five

- Never compiled. Expect the first Xcode build of each to show a few errors to fix.
- The SF Symbols are placeholders for ARASAAC pictograms.
- Vocabulary has not been reviewed by a speech therapist.
- Vocabulary is Swift code, not the description's bundled JSON. Moving the chosen board's
  vocabulary to a JSON or open board format file (which a therapist could review and a carer
  edit) is a task for after the choice.
- No prototype lets a carer edit phrases or add a photo cell (the description's carer persona).
  Each doc's "How it would grow" section sketches how its board would do it.
- iPadOS Eye Tracking is untested on a device; Holos treats it as touch, so the cell you dwell on
  is the cell you get.
- Compass's head-pointing directions (which way is left, which way is up — its panel has swap
  toggles meanwhile) and the Ukrainian iOS and macOS menu paths in the "no Ukrainian voice"
  notice ("Усний контент") need checking on a real device.
- There is no licence file yet, so the code is not yet open source in the legal sense the closing
  screens promise. The licence is yours to choose.
