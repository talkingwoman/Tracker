import UIKit

struct OnboardingPage {
    let image: ImageResource
    let title: String

    static let pages = [
        OnboardingPage(
            image: .onboardingBlue,
            title: "Отслеживайте только то, что хотите"
        ),
        OnboardingPage(
            image: .onboardingRed,
            title: "Даже если это\nне литры воды и йога"
        )
    ]
}
