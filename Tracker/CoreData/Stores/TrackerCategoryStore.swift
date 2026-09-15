import CoreData
import UIKit

protocol TrackerCategoryStoreDelegate: AnyObject {
    func trackerCategoryStoreDidUpdate(_ store: TrackerCategoryStore)
}

protocol TrackerCategoryStoreProtocol: AnyObject {
    var categories: [TrackerCategory] { get }
    var onChange: (() -> Void)? { get set }
    func addCategory(title: String) throws
}

enum TrackerCategoryStoreError: Error {
    case emptyTitle
    case duplicateTitle

    var message: String {
        switch self {
        case .emptyTitle: "Введите название категории"
        case .duplicateTitle: "Категория с таким названием уже существует"
        }
    }
}

final class TrackerCategoryStore: NSObject {
    weak var delegate: TrackerCategoryStoreDelegate?
    var onChange: (() -> Void)?

    var categories: [TrackerCategory] {
        fetchedResultsController.fetchedObjects?.map(makeCategory) ?? []
    }

    private let context: NSManagedObjectContext

    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData> = {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        let controller = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        controller.delegate = self
        return controller
    }()

    init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        do {
            try fetchedResultsController.performFetch()
        } catch {
            assertionFailure("Не удалось загрузить категории: \(error)")
        }
    }

    func addCategory(title: String) throws {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTitle.isEmpty else { throw TrackerCategoryStoreError.emptyTitle }

        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title ==[c] %@", normalizedTitle)
        request.fetchLimit = 1
        guard try context.count(for: request) == 0 else {
            throw TrackerCategoryStoreError.duplicateTitle
        }

        let object = TrackerCategoryCoreData(context: context)
        object.title = normalizedTitle
        try context.save()
    }

    private func makeCategory(from object: TrackerCategoryCoreData) -> TrackerCategory {
        let objects = (object.value(forKey: "trackers") as? NSSet)?.allObjects ?? []
        let trackers = objects.compactMap { $0 as? TrackerCoreData }.compactMap(makeTracker)
        return TrackerCategory(title: object.title ?? "", trackers: trackers)
    }

    private func makeTracker(from object: TrackerCoreData) -> Tracker? {
        guard
            let id = object.id,
            let title = object.title,
            let emoji = object.emoji,
            let color = object.value(forKey: "color") as? UIColor
        else { return nil }

        let rawDays = object.value(forKey: "schedule") as? [Int] ?? []
        let schedule = Set(rawDays.compactMap(WeekDay.init(rawValue:)))
        return Tracker(id: id, title: title, color: color, emoji: emoji, schedule: schedule)
    }
}

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        delegate?.trackerCategoryStoreDidUpdate(self)
        onChange?()
    }
}

extension TrackerCategoryStore: TrackerCategoryStoreProtocol { }
