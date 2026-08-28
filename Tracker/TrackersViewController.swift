import UIKit

enum TrackerColors {
    static let black = UIColor(named: "TrackerBlack") ?? .label
    static let blue = UIColor(named: "TrackerBlue") ?? .systemBlue
    static let gray = UIColor(named: "TrackerGray") ?? .systemGray
    static let red = UIColor(named: "TrackerRed") ?? .systemRed
    static let fieldBackground = (UIColor(named: "TrackerBackground") ?? .secondarySystemBackground)
        .withAlphaComponent(0.3)
    static let dateBackground = UIColor(named: "TrackerDateBackground") ?? .secondarySystemBackground
}

enum WeekDay: Int, CaseIterable, Hashable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var title: String {
        ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"][rawValue]
    }

    var shortTitle: String {
        ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"][rawValue]
    }
}

struct Tracker {
    let id: UUID
    let title: String
    let color: UIColor
    let emoji: String
    let schedule: Set<WeekDay>
}

struct TrackerCategory {
    let title: String
    let trackers: [Tracker]
}

struct TrackerRecord {
    let id: UUID
    let date: Date
}

private enum TrackerCreationMode {
    case habit
    case irregularEvent

    var navigationTitle: String {
        switch self {
        case .habit: return "Новая привычка"
        case .irregularEvent: return "Новое нерегулярное событие"
        }
    }
}

final class TrackersViewController: UIViewController {
    private var categories: [TrackerCategory] = [
        TrackerCategory(title: "По умолчанию", trackers: [])
    ]
    private var completedTrackers: [TrackerRecord] = []
    private var currentDate = Date()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 9
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 24, right: 16)
        layout.headerReferenceSize = CGSize(width: 0, height: 46)
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .systemBackground
        view.dataSource = self
        view.delegate = self
        view.register(TrackerCell.self, forCellWithReuseIdentifier: TrackerCell.id)
        view.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeader.id)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let emptyImageView: UIImageView = {
        let image = UIImage(named: "trackerPlaceholder")
            ?? UIImage(systemName: "star.fill")
        let view = UIImageView(image: image)
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        let picker = UIDatePicker()
        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .compact
        picker.locale = Locale(identifier: "ru_RU")
        picker.date = currentDate
        picker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
        return picker
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Трекеры"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        setupNavigationBar()
        setupContent()
        updateContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(addTracker))
        navigationItem.leftBarButtonItem?.tintColor = .label
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: datePicker)

        searchController.searchBar.placeholder = "Поиск"
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupContent() {
        [collectionView, emptyImageView, emptyLabel].forEach(view.addSubview)
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
            let isScheduledForSelectedDate = tracker.schedule.isEmpty || tracker.schedule.contains(currentWeekDay)
            let matchesSearch = query.isEmpty || tracker.title.localizedCaseInsensitiveContains(query)
            return isScheduledForSelectedDate && matchesSearch
        }
    }

    private func isCompleted(_ tracker: Tracker, on date: Date) -> Bool {
        let calendar = Calendar.current
        return completedTrackers.contains {
            $0.id == tracker.id && calendar.isDate($0.date, inSameDayAs: date)
        }
    }

    private func completedDaysCount(for tracker: Tracker) -> Int {
        completedTrackers.filter { $0.id == tracker.id }.count
    }

    private func updateContent() {
        let isEmpty = visibleTrackers.isEmpty
        let wasCollectionHidden = collectionView.isHidden
        let hasSearchQuery = !(searchController.searchBar.text?
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        emptyLabel.text = hasSearchQuery ? "Ничего не найдено" : "Что будем отслеживать?"
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

    @objc private func addTracker() {
        let controller = TrackerTypeViewController()
        controller.delegate = self
        present(UINavigationController(rootViewController: controller), animated: true)
    }

    @objc private func dateChanged(_ sender: UIDatePicker) {
        currentDate = sender.date
        updateContent()
    }

    private func toggleCompletion(for tracker: Tracker) {
        let calendar = Calendar.current
        let selectedDay = calendar.startOfDay(for: currentDate)
        guard selectedDay <= calendar.startOfDay(for: Date()) else { return }

        if let index = completedTrackers.firstIndex(where: {
            $0.id == tracker.id && calendar.isDate($0.date, inSameDayAs: selectedDay)
        }) {
            completedTrackers.remove(at: index)
        } else {
            completedTrackers.append(TrackerRecord(id: tracker.id, date: selectedDay))
        }
        collectionView.reloadData()
    }
}

extension TrackersViewController: NewHabitViewControllerDelegate {
    fileprivate func didCreateHabit(title: String, schedule: Set<WeekDay>, from controller: UIViewController) {
        let colors: [UIColor] = [.systemBlue, .systemRed, .systemGreen, .systemOrange, .systemPurple]
        let emojis = ["⭐️", "❤️", "🙂", "🏃‍♀️", "📚"]
        let trackersCount = categories.flatMap(\.trackers).count
        let tracker = Tracker(
            id: UUID(),
            title: title,
            color: colors[trackersCount % colors.count],
            emoji: emojis[trackersCount % emojis.count],
            schedule: schedule
        )
        let defaultCategory = categories[0]
        categories[0] = TrackerCategory(
            title: defaultCategory.title,
            trackers: defaultCategory.trackers + [tracker]
        )
        updateContent()
        controller.dismiss(animated: true)
    }
}

extension TrackersViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) { updateContent() }
}

