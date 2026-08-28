//
//  TrackerCell.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import UIKit

final class TrackerCell: UICollectionViewCell {
    static let reuseIdentifier = "TrackerCell"

    var completionTapped: (() -> Void)?

    private let cardView = UIView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
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
        daysLabel.text = daysText(completedDays)
        completionButton.setImage(UIImage(systemName: isCompleted ? "checkmark" : "plus"), for: .normal)
        completionButton.backgroundColor = isCompleted ? tracker.color.withAlphaComponent(0.3) : tracker.color
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

        daysLabel.font = .systemFont(ofSize: 12, weight: .medium)
        daysLabel.translatesAutoresizingMaskIntoConstraints = false

        completionButton.tintColor = .white
        completionButton.layer.cornerRadius = 17
        completionButton.addTarget(self, action: #selector(completionButtonTapped), for: .touchUpInside)
        completionButton.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)
        cardView.addSubview(emojiLabel)
        cardView.addSubview(titleLabel)
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
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -12),
            daysLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            daysLabel.centerYAnchor.constraint(equalTo: completionButton.centerYAnchor),
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
        let mod100 = count % 100
        let mod10 = count % 10
        let ending: String

        if 11...14 ~= mod100 {
            ending = "дней"
        } else if mod10 == 1 {
            ending = "день"
        } else if 2...4 ~= mod10 {
            ending = "дня"
        } else {
            ending = "дней"
        }
        return "\(count) \(ending)"
    }
}
