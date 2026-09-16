import CoreData
import SnapshotTesting
import RswiftResources
import UIKit
import XCTest
@testable import Tracker

@MainActor
final class TrackerSnapshotTests: XCTestCase {
    private var container: NSPersistentContainer!
    private var trackerStore: TrackerStore!
    private var categoryStore: TrackerCategoryStore!
    private var recordStore: TrackerRecordStore!
    private let date = Date(timeIntervalSince1970: 1_768_478_400) // 15 January 2026, 12:00 UTC
    private static let model: NSManagedObjectModel = {
        let url = Bundle(for: AppDelegate.self).url(forResource: "Tracker", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: url)!
    }()

    override func setUpWithError() throws {
        try super.setUpWithError()
        TrackerValueTransformers.register()
        // Load metadata from the bundle without initializing the application's database.
        container = NSPersistentContainer(name: "Tracker", managedObjectModel: Self.model)
        // A new isolated database for every test. Never read or modify the user's SQLite store.
        try container.persistentStoreCoordinator.addPersistentStore(
            ofType: NSInMemoryStoreType, configurationName: nil, at: nil
        )
        trackerStore = TrackerStore(context: container.viewContext)
        categoryStore = TrackerCategoryStore(context: container.viewContext)
        recordStore = TrackerRecordStore(context: container.viewContext)
    }

    override func tearDownWithError() throws {
        recordStore = nil
        categoryStore = nil
        trackerStore = nil
        container = nil
        try super.tearDownWithError()
    }

    func testEmptyTrackersLight() throws {
        assertScreen(try makeMainScreen(), style: .light)
    }

    func testCategoryTableHasNoOpaqueBackground() throws {
        let screen = try makeCategoriesScreen()
        screen.topViewController?.loadViewIfNeeded()
        let table = try XCTUnwrap(screen.topViewController?.view.subviews.compactMap { $0 as? UITableView }.first)
        XCTAssertEqual(table.backgroundColor, UIColor.clear)
    }

    func testGeneratedLocalizationAndPlurals() {
        let examples: [(String, String, [(Int, String)])] = [
            ("ru", "Трекеры", [(1, "1 день"), (2, "2 дня"), (5, "5 дней"), (11, "11 дней"), (21, "21 день")]),
            ("en", "Trackers", [(1, "1 day"), (2, "2 days")]),
            ("de", "Tracker", [(1, "1 Tag"), (2, "2 Tage")])
        ]
        for (language, title, cases) in examples {
            let strings = R.string(preferredLanguages: [language], locale: Locale(identifier: language)).localizable
            XCTAssertEqual(strings.tabTrackers(), title)
            for (count, expected) in cases {
                XCTAssertEqual(strings.trackerDays_count(days: count), expected)
            }
        }
        XCTAssertEqual(R.string(preferredLanguages: ["ar"]).localizable.tabTrackers(), "المتتبعات")
    }

    func testFilterSelectionSurvivesDateChangeAndCanBeReset() throws {
        try addCompletedTracker()
        let main = try makeMainScreen()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = main
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let navigation = try XCTUnwrap(main.viewControllers?.first as? UINavigationController)
        let screen = try XCTUnwrap(navigation.topViewController as? TrackersViewController)
        let picker = try XCTUnwrap(screen.navigationItem.rightBarButtonItem?.customView as? UIDatePicker)
        let collection = try XCTUnwrap(screen.view.subviews.compactMap { $0 as? UICollectionView }.first)
        let button = try XCTUnwrap(screen.view.subviews.compactMap { $0 as? UIButton }.first)
        UIView.setAnimationsEnabled(false)
        defer { UIView.setAnimationsEnabled(true) }
        button.sendActions(for: .touchUpInside)
        let modal = try XCTUnwrap(screen.presentedViewController as? UINavigationController)
        let filters = try XCTUnwrap(modal.topViewController as? FiltersViewController)
        filters.loadViewIfNeeded()
        let table = try XCTUnwrap(filters.view.subviews.compactMap { $0 as? UITableView }.first)
        filters.tableView(table, didSelectRowAt: IndexPath(row: 2, section: 0))
        XCTAssertEqual(collection.numberOfSections, 1)
        picker.date = date.addingTimeInterval(86_400)
        picker.sendActions(for: .valueChanged)
        XCTAssertEqual(collection.numberOfSections, 0)
        XCTAssertFalse(button.isHidden, "Empty filter results must not hide the filter button")
        filters.onSelect?(.all)
        XCTAssertEqual(collection.numberOfSections, 1)
        filters.onSelect?(.today)
        XCTAssertTrue(Calendar.current.isDateInToday(picker.date))
        XCTAssertEqual(collection.numberOfSections, 1)
    }

