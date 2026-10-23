# Holos Grid — the board, as specified

## The idea in one line

The description built faithfully: a calm, clinical topic grid with row–column scanning, a pinned row of urgent quick phrases, a message bar and six adult topic boards — the proven AAC pattern, done carefully, and the baseline the other four prototypes are measured against.

## Who it serves best

- **Mykola (stroke, right side paralysed, reads simple words).** Big picture-and-word cells, one press for a row and one for a cell, a haptic tick and a click on every step. The layout never moves: only the words in rows 4–5 change with the topic.
- **Yuriy (reads, cannot find words).** Topic boards *offer* the word. "Wife" is one recognisable cell that says the whole sentence "Please call my wife." — including the Ukrainian dative ("моїй дружині") that aphasia often takes away.
- **Speech therapists and carers.** It looks like the paper boards and commercial grids they already know: Fitzgerald colours, fixed rows, a predictable scan. Nothing to learn, easy to trust.
- **Oleksandr (head only)** is served through Core's head switch, which works on every screen. The grid adds nothing special for him.

Serves worst: someone who needs speed. Row–column scanning is predictable but slow — five rows mean up to about 7 s to come back round to a row you just missed. A person who can read and spell well is better served by a keyboard app such as «Я кажу», and a judge looking for a novel interaction will find this the least surprising of the five, by design.

## What to try first (60-second tour for Anna)

1. Launch, press Space three times on the nurse screen: each press knocks dully; the first gets only "…", then she asks again. Then press to begin.
2. On the intro card, press once. Watch the yellow ring step down the rows and the navy **Next** tag sit on "I'm in pain" in the Pain & body rows. Press when row 4 is lit, then when the cell is lit.
3. Follow the tag: Topics → Medicine → (the scan now *starts* on the Medicine rows) → Medicine → message row → Speak. The card tells you how many presses it took.
4. Step 3: Topics → Family → Wife → Speak. Press past the success card; on the head-turn panel that follows, press once to skip (Skip is lit first).
5. Step 4 switches the board to Ukrainian and says the same message. Press, read the closing screen, press once to start choosing, then press again on **Keep talking** for the free board. Try the УКР cell at the end of the topics row, and turn on Settings › Touch to see the same board tapped directly.

## The 3-minute judged flow

Default scan speed 1.4 s per step; the first item of each new level stays lit 2.1 s. Press times assume the judge presses about 0.7 s after the target lights. Reading times assume an attentive first-time reader: roughly three to four words a second, plus a moment to find their place.

| Step | What happens | Presses | Est. seconds | Running total |
| --- | --- | --- | --- | --- |
| 1 · Feel the problem | Nurse asks "How are you feeling?" (read ~11 s). Three presses go nowhere: a dull knock each time; the first gets only "…", then she asks again. "Holos turns that one press into a voice." Press to begin. | 4 | 18 | 0:18 |
| 2 · One switch, any message | Intro card (read ~13 s, 1 press). Then: row 4 → I'm in pain (5.6, 6.3 s) · topics row → Medicine tab (10.5, 14.7 s) · scan restarts on the Medicine rows: row 4 → Medicine (15.4, 16.1 s) · message row → Speak (16.8, 17.5 s). Success card shows the sentence and the press count (~5 s, 1 press). | 1 + 8 + 1 | 36 | 0:54 |
| 3 · The aphasia board | Intro card with Yuriy's story (read ~19 s, 1 press). Topics row (4.2 s) → Family (9.8 s) → row 4 (10.5 s) → Wife (11.2 s) → message row (11.9 s) → Speak (12.6 s). Success card on its own (~6 s, 1 press). Then Core's head-turn panel on its own, Skip lit first (~8 s, 1 press). | 1 + 6 + 1 + 1 | 46 | 1:40 |
| 4 · Hear it in Ukrainian | Board turns Ukrainian, says «Мені боляче. Ліки, будь ласка.» Read the card and press. With no Ukrainian voice the Speaker says it in English and the card adds a notice on how to install one: about +10 s of reading. | 1 | 9 (19) | 1:49 (1:59) |
| Closing | Who it is for; free, private, open source (read ~20 s). A first press starts the two-choice scan with "Keep talking" lit first; a second press picks it. | 2 | 22 | **2:11 (2:21)** |

About 2:11 with no mistakes (2:21 on a device without a Ukrainian voice), so roughly 40–50 s of slack. What a slip costs: about 7 s for a missed row (one loop of five rows), about 8.4 s for a missed cell (five cells and a back cell), and about 11 s for a missed topic tab (six tabs, the language cell and a back cell). Actually trying the head turn (+15–25 s including the camera prompt) uses most of the remaining slack, so a judge who tries it, misses a row and has no Ukrainian voice is close to 3:00.

Notes on the table:

