//
//  TurnBasedUtilities.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 10/19/22.
//

import Foundation
import GameKit
import SwiftUI

enum GKManagerMessage: String {
    case poll = "poll"
    case nudge = "nudge"
    case huzzah = "huzzah"
    case oof = "oof"
}

// A message that one player sends to another.
struct GKTurnBasedMessage: Identifiable {
    var id = UUID()
    var content: String
    var playerName: String
    var isLocalPlayer: Bool = false
}
