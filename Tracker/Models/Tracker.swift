//
//  Tracker.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import UIKit

struct Tracker {
    let id: UUID
    let title: String
    let color: UIColor
    let emoji: String
    let schedule: Set<WeekDay>
    let isPinned: Bool

    init(id: UUID, title: String, color: UIColor, emoji: String, schedule: Set<WeekDay>, isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.color = color
        self.emoji = emoji
        self.schedule = schedule
        self.isPinned = isPinned
    }
}
