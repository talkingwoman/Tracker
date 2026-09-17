import CoreData

protocol TrackerRecordStoreDelegate: AnyObject {
    func trackerRecordStoreDidUpdate(_ store: TrackerRecordStore)
}

protocol TrackerRecordStoreProtocol: AnyObject {
    var records: [TrackerRecord] { get }
    var onChange: (() -> Void)? { get set }
}

final class TrackerRecordStore: NSObject, TrackerRecordStoreProtocol {
    weak var delegate: TrackerRecordStoreDelegate?
    var onChange: (() -> Void)?

    var records: [TrackerRecord] {
        fetchedResultsController.fetchedObjects?.compactMap { object in
            guard let id = object.id, let date = object.date else { return nil }
            return TrackerRecord(id: id, date: date)
        } ?? []
    }

    private let context: NSManagedObjectContext

    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData> = {
        let request: NSFetchRequest<TrackerRecordCoreData> = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
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
            assertionFailure("Не удалось загрузить записи: \(error)")
        }
    }

    func add(_ record: TrackerRecord) throws {
        guard !records.contains(where: {
            $0.id == record.id && Calendar.current.isDate($0.date, inSameDayAs: record.date)
        }) else { return }
        let object = TrackerRecordCoreData(context: context)
        object.id = record.id
        object.date = Calendar.current.startOfDay(for: record.date)
        try context.save()
    }

    func delete(trackerID: UUID, date: Date) throws {
        let day = Calendar.current.startOfDay(for: date)
        guard let object = fetchedResultsController.fetchedObjects?.first(where: {
            $0.id == trackerID && $0.date.map { Calendar.current.isDate($0, inSameDayAs: day) } == true
        }) else { return }

        context.delete(object)
        try context.save()
    }
}

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    ) {
        delegate?.trackerRecordStoreDidUpdate(self)
        onChange?()
    }
}
