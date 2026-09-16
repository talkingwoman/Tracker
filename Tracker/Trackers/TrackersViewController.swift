//
//  TrackersViewController.swift
//  Tracker
//
//  Created by Victoria Soboleva on 28.08.2026.
//

import UIKit
import RswiftResources

final class TrackersViewController: UIViewController {
    private var categories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var currentDate = Date()
    private var visibleCategories: [TrackerCategory] = []
    private var selectedFilter: TrackerFilter = .all

    private let trackerStore: TrackerStore
    private let categoryStore: TrackerCategoryStore
    private let recordStore: TrackerRecordStore
    private let analytics: AnalyticsReporting

    init(
        trackerStore: TrackerStore,
        categoryStore: TrackerCategoryStore,
        recordStore: TrackerRecordStore,
        analytics: AnalyticsReporting = AnalyticsService.shared
    ) {
        self.trackerStore = trackerStore
        self.categoryStore = categoryStore
        self.recordStore = recordStore
        self.analytics = analytics
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) не поддерживается")
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 9
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 24, right: 16)
        layout.headerReferenceSize = CGSize(width: 0, height: 46)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = TrackerColors.background
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.reuseIdentifier)
        collectionView.register(
            SectionHeader.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: SectionHeader.reuseIdentifier
        )
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        return collectionView
    }()

    private let emptyImageView: UIImageView = {
        let image = R.image.trackerPlaceholder() ?? TrackerImages.trackerPlaceholderFallback
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = R.string.localizable.trackerEmptyTitle()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let searchController = UISearchController(searchResultsController: nil)

    private lazy var filtersButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle(R.string.localizable.filterTitle(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = TrackerColors.blue
        button.titleLabel?.font = .systemFont(ofSize: 17)
        button.layer.cornerRadius = 16
        button.addTarget(self, action: #selector(showFilters), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        // The design keeps a light date control in both appearances.
        datePicker.overrideUserInterfaceStyle = .light
        datePicker.backgroundColor = UIColor(resource: .trackerDateBackground)
        datePicker.layer.cornerRadius = 8
        datePicker.clipsToBounds = true
        datePicker.date = currentDate
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        return datePicker
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        trackerStore.delegate = self
        categoryStore.delegate = self
        recordStore.delegate = self
        reloadDataFromStores()
        view.backgroundColor = TrackerColors.background
        title = R.string.localizable.tabTrackers()
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        configureNavigationBar()
        setupViews()
        setupConstraints()
        updateContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        analytics.report(.open)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        analytics.report(.close)
    }

    // MARK: - Private Methods

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = TrackerColors.background
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        let addButton = UIBarButtonItem(
            image: TrackerImages.add,
            style: .plain,
            target: self,
            action: #selector(addTracker)
        )
        addButton.accessibilityLabel = R.string.localizable.trackerAdd()
        addButton.tintColor = .label
        navigationItem.leftBarButtonItem = addButton
        datePicker.accessibilityLabel = R.string.localizable.trackerDate()
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)

        searchController.searchBar.placeholder = R.string.localizable.trackerSearch()
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupViews() {
        [collectionView, emptyImageView, emptyLabel, filtersButton].forEach(view.addSubview)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            filtersButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            filtersButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            filtersButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 114),
            filtersButton.heightAnchor.constraint(equalToConstant: 50),
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

    private func isCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        completedTrackers.contains {
            $0.id == tracker.id && Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }

    private func completedDaysCount(for tracker: Tracker) -> Int {
        completedTrackers.filter { $0.id == tracker.id }.count
    }

    private func updateContent() {
        visibleCategories = TrackerFiltering.categories(
            from: categories, records: completedTrackers, date: currentDate,
            query: searchController.searchBar.text ?? "", filter: selectedFilter
        )
        let isEmpty = visibleCategories.isEmpty
        let hasScheduledTrackers = !TrackerFiltering.categories(
            from: categories, records: completedTrackers, date: currentDate
        ).isEmpty
        filtersButton.isHidden = !hasScheduledTrackers
        collectionView.contentInset.bottom = hasScheduledTrackers ? 82 : 0
        let wasCollectionHidden = collectionView.isHidden
        let searchText = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let noResults = !searchText.isEmpty || selectedFilter.isActive
        emptyImageView.image = noResults ? UIImage(resource: .searchPlaceholder) : R.image.trackerPlaceholder()
        emptyLabel.text = noResults ? R.string.localizable.trackerSearchEmpty() : R.string.localizable.trackerEmptyTitle()
        emptyImageView.isHidden = !isEmpty
        emptyLabel.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
        collectionView.reloadData()

        if wasCollectionHidden && !isEmpty {
            view.layoutIfNeeded()
            collectionView.setContentOffset(
                CGPoint(x: 0, y: -collectionView.adjustedContentInset.top),
                animated: false
            )
        }
    }

    private func reloadDataFromStores() {
        categories = categoryStore.categories
        completedTrackers = recordStore.records
    }

    private func toggleCompletion(for tracker: Tracker) {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: currentDate)
        guard selectedDay <= calendar.startOfDay(for: Date()) else { return }
        analytics.report(.click(.track))

        if completedTrackers.contains(where: {
            $0.id == tracker.id && calendar.isDate($0.date, inSameDayAs: selectedDay)
        }) {
            do {
                try recordStore.delete(trackerID: tracker.id, date: selectedDay)
            } catch {
                assertionFailure("Не удалось удалить отметку: \(error)")
            }
        } else {
            do {
                try recordStore.add(TrackerRecord(id: tracker.id, date: selectedDay))
            } catch {
                assertionFailure("Не удалось сохранить отметку: \(error)")
            }
        }
    }

    // MARK: - Actions

    @objc private func addTracker() {
        analytics.report(.click(.addTrack))
        let controller = TrackerTypeViewController(categoryStore: categoryStore)
        controller.delegate = self
        present(UINavigationController(rootViewController: controller), animated: true)
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
        updateContent()
    }

    @objc private func showFilters() {
        analytics.report(.click(.filter))
        let controller = FiltersViewController(selectedFilter: selectedFilter)
        controller.onSelect = { [weak self] filter in
            guard let self else { return }
            self.selectedFilter = filter.isActive ? filter : .all
            if filter == .today {
                self.currentDate = Date()
                self.datePicker.setDate(self.currentDate, animated: false)
            }
            self.updateContent()
        }
        present(UINavigationController(rootViewController: controller), animated: true)
    }

    private func edit(_ tracker: Tracker) {
        analytics.report(.click(.edit))
        guard let category = categories.first(where: { $0.trackers.contains(where: { $0.id == tracker.id }) }) else { return }
        let controller = NewTrackerViewController(tracker: tracker, categoryTitle: category.title,
            completedDays: completedDaysCount(for: tracker), categoryStore: categoryStore)
        controller.onSaveEdit = { [weak self, weak controller] tracker, category in
            do {
                try self?.trackerStore.update(tracker, categoryTitle: category)
                controller?.dismiss(animated: true)
            } catch { self?.showStoreError() }
        }
        present(UINavigationController(rootViewController: controller), animated: true)
    }

    private func confirmDeletion(of tracker: Tracker) {
        analytics.report(.click(.delete))
        let alert = UIAlertController(title: nil,
            message: R.string.localizable.trackerDeleteConfirm(),
            preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: R.string.localizable.commonDelete(), style: .destructive) { [weak self] _ in
            do { try self?.trackerStore.delete(id: tracker.id) }
            catch { self?.showStoreError() }
        })
        alert.addAction(UIAlertAction(title: R.string.localizable.commonCancel(), style: .cancel))
        alert.popoverPresentationController?.sourceView = view
        alert.popoverPresentationController?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
        present(alert, animated: true)
    }

    private func showStoreError() {
        let alert = UIAlertController(title: R.string.localizable.commonError(),
            message: R.string.localizable.trackerSaveError(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: R.string.localizable.commonOk(), style: .default))
        (presentedViewController ?? self).present(alert, animated: true)
    }
}

