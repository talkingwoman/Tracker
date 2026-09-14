import Foundation

struct OnboardingPage {
    let imageName: String
    let title: String

    static let pages = [
        OnboardingPage(
            imageName: "OnboardingBlue",
            title: "Отслеживайте только то, что хотите"
        ),
        OnboardingPage(
            imageName: "OnboardingRed",
            title: "Даже если это\nне литры воды и йога"
        )
    ]
}
