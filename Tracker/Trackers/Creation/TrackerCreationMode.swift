//
//  TrackerCreationMode.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import Foundation

enum TrackerCreationMode {
    case habit
    case irregularEvent

    var navigationTitle: String {
        switch self {
        case .habit:
            return "Новая привычка"
        case .irregularEvent:
            return "Новое нерегулярное событие"
        }
    }
}
