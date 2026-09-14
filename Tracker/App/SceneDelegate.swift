//
//  SceneDelegate.swift
//  Tracker
//
//  Created by Victoria Soboleva on 19.07.2026.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let stores = DataBaseStore.shared.makeStores()

        let window = UIWindow(windowScene: windowScene)
        let tabBarController = TabBarController(
            trackerStore: stores.trackerStore,
            categoryStore: stores.categoryStore,
            recordStore: stores.recordStore
        )
        var onboardingState = OnboardingStateStore()
        if onboardingState.isCompleted {
            window.rootViewController = tabBarController
        } else {
            let onboarding = OnboardingViewController()
            onboarding.completionTapped = { [weak window] in
                onboardingState.isCompleted = true
                UIView.transition(
                    with: window ?? UIWindow(),
                    duration: 0.3,
                    options: .transitionCrossDissolve,
                    animations: { window?.rootViewController = tabBarController }
                )
            }
            window.rootViewController = onboarding
        }
        window.makeKeyAndVisible()
        self.window = window
    }
}
