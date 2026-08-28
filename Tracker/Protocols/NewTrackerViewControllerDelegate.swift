//
//  NewTrackerViewControllerDelegate.swift
//  Tracker
//
//  Created by Victoria Soboleva on 29.08.2026.
//

import UIKit

protocol NewTrackerViewControllerDelegate: AnyObject {
    func didCreateTracker(title: String, schedule: Set<WeekDay>, from controller: UIViewController)
}
