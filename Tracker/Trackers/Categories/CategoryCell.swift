import UIKit

final class CategoryCell: UITableViewCell {
    static let reuseIdentifier = "CategoryCell"

    func configure(with viewModel: CategoryCellViewModel) {
        var configuration = defaultContentConfiguration()
        configuration.text = viewModel.title
        configuration.textProperties.font = .systemFont(ofSize: 17)
        contentConfiguration = configuration
        accessoryType = viewModel.isSelected ? .checkmark : .none
        tintColor = TrackerColors.blue
        backgroundColor = TrackerColors.fieldBackground
    }
}
