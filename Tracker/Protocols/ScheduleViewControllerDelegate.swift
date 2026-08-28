//
//  ScheduleViewControllerDelegate.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import Foundation

protocol ScheduleViewControllerDelegate: AnyObject {
    func didChooseSchedule(_ schedule: Set<WeekDay>)
}
