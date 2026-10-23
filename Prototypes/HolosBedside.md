# Holos Bedside — "A conversation, not a keyboard"

## The idea in one line

The communication partner asks a question, and the board answers with only the four to six replies that fit *that* question — scanned one at a time, spoken aloud as whole polite sentences — so a person with aphasia answers instead of composing.

## Who it serves best

- **Yuriy (aphasia, can read but cannot find words)** — the strongest fit. He never has to recall a word: every question arrives with its likely answers already on the board, and "Something else" offers words by topic when the prediction misses ("Call my wife" in step 3 is exactly his case).
- **Mykola (stroke, right side paralysed, reads simple words)** — very good. Linear scanning of at most eleven stops (twelve once "Show me" appears) means one press per answer and almost nothing to hold in mind; every cell has a picture, and the pain scale and body map need no reading at all.
- **Oleksandr (head movement only)** — good. A head turn is just another switch press, and the whole flow is one-switch.
- **Carers and nurses** — the partner question cards ("Ask…" row in free mode) give them an active, natural role: they ask, as they would anyway.
- **Serves worst:** someone who wants to *start* a conversation or say something long and specific with nobody asking. Bedside is reactive by design; the "Something else" board helps, but it is eight words per topic, not a full vocabulary. People who can type fluently are better served by «Я кажу».

## What to try first (60-second tour for Anna)

1. Launch, and just watch step 1 for 20 seconds. Press Space or tap a few times while the nurse waits — feel the dull knock and read "There is nothing to choose."
2. Press once on "Press to answer". In step 2, follow the terracotta "This one" tag: press when **In pain** lights up. Notice the nurse waits for your sentence to finish before replying, and the board changes shape with each question — big cells, then a **body**, then a **pain scale with faces**, then needs.
3. Deliberately pick a "wrong" answer once (say, *Scared*). The nurse answers kindly and the story carries on.
4. In step 3, press **Something else**, then **Talk**, then the top row (the tag sits on the row until you are inside it), then **Call my wife**. Press Skip on the head-turn panel (or try a head turn).
5. Listen to step 4: the transcript redraws in Ukrainian while the screen around it stays in English, and your answers are spoken again. Then choose **Keep talking** and, as the carer, tap the question cards along the top.

## The 3-minute judged flow

Default scan speed 1.4 s per step, first item of each new scan lit 2.1 s; every new set of answers waits 0.8 s before the scan starts, so the eye lands on the question first. Times include typing dots, the nurse's replies, waiting for the spoken answer to finish, and a reading allowance.

| Step | What happens | Presses | Est. seconds | Running total |
|---|---|---|---|---|
| 1. Feel the problem | Nurse: "Good morning! How are you feeling?" The answer area is empty and grey; presses only knock. "…", "Take your time.", "I'll come back later, then." She leaves (about 20 s of scene). Card: "Holos gives your answer a voice." (about 8 s to read) | 1 (plus any knocks) | 28 | 0:28 |
| 2. One switch, a whole conversation | Four turns, linear scan: **In pain** (1st item) → nurse "I'm sorry. Where does it hurt?" → body map, **Head** (1st) → "How bad is it?" → face scale, **A lot** (3rd) → "I'll bring your medicine now. Do you need anything else?" → **Water** (1st) → "Coming right up." About 26 s of typing, settling, scanning and speech, plus a few seconds to take in each new board | 4 | 38 | 1:06 |
| 3. When the word won't come | "Is there anything you want to tell me?" → **Something else** (1st, because an open question can't be predicted) → mini board: wait for **Talk** tab (5th), press; top row, press; **Call my wife** (1st), press → "Of course. I'll call your wife right away." → optional head-turn panel, **Skip** lit first (about 7 s with reading) | 5 | 28 | 1:34 |
| 4. Hear it in Ukrainian + closing | The transcript redraws in Ukrainian (the step, status and Continue stay in your language); each of your five answers is spoken again in turn, nurse lines shown, never spoken (about 11 s). **Continue** → closing card on who it is for and why it is free, private and open source — about 130 words, the longest read (about 35 s); its scan keeps going while you read, so the first press after reading chooses → **Keep talking** / **Start again** | 2 | 48 | 2:22 |

About 2:22 if each target is caught on its first pass. Step 3's goal text is the longest read on a board; a judge who reads it all will likely press **Something else** on its second pass, which makes about 2:35.

A missed pass costs one loop of the current board, n × 1.4 s: 12.6 s on the 9-item boards (pain scale, "anything else"), 14 s on "How are you feeling?" (10), 15.4 s on the 11-item boards (body map, needs) and 16.8 s once Show me joins them; the "Something else" board's top level is 7 items, 9.8 s. From 2:22 that leaves room for about two misses inside 3:00 — about one, if step 3 already took its second pass.

## How one switch drives every screen

