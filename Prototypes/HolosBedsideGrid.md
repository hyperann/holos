# Holos Bedside + Grid — "Ask first, the whole board behind it"

## The idea in one line

When someone asks, the board offers only the few answers that fit *that* question, as in Holos Bedside; when the answer isn't there, or nobody is asking, Holos Grid's whole board — every topic, the urgent quick phrases and a message to build — is one press away.

## Why combine them

Bedside has the lightest load and the strongest judged story, but it is reactive: with nobody asking there is little to say, and its "Something else" board holds 3 topics × 8 words. Grid has the full vocabulary and lets a person start a conversation, but every answer costs a row and a cell, and nothing in it knows what was just asked. Each one's weakness is the other's strength, and both already run on the same core, so this prototype keeps Bedside's story and conversation screen and replaces Bedside's small board with Grid's whole one, unchanged except for Bedside's palette and guide tag.

## Who it serves best

- **Yuriy (aphasia, can read but cannot find words)** — the strongest fit of all six. A question arrives with its likely answers; when the prediction misses, Family offers "Wife" as a word to *recognise*, and the cell says the whole sentence ("Please call my wife.") with the Ukrainian dative already right.
- **Mykola (stroke, right side paralysed, reads simple words)** — very good. Answers are still one press each, at most 11 stops (12 with Show me); only the whole board scans row, then cell.
- **Oleksandr (head movement only)** — good. Every screen is one-switch, and a head turn is just another press.
- **Someone who wants to start the conversation** — now served. After the story the whole board is home: quick phrases speak at once, and a message can be built with nobody asking first.
- **Carers and nurses** — the question cards from Bedside: they ask, as they would anyway, and the board changes to the answers that fit.
- **Serves worst:** anyone who needs speed for long, specific sentences (the whole board's row-column scan is Grid's, and as slow), and people who can type fluently.

## What to try first (60-second tour for Anna)

No build needed for a first look: open [design/HolosBedsideGrid/sketch.html](../design/HolosBedsideGrid/sketch.html) in a browser (Space or a tap is the switch). It is a browser sketch of the same flow, written alongside the Swift rather than generated from it.

1. Watch step 1 for 20 seconds and press a few times while the nurse waits: the dull knock, "There is nothing to choose."
2. Press "Press to answer". Step 2 is Bedside's: follow the terracotta "This one" tag through In pain, Head, A lot and Water.
3. In step 3 press **Something else**. The whole board replaces the chat and answers, and the line above it keeps the nurse's question. Follow the tag: it sits on the **topics row** until the scan is inside it, then on **Family**; then on Family's first row, then **Wife**; then the **message row**, then **Speak**.
4. On a second run, press Something else in step 2 by mistake: the tag moves to **Back to the answers**, the board's last scan stop, drawn beside the question.
5. After the replay, choose **Keep talking**. Nobody is asking, so the whole board is home: say something from it. Then, as the carer, tap a question card along the top; answer it, and the board comes back by itself.

## The 3-minute judged flow

Default scan speed 1.4 s per step, first item of each new scan lit 2.1 s; every new set of answers, and the whole board each time it opens, waits 0.8 s before its scan starts. Times include typing dots, the nurse's replies, waiting for the spoken answer to finish, and a reading allowance, counted the way Holos Bedside's doc counts them.

| Step | What happens | Presses | Est. seconds | Running total |
|---|---|---|---|---|
| 1. Feel the problem | As Bedside: the nurse asks, waits, and leaves; presses only knock. The card now also says the whole board is one press away (36 words, about 11 s to read) | 1 (plus any knocks) | 31 | 0:31 |
| 2. One switch, a whole conversation | As Bedside: **In pain** (1st) → body map, **Head** (1st) → face scale, **A lot** (3rd) → **Water** (1st) | 4 | 38 | 1:09 |
| 3. When the word won't come | "Is there anything you want to tell me?" → **Something else** (1st) → the whole board: message row, quick phrases, then the **topics row** (3rd), press → **Family** (4th tab), press → the scan starts again on Family's rows: **row 1** (1st), press → **Wife** (1st), press → the scan returns to the top: **message row** (1st), press → **Speak** (1st), press: "Please call my wife." → "Of course. I'll call your wife right away." → optional head-turn panel, **Skip** lit first (about 7 s with reading) | 7 | 33 | 1:42 |
| 4. Hear it in Ukrainian + closing | As Bedside: the transcript redraws in Ukrainian and your five answers are spoken again (about 11 s), the board's message among them. The closing card's "how" paragraph is longer (about 146 words in all, about 40 s) → **Keep talking** / **Start again** | 2 | 53 | 2:35 |

