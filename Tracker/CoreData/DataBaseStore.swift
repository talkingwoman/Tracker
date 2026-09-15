import CoreData

final class DataBaseStore {
    static let shared = DataBaseStore()

    lazy var persistentContainer: NSPersistentContainer = {
        TrackerValueTransformers.register()
        let container = NSPersistentContainer(name: "Tracker")

        if let description = container.persistentStoreDescriptions.first,
           let applicationSupportURL = FileManager.default.urls(
               for: .applicationSupportDirectory,
               in: .userDomainMask
           ).first {
            description.url = applicationSupportURL.appendingPathComponent("TrackerSprint15.sqlite")
        }

        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Не удалось загрузить Core Data: \(error)")
            }
        }

        return container
    }()

    private init() { }

    func makeStores() -> (
        trackerStore: TrackerStore,
        categoryStore: TrackerCategoryStore,
        recordStore: TrackerRecordStore
    ) {
        let context = persistentContainer.viewContext
        return (
            TrackerStore(context: context),
            TrackerCategoryStore(context: context),
            TrackerRecordStore(context: context)
        )
    }

    func saveContext() {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            assertionFailure("Не удалось сохранить Core Data: \(error)")
        }
    }
}