- **Step 1:** every press goes to `Experience.problemPressed()`. Before the card it knocks (haptic + low tone + the grey box darkening); in the card's first 1.5 s a press gets the same gentle "not yet" knock; after that a press continues, with the select feel. The card's button is drawn lit from the start: lit means "a press does this". The card covers only the area under the top bar, so Settings and the language toggle stay tappable, and VoiceOver treats it as modal. On a small phone or with very large text the card scrolls, and a clean tap on it still presses.
- **Steps 2–3 and the free board:** one `Scanner` per screen, fed by `Experience.scanTree`. The tree is linear for answers (≤ 6 answers + Yes · No · Not sure · Something else + the language toggle: at most 11 stops, 12 with Show me), row-column only on the eight-word "Something else" board (rows, then topics, then "Back to the answers"). Whenever the story changes the tree — the nurse takes her turn (empty tree, scan stops, cells dim), a new question arrives, the mini board opens — the scan restarts on the new tree after a 0.8 s settle.
- **Language:** the LanguageToggle in the top bar is the last item of every scan, so a switch-only user can reach Ukrainian. Carers can also just tap it: the top bar sits outside the switch area.
- **Never stuck:** a guide tag marks the next target, and when it lives on the mini board the tag leads there one step at a time (Something else → Talk → Call my wife; if the mini board is opened by mistake, the tag moves to "Back to the answers"). While scanning, the tag sits on the *row* that holds the word until the scan is inside it, and the banner says "Press when the marked row lights up, then the word." Any spoken answer moves the story on. After 45 s without progress (opening the board or choosing a topic counts), **Show me** appears first in the scan (and as a button in the banner) and answers for you.
- **Head-turn panel:** Core's `HeadTryPanel(pausing: scanner)` takes over routing, pauses the board's scanner while shown, and hands presses back to it before `onDone` moves the story on. It covers only the board under the top bar (Settings and the language toggle stay reachable), VoiceOver treats it as modal, and the banner shrinks to "Optional: try a turn of the head, or skip."
- **Step 4 and closing:** the replay routes every press to Continue (after 1.5 s; an earlier press gets the "not yet" knock); Continue has the select feel. The closing card scans its two choices, starting only after 1.5 s so the press that ended the replay can't also choose, and keeps scanning for 40 loops (about two minutes) instead of resting after Core's usual three, so the first press after reading the card chooses instead of only waking the scan.
- **Tap anywhere:** in scanning mode the answers — and step 1's empty answer box and step 4's Continue row — are Core's touch-down `switchTapArea`, so a shaking hand never loses a press there. The transcript beside them is a clean-tap switch (`pressOnTap`): a tap presses, a drag scrolls back through what was said. The closing card's long text works the same way, beside its big touch-down buttons.
- **Touch mode** (Settings, or automatically under VoiceOver / Switch Control): the scanner stops, tap areas switch off, every cell, tab and the body map are tapped directly; the banner says "Tap the marked answer".

## What makes it different

- **The partner is part of the interface.** Questions drive the board. This follows Supported Conversation for Adults with Aphasia: the skilled partner reduces the load by asking well, the board makes the answer possible.
- **The board changes shape with the question:** six picture cells, a body to point at, an ordered pain scale drawn as faces (smile to frown), a list of people. Recognition beats recall.
- **It is a conversation on screen.** The transcript is the record of the person being heard; their bubbles are on the right, filled, and spoken. The nurse's lines are text only — Holos' voice belongs to the person.
- **Turn-taking is built in:** the board dims and stops scanning while the partner "types", and the nurse never replies until the person's sentence has finished.
- **The transcript stores meaning, not text,** so step 4 redraws the whole conversation in Ukrainian (with feminine forms where a woman speaks) and re-speaks it without translating anything — while the screen around it stays in the judge's language, and nothing about the language setting changes.

## Strengths

- Fastest path to a meaningful answer: most targets are the first item lit; step 2 is four presses for "I'm in pain. My head hurts. A lot. Water, please."
- Kindest failure mode: there are no wrong answers; unexpected ones get a warm reply and the story continues.
- The emotional arc is felt, not explained: step 1's silence, the nurse leaving, then the same nurse coming back and *hearing* you.
- Small, predictable scan sets (≤ 11 items, 12 with Show me) suit fatigue, attention and memory problems after brain injury.
- Strong carer story for the real app: question cards are something a nurse can learn in ten seconds.

## Risks and open questions

