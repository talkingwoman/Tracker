//
//  ColorCell.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import UIKit

final class ColorCell: UICollectionViewCell {
    static let reuseIdentifier = "ColorCell"

    private let colorView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 8
        contentView.layer.borderWidth = 3
        contentView.addSubview(colorView)
        NSLayoutConstraint.activate([
            colorView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            colorView.widthAnchor.constraint(equalToConstant: 40),
            colorView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    required init?(coder: NSCoder) {
        nil
    }

    func configure(color: UIColor, isSelected: Bool) {
        colorView.backgroundColor = color
        contentView.layer.borderColor = isSelected
            ? color.withAlphaComponent(0.3).cgColor
            : UIColor.clear.cgColor
        accessibilityLabel = "Цвет трекера"
        accessibilityTraits = isSelected ? [.button, .selected] : .button
    }
}
