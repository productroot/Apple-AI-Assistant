//
//  Color+Extensions.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 7/1/25.
//

import SwiftUI

extension Color {
    /// The main accent color used throughout the app
    static var main: Color {
        Color.mint
    }
    
    /// Secondary background color that adapts to the platform
    static var secondaryBackgroundColor: Color {
        #if os(iOS)
        Color(UIColor.secondarySystemBackground)
        #elseif os(macOS)
        Color(NSColor.controlBackgroundColor)
        #else
        Color.gray.opacity(0.1)
        #endif
    }
    
    /// Initialize Color from a string name
    init(_ name: String) {
        switch name.lowercased() {
        case "red": self = .red
        case "blue": self = .blue
        case "green": self = .green
        case "yellow": self = .yellow
        case "orange": self = .orange
        case "purple": self = .purple
        case "pink": self = .pink
        case "gray", "grey": self = .gray
        case "black": self = .black
        case "white": self = .white
        case "brown": self = .brown
        case "cyan": self = .cyan
        case "indigo": self = .indigo
        case "mint": self = .mint
        case "teal": self = .teal
        default: self = .blue
        }
    }
}