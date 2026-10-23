import Foundation

/// Where the light falls in the room, and how dark the rest goes.
struct Spotlight: Equatable {
    /// The hotspot left at full brightness, or nil for an even veil.
    let hotspotID: String?
    /// 0 is the room as drawn; higher dims everything outside the spotlight.
    let dim: Double
}

/// Everything the views read about the room, worked out in one place so
/// the picture, the hints and VoiceOver can never disagree.
extension Experience {
    // MARK: - The board, as it is right now

    var openHotspot: Hotspot? {
        board.openHotspot(isScanning: isScanning)
    }

    var ringItems: [RingItem] {
        board.ringItems(isScanning: isScanning)
    }

    /// The id the board's scan has lit, while the board is being scanned.
    var litID: String? {
        guard isScanning, boardMode != .inert else { return nil }
        return board.scanner.highlightedID
    }

    /// The id lit on the Ukrainian or closing card. Before the Ukrainian has
    /// been said, a press can only say it, so that button shows lit as soon
    /// as a press will count — the same promise the scan highlight makes.
    var cardLitID: String? {
        guard isScanning else { return nil }
        if stage == .ukrainian, !saidInUkrainian {
            return canContinue ? RoomIDs.sayUkrainian : nil
        }
        return cardScanner.highlightedID
    }

    var isPaused: Bool {
        isScanning && boardMode != .inert && board.scanner.state == .paused
    }

    var spotlight: Spotlight {
        switch stage {
        case .problemAsk:
            // Only the nurse is lit: someone is asking, and that is all
            // the person can take in.
            return Spotlight(hotspotID: "ward.nurse", dim: 0.72)
        case .problemSilent:
            // The lights come up on everything — and still nothing to say.
            return Spotlight(hotspotID: nil, dim: 0)
        case .scanRoom, .familiar, .free:
            if let open = openHotspot {
                return Spotlight(hotspotID: open.id, dim: 0.62)
            }
            guard isScanning, board.scanner.state == .scanning, let lit = board.scanner.highlightedID else {
                return Spotlight(hotspotID: nil, dim: 0)
            }
            if board.place.hotspots.contains(where: { $0.id == lit }) {
                return Spotlight(hotspotID: lit, dim: 0.5)
            }
            // A chip or the message is lit: the room steps back so the eye
            // goes down to where the light is.
            return Spotlight(hotspotID: nil, dim: 0.35)
        case .scanDone, .familiarIntro, .familiarDone, .headTry, .ukrainian, .closing:
            return Spotlight(hotspotID: nil, dim: 0.38)
        }
    }

    // MARK: - The guide

    /// The id of the next thing to press on the way to the goal: a hotspot,
    /// a person in the photo, a phrase — or "go back" when the person has
    /// wandered into the wrong place. It moves with them, so the marker
    /// always answers "what now?" from wherever they are.
    var guideID: String? {
        guard boardMode == .guided, let target = nextTargetID, let route = Vocabulary.route(to: target) else {
            return nil
        }
        let open = board.openPath(isScanning: isScanning)
        if route.place != board.place {
            // A finger can reach the room switch from anywhere; a scan has
            // to step back out to the top first.
            if isScanning, let last = open.last { return Scanner.backID(for: last) }
            return RoomIDs.sceneChip
        }
        if open.count < route.ids.count, Array(route.ids.prefix(open.count)) == open {
            return route.ids[open.count]
        }
        // Wandered into another object: a finger can tap the right one
        // straight away, a scan steps back out of this one.
        if !isScanning, open.first != route.ids.first { return route.ids.first }
        if let last = open.last { return Scanner.backID(for: last) }
        return route.ids.first
    }

    /// The guide, in words.
    var hint: Bilingual? {
        guard let guide = guideID else { return nil }
        if Scanner.isBackID(guide) {
            return Copy.hintGoBack(scanning: isScanning)
        }
        if guide == RoomIDs.sceneChip {
            return Copy.hintReach(board.place.switchLabel, scanning: isScanning)
        }
        if let spot = Vocabulary.hotspot(guide) {
            return Copy.hintReach(spot.name, scanning: isScanning)
        }
        if let phrase = Vocabulary.cellPhrase(guide) {
            return Copy.hintChoose(phrase.label, scanning: isScanning)
        }
        return nil
    }

    var helpText: Bilingual? {
        guard helpOffered, boardMode == .guided else { return nil }
        return isScanning ? Copy.helpOfferedScanning : Copy.helpOfferedTouch
    }

    // MARK: - Words for the scan

    /// What auditory prompts say for each lit id.
    func label(for id: String) -> Bilingual? {
        if let spot = Vocabulary.hotspot(id) { return spot.name }
        if let phrase = Vocabulary.cellPhrase(id) { return phrase.label }
        switch id {
        case RoomIDs.sceneChip: return board.place.switchLabel
        case RoomIDs.languageChip: return Copy.languageChip
        case RoomIDs.helpChip: return Copy.helpChip
        default: return MessageBar.label(for: id)
        }
    }

    func cardLabel(for id: String) -> Bilingual? {
        switch id {
        case RoomIDs.sayUkrainian: saidInUkrainian ? Copy.sayAgain : Copy.sayInUkrainian
        case RoomIDs.cardContinue: Copy.continueButton
        case RoomIDs.keepTalking: Copy.keepTalking
        case RoomIDs.startAgain: Copy.startAgain
        default: nil
        }
    }
}
