//
//  TabBarController.swift
//  Tracker
//
//  Created by Victoria Soboleva on 28.08.2026.
//

import UIKit

final class TabBarController: UITabBarController {
    private let trackerStore: TrackerStore
    private let categoryStore: TrackerCategoryStore
    private let recordStore: TrackerRecordStore

    init(
        trackerStore: TrackerStore,
        categoryStore: TrackerCategoryStore,
        recordStore: TrackerRecordStore
    ) {
        self.trackerStore = trackerStore
        self.categoryStore = categoryStore
        self.recordStore = recordStore
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

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
        let navigationController = UINavigationController(
            rootViewController: TrackersViewController(
                trackerStore: trackerStore,
                categoryStore: categoryStore,
                recordStore: recordStore
            )
        )
        navigationController.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: TrackerImages.trackersTab,
            selectedImage: TrackerImages.trackersTab
        )
        return navigationController
    }

    private func makeStatisticsNavigationController() -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: StatisticsViewController())
        navigationController.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: TrackerImages.statisticsTab,
            selectedImage: TrackerImages.statisticsTab
        )
        return navigationController
    }
}
