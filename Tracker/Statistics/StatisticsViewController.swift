//
//  StatisticsViewController.swift
//  Tracker
//
//  Created by Victoria Soboleva on 28.08.2026.
//

import UIKit
import RswiftResources

final class StatisticsViewController: UIViewController {
    private let viewModel: StatisticsViewModel
    private let statisticCard = StatisticCardView()

    init(viewModel: StatisticsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private let emptyImageView: UIImageView = {
        let image = R.image.statisticsPlaceholder() ?? TrackerImages.statisticsPlaceholderFallback
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.statisticsEmpty()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .label
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = TrackerColors.background
        configureNavigationBar()
        setupViews()
        setupConstraints()
        viewModel.onChange = { [weak self] count in self?.update(count: count) }
        update(count: viewModel.completedCount)
    }

    // MARK: - Private Methods

    private func configureNavigationBar() {
        title = R.string.localizable.tabStatistics()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = TrackerColors.background
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupViews() {
        view.addSubview(emptyImageView)
        view.addSubview(emptyLabel)
        statisticCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statisticCard)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            statisticCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 66),
            statisticCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statisticCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statisticCard.heightAnchor.constraint(equalToConstant: 90),
            emptyImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyImageView.heightAnchor.constraint(equalToConstant: 80),
            emptyImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -35),
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 16),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func update(count: Int) {
        emptyImageView.isHidden = count > 0
        emptyLabel.isHidden = count > 0
        statisticCard.isHidden = count == 0
        statisticCard.configure(count: count)
    }
}
