import Foundation

protocol OnboardingStateStoring {
    var isCompleted: Bool { get set }
}

struct OnboardingStateStore: OnboardingStateStoring {
    private let defaults: UserDefaults
    private let key = "hasCompletedOnboarding"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isCompleted: Bool {
        get { defaults.bool(forKey: key) }
        set { defaults.set(newValue, forKey: key) }
    }
}
