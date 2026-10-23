import Foundation

/// What each stage of the story is, and what it says.
///
/// Read-only on purpose: everything here is worked out from the stage, so
/// the cards, the top bar and VoiceOver announcements always agree.
extension Experience {
    enum Stage: Hashable, Sendable {
        /// The nurse asks; the one button does nothing useful.
        case problemAsk
        /// The lights come up: everything is there, nothing can be said.
        case problemSilent
        /// Guided: "I'm in pain. Medicine, please."
        case scanRoom
        case scanDone
        case familiarIntro
        /// Guided: "Please call my wife", found through the family photo.
        case familiar
        case familiarDone
        /// Core's optional "try a head turn" panel.
        case headTry
        case ukrainian
        case closing
        /// The real app: the room, freely.
        case free
    }

    enum BoardMode: Equatable, Sendable {
        /// Visible but not in play: a card is speaking for the story.
        case inert
        /// In play, with a goal, a guide marker and hints.
        case guided
        case free
    }

    // MARK: - What the stage is

    var boardMode: BoardMode {
        switch stage {
        case .scanRoom, .familiar: .guided
        case .free: .free
        case .problemAsk, .problemSilent, .scanDone, .familiarIntro, .familiarDone, .headTry, .ukrainian, .closing: .inert
        }
    }

    /// Narrative cards: a press, after a moment, means "continue".
    var isNarrative: Bool {
        switch stage {
        case .problemAsk, .problemSilent, .scanDone, .familiarIntro, .familiarDone: true
        case .scanRoom, .familiar, .headTry, .ukrainian, .closing, .free: false
        }
    }

    var targets: [String] {
        switch stage {
        case .scanRoom: Vocabulary.scanGoal
        case .familiar: Vocabulary.familiarGoal
        case .problemAsk, .problemSilent, .scanDone, .familiarIntro, .familiarDone, .headTry, .ukrainian, .closing, .free: []
        }
    }

    /// The goal's next phrase not yet said, in any order the person likes.
    var nextTargetID: String? {
        targets.first { !doneTargets.contains($0) }
    }

    /// Step 4 replays the person's own message; if step 2 somehow ended
    /// with nothing said, it falls back to the goal sentence.
    var ukrainianMessage: [Phrase] {
        firstMessage.isEmpty ? Vocabulary.defaultFirstMessage : firstMessage
    }

    /// The language the Ukrainian card explains itself in: the judge's own,
    /// even while the board behind it has switched to Ukrainian — otherwise
    /// an English-speaking judge would lose the explanation, the buttons and
    /// the "how to add a Ukrainian voice" notice at the very moment they
    /// matter. Auditory prompts still follow the board's language.
    var readingLanguage: Language {
        languageBeforeUkrainian ?? services.settings.language
    }

    /// The two buttons the card scan visits on the Ukrainian and closing
    /// cards. (On the Ukrainian card the scan starts only once the message
    /// has been said; until then any press says it.)
    var cardItems: [ScanNode] {
        switch stage {
        case .ukrainian: [.item(RoomIDs.sayUkrainian), .item(RoomIDs.cardContinue)]
        case .closing: [.item(RoomIDs.keepTalking), .item(RoomIDs.startAgain)]
        case .problemAsk, .problemSilent, .scanRoom, .scanDone, .familiarIntro, .familiar, .familiarDone, .headTry, .free: []
        }
    }

    // MARK: - Words for each stage

    /// Which of the four judged parts this is (0-based); nil in the free room.
    var partIndex: Int? {
        switch stage {
        case .problemAsk, .problemSilent: 0
        case .scanRoom, .scanDone: 1
        case .familiarIntro, .familiar, .familiarDone, .headTry: 2
        case .ukrainian, .closing: 3
        case .free: nil
        }
    }

    var title: Bilingual {
        switch stage {
        case .problemAsk, .problemSilent: Copy.problemTitle
        case .scanRoom, .scanDone: Copy.scanTitle
        case .familiarIntro, .familiar, .familiarDone, .headTry: Copy.familiarTitle
        case .ukrainian, .closing: Copy.ukrainianTitle
        case .free: Copy.freeTitle
        }
    }

    var goal: Bilingual? {
        switch stage {
        case .scanRoom: Copy.scanGoal
        case .familiar: Copy.familiarGoal
        case .problemAsk, .problemSilent, .scanDone, .familiarIntro, .familiarDone, .headTry, .ukrainian, .closing, .free: nil
        }
    }

    var how: Bilingual? {
        switch stage {
        case .scanRoom: isScanning ? Copy.scanHow : Copy.scanHowTouch
        case .familiar: Copy.familiarHow
        case .free: Copy.freeHow
        case .problemAsk, .problemSilent, .scanDone, .familiarIntro, .familiarDone, .headTry, .ukrainian, .closing: nil
        }
    }

    var cardTitle: Bilingual? {
        switch stage {
        case .problemAsk: Copy.problemAskTitle
        case .problemSilent: Copy.problemSilentTitle
        case .scanDone: Copy.scanDoneTitle
        case .familiarIntro: Copy.familiarIntroTitle
        case .familiarDone: lastGoalMet ? Copy.familiarDoneTitle : Copy.familiarOtherTitle
        case .scanRoom, .familiar, .headTry, .ukrainian, .closing, .free: nil
        }
    }

    var cardBody: Bilingual? {
        switch stage {
        case .problemAsk: Copy.problemAskBody
        case .problemSilent: Copy.problemSilentBody
        case .scanDone: Copy.scanDoneBody
        case .familiarIntro: Copy.familiarIntroBody
        case .familiarDone: lastGoalMet ? Copy.familiarDoneBody : Copy.familiarOtherBody
        case .scanRoom, .familiar, .headTry, .ukrainian, .closing, .free: nil
        }
    }

    /// What VoiceOver hears when a stage begins. The head-turn panel
    /// announces itself, so it gets nothing here.
    var announcement: String {
        let language = services.settings.language
        let gender = services.settings.gender
        let parts: [Bilingual?]
        switch stage {
        case .problemAsk, .problemSilent, .scanDone, .familiarIntro, .familiarDone:
            parts = [cardTitle, cardBody]
        case .scanRoom, .familiar, .free:
            parts = [title, goal, how]
        case .ukrainian:
            parts = [Copy.ukrainianTitle, Copy.ukrainianBody]
        case .closing:
            parts = [Copy.closingTitle]
        case .headTry:
            parts = []
        }
        return parts.compactMap { $0?.callAsFunction(language, gender) }.joined(separator: " ")
    }
}
