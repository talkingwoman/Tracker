import Foundation

enum TrackerStatistics {
    private struct Completion: Hashable {
        let trackerID: UUID
        let day: Date
    }

    static func completedCount(records: [TrackerRecord], calendar: Calendar = .current) -> Int {
        Set(records.map { Completion(trackerID: $0.id, day: calendar.startOfDay(for: $0.date)) }).count
    }
}
