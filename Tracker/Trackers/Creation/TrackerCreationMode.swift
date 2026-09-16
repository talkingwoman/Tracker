//
//  TrackerCreationMode.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import Foundation
import RswiftResources

enum TrackerCreationMode {
    case habit
    case irregularEvent

    var navigationTitle: String {
        switch self {
        case .habit:
            return R.string.localizable.creationNewHabit()
        case .irregularEvent:
            return R.string.localizable.creationNewEvent()
        }
    }
}
