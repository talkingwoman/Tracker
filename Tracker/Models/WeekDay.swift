//
//  WeekDay.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import Foundation

enum WeekDay: Int, CaseIterable, Hashable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var title: String {
        ["Понедельник", "Вторник", "Среда", "Четверг", "Пятница", "Суббота", "Воскресенье"][rawValue]
    }

    var shortTitle: String {
        ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"][rawValue]
    }
}
