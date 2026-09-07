//
//  AppDelegate.swift
//  Tracker
//
//  Created by Victoria Soboleva on 19.07.2026.
//

import UIKit
import CoreData

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        return true
    }

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

    func saveContext() {
        let context = persistentContainer.viewContext

        guard context.hasChanges else {
            return
        }

        do {
            try context.save()
        } catch {
            assertionFailure("Не удалось сохранить Core Data: \(error)")
        }
    }

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

    // MARK: - UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) { }
}