About 2:35 if each target is caught on its first pass. A judge who reads step 3's goal before pressing will likely press **Something else** on its second pass, which makes about 2:48.

A missed pass costs one loop of the current scan. Among the answers it is Bedside's: 12.6 s to 16.8 s. On the whole board it is 7.7 s at the top level (five rows; 9.1 s with Back to the answers, 10.5 s once Show me joins), 11.9 s inside the topics row (six tabs, language, go back) and 9.1 s inside a row of five cells. From 2:35 that leaves room for about two misses on the board, or one among the answers, inside 3:00.

## Screens

No design mockups yet; the [design gallery](../design/README.md) covers the first five. The [browser sketch](../design/HolosBedsideGrid/sketch.html) shows every screen of the flow, on an iPad or an iPhone canvas.

## How one switch drives every screen

- **Step 1, step 4 and the closing** are Bedside's, unchanged: see [HolosBedside.md](HolosBedside.md#how-one-switch-drives-every-screen).
- **Two scans, one switch.** The answers have their own `Scanner` (owned by `ConversationScreen`, fed by `Experience.scanTree`); the whole board keeps Grid's, inside `GridBoard`. `ConversationScreen` routes every press to whichever is on screen. Only one of them runs at a time: the answers' tree is empty while the whole board shows, and the board's scan stops the moment it closes (`Experience.wholeBoardIsLive`). Each starts 0.8 s after its screen appears.
- **One Speaker hook.** Core's `Speaker` has a single "message finished" hook, owned by the scanner bound last, so the board binds again whenever its scan starts and the answers bind again whenever they come back. Otherwise an item lit while a sentence was being spoken would not be announced once it ended.
- **The whole board** is Grid's: the message row (Speak, Delete last, a two-press Clear), quick phrases that speak at once, the topic tabs with a language cell, the open topic's two rows of five, and every row ending in "go back". After a topic is chosen the scan starts on that topic's rows. While a question waits, **Back to the answers** is its last stop, drawn in the line above the board beside the question.
- **Never stuck.** In the guided story the tag leads from "Something else" across the board one press at a time: the topic, the word, then Speak. While scanning, the tag sits on the *row* that holds the next stop, with a terracotta outline, until the scan is inside it; the banner's second line names the row first ("Open the Family board: the topics row, then Family."). If the board was opened for a turn whose answer is with the answers, the tag sits on Back to the answers. After 45 s without progress (opening the board, choosing a topic, adding a word or going back all count), **Show me** is the first stop of either scan and a button in the banner; for a word on the board it says that word as its own message.
- **What counts as an answer.** An answer cell, a quick phrase or a spoken message. The nurse hears what was said whichever board it came from: a board cell that says the same sentence as one of the answers ("My chest hurts.") counts as that answer, and a message that holds the turn's word counts as the word, whatever else is in it, just as the guide counts it. The board's message is emptied once it has been said, because it is now a line of the conversation.
- **Core's Speak button.** Core's `MessageBar` speaks by itself when its Speak is tapped, without telling the board, so `WholeBoardScreen` watches the Speaker and `GridBoard.speechStarted` recognises its own message being spoken (in every language and gendered form it could be spoken in). The board's own speech is skipped, so nothing is recorded twice.
- **Free conversation.** The whole board is home whenever nobody is asking. A question card shows that question's answers; once it is answered, by any route, the board is home again.
- **Touch mode** (Settings, or automatically under VoiceOver or Switch Control): both scans stop, and cells, tabs, the body map, Speak and Back to the answers are tapped directly. Opening the board tells a VoiceOver user where to go first.

## What makes it different

- **Prediction first, never a cage.** Most answers are still the first or second thing lit. The whole vocabulary is behind one press, not instead of the prediction.
- **The person can start.** The free board needs no question; quick phrases and topics are always there.
- **One guide across both boards.** The same terracotta tag moves from the answers into the grid and back, and it never says "wrong".
- **The conversation stays in view.** The line above the board keeps the question, or what the person said last, so nobody has to hold it in mind while building an answer.

## Strengths

- Keeps Bedside's fastest path and kindest failure mode, and its emotional arc, almost untouched.
- Removes Bedside's two main risks: the small fallback board and the reactive-only design.
- Step 3 now shows both halves of the idea in one turn: the prediction misses, and the whole board catches it.
- Everything a therapist expects from Grid (topics, quick phrases, Fitzgerald colours, row-column scanning, go-back cells) is there for free conversation.

## Risks and open questions