    func testSearchEmptyLight() throws {
        let main = try makeMainScreen()
        let navigation = try XCTUnwrap(main.viewControllers?.first as? UINavigationController)
        let screen = try XCTUnwrap(navigation.topViewController as? TrackersViewController)
        let search = try XCTUnwrap(screen.navigationItem.searchController)
        search.searchBar.text = "QWERTY"
        screen.updateSearchResults(for: search)
        assertScreen(main, style: .light)
    }

    func testStatisticsScreenUpdatesAfterCompletionAndDeletion() throws {
        let viewModel = StatisticsViewModel(store: recordStore)
        let screen = StatisticsViewController(viewModel: viewModel)
        screen.loadViewIfNeeded()
        let card = try XCTUnwrap(screen.view.subviews.compactMap { $0 as? StatisticCardView }.first)
        XCTAssertTrue(card.isHidden)
        try addCompletedTracker()
        XCTAssertEqual(viewModel.completedCount, 1)
        XCTAssertFalse(card.isHidden)
        XCTAssertTrue(card.accessibilityLabel?.hasSuffix(": 1") == true)
        let tracker = try XCTUnwrap(categoryStore.categories.first?.trackers.first)
        try trackerStore.delete(id: tracker.id)
        XCTAssertEqual(viewModel.completedCount, 0)
        XCTAssertTrue(card.isHidden)
    }

    func testEmptyTrackersDark() throws {
        assertScreen(try makeMainScreen(), style: .dark)
    }

    func testCompletedTrackerDark() throws {
        try addCompletedTracker()
        assertScreen(try makeMainScreen(), style: .dark)
    }

    func testNewHabitDark() { assertScreen(makeHabitScreen(), style: .dark) }
    func testScheduleDark() { assertScreen(makeScheduleScreen(), style: .dark) }
    func testCategoriesDark() throws { assertScreen(try makeCategoriesScreen(), style: .dark) }
    func testTrackerTypeDark() {
        assertScreen(UINavigationController(rootViewController: TrackerTypeViewController(categoryStore: categoryStore)), style: .dark)
    }
    func testStatisticsDark() throws {
        let screen = try makeMainScreen()
        screen.selectedIndex = 1
        assertScreen(screen, style: .dark)
    }
    func testFilledStatisticsLight() throws {
        try addCompletedTracker()
        let screen = try makeMainScreen()
        screen.selectedIndex = 1
        assertScreen(screen, style: .light)
    }
    func testFilledStatisticsDark() throws {
        try addCompletedTracker()
        let screen = try makeMainScreen()
        screen.selectedIndex = 1
        assertScreen(screen, style: .dark)
    }
    func testFiltersLight() {
        assertScreen(UINavigationController(rootViewController: FiltersViewController(selectedFilter: .completed)), style: .light)
    }
    func testFiltersDark() {
        assertScreen(UINavigationController(rootViewController: FiltersViewController(selectedFilter: .completed)), style: .dark)
    }

    func testSearchKeepsCategorySections() throws {
        try addCompletedTracker()
        let second = Tracker(id: UUID(), title: "Зарядка вечером", color: .blue,
                             emoji: "🙂", schedule: Set(WeekDay.allCases))
        try trackerStore.add(second, categoryTitle: "Вечер")
        let main = try makeMainScreen()
        let nav = try XCTUnwrap(main.viewControllers?.first as? UINavigationController)
        let screen = try XCTUnwrap(nav.topViewController as? TrackersViewController)
        screen.navigationItem.searchController?.searchBar.text = "ЗАРЯДКА"
        screen.updateSearchResults(for: try XCTUnwrap(screen.navigationItem.searchController))
        let collection = try XCTUnwrap(screen.view.subviews.compactMap { $0 as? UICollectionView }.first)
        XCTAssertEqual(collection.numberOfSections, 2)
        XCTAssertEqual(collection.numberOfItems(inSection: 0), 1)
    }

    func testDeletingTrackerAlsoDeletesItsHistory() throws {
        try addCompletedTracker()
        let tracker = try XCTUnwrap(categoryStore.categories.first?.trackers.first)
        try trackerStore.delete(id: tracker.id)
        XCTAssertTrue(categoryStore.categories.flatMap(\.trackers).isEmpty)
        XCTAssertTrue(recordStore.records.isEmpty)
    }

