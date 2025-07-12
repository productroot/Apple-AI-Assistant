//
//  NavigationCoordinator.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/25/25.
//

import SwiftUI
import Observation

@Observable
final class NavigationCoordinator {
    static let shared = NavigationCoordinator()

    var tabSelection: TabSelection = .tasks
    var splitViewSelection: TabSelection? = .tasks

    private init() {}

    @MainActor
    public func navigate(to tab: TabSelection) {
        tabSelection = tab
        splitViewSelection = tab
    }
}
