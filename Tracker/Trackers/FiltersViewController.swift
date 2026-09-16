import UIKit
import RswiftResources

final class FiltersViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var onSelect: ((TrackerFilter) -> Void)?
    private let selectedFilter: TrackerFilter
    private let tableView = UITableView(frame: .zero, style: .plain)

    init(selectedFilter: TrackerFilter) {
        self.selectedFilter = selectedFilter
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.localizable.filterTitle()
        view.backgroundColor = TrackerColors.background
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 75
        tableView.isScrollEnabled = false
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = TrackerColors.fieldBackground
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: 300)
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        TrackerFilter.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let filter = TrackerFilter.allCases[indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.text = filter.title
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.backgroundColor = TrackerColors.fieldBackground
        cell.tintColor = TrackerColors.blue
        cell.accessoryType = filter.isActive && filter == selectedFilter ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onSelect?(TrackerFilter.allCases[indexPath.row])
        dismiss(animated: true)
    }
}
