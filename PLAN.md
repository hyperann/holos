# PLAN.md — Holos: from six prototypes to a real voice

Written 2026-10-27. The prototypes, their docs and the browser sketch are the spec; this file
is the order of work, the dates and the decisions. Update it when a gate fires or a date slips,
and tick a box from evidence (a build that runs, a test that passed, a reply in your inbox),
never from having started the task.

## Gate 0 — one decision before anything else (by Sunday 1 November)

Three facts decide what this plan is:

1. **You can enter one app playground.** The Swift Student Challenge terms: "You may only
   submit one app playground to the Challenge." Your other project,
   [Vidkryto](https://github.com/hyperann/swift/blob/main/PLAN.md), is already planned as your
   2027 entry: about two focused evenings a week, submission-ready on 24 January 2027, and its
   own eligibility verdict (its Gate 0) is still blank as of its last commit. Both projects
   share that verdict and those evenings.
2. **A Holos entry has to be rebuilt by you.** The terms require the app playground to be
   "created entirely by you as an individual"; AI may assist "with specific tasks", fully
   disclosed. These prototypes were written by Claude, so they can be the spec and a reference,
   but not the submission.
3. **The Challenge constrains Holos more than it constrains Vidkryto.** "All content must be
   in English" (Holos is about Ukrainian); third-party images must be public domain (so no
   ARASAAC pictograms); everything must work offline in three minutes.

| Path | What happens | Fits when |
|---|---|---|
| **B. Vidkryto for SSC 2027; Holos becomes a real app from February** (recommended) | Vidkryto keeps its evenings and its January freeze. Holos uses the months until February for the slow, people-shaped work it needs anyway, then builds from the prototypes with no Challenge constraints. | You want both to happen, and Holos to reach real people. |
| **A. Holos replaces Vidkryto as the 2027 entry** | You build a lean Holos yourself from an empty template in about 30 evenings (see Path A). Vidkryto pauses. | Holos matters more to you than Vidkryto, and you accept a smaller Holos than the prototypes. |
| **C. Holos for SSC 2028** | As B, but Holos must then be written by you from the first line, so the prototype code cannot be reused. | You will still be eligible in 2028. |

**Why B.** Vidkryto is months along, with a detailed plan to a January freeze. A self-built Holos in the evenings left
before February would have to be Bedside-sized, not the Bedside + Grid hybrid, and would
carry the English-only risk. Meanwhile, what Holos needs most cannot be coded: a speech
therapist's review, a rehab partner, and people to try it. Those take calendar time, not
evenings, so they fit around Vidkryto.

**VERDICT: ______** (A, B or C, and one line on why)

---

## Path B (recommended): Holos as a real app

### Now → 24 January: groundwork that costs no build evenings

Each item is an email, a call or an hour of reading, so none competes with Vidkryto's evenings.

- [ ] Send the browser sketch (`design/HolosBedsideGrid/sketch.html`, opens in any browser) to
      Talk! (Говори!) and one or two rehab centres or speech therapists. Ask three things: does
      a conversation-first board fit their wards; will someone review the vocabulary; could
      three to five patients try it in spring?
- [ ] Get the vocabulary reviewed by a Ukrainian speech therapist: every phrase, its picture
      and its Ukrainian, both forms where a man and a woman say it differently. (A spreadsheet
      export is easier for them than Swift files; Claude can generate one.)
- [ ] Choose the code licence, and read ARASAAC's terms (CC BY-NC-SA) for a free,
      open-source app.
- [ ] Decide whether Holos might ever be a Challenge entry (Path C). If yes, the February build
      starts from an empty template, not from the prototypes.
- [ ] Budget the paid Apple Developer Program membership: TestFlight and the App Store need it.

### February → March: v0.1 (about 16 evenings, after Vidkryto is submitted)

- [ ] Build `Prototypes/HolosBedsideGrid.swiftpm` in Xcode, fix the first-build errors, run it
      on an iPad.
