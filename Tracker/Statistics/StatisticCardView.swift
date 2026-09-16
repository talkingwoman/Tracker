import UIKit
import RswiftResources

final class StatisticCardView: UIView {
    private let valueLabel = UILabel()
    private let titleLabel = UILabel()
    private let gradient = CAGradientLayer()
    private let borderMask = CAShapeLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradient.colors = [UIColor(red: 253/255, green: 76/255, blue: 73/255, alpha: 1).cgColor,
                           UIColor(red: 70/255, green: 230/255, blue: 157/255, alpha: 1).cgColor,
                           UIColor(red: 0, green: 123/255, blue: 250/255, alpha: 1).cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        borderMask.lineWidth = 1
        borderMask.fillColor = UIColor.clear.cgColor
        borderMask.strokeColor = UIColor.black.cgColor
        gradient.mask = borderMask
        layer.addSublayer(gradient)
        valueLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.text = R.string.localizable.statisticsCompleted()
        titleLabel.numberOfLines = 0
        [valueLabel, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        NSLayoutConstraint.activate([
            valueLabel.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 7),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12)
        ])
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        borderMask.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), cornerRadius: 16).cgPath
    }

    func configure(count: Int) {
        valueLabel.text = count.formatted()
        accessibilityLabel = "\(titleLabel.text ?? ""): \(valueLabel.text ?? "")"
    }
}