- **Step 1's reveal.** Holos is named 1.6 s after the third press; if the judge presses once or twice and stops, 12 s after the first press; if nobody presses at all, 20 s after the screen opens — whichever comes first. Counting from the first press (rather than from the screen opening) means someone who reads before pressing still feels at least one press go nowhere.
- **The quick row's "I'm in pain".** It is scanned two rows before the Pain & body cells. Choosing it in step 2 speaks it at once and counts as the goal's first word (it joins the message, and the Next tag moves to Medicine): the same 8 presses, about 2 s slower.

**Why "Medicine" lives on the Medicine board (two topics) rather than on Pain & body.** Measured, the two-topic path costs 8 presses and 17.5 s; putting a Medicine cell on Pain & body would cost 6 presses and 16.1 s. That is 1.4 s for a real gain: the judge rehearses the topic switch that step 3 depends on (so step 3 needs no explanation of tabs), Pain & body keeps exactly the ten body words the description lists, and medicine stays where a clinician would look for it. Rotating the scan to start on the chosen topic's rows is what keeps the two-topic path this close.

**Why step 3 uses one cell ("Wife" says "Please call my wife.") rather than "Call" + "Wife".** It is two presses and about 3 s faster, and it is the point of the step: one recognised word, one whole sentence. It also avoids a grammar trap — "Call" followed by a standalone "Wife" would need the dative in Ukrainian ("Подзвоніть … моїй дружині"), which a cell that also stands alone cannot say.

## How one switch drives every screen