- [ ] Fix the review's first-priority items: one shared vocabulary with one picture and colour
      per word; say it again; the board opening on the question's topic; the partner's question
      waiting instead of interrupting; VoiceOver feedback, focus and the full sentence read
      aloud; text that grows without a cap; a contrast-checked dark palette; stronger cell
      edges; hold time and slower scan speeds.
- [ ] Turn the three-minute story into an optional tour, so the app opens on the board.
- [ ] If the evenings run short, text growth and the dark palette move to the pilot months;
      everything else on this list is needed before anyone tries it.
- [ ] **Exit gate:** a speech therapist holds a whole conversation in Ukrainian on an iPad,
      once by switch and once by touch, without your help.

### April → June: pilot

- [ ] TestFlight build; consent arranged through the partner organisation.
- [ ] Three to five people, each with a carer or therapist, for a few weeks. Track how long an
      answer takes, mis-selections, fatigue, and what they wanted to say but couldn't.
- [ ] Recordings: a man's and a woman's Ukrainian voice for all of about 90 sentences, recorded
      with consent and licensed to the project.
- [ ] Carer editing (names, family photos) if the pilot asks for it; it probably will.

### July → September: v1.0

- [ ] ARASAAC pictograms in place of SF Symbols.
- [ ] Two-switch step scanning and inverse scanning.
- [ ] Privacy policy (nothing is collected), App Store accessibility labels, Ukrainian-first
      store listing; free, open-source release.

---

## Path A: Holos as the 2027 entry instead of Vidkryto

**Scope.** Holos Bedside, lean: Bedside's four-step story with a small "Something else" board,
built by you from Xcode's empty App Playground template. Not the hybrid: Grid's whole board
(message bar, quick phrases, six topics) does not fit in about 30 evenings alongside an engine
written from scratch. Head control, game controllers and two-switch scanning are out.

**Capacity.** About two evenings a week plus the holiday surplus: roughly 30 evenings from
2 November to a 31 January freeze. The 2026 window ran 6–28 February; assume a similar 2027
window and submit in its first week.

| When | Milestone | Evenings | Exit gate |
|---|---|---|---|
| by Sun 1 Nov | **Gate 0**: verdict; eligibility verdict; new repository from the template; `submission/ai-usage-log.md` | — | Template project builds in Swift Playgrounds on iPad |
| 2–22 Nov | **H1 Engine**: tap anywhere and Space/Enter as one press; a timed linear scan with a longer first step; speech with language-tagged text; click and haptic; settings for scan speed (up to 10 s), touch or scan, and touch automatically under VoiceOver and Switch Control | 6 | Six answers scanned and spoken with one switch; Swift Playgrounds iPad smoke test |
| Mon 9 Nov | **Rules check**: compare the 2027 announcement with this plan (window, toolchain, AI, English) | — | Differences written here |
| 23 Nov – 13 Dec | **H2 Conversation**: chat; the nurse's five turns; answer cells, face scale (body map optional); guide tag; say it again; Show me | 6 | Step 2 playable start to finish; vocabulary sent to a speech therapist |
| 14 Dec – 3 Jan | **H3 Something else**: one shared vocabulary; a two-topic board scanned by row then cell, opening on the question's topic; Back to the answers | 7 | Step 3 playable |
| 4–17 Jan | **H4 Story and accessibility**: step 1 scene; step 4 replay with your five recordings (system voice as fallback); closing; instructions locked to English; VoiceOver feedback, focus, Magic Tap, escape; larger text; contrast; hold time | 6 | Full flow under 3:00 with three fresh testers; the whole flow done with VoiceOver alone |
| 18–31 Jan | **H5 Freeze and pack**: bug fixes only; clean builds in Swift Playgrounds (iPad and Mac) and Xcode; airplane-mode run; ZIP under 25 MB; credits; AI declaration; essays (yours) | 5 | Submission-ready 31 January |
| early Feb | **Submit** in the window's first week | — | Submitted |

**De-scope ladder** (cut from the top, calmly, at the date shown):

| # | Cut | Decide by |
|---|---|---|
| 1 | Dark palette → keep the contrast-checked light palette only | 4 Jan |
| 2 | Body map → plain answer cells | 13 Dec |
| 3 | "Something else" → one topic (Family) | 3 Jan |
| 4 | Free conversation after the story → closing with Start again only | 17 Jan |

