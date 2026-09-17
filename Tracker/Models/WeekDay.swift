//
//  WeekDay.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import Foundation
import RswiftResources

enum WeekDay: Int, CaseIterable, Hashable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var title: String {
        [
            R.string.localizable.weekdayMonday(),
            R.string.localizable.weekdayTuesday(),
            R.string.localizable.weekdayWednesday(),
            R.string.localizable.weekdayThursday(),
            R.string.localizable.weekdayFriday(),
            R.string.localizable.weekdaySaturday(),
            R.string.localizable.weekdaySunday()
        ][rawValue]
    }

    var shortTitle: String {
        [
            R.string.localizable.weekdayMondayShort(),
            R.string.localizable.weekdayTuesdayShort(),
            R.string.localizable.weekdayWednesdayShort(),
            R.string.localizable.weekdayThursdayShort(),
            R.string.localizable.weekdayFridayShort(),
            R.string.localizable.weekdaySaturdayShort(),
            R.string.localizable.weekdaySundayShort()
        ][rawValue]
    }
}
