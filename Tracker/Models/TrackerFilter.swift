import Foundation
import RswiftResources

enum TrackerFilter: Int, CaseIterable {
    case all, today, completed, incomplete

    var isActive: Bool { self == .completed || self == .incomplete }

    var title: String {
        switch self {
        case .all: R.string.localizable.filterAll()
        case .today: R.string.localizable.filterToday()
        case .completed: R.string.localizable.filterCompleted()
        case .incomplete: R.string.localizable.filterIncomplete()
        }
    }
}

enum TrackerFiltering {
    static func categories(
        from categories: [TrackerCategory], records: [TrackerRecord], date: Date,
        query: String = "", filter: TrackerFilter = .all, calendar: Calendar = .current
    ) -> [TrackerCategory] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let weekday = WeekDay(rawValue: (calendar.component(.weekday, from: date) + 5) % 7) else {
            return []
        }
        let completedIDs = Set(records.filter { calendar.isDate($0.date, inSameDayAs: date) }.map(\.id))
        var pinned: [Tracker] = []
        var visible = categories.compactMap { category -> TrackerCategory? in
            let trackers = category.trackers.filter { tracker in
                let scheduled = tracker.schedule.isEmpty || tracker.schedule.contains(weekday)
                let matchesQuery = query.isEmpty || tracker.title.localizedCaseInsensitiveContains(query)
                let completed = completedIDs.contains(tracker.id)
                let matchesFilter = !filter.isActive || (filter == .completed ? completed : !completed)
                return scheduled && matchesQuery && matchesFilter
            }
            pinned.append(contentsOf: trackers.filter(\.isPinned))
            let regular = trackers.filter { !$0.isPinned }
            return regular.isEmpty ? nil : TrackerCategory(title: category.title, trackers: regular)
        }
        if !pinned.isEmpty {
            visible.insert(TrackerCategory(
                title: R.string.localizable.trackerPinned(), trackers: pinned
            ), at: 0)
        }
        return visible
    }
}
