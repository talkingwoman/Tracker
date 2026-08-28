//
//  NewTrackerViewController.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import UIKit

final class NewTrackerViewController: UIViewController {
    weak var delegate: NewTrackerViewControllerDelegate?

    private let mode: TrackerCreationMode
    private var schedule: Set<WeekDay> = []
    private let nameField = UITextField()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let createButton = UIButton(type: .system)
    private var nameErrorHeightConstraint: NSLayoutConstraint?
    private let nameErrorLabel: UILabel = {
        let label = UILabel()
        label.text = "Ограничение 38 символов"
        label.textColor = TrackerColors.red
        label.font = .systemFont(ofSize: 17)
        label.textAlignment = .center
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(mode: TrackerCreationMode) {
        self.mode = mode
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = mode.navigationTitle
        navigationItem.hidesBackButton = true
        view.backgroundColor = .systemBackground
        configureNavigationBar()
        setupViews()
        setupConstraints()
        updateCreateButton()
    }

    // MARK: - Private Methods

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = .clear
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
    }

    private func setupViews() {
        nameField.placeholder = "Введите название трекера"
        nameField.backgroundColor = TrackerColors.fieldBackground
        nameField.layer.cornerRadius = 16
        nameField.clearButtonMode = .whileEditing
        nameField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        nameField.leftViewMode = .always
        nameField.delegate = self
        nameField.addTarget(self, action: #selector(updateCreateButton), for: .editingChanged)
        nameField.translatesAutoresizingMaskIntoConstraints = false

        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
        tableView.rowHeight = 75
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.tableFooterView = UIView()
        tableView.layer.cornerRadius = 16
        tableView.clipsToBounds = true
        tableView.translatesAutoresizingMaskIntoConstraints = false

        let cancelButton = makeButton(title: "Отменить", foreground: TrackerColors.red, background: .systemBackground)
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = TrackerColors.red.cgColor
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)

        createButton.setTitle("Создать", for: .normal)
        createButton.setTitleColor(.white, for: .normal)
        createButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        createButton.layer.cornerRadius = 16
        createButton.translatesAutoresizingMaskIntoConstraints = false
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)

        [nameField, nameErrorLabel, tableView, cancelButton, createButton].forEach(view.addSubview)
        setupConstraints(cancelButton: cancelButton)
    }

    private func setupConstraints() {
        nameErrorHeightConstraint = nameErrorLabel.heightAnchor.constraint(equalToConstant: 0)
        nameErrorHeightConstraint?.isActive = true
    }

    private func setupConstraints(cancelButton: UIButton) {
        NSLayoutConstraint.activate([
            nameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            nameField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            nameField.heightAnchor.constraint(equalToConstant: 75),
            nameErrorLabel.topAnchor.constraint(equalTo: nameField.bottomAnchor),
            nameErrorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            nameErrorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: nameErrorLabel.bottomAnchor, constant: 24),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.heightAnchor.constraint(equalToConstant: mode == .habit ? 150 : 75),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 60),
            createButton.leadingAnchor.constraint(equalTo: cancelButton.trailingAnchor, constant: 8),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            createButton.bottomAnchor.constraint(equalTo: cancelButton.bottomAnchor),
            createButton.heightAnchor.constraint(equalTo: cancelButton.heightAnchor),
            createButton.widthAnchor.constraint(equalTo: cancelButton.widthAnchor)
        ])
    }

    private func makeButton(title: String, foreground: UIColor, background: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.setTitleColor(foreground, for: .normal)
        button.backgroundColor = background
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func createTapped() {
        let title = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !title.isEmpty, mode == .irregularEvent || !schedule.isEmpty else { return }
        delegate?.didCreateTracker(title: title, schedule: schedule, from: self)
    }

    @objc private func updateCreateButton() {
        let title = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        createButton.isEnabled = !title.isEmpty && (mode == .irregularEvent || !schedule.isEmpty)
        createButton.backgroundColor = createButton.isEnabled ? TrackerColors.black : TrackerColors.gray
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension NewTrackerViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        mode == .habit ? 2 : 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = indexPath.row == 0 ? "Категория" : "Расписание"
        if indexPath.row == 1, !schedule.isEmpty {
            cell.detailTextLabel?.text = schedule.count == 7
                ? "Каждый день"
                : schedule.sorted { $0.rawValue < $1.rawValue }.map(\.shortTitle).joined(separator: ", ")
        }
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = TrackerColors.fieldBackground
        cell.textLabel?.font = .systemFont(ofSize: 17)
        cell.detailTextLabel?.font = .systemFont(ofSize: 17)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row == 1 else { return }
        let controller = ScheduleViewController(selectedDays: schedule)
        controller.delegate = self
        navigationController?.pushViewController(controller, animated: true)
    }
}

// MARK: - UITextFieldDelegate

extension NewTrackerViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let currentText = textField.text,
              let textRange = Range(range, in: currentText) else { return true }
        let updatedText = currentText.replacingCharacters(in: textRange, with: string)
        let isWithinLimit = updatedText.count <= 38
        nameErrorLabel.isHidden = isWithinLimit
        nameErrorHeightConstraint?.constant = isWithinLimit ? 0 : 22
        return isWithinLimit
    }
}

// MARK: - ScheduleViewControllerDelegate

extension NewTrackerViewController: ScheduleViewControllerDelegate {
    func didChooseSchedule(_ schedule: Set<WeekDay>) {
        self.schedule = schedule
        tableView.reloadData()
        updateCreateButton()
        navigationController?.popViewController(animated: true)
    }
}
