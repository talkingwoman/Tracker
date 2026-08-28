import UIKit

final class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTabBar()
        setupViewControllers()
    }

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
        let trackersViewController = TrackersViewController()
        let trackersNavigationController = UINavigationController(
            rootViewController: trackersViewController
        )

        trackersNavigationController.tabBarItem = UITabBarItem(
            title: "Трекеры",
            image: UIImage(systemName: "record.circle.fill"),
            selectedImage: UIImage(systemName: "record.circle.fill")
        )

        let statisticsViewController = StatisticsViewController()
        let statisticsNavigationController = UINavigationController(
            rootViewController: statisticsViewController
        )

        statisticsNavigationController.tabBarItem = UITabBarItem(
            title: "Статистика",
            image: UIImage(systemName: "hare.fill"),
            selectedImage: UIImage(systemName: "hare.fill")
        )

        viewControllers = [
            trackersNavigationController,
            statisticsNavigationController
        ]
    }
}
