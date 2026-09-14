//
//  TrackersViewController.swift
//  Tracker
//
//  Created by Victoria Soboleva on 28.08.2026.
//

import UIKit

final class TrackersViewController: UIViewController {
    private var categories: [TrackerCategory] = []
    private var completedTrackers: [TrackerRecord] = []
    private var currentDate = Date()

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
        fatalError("init(coder:) не поддерживается")
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 9
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 24, right: 16)
        layout.headerReferenceSize = CGSize(width: 0, height: 46)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
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
        let image = UIImage(named: "trackerPlaceholder") ?? UIImage(systemName: "star.fill")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Что будем отслеживать?"
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let searchController = UISearchController(searchResultsController: nil)

    private lazy var datePicker: UIDatePicker = {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .date
        datePicker.preferredDatePickerStyle = .compact
        datePicker.locale = Locale(identifier: "ru_RU")
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
        view.backgroundColor = .systemBackground
        title = "Трекеры"
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

    // MARK: - Private Methods

    private func configureNavigationBar() {
        let addButton = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addTracker)
        )
        addButton.accessibilityLabel = "Добавить трекер"
        addButton.tintColor = .label
        navigationItem.leftBarButtonItem = addButton
        datePicker.accessibilityLabel = "Выбрать дату"
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)

        searchController.searchBar.placeholder = "Поиск"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupViews() {
        [collectionView, emptyImageView, emptyLabel].forEach(view.addSubview)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyImageView.heightAnchor.constraint(equalToConstant: 80),
            emptyImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -35),
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private var visibleTrackers: [Tracker] {
        let query = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let weekDayIndex = (Calendar.current.component(.weekday, from: currentDate) + 5) % 7
        guard let currentWeekDay = WeekDay(rawValue: weekDayIndex) else { return [] }

        return categories.flatMap(\.trackers).filter { tracker in
            let isScheduled = tracker.schedule.isEmpty || tracker.schedule.contains(currentWeekDay)
            let matchesSearch = query.isEmpty || tracker.title.localizedCaseInsensitiveContains(query)
            return isScheduled && matchesSearch
        }
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
        let isEmpty = visibleTrackers.isEmpty
        let wasCollectionHidden = collectionView.isHidden
        let searchText = searchController.searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        emptyLabel.text = searchText.isEmpty ? "Что будем отслеживать?" : "Ничего не найдено"
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
        let controller = TrackerTypeViewController()
        controller.delegate = self
        present(UINavigationController(rootViewController: controller), animated: true)
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
        updateContent()
    }
}

// MARK: - NewTrackerViewControllerDelegate

extension TrackersViewController: NewTrackerViewControllerDelegate {
    func didCreateTracker(
        title: String,
        emoji: String,
        color: UIColor,
        schedule: Set<WeekDay>,
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
            try trackerStore.add(tracker, categoryTitle: "По умолчанию")
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
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        visibleTrackers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TrackerCell.reuseIdentifier,
            for: indexPath
        ) as? TrackerCell else {
            return UICollectionViewCell()
        }
        let tracker = visibleTrackers[indexPath.item]
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
        header.configure(title: categories.first?.title ?? "По умолчанию")
        return header
    }
}
