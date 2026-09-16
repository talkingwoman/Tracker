//
//  OptionsSectionHeader.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import UIKit

final class OptionsSectionHeader: UICollectionReusableView {
    static let reuseIdentifier = "OptionsSectionHeader"

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 19, weight: .bold)
        label.textColor = TrackerColors.primary
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(title: String) {
        titleLabel.text = title
    }
}