extension TrackersViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { visibleTrackers.count }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TrackerCell.id, for: indexPath) as! TrackerCell
        let tracker = visibleTrackers[indexPath.item]
        cell.configure(
            with: tracker,
            isCompleted: isCompleted(tracker, on: currentDate),
            completedDays: completedDaysCount(for: tracker),
            completionEnabled: Calendar.current.startOfDay(for: currentDate) <= Calendar.current.startOfDay(for: Date())
        )
        cell.completionTapped = { [weak self] in self?.toggleCompletion(for: tracker) }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: (collectionView.bounds.width - 41) / 2, height: 148)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeader.id, for: indexPath) as! SectionHeader
        header.configure(title: categories.first?.title ?? "По умолчанию")
        return header
    }
}

private final class SectionHeader: UICollectionReusableView {
    static let id = "SectionHeader"
    private let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12), label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)])
    }
    required init?(coder: NSCoder) { nil }
    func configure(title: String) { label.text = title }
}

private final class TrackerCell: UICollectionViewCell {
    static let id = "TrackerCell"
    private let card = UIView()
    private let emoji = UILabel()
    private let name = UILabel()
    private let days = UILabel()
    private let plus = UIButton(type: .system)
    var completionTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        card.layer.cornerRadius = 16
        card.translatesAutoresizingMaskIntoConstraints = false
        emoji.font = .systemFont(ofSize: 16)
        emoji.textAlignment = .center
        emoji.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        emoji.layer.cornerRadius = 12
        emoji.clipsToBounds = true
        emoji.translatesAutoresizingMaskIntoConstraints = false
        name.font = .systemFont(ofSize: 12, weight: .medium)
        name.textColor = .white
        name.numberOfLines = 2
        name.translatesAutoresizingMaskIntoConstraints = false
        days.font = .systemFont(ofSize: 12, weight: .medium)
        days.translatesAutoresizingMaskIntoConstraints = false
        plus.setImage(UIImage(systemName: "plus"), for: .normal)
        plus.tintColor = .white
        plus.layer.cornerRadius = 17
        plus.addTarget(self, action: #selector(completionButtonTapped), for: .touchUpInside)
        plus.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)
        card.addSubview(emoji)
        card.addSubview(name)
        contentView.addSubview(days)
        contentView.addSubview(plus)
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor), card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor), card.heightAnchor.constraint(equalToConstant: 90),
            emoji.topAnchor.constraint(equalTo: card.topAnchor, constant: 12), emoji.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12), emoji.widthAnchor.constraint(equalToConstant: 24), emoji.heightAnchor.constraint(equalToConstant: 24),
            name.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12), name.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12), name.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            days.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12), days.centerYAnchor.constraint(equalTo: plus.centerYAnchor),
            plus.topAnchor.constraint(equalTo: card.bottomAnchor, constant: 8), plus.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12), plus.widthAnchor.constraint(equalToConstant: 34), plus.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    required init?(coder: NSCoder) { nil }
    override func prepareForReuse() {
        super.prepareForReuse()
        completionTapped = nil
    }

    func configure(with tracker: Tracker, isCompleted: Bool, completedDays: Int, completionEnabled: Bool) {
        card.backgroundColor = tracker.color
        plus.backgroundColor = tracker.color
        emoji.text = tracker.emoji
        name.text = tracker.title
        plus.setImage(UIImage(systemName: isCompleted ? "checkmark" : "plus"), for: .normal)
        plus.backgroundColor = isCompleted ? tracker.color.withAlphaComponent(0.3) : tracker.color
        plus.isEnabled = completionEnabled
        plus.alpha = completionEnabled ? 1 : 0.3
        days.text = daysText(completedDays)
    }

    @objc private func completionButtonTapped() { completionTapped?() }

    private func daysText(_ count: Int) -> String {
        let mod100 = count % 100
        let mod10 = count % 10
        let ending: String
        if mod100 >= 11 && mod100 <= 14 { ending = "дней" }
        else if mod10 == 1 { ending = "день" }
        else if mod10 >= 2 && mod10 <= 4 { ending = "дня" }
        else { ending = "дней" }
        return "\(count) \(ending)"
    }
}

