//
//  TrackerTypeViewController.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import UIKit
import RswiftResources

final class TrackerTypeViewController: UIViewController {
    weak var delegate: NewTrackerViewControllerDelegate?
    private let categoryStore: TrackerCategoryStoreProtocol

    init(categoryStore: TrackerCategoryStoreProtocol) {
        self.categoryStore = categoryStore
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.localizable.creationTitle()
        view.backgroundColor = TrackerColors.background
        setupButtons()
    }

    // MARK: - Private Methods

    private func setupButtons() {
        let habitButton = makeButton(title: R.string.localizable.creationHabit(), action: #selector(createHabit))
        let eventButton = makeButton(title: R.string.localizable.creationEvent(), action: #selector(createIrregularEvent))
        let stackView = UIStackView(arrangedSubviews: [habitButton, eventButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            habitButton.heightAnchor.constraint(equalToConstant: 60),
            eventButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(TrackerColors.background, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = TrackerColors.primary
        button.layer.cornerRadius = 16
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func showCreationScreen(mode: TrackerCreationMode) {
        let controller = NewTrackerViewController(mode: mode, categoryStore: categoryStore)
        controller.delegate = delegate
        navigationController?.pushViewController(controller, animated: true)
    }

    // MARK: - Actions

    @objc private func createHabit() {
        showCreationScreen(mode: .habit)
    }

    @objc private func createIrregularEvent() {
        showCreationScreen(mode: .irregularEvent)
    }
}
