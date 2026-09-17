import AppMetricaCore
import Foundation

enum AnalyticsEvent {
    enum Item: String, CaseIterable {
        case addTrack = "add_track"
        case track, filter, edit, delete
    }

    case open, close, click(Item)

    var name: String {
        switch self {
        case .open: "open"
        case .close: "close"
        case .click: "click"
        }
    }

    var parameters: [String: String] {
        var result = ["event": name, "screen": "Main"]
        if case let .click(item) = self { result["item"] = item.rawValue }
        return result
    }
}

protocol AnalyticsReporting {
    func report(_ event: AnalyticsEvent)
}

struct AnalyticsService: AnalyticsReporting {
    static let shared = AnalyticsService { name, parameters in
        guard isActivated else { return }
        AppMetrica.reportEvent(name: name, parameters: parameters) { error in
            NSLog("AppMetrica event delivery error: %@", error.localizedDescription)
        }
    }
    private static var isActivated = false
    private let send: (String, [String: String]) -> Void

    init(send: @escaping (String, [String: String]) -> Void) {
        self.send = send
    }

    /// Call once at application launch. Unit tests must never send real analytics.
    static func activate() {
        guard !isActivated,
              ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        let fileURL = Bundle.main.url(forResource: "AnalyticsKeys", withExtension: "plist")
        let data = fileURL.flatMap { try? Data(contentsOf: $0) }
        let keys = data.flatMap { try? PropertyListSerialization.propertyList(from: $0, format: nil) as? [String: String] }
        let key = ProcessInfo.processInfo.environment["APPMETRICA_API_KEY"] ?? keys?["APIKey"] ?? ""
        guard UUID(uuidString: key) != nil, let configuration = AppMetricaConfiguration(apiKey: key) else {
            NSLog("AppMetrica is not configured. Add AnalyticsKeys.plist with the application's APIKey.")
            return
        }
        configuration.locationTracking = false
        AppMetrica.activate(with: configuration)
        isActivated = true
    }

    func report(_ event: AnalyticsEvent) {
        #if DEBUG
        NSLog("Analytics %@: %@", event.name, event.parameters.description)
        #endif
        send(event.name, event.parameters)
    }
}
