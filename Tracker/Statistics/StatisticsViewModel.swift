import Foundation

final class StatisticsViewModel {
    var onChange: ((Int) -> Void)?
    var completedCount: Int { TrackerStatistics.completedCount(records: store.records) }
    private let store: TrackerRecordStoreProtocol

    init(store: TrackerRecordStoreProtocol) {
        self.store = store
        store.onChange = { [weak self] in
            guard let self else { return }
            self.onChange?(self.completedCount)
        }
    }
}
