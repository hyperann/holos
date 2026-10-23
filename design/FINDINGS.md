# What the mockups turned up

Redrawing each screen meant working out, from the SwiftUI code, how big every view would really
be. These are the places where that arithmetic says the app will look wrong. **None of them is
confirmed on a device**, because nothing has been compiled yet, so treat each one as the first
thing to check in the simulator rather than as a known bug. Nothing here has been fixed: the
mockups show the code as it stands.

Paths are relative to the prototype's `.swiftpm` folder; `Core/…` is the shared engine
(`Shared/HolosCore/…`, copied into every prototype). "Screen 3" means `design/<Prototype>/03-….png`.
Sizes are for an 11-inch iPad in landscape (1194 × 834 pt) unless an iPhone (393 × 852 pt) is
named.

## In the shared core (all five)

- **Lit labels touch the scan ring.** A cell pads its label by 10 pt (`Core/UI/SymbolCell.swift:38`),
  but the ring is drawn 11 pt deep inside the cell's edge (`Core/UI/ScanHighlight.swift:35`), so a
  lit label that fills the cell's width runs into it: "Call my wife" in Bedside, "I'm in pain" in
  Room's phrase ring.
- **Icons stay body-size beside large titles.** Where a `Label` sets its font on the title text
  only, the icon keeps the default body size next to a 20–34 pt title: Core's head-turn panel
  (`Core/UI/HeadTryPanel.swift:40–44`, `:101`), and the same pattern in Grid and Bedside below.
  Setting the font on the `Label` itself fixes every case.

## Holos Grid

- **The closing pillars never sit side by side, and the last one is cut off** (screen 7).
  `ViewThatFits` measures the row of pillars at its ideal width, about 1,150 pt with every detail
  line unwrapped, so the row never fits and they always stack (`Steps/ClosingStep.swift:29–31`).
  That makes about 656 pt of content in about 587 pt of scroll area, and "Open source" falls below
  the fold.
- **The board starts scrolling when "Show me" appears.** After 45 s without progress the goal card
  adds its Show me row, 74 pt taller (`Steps/GoalCard.swift:67–68`). The topic rows then come out at
  about 78 pt, under their 100 pt minimum, so the board scrolls (`Board/GridBoardView.swift:49–62`),
  though the doc says it fits without scrolling.
- **The grid moves at step 4.** The goal card is dropped for the Ukrainian step
  (`Steps/BoardStep.swift:47–58`), so the topic cells grow from about 115 to about 176 pt behind the
  card. The doc says the grid never moves.
- **Go back is too big for the topics row.** Its arrow and word need about 56 pt before padding
  (`Core/UI/SymbolCell.swift:63–76`), so they fill the 56 pt topics row edge to edge on iPad and
  overflow the 46 pt cells on iPhone (`Board/BoardRows.swift:188–191`).
- **The dim behind cards stops at the top bar** (`App/GridTheme.swift:127–129`). The top bar stays
  bright above the dimmed board during the intro, success, head-turn and Ukrainian cards. It may be
  intended, but it reads as a seam.
- **Card icons are small.** The success and Ukrainian cards' title icons are body-size
  (`Steps/StepCards.swift:83`, `:145–153`; see the core note).
- On an iPhone (screen 8):
  - **Cells are too narrow for their labels.** At about 52 pt wide they leave 31.8 pt for the label
    (`Core/UI/SymbolCell.swift:35–36`), so labels drop to 11–16 pt, break mid-word or truncate, and
    the symbols are about 16 pt. The quick phrases' speaker badge overlaps the symbol
    (`Board/BoardRows.swift:118–121`).
  - **The language cell overflows.** None of its three layouts fits an 82 × 46 pt cell, so the
    stacked chips, about 67 pt tall, spill over the tab above and below
    (`Board/BoardPieces.swift:81–94`).
  - **The step line truncates** to "Step 2 of 4 · One swit…" (`App/TopBar.swift:29–33`).

## Holos Bedside

- **The scan ring draws over the "This one" tag** and clips its corner on the lit answer
  (`Board/AnswerCell.swift:41–47`). The mini board layers them the other way round.
