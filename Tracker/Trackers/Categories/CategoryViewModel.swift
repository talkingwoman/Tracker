import Foundation

struct CategoryCellViewModel: Equatable {
    let title: String
    let isSelected: Bool
}

final class CategoryViewModel {
    var onCategoriesChanged: (() -> Void)?
    var onCategorySelected: ((String) -> Void)?
    var onError: ((String) -> Void)?

    private(set) var cellViewModels: [CategoryCellViewModel] = []
    private let store: TrackerCategoryStoreProtocol
    private var selectedTitle: String?

    init(store: TrackerCategoryStoreProtocol, selectedTitle: String?) {
        self.store = store
        self.selectedTitle = selectedTitle
        self.store.onChange = { [weak self] in self?.reload() }
        updateCellViewModels()
    }

    func reload() {
        updateCellViewModels()
        onCategoriesChanged?()
    }

    private func updateCellViewModels() {
        cellViewModels = store.categories.map {
            CategoryCellViewModel(title: $0.title, isSelected: $0.title == selectedTitle)
        }
    }

    func selectCategory(at index: Int) {
        guard cellViewModels.indices.contains(index) else { return }
        selectedTitle = cellViewModels[index].title
        reload()
        onCategorySelected?(cellViewModels[index].title)
    }

    func addCategory(title: String) -> Bool {
        do {
            try store.addCategory(title: title)
            reload()
            return true
        } catch {
            onError?((error as? LocalizedError)?.errorDescription ?? "Не удалось сохранить категорию")
            return false
        }
    }
}