    func testCompletionCannotBeDuplicatedWithinOneDay() throws {
        try addCompletedTracker()
        let record = try XCTUnwrap(recordStore.records.first)
        try recordStore.add(TrackerRecord(id: record.id, date: date.addingTimeInterval(60)))
        XCTAssertEqual(recordStore.records.count, 1)
    }

    func testCompletionButtonTogglesSelectedDateButRejectsFuture() throws {
        try addCompletedTracker()
        let main = try makeMainScreen()
        let navigation = try XCTUnwrap(main.viewControllers?.first as? UINavigationController)
        let screen = try XCTUnwrap(navigation.topViewController as? TrackersViewController)
        let picker = try XCTUnwrap(screen.navigationItem.rightBarButtonItem?.customView as? UIDatePicker)
        let collection = try XCTUnwrap(screen.view.subviews.compactMap { $0 as? UICollectionView }.first)
        func completionCell() throws -> TrackerCell {
            try XCTUnwrap(screen.collectionView(collection, cellForItemAt: IndexPath(item: 0, section: 0)) as? TrackerCell)
        }
        try completionCell().completionTapped?()
        XCTAssertTrue(recordStore.records.isEmpty)
        try completionCell().completionTapped?()
        XCTAssertEqual(recordStore.records.count, 1)
        XCTAssertTrue(Calendar.current.isDate(try XCTUnwrap(recordStore.records.first?.date), inSameDayAs: date))
        picker.date = Date().addingTimeInterval(172_800)
        picker.sendActions(for: .valueChanged)
        let futureCell = try completionCell()
        let button = try XCTUnwrap(futureCell.contentView.subviews.compactMap { $0 as? UIButton }.first)
        XCTAssertFalse(button.isEnabled)
        futureCell.completionTapped?()
        XCTAssertEqual(recordStore.records.count, 1)
    }