- **"Something else" doesn't fit the strip.** Its word column is 81 pt wide and "Something" alone
  is about 100 pt, so the label drops to about 16 pt, or the word breaks mid-way
  (`Board/AnswerCell.swift:86–92`). On iPhone it falls to about 12 pt.
- **The pain-scale faces don't line up** (screen 4). "The worst ever" needs two lines, so its face
  sits about 14 pt higher than the other three (`Board/AnswerCell.swift:78–81`).
- **The replay ring doesn't match the bubble** (screen 6). The ring has a uniform 22 pt radius but
  the bubble's bottom-trailing corner is 6 pt, so that corner sticks out of the ring
  (`Board/ChatBubble.swift:109`).
- **The newest chat line sits flush on the bottom edge.** Scrolling it to `.bottom` hides the 16 pt
  padding below it once the transcript overflows; its shadow is clipped, and a nurse avatar there
  pokes past the rounded corner, because the scroll view clips to a plain rectangle
  (`Board/ChatView.swift:72`, background at `:62`).
- **Button chevrons are small and on the wrong side.** The font is set on the title only, so each
  chevron renders at body size beside 22 pt words, and it sits before "Continue" and "Press to
  answer" rather than after them (`Steps/ReplayStep.swift:86–91`, `Steps/ProblemStep.swift:168–173`,
  `Steps/ClosingStep.swift:97–104`).
- On an iPhone (screen 8):
  - **The "This one" tag covers the picture.** About 100 pt wide on a 111 pt cell, it hides most of
    the water drop; only the strip ever uses the small tag (`Board/AnswerCell.swift:41–44`).
  - **Answer words come out at very different sizes**, from about 16 pt ("Help me move") to about
    33 pt ("Rest") on one board, with the pictures shrunk to 38–53 pt (`Board/AnswerCell.swift:78–81`,
    `:86–92`).
  - **The layout jumps between turns.** Whether the answer area counts as short (under 420 pt)
    flips from turn to turn with the banner's detail line, and the first turn misses the cut-off by
    2.4 pt. So the Yes/No strip switches between 96 and 72 pt, and the question between two lines
    and one (`Board/AnswerArea.swift:20`, `:24`, `:37`).

## Holos Room

- **The nurse's speech bubble covers her head** (screens 1–3). Its tail points beside her face
  (`Board/RoomCanvas.swift:112`), but the 300 pt box (`:137–138`) is pushed back inside the room
  (`:153`), so it slides 30–55 pt left and its lower edge lies across her hair and forehead (drawn at
  `Art/WardArt.swift:160–163`). On an iPhone it flips below her (`:154`) and covers the phone and
  her upper body.
- **The room uses only 61 % of the iPad's width in guided steps.** The 163 pt top bar leaves the
  10:7 room bound by its height (`Board/RoomCanvas.swift:45`, `:52`), with about 224 pt of empty
  backdrop on each side. This is also why the phrase labels are small.
- **Phrase labels are much smaller than the room's own 15 pt pills.** At room scale 0.70 the cells
  hit their 108 × 91 pt minimum (`Board/PhraseRing.swift:65`), which leaves the label 32 pt of
  height: "Help me sit up" and "I want to lie down" render at about 13.5 pt.
- **The "opens more" badge hides the ends of the people labels** (screen 4). "My wife" and "My mum"
  lose their last letter, "My children" its last two (`Board/PhraseRing.swift:183`, `:211–213`).
- **Step 4 hides the room it relabels.** Without a Ukrainian voice, the card's notice
  (`Steps/UkrainianCard.swift:45`) makes it 530 pt tall, covering every pill but half of
  «Медсестра», so the relabelling the card promises (`:5–7`) cannot be seen. For 4 s after the
  press the spoken «Мені боляче…» bubble (`App/Experience.swift:416`, anchored at the patient,
  `Room/RoomPlace.swift:50`) also sits mostly behind the card, or wholly with the notice.
- **The closing screen's top bar still says part 4**, "Hear it in Ukrainian"
  (`App/Experience+Stage.swift:111`), above a card titled "Holos: a voice, one press at a time".
- **Possibly intended:** in step 1a the nurse wears the full yellow scan ring
  (`Board/HotspotLayer.swift:24`, `:55`; `App/Experience+Room.swift:50`). That is the same signal as
  a scan stop, though a press only continues the card.