- Every input (tap, Space/Enter, controller button, head turn) becomes `SwitchHub.press`, routed to one place: `Experience.press(_:)`. What a press means depends on the step: on narrative screens it continues (after a 0.9–2 s read gate, so a double press never skips a screen unread); on the board it goes to the board's `Scanner`; on the closing screen the first press after its read gate starts a small two-choice scan and the next one picks; during the head-turn panel, Core's panel borrows the switch and `headTryFinished()` takes it back. Step 3's success card is a screen of its own with its own read gate, and the head-turn panel appears only after a press on it, so a quick second press can never skip both.
- On narrative screens a tap anywhere is the press, landing when the finger lifts, so the card's text can still be scrolled on a phone. On the board, the head-turn panel and the closing choices the press lands on touch-down, as Core does it, which suits a hand with tremor.
- The board scans row–column: message row → quick phrases → topics (+ language cell) → topic row 1 → topic row 2. Every row ends in a back cell (the message bar draws its own). Rows not in play dim to 45% (60% under Increase Contrast). After choosing a topic, the scan starts on that topic's first row; after any other choice it returns to the message row, so Speak is always two presses away.
- Whichever scanner goes live is bound to the services last (the board each time it starts, the closing choices, Core's head panel), because Core's Speaker has one "message finished" hook. That keeps auditory prompts re-announcing the lit item after a message on every screen.
- Language is in the scan (the УКР/EN cell at the end of the topics row), so a switch-only user never needs help to change it. Settings and the top-bar language toggle sit outside every tap area for carers. Step 4 borrows the saved language and gives it back; a small marker puts it back at the next launch if the playground was stopped during step 4, so English stays the default.
- Nothing can get stuck: the goal card always shows the goal and a "Next:" line that names the board ("Next: "I'm in pain" on the Pain & body board"), a navy **Next** tag marks the next target (topic tab, cell or Speak), any spoken message completes a guided step (the goal or not), and after 45 s without progress a lit **Show me** item appears at the top of the scan that builds and speaks the message for you. A paused scan says "press to start it again".
- Touch mode (Settings, or automatically under VoiceOver / Switch Control): the scan stops, tap areas switch off, every cell, tab and button is tapped directly, and the same guidance applies.

## What makes it different

It is deliberately *not* different: it is the layout therapists already use on paper, made switch-accessible and bilingual. What it adds over a generic grid:

- Cells say whole polite sentences in both languages, with Ukrainian gendered forms (втомився/втомилася) and case endings handled inside the cell.
- The scan restarts on the chosen topic's rows, saving two to three steps every time a topic is opened.
- The pinned urgent row speaks immediately, without building a message.
- The step-2 success card counts the presses: "8 presses. One movement, a whole sentence." — the argument for switch access, in one number. It only says so when the person built the goal; after **Show me** it says Holos built the message this time, and a different message gets a plain "You said it."

## Strengths

- Instantly legible to clinicians, carers and judges; nothing to explain beyond "rows, then cells".
- The most predictable of the five: the grid never moves, which matters for people with aphasia and visual-attention problems.
- Complete adult vocabulary: 60 topic cells plus 5 quick phrases, all in natural English and Ukrainian.
- Every screen works with one switch, with touch, and with VoiceOver; fits an 11-inch iPad in landscape without scrolling.

## Risks and open questions

- **Slow.** Row–column on five rows averages several seconds per choice. Fine for the 3-minute flow, but real users may want frequency-ordered rows or a faster scan; the other prototypes test alternatives.
- **Least novel.** Judges score creativity; this prototype's argument is reliability and care, not surprise.
- **Placeholder symbols.** SF Symbols stand in for ARASAAC pictograms; a few (stomach, back, itchy) are only approximate. "Thank you" uses a heart, the same glyph as Chest (the two boards are never on screen together). "A little" / "A lot" use 3 and 8 as a pain-scale nod; check with a therapist.
- **Duplicate labels.** The quick row's "I'm in pain" is the same words as step 2's first goal cell, and it is scanned first. Unhandled, choosing it ended step 2 with half the goal (no topic opened, no Speak, and step 4 replaying only «Мені боляче.»). The hint now names the board, and the quick cell counts as the first word instead. Any future goal that repeats a quick phrase needs the same care.
- **iPhone is cramped.** Core's message bar needs about 320 pt for its controls, 404 pt with its row entered and 504 pt with Clear open — wider than a phone held upright. So on a phone the board draws its own compact strip of the same controls (Core's ids and actions, the same two-press Clear, shared widths of at least 60 × 60 pt) under a large sentence strip, and scrolls, following the scan automatically. Usable, not lovely.
- **Large text.** The grid caps Dynamic Type at xxxLarge, because its fixed-size cells would only shrink their text beyond it, and offers the Large Content Viewer on topic tabs, the language cell, the topic header and the message controls. The board measures its real height and follows the scan whenever it overflows.
- **Tap, not touch-down, on narrative screens.** It keeps long cards scrollable, but a hand that slides may need a second try there; worth checking with a tremor user. The board itself keeps Core's touch-down press.
- **Clinical review needed.** The vocabulary and the "family cell = please call" convention should be checked with a speech therapist (Talk! / Говори!).
- Unverified without a device: haptic feel, camera behaviour in Swift Playgrounds, default Ukrainian voices.

## How it would grow into the real app

- Editable boards (carer adds a cell, uses a photo of the actual wife), frequency-based ordering and a "recent messages" row.
- ARASAAC pictograms with an About screen crediting them.
- Vocabulary moved to an open board format (OBF) file so other AAC apps can reuse the Ukrainian adult set.
- A Watch companion showing only the quick-phrases row.

## Files

- `HolosGrid.swiftpm/App/HolosGridApp.swift` — @main; builds the services and the tour coordinator.
- `HolosGrid.swiftpm/App/RootView.swift` — top bar + current step, light scheme, Settings sheet, switch keys and press flash.
- `HolosGrid.swiftpm/App/FlowStep.swift` — the tour's steps and a guided step's phases.
- `HolosGrid.swiftpm/App/Experience.swift` — the step coordinator: what a press means now, step and phase changes, read gates, stuck timer, Show me, the quick-phrase first word, what the success card may claim.
- `HolosGrid.swiftpm/App/Experience+Language.swift` — the marker that gives step 4's borrowed language back, even after the app was stopped mid-step.
- `HolosGrid.swiftpm/App/TopBar.swift` — name, step line, language toggle, Settings, and Start-again on the free board.
- `HolosGrid.swiftpm/App/GridTheme.swift` — colours and fonts, card style, narrative tap area, Continue button, overlay card.
- `HolosGrid.swiftpm/Copy.swift` — every prototype string in English and Ukrainian.
- `HolosGrid.swiftpm/Vocabulary/Vocabulary.swift` — the six topics, 60 cells, 5 quick phrases and the two step goals.
- `HolosGrid.swiftpm/Vocabulary/Guide.swift` — a guided goal, its next missing stop, and how it picks the next target.
- `HolosGrid.swiftpm/Board/GridBoard.swift` — the board model: scan tree, scanned and touched choices, speech detection.
- `HolosGrid.swiftpm/Board/GridBoardView.swift` — layout metrics, the measured overflow check and the scrolling-when-needed board.
- `HolosGrid.swiftpm/Board/BoardRows.swift` — message row, quick phrases row, topics row, topic header, topic rows.
- `HolosGrid.swiftpm/Board/CompactMessageBar.swift` — the message row's controls on a phone, drawn from Core's ids and actions.
- `HolosGrid.swiftpm/Board/BoardPieces.swift` — topic tab, language cell, Next tag, row frame, small helpers.
- `HolosGrid.swiftpm/Steps/ProblemStep.swift` — step 1: the nurse and the one big switch.
- `HolosGrid.swiftpm/Steps/BoardStep.swift` — steps 2–4 and the free board: goal card, board, overlays, the head-turn panel.
- `HolosGrid.swiftpm/Steps/GoalCard.swift` — goal, next target, press count, Show me.
- `HolosGrid.swiftpm/Steps/StepCards.swift` — intro, success and Ukrainian cards.
- `HolosGrid.swiftpm/Steps/ClosingStep.swift` — who it is for, the three pillars, "Press to choose", Keep talking / Start again.
