import Foundation

/// The standard feel of a scan, wired once.
///
/// Every step gets a haptic tick and a soft click, so a person who is not
/// looking at the screen still feels where they are. Entering a group,
/// choosing, going back and pausing each have their own distinct pattern.
/// With auditory prompts on, each lit item is also spoken quietly — and the
/// highlight waits for that prompt to finish before moving on, so a slow
/// voice is never cut off mid-word by a fast scan.
///
/// Every prototype calls this, so the feel of scanning is identical across
/// them and only the board itself differs — which is exactly what the
/// prototypes are there to compare.
extension Scanner {
    /// Call before `load(_:start:)` so the first lit item is announced too
    /// (calling it on a running scan announces the current item at once).
    ///
    /// - Parameters:
    ///   - label: The words for an id, for auditory prompts. Return `nil`
    ///     to stay quiet for that id. Back cells are handled for you.
    ///   - onSelect: Called with the id of each chosen item.
    func bind(
        to services: HolosServices,
        label: @escaping (String) -> Bilingual?,
        onSelect: @escaping (String) -> Void
    ) {
        let settings = services.settings
        let feedback = services.feedback
        let speaker = services.speaker
        let hub = services.hub
        stepSeconds = { settings.scanInterval }
        holdsStep = { settings.auditoryPrompts && speaker.isPrompting }
        isSuspended = { hub.isSuspended }

        let promptLitItem: () -> Void = { [weak self] in
            guard settings.auditoryPrompts, let self, self.state == .scanning,
                  let id = self.highlightedID else { return }
            let words = Scanner.isBackID(id) ? CoreCopy.goBack : label(id)
            guard let words else { return }
            speaker.prompt(words)
        }
        onStart = promptLitItem
        // Items lit while a message was being spoken were not announced;
        // say the current one as soon as the message ends.
        speaker.onMessageFinished = promptLitItem
        onEvent = { event in
            switch event {
            case .moved:
                feedback.step()
                promptLitItem()
            case .entered:
                feedback.enter()
                promptLitItem()
            case .selected(let id):
                feedback.select()
                onSelect(id)
                // After the handler, so a board it has just loaded (or a scan
                // it has stopped) decides what, if anything, is announced.
                promptLitItem()
            case .backedOut:
                feedback.back()
                promptLitItem()
            case .paused:
                feedback.pause()
            case .resumed:
                // start() has already announced the first item via onStart.
                feedback.step()
            }
        }
        if state == .scanning {
            promptLitItem()
        }
    }

    /// Makes every accepted switch press go to this scanner.
    func listen(to hub: SwitchHub) {
        hub.route { [weak self] _ in
            self?.press()
        }
    }
}