Never on the ladder: the four steps (the problem, one switch, the word that won't come, the
Ukrainian replay); finishing everything with one switch; finishing everything with VoiceOver;
the five recordings (an evening's work, and the replay depends on them).

**The five recordings.** The judge hears five Ukrainian sentences in step 4: Мені боляче,
Болить голова, Сильно, Води, будь ласка, Подзвоніть, будь ласка, моїй дружині. None changes
with the speaker's gender, so your own voice works for all five, and the replay no longer
depends on the judge's device having a Ukrainian voice.

---

## Either path

### Accessibility definition of done

A build passes when every row passes. Run the matrix at each exit gate from H4 / v0.1 on.

| Check | How | Passes when |
|---|---|---|
| One switch | Space bar only, at 1.4 s and at the slowest speed | Every step finishes; nothing needs a tap |
| VoiceOver | Screen Curtain on (three-finger triple tap) | Every step finishes; each change (topic, word added, board opened or closed) is announced; focus never lands on something that has gone |
| Switch Control | Apple's own, one switch | Every step finishes (Holos hands over to it) |
| Voice Control | "Tap Wife", then "Show numbers" | Every cell answers to its name in English and Ukrainian |
| Larger text | Largest accessibility size, iPhone and iPad | No clipped text; the board grows and scrolls instead of shrinking words |
| Contrast | Measured, light and dark (Claude can compute these) | Text at least 4.5:1 (3:1 for large text); cell edges and the guide tag at least 3:1 |
| Colour | Grayscale filter on | The guide and the selected topic still read (shape, outline and text, not colour alone) |
| Motion | Reduce Motion on | Fades only, no lift, no slide |
| Light sensitivity | Dark Mode, then Smart Invert | Readable, no bright flashes |
| Timing | Three people who have never seen it | Judged flow under 3:00 (Path A); the pilot's most common requests reachable in three presses or fewer (Path B) |
| Language | Language toggle pressed mid-flow (Path A) | Everything a judge must read stays in English |

Standards behind the matrix: WCAG 2.2 AA (text contrast 1.4.3, resizing text 1.4.4, edge
contrast 1.4.11, pointer cancellation 2.5.2, target size 2.5.8, status messages 4.1.3) and
Apple's Human Interface Guidelines for accessibility.

### Working with AI

- **Path A (the entry):** you write the code. Claude can explain an API, review code you wrote,
  find bugs, compute contrast and check timing — and every use gets one line in
  `submission/ai-usage-log.md` (date, milestone, what it did), as Vidkryto already does.
  Reading the prototypes is research; copying their code in would break "created entirely
  by you".
- **Path B (the app):** no Challenge rule applies, so the prototype code is yours to build on.
  Say in the README that it was written with Claude, and understand every file you ship: you
  will maintain it.

### Risks

| Risk | Mitigation |
|---|---|
| Not eligible for 2027 | The eligibility verdict comes first; under Path B, Holos is unaffected either way |
| The 2027 rules change | 9 November check; re-plan from the differences |
| "All content must be in English" (Path A) | Instructions locked to English; Ukrainian only as the thing being shown; ask Apple if in doubt |
| No speech therapist replies | Write to several at once in November; Talk! (Говори!) first |
| The evenings run out | The ladder, decided at its dates, not in the last week |
| Pilot ethics (Path B) | Pilot only through a partner organisation, with consent, no medical claims, and no data leaving the device |

### Sources

- [Swift Student Challenge eligibility](https://developer.apple.com/swift-student-challenge/eligibility/)
  and [2026 terms](https://developer.apple.com/swift-student-challenge/policy/): one entry per
  person, created by you, AI disclosed, English only, offline, 25 MB, third-party images and
  sounds only if public domain.
- [2026 window: 6–28 February](https://www.mactech.com/2025/11/06/apples-2026-swift-student-challenge-will-open-february-6),
  announced 6 November 2025.
- [WCAG 2.2 quick reference](https://www.w3.org/WAI/WCAG22/quickref/) and
  [Apple HIG: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility).
