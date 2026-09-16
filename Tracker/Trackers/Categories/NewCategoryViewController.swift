import UIKit
import RswiftResources

final class NewCategoryViewController: UIViewController {
    private let viewModel: CategoryViewModel
    private let textField = UITextField()
    private let doneButton = UIButton(type: .system)

    init(viewModel: CategoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) не поддерживается") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = R.string.localizable.categoryNew()
        view.backgroundColor = TrackerColors.background
        configureViews()
        updateButton()
    }

    private func configureViews() {
        textField.placeholder = R.string.localizable.categoryNamePlaceholder()
        textField.backgroundColor = TrackerColors.fieldBackground
        textField.layer.cornerRadius = 16
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        // UITextField mirrors its accessory views automatically in RTL languages.
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.textAlignment = .natural
        textField.adjustsFontSizeToFitWidth = true
        textField.minimumFontSize = 12
        textField.clearButtonMode = .whileEditing
        textField.delegate = self
        textField.addTarget(self, action: #selector(updateButton), for: .editingChanged)
        textField.translatesAutoresizingMaskIntoConstraints = false

        doneButton.setTitle(R.string.localizable.commonDone(), for: .normal)
        doneButton.setTitleColor(TrackerColors.background, for: .normal)
        doneButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        doneButton.layer.cornerRadius = 16
        doneButton.addTarget(self, action: #selector(doneTapped), for: .touchUpInside)
        doneButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(textField)
        view.addSubview(doneButton)
        NSLayoutConstraint.activate([
            textField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textField.heightAnchor.constraint(equalToConstant: 75),
            doneButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            doneButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            doneButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            doneButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }

    @objc private func updateButton() {
        let title = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        doneButton.isEnabled = !title.isEmpty
        doneButton.backgroundColor = title.isEmpty ? TrackerColors.gray : TrackerColors.primary
        doneButton.setTitleColor(title.isEmpty ? .white : TrackerColors.background, for: .normal)
    }

    @objc private func doneTapped() {
        let title = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if viewModel.addCategory(title: title) {
            navigationController?.popViewController(animated: true)
        }
    }
}

extension NewCategoryViewController: UITextFieldDelegate {
    func textField(
        _ textField: UITextField,
        shouldChangeCharactersIn range: NSRange,
        replacementString string: String
    ) -> Bool {
        guard let currentText = textField.text,
              let textRange = Range(range, in: currentText) else { return true }
        return currentText.replacingCharacters(in: textRange, with: string).count
            <= TrackerConstants.maximumNameLength
    }
}