- **Reactive by design.** Without a partner asking, the person has only "Something else". The real app needs a way to *initiate* (a "I want to say something" bell, quick phrases).
- **Prediction quality is everything.** Seven hand-written answer sets are a demo; real sets must come from speech therapists and from what patients actually say, and must be editable by carers.
- **Linear scanning of 11 items is slow when the answer is near the end** (≈ 16 s for the last item). Order matters; the scale is deliberately not reordered so it stays truthful.
- **"Something else" is small** (3 topics × 8 words). A real fallback needs a full topic board.
- **Dark mode:** the warm palette is light-only (`preferredColorScheme(.light)`) and contrast-checked as such; a dark palette would need its own checks.
- **The nurse is scripted in the demo.** Judges may wonder whether the partner has to "type"; the free board answers this (the partner taps question cards), but only if the judge chooses Keep talking.
- **iPhone:** works in portrait. There the chat takes a fifth of the height instead of a third, the banner keeps to two lines (with a shorter step-3 text), and a short answer area keeps the question to one line, slims the Yes/No strip, and drops the mini board's help line, shrinking its tabs and back cells, with every row at least 64 pt. By the layout's arithmetic (not measured on a device) the answer cells stay at about 56 pt or more on a 6.1-inch iPhone; on the 4.7-inch iPhone SE the body-map cells come to about 50 pt, still above 44. iPad is the real canvas.
- **Transcript scrolling in scanning mode:** the transcript is a clean-tap switch so it can be scrolled back by hand, but a tap that slides on it scrolls instead of pressing. The answers beside it keep the touch-down switch.
- **No Ukrainian voice on the judge's device.** Step 4 then shows the whole conversation in Ukrainian but speaks it in English; a notice, written in the screen's own language, explains how to add the voice, and the status line says the answers are *shown* in Ukrainian rather than claiming Ukrainian speech. Check which Ukrainian voices ship by default on iPad and Mac. If none do, consider a self-recorded clip of the five answers as a fallback (logged in the credits).
- **The head-turn panel rests after three loops** (Core's default, about 9 s): a judge who reads it all before pressing may need one press to wake it, then one for Skip.
- **Not verified on device:** no compiler was available while writing; timing estimates come from the code's delays, not from a stopwatch.

## How it would grow into the real app

1. **Carer question deck:** editable question cards with their answer sets, a "recent questions" row, and therapist-made packs (ward, rehab gym, family visit, doctor's round).
2. **Learning predictions:** answers the person uses most for a question move up the scan (on device only); the scale and body map stay fixed.
3. **Initiation:** a single "I want to say something" alert that calls a partner, then offers the topic board.
4. **Fuller fallback:** the mini board becomes the full aphasia topic board from the other prototypes, still one press away.
5. **Watch companion:** the partner's question appears on the person's wrist with Yes · No · Not sure · Something else.
6. **Shareable transcript:** an optional, local-only conversation log a family member can read, to see what was said while they were away.

## Files

- `HolosBedside.swiftpm/App/HolosBedsideApp.swift` — `@main`; creates the services and the story, starts the switches.
- `HolosBedside.swiftpm/App/RootView.swift` — shows the current step; applies switch keys, the press flash and the light palette once.
- `HolosBedside.swiftpm/App/Experience.swift` — the story coordinator: steps, nurse timing, Show me, replay, free mode.
- `HolosBedside.swiftpm/App/Experience+Board.swift` — what the board shows: current turn, guide marker and its row, banner detail, scan tree.
- `HolosBedside.swiftpm/App/Chrome.swift` — Settings button, top bar, step header, chat/board split layout (with a smaller chat share for phones), scroll-friendly tap-to-press.
- `HolosBedside.swiftpm/App/BedsideTheme.swift` — the warm palette (with Increase Contrast variants) and SF Rounded helper.
- `HolosBedside.swiftpm/Conversation/Conversation.swift` — transcript lines, the current question, the "Something else" state.
- `HolosBedside.swiftpm/Conversation/NurseScript.swift` — the five scripted exchanges and their kind replies.
- `HolosBedside.swiftpm/Vocabulary/Question.swift` — partner questions, mini-board topics, body regions, scan ids.
- `HolosBedside.swiftpm/Vocabulary/Vocabulary.swift` — every phrase, bilingual, with feminine Ukrainian forms.
- `HolosBedside.swiftpm/Copy.swift` — every other on-screen string, bilingual.
- `HolosBedside.swiftpm/Board/ChatView.swift` — the scrolling transcript.
- `HolosBedside.swiftpm/Board/ChatBubble.swift` — nurse/partner/person/note bubbles (a pain answer shows the face it was chosen by, never a number), avatar, typing dots.
- `HolosBedside.swiftpm/Board/AnswerArea.swift` — question header, answer grid, Yes/No strip.
- `HolosBedside.swiftpm/Board/AnswerCell.swift` — big answer cell, guide tag, drawn pain faces.
- `HolosBedside.swiftpm/Board/BodyMap.swift` — the drawn body figure for "Where does it hurt?".
- `HolosBedside.swiftpm/Board/MiniBoardView.swift` — the "Something else" topic board (row-column).
- `HolosBedside.swiftpm/Board/GoalBanner.swift` — guided goal banner with Show me; the carer's Ask… question cards.
- `HolosBedside.swiftpm/Steps/ProblemStep.swift` — step 1.
- `HolosBedside.swiftpm/Steps/ConversationScreen.swift` — steps 2–3 and the free board; owns the scanner.
- `HolosBedside.swiftpm/Steps/ReplayStep.swift` — step 4, with its own no-Ukrainian-voice notice (shown in the screen's language).
- `HolosBedside.swiftpm/Steps/ClosingStep.swift` — closing card with Keep talking / Start again.