    func testFiltersCombineSearchScheduleAndCompletionDate() throws {
        try addCompletedTracker()
        let calendar = Calendar(identifier: .gregorian)
        let categories = categoryStore.categories
        let records = recordStore.records
        XCTAssertEqual(TrackerFiltering.categories(from: categories, records: records, date: date,
            query: "ЗАРЯДКА", filter: .completed).flatMap(\.trackers).count, 1)
        XCTAssertTrue(TrackerFiltering.categories(from: categories, records: records, date: date,
            filter: .incomplete).isEmpty)
        let tomorrow = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: date))
        XCTAssertTrue(TrackerFiltering.categories(from: categories, records: records, date: tomorrow,
            filter: .completed).isEmpty)
        XCTAssertEqual(TrackerFiltering.categories(from: categories, records: records, date: tomorrow,
            filter: .incomplete).flatMap(\.trackers).count, 1)
        let friday = Tracker(id: UUID(), title: "Пятница", color: .red, emoji: "🙂", schedule: [.friday])
        let event = Tracker(id: UUID(), title: "Событие", color: .red, emoji: "🙂", schedule: [])
        let result = TrackerFiltering.categories(from: [TrackerCategory(title: "Другое", trackers: [friday, event])],
            records: [], date: date, calendar: calendar)
        XCTAssertEqual(result.flatMap(\.trackers).map(\.id), [event.id])
    }

    func testStatisticsCountsAllHistoryButNotDuplicateRecords() {
        let id = UUID()
        let records = [TrackerRecord(id: id, date: date),
                       TrackerRecord(id: id, date: date.addingTimeInterval(60)),
                       TrackerRecord(id: UUID(), date: date),
                       TrackerRecord(id: id, date: date.addingTimeInterval(-86_400))]
        XCTAssertEqual(TrackerStatistics.completedCount(records: []), 0)
        XCTAssertEqual(TrackerStatistics.completedCount(records: records), 3)
    }

    func testAnalyticsPayloadIncludesItemOnlyForClicks() {
        var events: [(String, [String: String])] = []
        let service = AnalyticsService { events.append(($0, $1)) }
        service.report(.open)
        service.report(.close)
        AnalyticsEvent.Item.allCases.forEach { service.report(.click($0)) }
        XCTAssertEqual(events.count, 7)
        XCTAssertEqual(events[0].1, ["event": "open", "screen": "Main"])
        XCTAssertEqual(events[1].1, ["event": "close", "screen": "Main"])
        XCTAssertEqual(events.dropFirst(2).compactMap { $0.1["item"] },
                       ["add_track", "track", "filter", "edit", "delete"])
        XCTAssertTrue(events.allSatisfy { $0.0 == $0.1["event"] && $0.1["screen"] == "Main" })
    }

    func testEditAndPinPreserveIdentityHistoryAndOriginalCategory() throws {
        try addCompletedTracker()
        let original = try XCTUnwrap(categoryStore.categories.first?.trackers.first)
        try trackerStore.setPinned(true, id: original.id)
        let pinned = TrackerFiltering.categories(from: categoryStore.categories, records: recordStore.records, date: date)
        XCTAssertEqual(pinned.first?.trackers.first?.id, original.id)
        XCTAssertEqual(categoryStore.categories.first?.title, "Здоровье")
        try trackerStore.update(Tracker(id: original.id, title: "Обновлено", color: .blue,
            emoji: "❤️", schedule: [.thursday]), categoryTitle: "Другая")
        let edited = try XCTUnwrap(categoryStore.categories.flatMap(\.trackers).first)
        XCTAssertEqual(edited.title, "Обновлено")
        XCTAssertTrue(edited.isPinned)
        XCTAssertEqual(recordStore.records.map(\.id), [original.id])
        try trackerStore.setPinned(false, id: original.id)
        let regular = TrackerFiltering.categories(from: categoryStore.categories, records: recordStore.records, date: date)
        XCTAssertEqual(regular.first?.title, "Другая")
        XCTAssertFalse(try XCTUnwrap(regular.first?.trackers.first).isPinned)
    }

    func testExistingSQLiteMigratesAndKeepsDataAfterReopening() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("TrackerMigration-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("Tracker.sqlite")
        let oldModelURL = try XCTUnwrap(Bundle.main.url(forResource: "Tracker", withExtension: "mom", subdirectory: "Tracker.momd"))
        let oldModel = try XCTUnwrap(NSManagedObjectModel(contentsOf: oldModelURL))
        // Avoid registering a second model for the application's generated subclasses.
        oldModel.entities.forEach { $0.managedObjectClassName = "NSManagedObject" }
        let oldCoordinator = NSPersistentStoreCoordinator(managedObjectModel: oldModel)
        let oldStore = try oldCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url)
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = oldCoordinator
        let category = NSManagedObject(entity: try XCTUnwrap(oldModel.entitiesByName["TrackerCategoryCoreData"]), insertInto: context)
        category.setValue("Здоровье", forKey: "title")
        let tracker = NSManagedObject(entity: try XCTUnwrap(oldModel.entitiesByName["TrackerCoreData"]), insertInto: context)
        let id = UUID()
        tracker.setValue(id, forKey: "id")
        tracker.setValue("Старая привычка", forKey: "title")
        tracker.setValue("🙂", forKey: "emoji")
        tracker.setValue(UIColor.red, forKey: "color")
        tracker.setValue([WeekDay.thursday.rawValue], forKey: "schedule")
        tracker.setValue(category, forKey: "category")
        let record = NSManagedObject(entity: try XCTUnwrap(oldModel.entitiesByName["TrackerRecordCoreData"]), insertInto: context)
        record.setValue(id, forKey: "id")
        record.setValue(date, forKey: "date")
        try context.save()
        context.reset()
        try oldCoordinator.remove(oldStore)

        let migrated = NSPersistentContainer(name: "Tracker", managedObjectModel: container.managedObjectModel)
        let disk = try migrated.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
            configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true,
                                                     NSInferMappingModelAutomaticallyOption: true])
        let migratedCategories = TrackerCategoryStore(context: migrated.viewContext)
        XCTAssertEqual(migratedCategories.categories.first?.trackers.first?.id, id)
        XCTAssertEqual(migratedCategories.categories.first?.trackers.first?.isPinned, false)
        XCTAssertEqual(migratedCategories.categories.first?.title, "Здоровье")
        let restored = try XCTUnwrap(migratedCategories.categories.first?.trackers.first)
        XCTAssertEqual(restored.title, "Старая привычка")
        XCTAssertEqual(restored.emoji, "🙂")
        XCTAssertEqual(restored.schedule, [.thursday])
        XCTAssertEqual(restored.color, UIColor.red)
        try TrackerStore(context: migrated.viewContext).setPinned(true, id: id)
        migrated.viewContext.reset()
        try migrated.persistentStoreCoordinator.remove(disk)
        let reopened = NSPersistentContainer(name: "Tracker", managedObjectModel: container.managedObjectModel)
        let reopenedDisk = try reopened.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType,
            configurationName: nil, at: url)
        XCTAssertEqual(TrackerCategoryStore(context: reopened.viewContext).categories.first?.trackers.first?.isPinned, true)
        XCTAssertEqual(TrackerRecordStore(context: reopened.viewContext).records.map(\.id), [id])
        XCTAssertEqual(TrackerRecordStore(context: reopened.viewContext).records.first?.date, date)
        reopened.viewContext.reset()
        try reopened.persistentStoreCoordinator.remove(reopenedDisk)
    }

    func testCompletedTrackerLight() throws {
        try addCompletedTracker()
        assertScreen(try makeMainScreen(), style: .light)
    }

    func testNewHabitLight() {
        assertScreen(makeHabitScreen(), style: .light)
    }

    func testScheduleLight() {
        assertScreen(makeScheduleScreen(), style: .light)
    }

    func testCategoriesLight() throws {
        assertScreen(try makeCategoriesScreen(), style: .light)
    }

    func testTrackerTypeLight() {
        assertScreen(UINavigationController(
            rootViewController: TrackerTypeViewController(categoryStore: categoryStore)
        ), style: .light)
    }

    func testStatisticsLight() throws {
        let controller = try makeMainScreen()
        controller.selectedIndex = 1
        assertScreen(controller, style: .light)
    }

    // Catches the original bug: the primary button disappears against a dark background.
    func testPrimaryButtonChangesWithAppearance() throws {
        let controller = makeScheduleScreen()
        controller.loadViewIfNeeded()
        let schedule = try XCTUnwrap(controller.topViewController)
        schedule.loadViewIfNeeded()
        let button = try XCTUnwrap(schedule.view.subviews.compactMap { $0 as? UIButton }.first)
        let background = try XCTUnwrap(button.backgroundColor)
        let light = background.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = background.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
        XCTAssertNotEqual(light, dark)
        let title = try XCTUnwrap(button.titleColor(for: .normal))
        XCTAssertNotEqual(dark, title.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark)))
    }

    private func makeMainScreen() throws -> TabBarController {
        let controller = TabBarController(
            trackerStore: trackerStore, categoryStore: categoryStore, recordStore: recordStore
        )
        controller.loadViewIfNeeded()
        let navigation = try XCTUnwrap(controller.viewControllers?.first as? UINavigationController)
        let trackers = try XCTUnwrap(navigation.topViewController as? TrackersViewController)
        trackers.loadViewIfNeeded()
        let picker = try XCTUnwrap(trackers.navigationItem.rightBarButtonItem?.customView as? UIDatePicker)
        picker.locale = Locale(identifier: "ru_RU")
        picker.calendar = Calendar(identifier: .gregorian)
        picker.timeZone = TimeZone(secondsFromGMT: 0)
        picker.setDate(date, animated: false)
        picker.sendActions(for: .valueChanged)
        return controller
    }

    private func makeHabitScreen() -> UINavigationController {
        UINavigationController(rootViewController: NewTrackerViewController(
            mode: .habit, categoryStore: categoryStore
        ))
    }

    private func makeScheduleScreen() -> UINavigationController {
        UINavigationController(rootViewController: ScheduleViewController(
            selectedDays: [.monday, .wednesday, .friday]
        ))
    }

    private func makeCategoriesScreen() throws -> UINavigationController {
        try categoryStore.addCategory(title: "Здоровье")
        return UINavigationController(rootViewController: CategoryViewController(
            viewModel: CategoryViewModel(store: categoryStore, selectedTitle: "Здоровье")
        ))
    }

    private func addCompletedTracker() throws {
        let tracker = Tracker(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "Утренняя зарядка",
            color: TrackerPalette.colors[0],
            emoji: "🙂",
            schedule: Set(WeekDay.allCases)
        )
        try trackerStore.add(tracker, categoryTitle: "Здоровье")
        try recordStore.add(TrackerRecord(id: tracker.id, date: date))
    }

    private func assertScreen(
        _ controller: UIViewController,
        style: UIUserInterfaceStyle,
        file: StaticString = #filePath,
        testName: String = #function,
        line: UInt = #line
    ) {
        controller.overrideUserInterfaceStyle = style
        assertSnapshot(
            of: controller,
            as: .image(on: .iPhone13, traits: UITraitCollection {
                $0.userInterfaceStyle = style
                $0.preferredContentSizeCategory = .large
            }),
            file: file, testName: testName, line: line
        )
    }
}