// MARK: - NewTrackerViewControllerDelegate

extension TrackersViewController: NewTrackerViewControllerDelegate {
    func didCreateTracker(
        title: String,
        emoji: String,
        color: UIColor,
        schedule: Set<WeekDay>,
        categoryTitle: String,
        from controller: UIViewController
    ) {
        let tracker = Tracker(
            id: UUID(),
            title: title,
            color: color,
            emoji: emoji,
            schedule: schedule
        )
        do {
            try trackerStore.add(tracker, categoryTitle: categoryTitle)
            controller.dismiss(animated: true)
        } catch {
            assertionFailure("Не удалось сохранить трекер: \(error)")
        }
    }
}

// MARK: - Store Delegates

extension TrackersViewController: TrackerStoreDelegate {
    func trackerStoreDidUpdate(_ store: TrackerStore) {
        reloadDataFromStores()
        updateContent()
    }
}

extension TrackersViewController: TrackerCategoryStoreDelegate {
    func trackerCategoryStoreDidUpdate(_ store: TrackerCategoryStore) {
        reloadDataFromStores()
        updateContent()
    }
}

extension TrackersViewController: TrackerRecordStoreDelegate {
    func trackerRecordStoreDidUpdate(_ store: TrackerRecordStore) {
        reloadDataFromStores()
        updateContent()
    }
}

// MARK: - UISearchResultsUpdating

extension TrackersViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        updateContent()
    }
}

// MARK: - UICollectionViewDataSource, UICollectionViewDelegateFlowLayout

extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
        contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let pin = UIAction(title: tracker.isPinned
                ? R.string.localizable.trackerUnpin()
                : R.string.localizable.trackerPin()) { [weak self] _ in
                do { try self?.trackerStore.setPinned(!tracker.isPinned, id: tracker.id) }
                catch { self?.showStoreError() }
            }
            let edit = UIAction(title: R.string.localizable.commonEdit()) { [weak self] _ in
                self?.edit(tracker)
            }
            let delete = UIAction(title: R.string.localizable.commonDelete(), attributes: .destructive) { [weak self] _ in
                self?.confirmDeletion(of: tracker)
            }
            return UIMenu(children: [pin, edit, delete])
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int { visibleCategories.count }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleCategories[section].trackers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }
        let tracker = visibleCategories[indexPath.section].trackers[indexPath.item]
        cell.configure(
            with: tracker,
            isCompleted: isCompleted(tracker, on: currentDate),
            completedDays: completedDaysCount(for: tracker),
            completionEnabled: Calendar.current.startOfDay(for: currentDate) <= Calendar.current.startOfDay(for: Date())
        )
        cell.completionTapped = { [weak self] in
            self?.toggleCompletion(for: tracker)
        }
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: (collectionView.bounds.width - 41) / 2, height: 148)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        guard let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: SectionHeader.reuseIdentifier,
            for: indexPath
        ) as? SectionHeader else {
            return UICollectionReusableView()
        }
        header.configure(title: visibleCategories[indexPath.section].title)
        return header
    }
}
