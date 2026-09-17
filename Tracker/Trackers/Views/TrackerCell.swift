//
//  TrackerCell.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import UIKit
import RswiftResources

final class TrackerCell: UICollectionViewCell {
    static let reuseIdentifier = "TrackerCell"

    var completionTapped: (() -> Void)?

    private let cardView = UIView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let pinImageView = UIImageView(image: TrackerImages.pinned)
    private let daysLabel = UILabel()
    private let completionButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        completionTapped = nil
    }

    func configure(with tracker: Tracker, isCompleted: Bool, completedDays: Int, completionEnabled: Bool) {
        cardView.backgroundColor = tracker.color
        emojiLabel.text = tracker.emoji
        titleLabel.text = tracker.title
        pinImageView.isHidden = !tracker.isPinned
        daysLabel.text = daysText(completedDays)
        completionButton.setImage(isCompleted ? TrackerImages.completed : TrackerImages.add, for: .normal)
        completionButton.backgroundColor = isCompleted ? tracker.color.withAlphaComponent(0.3) : tracker.color
        completionButton.accessibilityLabel = isCompleted
            ? R.string.localizable.trackerUndo()
            : R.string.localizable.trackerComplete()
        completionButton.isEnabled = completionEnabled
        completionButton.alpha = completionEnabled ? 1 : 0.3
    }

    private func setupViews() {
        cardView.layer.cornerRadius = 16
        cardView.translatesAutoresizingMaskIntoConstraints = false

        emojiLabel.font = .systemFont(ofSize: 16)
        emojiLabel.textAlignment = .center
        emojiLabel.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        emojiLabel.layer.cornerRadius = 12
        emojiLabel.clipsToBounds = true
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        pinImageView.tintColor = .white
        pinImageView.contentMode = .scaleAspectFit
        pinImageView.translatesAutoresizingMaskIntoConstraints = false

        daysLabel.font = .systemFont(ofSize: 12, weight: .medium)
        daysLabel.adjustsFontSizeToFitWidth = true
        daysLabel.minimumScaleFactor = 0.75
        daysLabel.translatesAutoresizingMaskIntoConstraints = false

        completionButton.tintColor = TrackerColors.background
        completionButton.layer.cornerRadius = 17
        completionButton.addTarget(self, action: #selector(completionButtonTapped), for: .touchUpInside)
        completionButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(emojiLabel)
        cardView.addSubview(titleLabel)
        cardView.addSubview(pinImageView)
        contentView.addSubview(daysLabel)
        contentView.addSubview(completionButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.heightAnchor.constraint(equalToConstant: 90),
            emojiLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 12),
            emojiLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            emojiLabel.widthAnchor.constraint(equalToConstant: 24),
            emojiLabel.heightAnchor.constraint(equalToConstant: 24),
            pinImageView.centerYAnchor.constraint(equalTo: emojiLabel.centerYAnchor),
            pinImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            pinImageView.widthAnchor.constraint(equalToConstant: 12),
            pinImageView.heightAnchor.constraint(equalToConstant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            daysLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            daysLabel.centerYAnchor.constraint(equalTo: completionButton.centerYAnchor),
            daysLabel.trailingAnchor.constraint(lessThanOrEqualTo: completionButton.leadingAnchor, constant: -8),
            completionButton.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 8),
            completionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            completionButton.widthAnchor.constraint(equalToConstant: 34),
            completionButton.heightAnchor.constraint(equalToConstant: 34)
        ])
    }

    @objc private func completionButtonTapped() {
        completionTapped?()
    }

    private func daysText(_ count: Int) -> String {
        R.string.localizable.trackerDays_count(days: count)
    }
}
