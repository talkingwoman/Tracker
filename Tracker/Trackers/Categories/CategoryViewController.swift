import UIKit
import RswiftResources

final class CategoryViewController: UIViewController {
    private let viewModel: CategoryViewModel

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyImageView = UIImageView(image: UIImage(resource: .trackerPlaceholder))
    private let emptyLabel = UILabel()
    private let addButton = UIButton(type: .system)

    init(viewModel: CategoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.localizable.categoryTitle()
        view.backgroundColor = TrackerColors.background
        configureViews()
        bindViewModel()
        viewModel.reload()
    }

    private func configureViews() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(CategoryCell.self, forCellReuseIdentifier: CategoryCell.reuseIdentifier)
        tableView.rowHeight = 75
        tableView.backgroundColor = .clear
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.translatesAutoresizingMaskIntoConstraints = false

        emptyImageView.contentMode = .scaleAspectFit
        emptyImageView.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.text = R.string.localizable.categoryEmpty()
        emptyLabel.font = .systemFont(ofSize: 12, weight: .medium)
        emptyLabel.numberOfLines = 2
        emptyLabel.textAlignment = .center
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        addButton.setTitle(R.string.localizable.categoryAdd(), for: .normal)
        addButton.setTitleColor(TrackerColors.background, for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        addButton.backgroundColor = TrackerColors.primary
        addButton.layer.cornerRadius = 16
        addButton.addTarget(self, action: #selector(addCategoryTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false

        [tableView, emptyImageView, emptyLabel, addButton].forEach(view.addSubview)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -24),
            emptyImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            emptyImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyImageView.heightAnchor.constraint(equalToConstant: 80),
            emptyLabel.topAnchor.constraint(equalTo: emptyImageView.bottomAnchor, constant: 8),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            addButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func bindViewModel() {
        viewModel.onCategoriesChanged = { [weak self] in self?.updateContent() }
        viewModel.onError = { [weak self] message in
            let alert = UIAlertController(title: R.string.localizable.commonError(), message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: R.string.localizable.commonOk(), style: .default))
            self?.present(alert, animated: true)
        }
    }

    private func updateContent() {
        let isEmpty = viewModel.cellViewModels.isEmpty
        tableView.isHidden = isEmpty
        emptyImageView.isHidden = !isEmpty
        emptyLabel.isHidden = !isEmpty
        tableView.reloadData()
    }

    @objc private func addCategoryTapped() {
        navigationController?.pushViewController(NewCategoryViewController(viewModel: viewModel), animated: true)
    }
}

extension CategoryViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.cellViewModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: CategoryCell.reuseIdentifier,
            for: indexPath
        ) as? CategoryCell else { return UITableViewCell() }
        cell.configure(with: viewModel.cellViewModels[indexPath.row])
        var corners: CACornerMask = []
        if indexPath.row == 0 { corners.formUnion([.layerMinXMinYCorner, .layerMaxXMinYCorner]) }
        if indexPath.row == viewModel.cellViewModels.count - 1 {
            corners.formUnion([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
        }
        cell.layer.cornerRadius = 16
        cell.layer.maskedCorners = corners
        cell.clipsToBounds = true
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectCategory(at: indexPath.row)
    }
}
