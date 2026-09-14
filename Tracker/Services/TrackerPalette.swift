//
//  TrackerPalette.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import UIKit

enum TrackerPalette {
    static let emojis = [
        "🙂", "😻", "🌺", "🐶", "❤️", "😱",
        "😇", "😡", "🥶", "🤔", "🙌", "🍔",
        "🥦", "🏓", "🥇", "🎸", "🏝", "😪"
    ]

    static let colors = [
        UIColor(hex: 0xFD4C49), UIColor(hex: 0xFF881E), UIColor(hex: 0x007BFA),
        UIColor(hex: 0x6E44FE), UIColor(hex: 0x33CF69), UIColor(hex: 0xE66DD4),
        UIColor(hex: 0xF9D4D4), UIColor(hex: 0x34A7FE), UIColor(hex: 0x46E69D),
        UIColor(hex: 0x35347C), UIColor(hex: 0xFF674D), UIColor(hex: 0xFF99CC),
        UIColor(hex: 0xF6C48B), UIColor(hex: 0x7994F5), UIColor(hex: 0x832CF1),
        UIColor(hex: 0xAD56DA), UIColor(hex: 0x8D72E6), UIColor(hex: 0x2FD058)
    ]
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
