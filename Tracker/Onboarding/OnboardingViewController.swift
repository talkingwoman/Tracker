import UIKit

final class OnboardingViewController: UIPageViewController {
    var completionTapped: (() -> Void)?

    private lazy var pages: [OnboardingPageViewController] = OnboardingPage.pages.map { page in
        let controller = OnboardingPageViewController(page: page)
        controller.completionTapped = { [weak self] in self?.completionTapped?() }
        return controller
    }

    private let pageControl: UIPageControl = {
        let control = UIPageControl()
        control.currentPage = 0
        control.numberOfPages = OnboardingPage.pages.count
        control.currentPageIndicatorTintColor = TrackerColors.black
        control.pageIndicatorTintColor = TrackerColors.black.withAlphaComponent(0.3)
        control.isUserInteractionEnabled = false
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    init() {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
        setViewControllers([pages[0]], direction: .forward, animated: false)
        view.addSubview(pageControl)
        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120)
        ])
    }
}

extension OnboardingViewController: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard let controller = viewController as? OnboardingPageViewController,
              let index = pages.firstIndex(of: controller), index > 0 else { return nil }
        return pages[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let controller = viewController as? OnboardingPageViewController,
              let index = pages.firstIndex(of: controller), index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }
}

extension OnboardingViewController: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let current = viewControllers?.first as? OnboardingPageViewController,
              let index = pages.firstIndex(of: current) else { return }
        pageControl.currentPage = index
    }
}
