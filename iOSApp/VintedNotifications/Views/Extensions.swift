//
//  Extensions.swift
//  Vinted Notifications
//
//  String Extensions
//

import Foundation

// MARK: - String Extension
extension String {
    func removingEmojis() -> String {
        return self.filter { character in
            !character.isEmoji
        }
    }
}

// MARK: - Character Extension
extension Character {
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}