private protocol NewHabitViewControllerDelegate: AnyObject {
    func didCreateHabit(title: String, schedule: Set<WeekDay>, from controller: UIViewController)
}

private final class TrackerTypeViewController: UIViewController {
    weak var delegate: NewHabitViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Создание трекера"
        view.backgroundColor = .systemBackground

        let habitButton = makeButton(title: "Привычка", action: #selector(createHabit))
        let eventButton = makeButton(title: "Нерегулярное событие", action: #selector(createIrregularEvent))
        let stack = UIStackView(arrangedSubviews: [habitButton, eventButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            habitButton.heightAnchor.constraint(equalToConstant: 60),
            eventButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = TrackerColors.black
        button.layer.cornerRadius = 16
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func createHabit() { showCreationScreen(mode: .habit) }
    @objc private func createIrregularEvent() { showCreationScreen(mode: .irregularEvent) }

    private func showCreationScreen(mode: TrackerCreationMode) {
        let controller = NewHabitViewController(mode: mode)
        controller.delegate = delegate
        navigationController?.pushViewController(controller, animated: true)
    }
}

private final class NewHabitViewController: UIViewController {
    weak var delegate: NewHabitViewControllerDelegate?
    private let mode: TrackerCreationMode
    private var schedule: Set<WeekDay> = []
    private let nameField = UITextField()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let createButton = UIButton(type: .system)
    private var nameErrorHeightConstraint: NSLayoutConstraint?
    private let nameErrorLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.textColor = TrackerColors.red
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(mode: TrackerCreationMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = mode.navigationTitle
        navigationItem.hidesBackButton = true
        view.backgroundColor = .systemBackground
        removeNavigationBarSeparator()
        setupUI()
    }

    private func removeNavigationBarSeparator() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupUI() {
        nameField.placeholder = "Введите название трекера"
        nameField.backgroundColor = TrackerColors.fieldBackground
        nameField.layer.cornerRadius = 16
        nameField.clearButtonMode = .whileEditing
        nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        nameField.leftViewMode = .always
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

        let cancel = makeButton(title: "Отменить", foreground: TrackerColors.red, background: .systemBackground)
        cancel.layer.borderWidth = 1
        cancel.layer.borderColor = TrackerColors.red.cgColor
        cancel.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        createButton.setTitle("Создать", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.backgroundColor = TrackerColors.gray
        createButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        createButton.layer.cornerRadius = 16
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        [nameField, nameErrorLabel, tableView, cancel, createButton].forEach(view.addSubview)
        NSLayoutConstraint.activate([
            nameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24), nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16), nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), nameField.heightAnchor.constraint(equalToConstant: 75),
            nameErrorLabel.topAnchor.constraint(equalTo: nameField.bottomAnchor), nameErrorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16), nameErrorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: nameErrorLabel.bottomAnchor, constant: 24), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), tableView.heightAnchor.constraint(equalToConstant: mode == .habit ? 150 : 75),
            cancel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), cancel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16), cancel.heightAnchor.constraint(equalToConstant: 60),
            createButton.leadingAnchor.constraint(equalTo: cancel.trailingAnchor, constant: 8), createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), createButton.bottomAnchor.constraint(equalTo: cancel.bottomAnchor), createButton.heightAnchor.constraint(equalTo: cancel.heightAnchor), createButton.widthAnchor.constraint(equalTo: cancel.widthAnchor)
        ])
        nameErrorHeightConstraint = nameErrorLabel.heightAnchor.constraint(equalToConstant: 0)
        nameErrorHeightConstraint?.isActive = true
        updateCreateButton()
    }

    private func makeButton(title: String, foreground: UIColor, background: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(foreground, for: .normal)
        button.backgroundColor = background
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    @objc private func cancelTapped() { dismiss(animated: true) }
    @objc private func createTapped() {
        let title = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty, mode == .irregularEvent || !schedule.isEmpty else { return }
        delegate?.didCreateHabit(title: title, schedule: schedule, from: self)
    }
    @objc private func updateCreateButton() {
        let title = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        createButton.isEnabled = !title.isEmpty && (mode == .irregularEvent || !schedule.isEmpty)
        createButton.backgroundColor = createButton.isEnabled ? TrackerColors.black : TrackerColors.gray
    }
}

