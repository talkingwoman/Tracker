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
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        let stores = appDelegate.makeStores()

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = TabBarController(
            trackerStore: stores.trackerStore,
            categoryStore: stores.categoryStore,
            recordStore: stores.recordStore
        )
        window.makeKeyAndVisible()
        self.window = window
    }
}
