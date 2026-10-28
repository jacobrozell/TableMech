import Foundation
import Observation
import SwiftUI
import TableMechDomain
import UIKit

enum AppColorSchemePreference: String, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

@Observable
@MainActor
final class AppPreferences {
    static let hapticsKey = "settings.hapticsEnabled"
    static let themeKey = "settings.theme"
    static let keepScreenAwakeKey = "settings.keepScreenAwake"
    static let defaultDiceModeKey = "settings.defaultDiceMode"
    static let gettingStartedChecksKey = "settings.gettingStartedChecks"
    static let hasSeenIntroKey = "settings.hasSeenIntro"

    private let defaults: UserDefaults

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Self.hapticsKey) }
    }

    var theme: AppColorSchemePreference {
        didSet { defaults.set(theme.rawValue, forKey: Self.themeKey) }
    }

    var keepScreenAwake: Bool {
        didSet { defaults.set(keepScreenAwake, forKey: Self.keepScreenAwakeKey) }
    }

    var defaultDiceMode: DiceMode {
        didSet { defaults.set(defaultDiceMode.rawValue, forKey: Self.defaultDiceModeKey) }
    }

    var gettingStartedChecks: Set<String> {
        didSet { defaults.set(Array(gettingStartedChecks).sorted(), forKey: Self.gettingStartedChecksKey) }
    }

    var hasSeenIntro: Bool {
        didSet { defaults.set(hasSeenIntro, forKey: Self.hasSeenIntroKey) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Self.hapticsKey) == nil {
            hapticsEnabled = true
        } else {
            hapticsEnabled = defaults.bool(forKey: Self.hapticsKey)
        }
        theme = AppColorSchemePreference(rawValue: defaults.string(forKey: Self.themeKey) ?? "") ?? .system
        if defaults.object(forKey: Self.keepScreenAwakeKey) == nil {
            keepScreenAwake = true
        } else {
            keepScreenAwake = defaults.bool(forKey: Self.keepScreenAwakeKey)
        }
        defaultDiceMode = DiceMode(rawValue: defaults.string(forKey: Self.defaultDiceModeKey) ?? "") ?? .manual
        gettingStartedChecks = Set(defaults.stringArray(forKey: Self.gettingStartedChecksKey) ?? [])
        hasSeenIntro = defaults.bool(forKey: Self.hasSeenIntroKey)
    }

    func toggleGettingStarted(_ id: String) {
        var next = gettingStartedChecks
        if next.contains(id) {
            next.remove(id)
        } else {
            next.insert(id)
        }
        gettingStartedChecks = next
    }

    func clearGettingStartedChecks() {
        gettingStartedChecks = []
    }

    func applyKeepScreenAwake() {
        UIApplication.shared.isIdleTimerDisabled = keepScreenAwake
    }
}