- **Step 3 is longer.** Seven presses instead of Bedside's five, about 33 s, and the whole board is a lot to take in on a first look. If timing tests run over, open the board on Family for that turn (two presses fewer), or let "Something else" there start the scan on the topics row.
- **The whole board under the banner.** By the layout's arithmetic (not measured on a device), on an 11-inch iPad in landscape the board just fits under the goal banner and the question line, with topic rows of about 108 pt; once Show me joins the banner it scrolls by about 35 pt and follows the scan, as Grid's board does on a phone. On an iPhone it always scrolls.
- **The chat is hidden while the board is open.** Only the question stays in view. A wide iPad could show the chat beside the board, at the cost of smaller cells.
- **A watcher where an API would be cleaner.** Core's `MessageBar` has no callback for its own Speak button, so a tapped Speak is noticed when the Speaker's text changes. One case slips through: a message whose sentence is the very one still being spoken (rebuilt and spoken again at once, or said a moment earlier from an answer cell) is said but not added to the conversation, and stays in the bar; Speak works again once the voice has stopped. A one-line `onSpeak` in the core would remove the watcher, and the gap, for every prototype that needs it.
- **Two vocabularies.** The answer sets and the whole board both have Water, Wife and others under different ids. The nurse treats the same sentence as the same answer, but a real app would draw both from one vocabulary.
- **Opening the whole board by mistake** in step 2 puts six topics, five quick phrases and a message row between the person and a one-press answer; the tag points straight back, and Back to the answers is the board's last stop.
- **Everything in Bedside's list still applies:** prediction quality, the light-only palette, the scripted nurse, transcript scrolling in scanning mode, the head-turn panel resting after three loops, and no Ukrainian voice on a judge's device.
- **Not verified on device:** no compiler was available while writing; timing estimates come from the code's delays, not from a stopwatch.

## How it would grow into the real app

1. **Carer question deck** (Bedside's): editable question cards with their answer sets, made by therapists for the ward, the rehab gym, a family visit.
2. **Learning predictions:** when a person reaches the same board word for the same question again and again, it joins that question's answers.
3. **One vocabulary:** answers and board cells drawn from one bundled, editable file, so a carer's new phrase appears in both.
4. **A carer's photo cells** on the Family board, the way Room puts the person's own family in the scene.
5. **Initiation from anywhere:** a held press or a single "I want to say something" cell that brings the whole board up mid-conversation.
6. **Watch companion:** the partner's question on the person's wrist with Yes · No · Not sure · Something else, the whole board on the iPad.

## Files

Bedside's files, with these changes:

- `HolosBedsideGrid.swiftpm/App/HolosBedsideGridApp.swift` — `@main`; creates the services (saved under their own key prefix) and the story.
- `HolosBedsideGrid.swiftpm/App/Experience.swift` — the story coordinator, now also owning the whole board: opening and closing it, what it says, Show me on both boards, free mode with the board as home.
- `HolosBedsideGrid.swiftpm/App/Experience+Board.swift` — the current turn, the answers' guide, the whole board's goal and tag, the banner's guide line, the answers' scan tree.
- `HolosBedsideGrid.swiftpm/Conversation/Conversation.swift` — adds whether a question is waiting and whether the whole board is open, and board messages as one line.
- `HolosBedsideGrid.swiftpm/Vocabulary/BoardVocabulary.swift` — Grid's six topics and quick phrases (Grid's vocabulary, with plain English apostrophes), including the "Wife" cell step 3 is about.
- `HolosBedsideGrid.swiftpm/Vocabulary/Guide.swift` — Grid's guide: the next goal cell the message lacks, and where its tag goes.
- `HolosBedsideGrid.swiftpm/Board/GridBoard.swift` — Grid's board model and scan, with Back to the answers, Show me and progress reporting.
- `HolosBedsideGrid.swiftpm/Board/GridBoardView.swift`, `BoardRows.swift`, `BoardPieces.swift`, `CompactMessageBar.swift` — Grid's board views in Bedside's palette, with the row-then-cell guide tag.
- `HolosBedsideGrid.swiftpm/Board/WholeBoardScreen.swift` — the board under its question line, with Back to the answers and the speech watcher.
- `HolosBedsideGrid.swiftpm/Steps/ConversationScreen.swift` — routes the switch to the board on screen and runs both scans.
- `HolosBedsideGrid.swiftpm/Board/GoalBanner.swift`, `AnswerArea.swift`, `Copy.swift` — the banner's board line, no mini board, the new copy.
- Removed: Bedside's `MiniBoardView.swift` and its mini-board vocabulary.
