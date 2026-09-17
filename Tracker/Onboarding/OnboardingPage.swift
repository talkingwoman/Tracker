import UIKit
import DeveloperToolsSupport
import RswiftResources

struct OnboardingPage {
    let image: DeveloperToolsSupport.ImageResource
    let title: String

    static let pages = [
        OnboardingPage(
            image: .onboardingBlue,
            title: R.string.localizable.onboardingTrack()
        ),
        OnboardingPage(
            image: .onboardingRed,
            title: R.string.localizable.onboardingFreedom()
        )
    ]
}
