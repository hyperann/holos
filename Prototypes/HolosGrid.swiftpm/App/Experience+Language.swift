import Foundation

/// Step 4 borrows the person's saved language to show the board in
/// Ukrainian, and gives it back when the step ends. A small marker makes the
/// giving back survive the app stopping half-way — the playground re-run
/// from Xcode, or swiped away during step 4 — which would otherwise leave
/// the next launch narrating the whole tour in Ukrainian. English is the
/// default, and nothing the tour does may change that behind anyone's back.
extension Experience {
    private static let borrowKey = "holos.grid.tour.borrowedLanguage"

    /// Notes what to give back, just before step 4 switches to Ukrainian.
    func rememberBorrowedLanguage(_ language: Language) {
        guard persistsTourState else { return }
        UserDefaults.standard.set(language.rawValue, forKey: Self.borrowKey)
    }

    /// Step 4 ended normally and has already given the language back.
    func forgetBorrowedLanguage() {
        guard persistsTourState else { return }
        UserDefaults.standard.removeObject(forKey: Self.borrowKey)
    }

    /// At launch: if a tour stopped during step 4, put the language back
    /// before the tour starts again.
    func returnBorrowedLanguage() {
        guard persistsTourState,
              let raw = UserDefaults.standard.string(forKey: Self.borrowKey) else { return }
        if let borrowed = Language(rawValue: raw) {
            services.settings.language = borrowed
        }
        UserDefaults.standard.removeObject(forKey: Self.borrowKey)
    }
}