## Holos Compass

- **The hold ring sits under the scan ring** (screen 4). A petal being pointed at is always lit,
  and the 11 pt ring drawn on top hides much of the 56 pt hold badge, including where its fill
  starts at 12 o'clock (`Board/PetalView.swift:87`, `:124`, `:135`).
- **Labels break and shrink on iPad.** "I need…" breaks as "I / need…" (`Board/PetalView.swift:36–42`),
  "Unbearable" shrinks to about 32 pt, and the "Back to start" chip to about 16 pt
  (`Board/HubChip.swift:56`).
- **The step 3 panel moves while it is read.** With pointing on, every scan step re-centres the lit
  button, shifting the panel 11–22 pt and cutting off the card's rounded top
  (`Steps/HeadPointStep.swift:87–89`).
- **The closing buttons sit below the text, not beside it as the doc says**, at the default text
  size (`Steps/ClosingStep.swift:35–37`).
- **The top bar's dial loses its needle.** The fixed 10 pt centre dot covers most of it on the 34 pt
  dial (`Board/NeedleDial.swift:39`).
- **From reading only, not drawn:** a guided chip's "Next" tag is lifted 16 pt into a 14 pt gap
  (8 pt on a phone), so it would overlap the hub, or the south petal on a phone
  (`Board/HubChip.swift:72`).
- On an iPhone (screen 7), where the top and bottom petals are 146 × 90 pt and the side ones
  95 × 178:
  - **The 40 pt direction badge covers "Yes"** and the tops of the heart and thumbs-down symbols
    (`Board/PetalView.swift:61–70`).
  - **The "Next" tag hides most of the hand** on the south petal (`Board/PetalView.swift:71–76`).
  - **"I need…" shrinks to about 14 pt.** A 146 × 90 petal still counts as wide, so its symbol sits
    beside the label and leaves it about 42 pt (`Board/PetalView.swift:36`, `:110–111`). The hub
    message shrinks to about 18 pt.

## Holos Words

- **Step 4 overflows the 11-inch iPad** (screen 6). The page needs about 708 pt and has 634, so it
  scrolls, and the wife sentence starts below the fold with no cue to scroll
  (`Steps/UkrainianStep.swift:49–64`, `UI/NarrativePage.swift:24–33`). A judge using only the Space
  bar cannot scroll at all. Without a Ukrainian voice the notice adds about 126 pt: card 2's
  sentence is clipped and card 3 is hidden.
- **The blank fades while it is being filled.** Rows the scan is not in fade to 45 %, and that
  includes the sentence bar while its blank's word is being chosen (`UI/ScanRowStyle.swift:15`,
  `:27`). The Find strip is not a scanned row, so it never fades and competes with the row in play
  (`Board/FillerGrid.swift:69–123`).
- **Two "Go back" controls in Find a word.** The sentence row's Go back pill is drawn whenever
  scanning is on (`Board/SentenceBar.swift:157–162`), but while Find a word is open the scan covers
  only the panel (`Board/WordsBoard.swift:297–301`), so that pill can never be reached.
- **"I need…" looks already chosen on a fresh board.** The board starts with `shownFrame = .need`
  (`Board/WordsBoard.swift:134`), so "I need…" wears the open-starter outline while the goal and the
  Next tag point to "I feel…".
- **The Find panel leaves empty slots.** Six slots per row on iPad (`Board/BoardScreen.swift:74`)
  leave one or two empty on most screens and make the answers tall, narrow columns.
- **Minor, from SwiftUI's baseline rules:** in step 1 the blank's underline sits about 14 pt below
  "Call my", because the ghost word gives the blank its baseline (`UI/BlankSlot.swift:19–27`,
  `Steps/ProblemStep.swift:50`).
- On an iPhone (screen 8):
  - **Word cells are about 65 pt wide** (the Back cell takes 58 pt: `Board/FillerGrid.swift:55`), so
    "Medicine", the word the step-2 goal asks for, truncates even at Core's 0.55 scale floor.
  - **The language cell reads "Укра…"** (`Board/StarterRow.swift:87–98`).
  - **The sentence bar's Back pill reads "Go …"** at 9 pt (`Board/SentenceBar.swift:161`).
