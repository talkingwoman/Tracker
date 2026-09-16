//
//  TrackerColors.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import UIKit

enum TrackerColors {
    static let black = UIColor(resource: .trackerBlack)
    static let primary = UIColor(resource: .trackerPrimary)
    static let background = UIColor(resource: .trackerSurface)
    static let blue = UIColor(resource: .trackerBlue)
    static let gray = UIColor(resource: .trackerGray)
    static let red = UIColor(resource: .trackerRed)
    static let selectionBackground = UIColor(resource: .trackerBackground)
    static let fieldBackground = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(resource: .trackerField)
            : UIColor(resource: .trackerBackground).withAlphaComponent(0.3)
    }
    static let dateBackground = UIColor(resource: .trackerDateBackground)
}
