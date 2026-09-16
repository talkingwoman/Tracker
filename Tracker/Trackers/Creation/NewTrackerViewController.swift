//
//  NewTrackerViewController.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import UIKit
import RswiftResources

final class NewTrackerViewController: UIViewController {
    private enum OptionsSection: Int, CaseIterable {
        case emoji
        case color

        var title: String {
            switch self {
            case .emoji: return R.string.localizable.creationEmoji()
            case .color: return R.string.localizable.creationColor()
            }
        }
    }

    weak var delegate: NewTrackerViewControllerDelegate?
    var onSaveEdit: ((Tracker, String) -> Void)?
    private var editingTracker: Tracker?
    private var completedDays = 0

    private let mode: TrackerCreationMode
    private let categoryStore: TrackerCategoryStoreProtocol
    private var schedule: Set<WeekDay> = []
    private var selectedCategoryTitle: String?
    private var selectedEmoji: String?
    private var selectedColor: UIColor?
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let nameField = UITextField()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let cancelButton = UIButton(type: .system)
    private let createButton = UIButton(type: .system)
    private var nameErrorHeightConstraint: NSLayoutConstraint?

    private let nameErrorLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.creationNameLimit(TrackerConstants.maximumNameLength)
        label.textColor = TrackerColors.red
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var optionsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 5
        layout.minimumLineSpacing = 0
        layout.sectionInset = UIEdgeInsets(top: 24, left: 12, bottom: 24, right: 12)
        layout.headerReferenceSize = CGSize(width: 0, height: 22)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = TrackerColors.background
        collectionView.isScrollEnabled = false
        collectionView.allowsMultipleSelection = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: EmojiCell.reuseIdentifier)
        collectionView.register(ColorCell.self, forCellWithReuseIdentifier: ColorCell.reuseIdentifier)
        collectionView.register(
            OptionsSectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: OptionsSectionHeader.reuseIdentifier
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    init(mode: TrackerCreationMode, categoryStore: TrackerCategoryStoreProtocol) {
        self.mode = mode
        self.categoryStore = categoryStore
        super.init(nibName: nil, bundle: nil)
    }

    convenience init(tracker: Tracker, categoryTitle: String, completedDays: Int,
                     categoryStore: TrackerCategoryStoreProtocol) {
        self.init(mode: tracker.schedule.isEmpty ? .irregularEvent : .habit, categoryStore: categoryStore)
        editingTracker = tracker
        self.completedDays = completedDays
        selectedCategoryTitle = categoryTitle
        selectedEmoji = tracker.emoji
        selectedColor = tracker.color
        schedule = tracker.schedule
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = editingTracker == nil ? mode.navigationTitle : R.string.localizable.trackerEditTitle()
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.hidesBackButton = true
        view.backgroundColor = TrackerColors.background
        configureNavigationBar()
        configureControls()
        if let editingTracker {
            nameField.text = editingTracker.title
            createButton.setTitle(R.string.localizable.commonSave(), for: .normal)
        }
        setupViews()
        setupConstraints()
        updateCreateButton()
    }

    // MARK: - Private Methods

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = TrackerColors.background
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func configureControls() {
        scrollView.keyboardDismissMode = .onDrag
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        nameField.placeholder = R.string.localizable.creationNamePlaceholder()
        nameField.backgroundColor = TrackerColors.fieldBackground
        nameField.layer.cornerRadius = 16
        nameField.clearButtonMode = .whileEditing
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        // UITextField mirrors its accessory views automatically in RTL languages.
        nameField.leftView = paddingView
        nameField.leftViewMode = .always
        nameField.textAlignment = .natural
        nameField.adjustsFontSizeToFitWidth = true
        nameField.minimumFontSize = 12
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(updateCreateButton), for: .editingChanged)
        nameField.translatesAutoresizingMaskIntoConstraints = false

        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
        tableView.rowHeight = 75
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.tableFooterView = UIView()
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.translatesAutoresizingMaskIntoConstraints = false

        configureButton(cancelButton, title: R.string.localizable.commonCancel(), titleColor: TrackerColors.red, backgroundColor: TrackerColors.background)
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = TrackerColors.red.cgColor
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        configureButton(createButton, title: R.string.localizable.creationCreate(), titleColor: .white, backgroundColor: TrackerColors.gray)
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
    }

    private func configureButton(_ button: UIButton, title: String, titleColor: UIColor, backgroundColor: UIColor) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(titleColor, for: .normal)
        button.backgroundColor = backgroundColor
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.75
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupViews() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [nameField, nameErrorLabel, tableView, optionsCollectionView].forEach(contentView.addSubview)
        view.addSubview(cancelButton)
        view.addSubview(createButton)
    }

    private func setupConstraints() {
        let tableHeight: CGFloat = mode == .habit ? 150 : 75
        nameErrorHeightConstraint = nameErrorLabel.heightAnchor.constraint(equalToConstant: 0)
        nameErrorHeightConstraint?.isActive = true

        NSLayoutConstraint.activate([
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 8),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor),
            createButton.heightAnchor.constraint(equalTo: cancelButton.heightAnchor),
            createButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: cancelButton.topAnchor, constant: -8),
            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            nameField.topAnchor.constraint(equalTo: contentView.topAnchor, constant: editingTracker == nil ? 24 : 94),
            nameField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            nameField.heightAnchor.constraint(equalToConstant: 75),
            nameErrorLabel.topAnchor.constraint(equalTo: nameField.bottomAnchor),
            nameErrorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            nameErrorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: nameErrorLabel.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: tableHeight),
            optionsCollectionView.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 24),
            optionsCollectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            optionsCollectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            optionsCollectionView.heightAnchor.constraint(equalToConstant: 452),
            optionsCollectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        if editingTracker != nil {
            let countLabel = UILabel()
            countLabel.text = R.string.localizable.trackerDays_count(days: completedDays)
            countLabel.font = .systemFont(ofSize: 32, weight: .bold)
            countLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(countLabel)
            NSLayoutConstraint.activate([
                countLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
                countLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
            ])
        }
    }

    private func isSameColor(_ lhs: UIColor?, _ rhs: UIColor) -> Bool {
        lhs?.isEqual(rhs) == true
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func createTapped() {
        let trackerTitle = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trackerTitle.isEmpty,
              let selectedEmoji,
              let selectedColor,
              let selectedCategoryTitle,
              mode == .irregularEvent || !schedule.isEmpty else { return }
        if let editingTracker {
            onSaveEdit?(Tracker(id: editingTracker.id, title: trackerTitle, color: selectedColor,
                emoji: selectedEmoji, schedule: schedule, isPinned: editingTracker.isPinned), selectedCategoryTitle)
            return
        }
        delegate?.didCreateTracker(
            title: trackerTitle,
            emoji: selectedEmoji,
            color: selectedColor,
            schedule: schedule,
            categoryTitle: selectedCategoryTitle,
            from: self
        )
    }

    @objc private func updateCreateButton() {
        let trackerTitle = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let hasSchedule = mode == .irregularEvent || !schedule.isEmpty
        let canCreate = !trackerTitle.isEmpty
            && selectedCategoryTitle != nil
            && selectedEmoji != nil
            && selectedColor != nil
            && hasSchedule
        createButton.isEnabled = canCreate
        createButton.backgroundColor = canCreate ? TrackerColors.primary : TrackerColors.gray
        createButton.setTitleColor(canCreate ? TrackerColors.background : .white, for: .normal)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension NewTrackerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        mode == .habit ? 2 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = indexPath.row == 0 ? R.string.localizable.categoryTitle() : R.string.localizable.scheduleTitle()
        if indexPath.row == 0 {
            cell.detailTextLabel?.text = selectedCategoryTitle
        }
        if indexPath.row == 1, !schedule.isEmpty {
            cell.detailTextLabel?.text = schedule.count == 7
                ? R.string.localizable.scheduleEveryDay()
                : schedule.sorted { $0.rawValue < $1.rawValue }.map(\.shortTitle).joined(separator: R.string.localizable.scheduleSeparator())
        }
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = TrackerColors.fieldBackground
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.detailTextLabel?.font = .systemFont(ofSize: 17)
        cell.detailTextLabel?.adjustsFontSizeToFitWidth = true
        cell.detailTextLabel?.minimumScaleFactor = 0.75
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 0 {
            let viewModel = CategoryViewModel(store: categoryStore, selectedTitle: selectedCategoryTitle)
            viewModel.onCategorySelected = { [weak self] title in
                self?.selectedCategoryTitle = title
                self?.tableView.reloadData()
                self?.updateCreateButton()
                self?.navigationController?.popViewController(animated: true)
            }
            let controller = CategoryViewController(viewModel: viewModel)
            navigationController?.pushViewController(controller, animated: true)
            return
        }
        let controller = ScheduleViewController(selectedDays: schedule)
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension NewTrackerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        OptionsSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let section = OptionsSection(rawValue: section) else { return 0 }
        return section == .emoji ? TrackerPalette.emojis.count : TrackerPalette.colors.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let section = OptionsSection(rawValue: indexPath.section) else { return UICollectionViewCell() }
        switch section {
        case .emoji:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: EmojiCell.reuseIdentifier,
                for: indexPath
            ) as? EmojiCell else { return UICollectionViewCell() }
            let emoji = TrackerPalette.emojis[indexPath.item]
            cell.configure(emoji: emoji, isSelected: emoji == selectedEmoji)
            return cell
        case .color:
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: ColorCell.reuseIdentifier,
                for: indexPath
            ) as? ColorCell else { return UICollectionViewCell() }
            let color = TrackerPalette.colors[indexPath.item]
            cell.configure(color: color, isSelected: isSameColor(selectedColor, color))
            return cell
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: OptionsSectionHeader.reuseIdentifier,
            for: indexPath
        ) as? OptionsSectionHeader,
        let section = OptionsSection(rawValue: indexPath.section) else { return UICollectionReusableView() }
        header.configure(title: section.title)
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension NewTrackerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let section = OptionsSection(rawValue: indexPath.section) else { return }
        switch section {
        case .emoji: selectedEmoji = TrackerPalette.emojis[indexPath.item]
        case .color: selectedColor = TrackerPalette.colors[indexPath.item]
        }
        collectionView.reloadData()
        updateCreateButton()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let availableWidth = collectionView.bounds.width - 24 - 25
        return CGSize(width: floor(availableWidth / 6), height: 52)
    }
}

// MARK: - UITextFieldDelegate

extension NewTrackerViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let currentText = textField.text,
              let textRange = Range(range, in: currentText) else { return true }
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)
        let isWithinLimit = updatedText.count <= TrackerConstants.maximumNameLength
        nameErrorLabel.isHidden = isWithinLimit
        nameErrorHeightConstraint?.constant = isWithinLimit ? 0 : 22
        return isWithinLimit
    }
}

// MARK: - ScheduleViewControllerDelegate

extension NewTrackerViewController: ScheduleViewControllerDelegate {
    func didChooseSchedule(_ schedule: Set<WeekDay>) {
        self.schedule = schedule
        tableView.reloadData()
        updateCreateButton()
        navigationController?.popViewController(animated: true)
    }
}
