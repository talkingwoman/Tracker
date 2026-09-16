import CoreData
import UIKit

protocol TrackerStoreDelegate: AnyObject {
    func trackerStoreDidUpdate(_ store: TrackerStore)
}

final class TrackerStore: NSObject {
    weak var delegate: TrackerStoreDelegate?

    private let context: NSManagedObjectContext

    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCoreData> = {
        let request: NSFetchRequest<TrackerCoreData> = TrackerCoreData.fetchRequest()
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
            assertionFailure("Не удалось загрузить трекеры: \(error)")
        }
    }

    func add(_ tracker: Tracker, categoryTitle: String) throws {
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", categoryTitle)
        request.fetchLimit = 1

        let category = try context.fetch(request).first ?? TrackerCategoryCoreData(context: context)
        category.title = categoryTitle

        let object = TrackerCoreData(context: context)
        object.id = tracker.id
        object.title = tracker.title
        object.emoji = tracker.emoji
        object.category = category
        object.setValue(tracker.color, forKey: "color")
        object.setValue(tracker.schedule.map(\.rawValue), forKey: "schedule")
        try context.save()
    }

    func delete(id: UUID) throws {
        guard let object = fetchedResultsController.fetchedObjects?.first(where: { $0.id == id }) else {
            return
        }
        // Records store the tracker UUID rather than a relationship: delete them in
        // the same transaction so statistics cannot retain orphaned completions.
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        try context.fetch(request).forEach(context.delete)
        context.delete(object)
        try context.save()
    }

    func update(_ tracker: Tracker, categoryTitle: String) throws {
        guard let object = fetchedResultsController.fetchedObjects?.first(where: { $0.id == tracker.id }) else {
            return
        }
        let request: NSFetchRequest<TrackerCategoryCoreData> = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", categoryTitle)
        request.fetchLimit = 1
        let category = try context.fetch(request).first ?? TrackerCategoryCoreData(context: context)
        category.title = categoryTitle
        object.title = tracker.title
        object.emoji = tracker.emoji
        object.category = category
        object.setValue(tracker.color, forKey: "color")
        object.setValue(tracker.schedule.map(\.rawValue), forKey: "schedule")
        try context.save()
    }

    func setPinned(_ isPinned: Bool, id: UUID) throws {
        guard let object = fetchedResultsController.fetchedObjects?.first(where: { $0.id == id }) else { return }
        object.isPinned = isPinned
        try context.save()
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        delegate?.trackerStoreDidUpdate(self)
    }
}
