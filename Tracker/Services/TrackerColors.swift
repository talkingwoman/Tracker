//
//  TrackerColors.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import UIKit

enum TrackerColors {
    static let black = UIColor(named: "TrackerBlack") ?? .label
    static let blue = UIColor(named: "TrackerBlue") ?? .systemBlue
    static let gray = UIColor(named: "TrackerGray") ?? .systemGray
    static let red = UIColor(named: "TrackerRed") ?? .systemRed
    static let fieldBackground = (UIColor(named: "TrackerBackground") ?? .secondarySystemBackground)
        .withAlphaComponent(0.3)
    static let dateBackground = UIColor(named: "TrackerDateBackground") ?? .secondarySystemBackground
}