extension NewHabitViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        mode == .habit ? 2 : 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = indexPath.row == 0 ? "Категория" : "Расписание"
        if indexPath.row == 1, !schedule.isEmpty {
            cell.detailTextLabel?.text = schedule.count == 7 ? "Каждый день" : schedule.sorted { $0.rawValue < $1.rawValue }.map(\.shortTitle).joined(separator: ", ")
        }
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = TrackerColors.fieldBackground
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.detailTextLabel?.font = .systemFont(ofSize: 17)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row == 1 else { return }
        let controller = ScheduleViewController(selectedDays: schedule)
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension NewHabitViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let currentText = textField.text,
              let textRange = Range(range, in: currentText) else { return true }
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)
        let isWithinLimit = updatedText.count <= 38
        nameErrorLabel.isHidden = isWithinLimit
        nameErrorHeightConstraint?.constant = isWithinLimit ? 0 : 22
        return isWithinLimit
    }
}

extension NewHabitViewController: ScheduleViewControllerDelegate {
    fileprivate func didChooseSchedule(_ schedule: Set<WeekDay>) {
        self.schedule = schedule
        tableView.reloadData()
        updateCreateButton()
        navigationController?.popViewController(animated: true)
    }
}

private protocol ScheduleViewControllerDelegate: AnyObject { func didChooseSchedule(_ schedule: Set<WeekDay>) }

private final class ScheduleViewController: UIViewController, UITableViewDataSource {
    weak var delegate: ScheduleViewControllerDelegate?
    private var selectedDays: Set<WeekDay>
    private let tableView = UITableView(frame: .zero, style: .plain)

    init(selectedDays: Set<WeekDay>) {
        self.selectedDays = selectedDays
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Расписание"
        navigationItem.hidesBackButton = true
        view.backgroundColor = .systemBackground
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        tableView.dataSource = self
        tableView.isScrollEnabled = true
        tableView.rowHeight = 75
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.tableFooterView = UIView()
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.backgroundColor = .clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        let done = UIButton(type: .system)
        done.setTitle("Готово", for: .normal)
        done.setTitleColor(.white, for: .normal)
        done.backgroundColor = TrackerColors.black
        done.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        done.layer.cornerRadius = 16
        done.translatesAutoresizingMaskIntoConstraints = false
        done.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        view.addSubview(tableView)
        view.addSubview(done)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24), tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16), tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16), tableView.bottomAnchor.constraint(equalTo: done.topAnchor, constant: -39),
            done.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20), done.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20), done.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16), done.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { WeekDay.allCases.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let day = WeekDay.allCases[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = day.title
        cell.selectionStyle = .none
        cell.backgroundColor = TrackerColors.fieldBackground
        let daySwitch = UISwitch()
        daySwitch.tag = day.rawValue
        daySwitch.isOn = selectedDays.contains(day)
        daySwitch.onTintColor = TrackerColors.blue
        daySwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = daySwitch
        return cell
    }
    @objc private func switchChanged(_ sender: UISwitch) {
        guard let day = WeekDay(rawValue: sender.tag) else { return }
        if sender.isOn { selectedDays.insert(day) } else { selectedDays.remove(day) }
    }
    @objc private func doneTapped() { delegate?.didChooseSchedule(selectedDays) }
}
