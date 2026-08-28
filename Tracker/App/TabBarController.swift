//
//  TabBarController.swift
//  Tracker
//
//  Created by Victoria Soboleva on 28.08.2026.
//

import UIKit

final class TabBarController: UITabBarController {
    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
        setupViewControllers()
    }

    // MARK: - Private Methods

    private func setupTabBar() {
        tabBar.tintColor = TrackerColors.blue
        tabBar.unselectedItemTintColor = TrackerColors.gray
        tabBar.backgroundColor = .systemBackground

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = TrackerColors.gray.withAlphaComponent(0.5)
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }

    private func setupViewControllers() {
        viewControllers = [
            makeTrackersNavigationController(),
            makeStatisticsNavigationController()
        ]
    }

    private func makeTrackersNavigationController() -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: TrackersViewController())
        navigationController.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(systemName: "record.circle.fill"),
            selectedImage: UIImage(systemName: "record.circle.fill")
        )
        return navigationController
    }

    private func makeStatisticsNavigationController() -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: StatisticsViewController())
        navigationController.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(systemName: "hare.fill"),
            selectedImage: UIImage(systemName: "hare.fill")
        )
        return navigationController
    }
}
