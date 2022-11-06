//
//  GKManager+GKTurnBasedEventListener.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 10/23/22.
//

import Foundation
import GameKit

/// Extension that handles Listening for Turn Based Game Events
extension GKManager: GKTurnBasedEventListener {
    
    /// Handles multiple turn-based events during a match.
    @MainActor
    func player(
        _ player: GKPlayer,
        receivedTurnEventFor match: GKTurnBasedMatch,
        didBecomeActive: Bool
    ) {
        // Handles these turn-based events when:
        // 1. The local player accepts an invitation from another participant.
        // 2. GameKit passes the turn to the local player.
        // 3. The local player opens an existing or completed match.
        // 4. Another player forfeits the match.
        switch match.status {
        case .open:
            Task {
                do {
                    // If the match is open, first check whether game play should continue.
                    // Remove participants who quit or otherwise aren't in the match.
                    let nextParticipants = match.participants.filter {
                        switch $0.status {
                        case .invited, .matching, .active:
                            return true
                        case .declined, .done, .unknown:
                            return false
                        @unknown default:
                            return true
                        }
                    }
                    
                    // End the match if active participants drop below the minimum.
                    if nextParticipants.count < GKManager.minPlayers {
                        try await endMatch(
                            activeParticipants: nextParticipants,
                            match: match,
                            reason: .notEnoughPlayers
                        )
                    }
                    else if (
                        self.currentMatchID == nil ||
                        self.currentMatchID == match.matchID
                    ) {
                        // If the local player isn't playing another match or is playing this match,
                        // display and update the game view.
                            
                        // Remove the local player from the participants to find the opponents.
                        let opponents = match.participants.filter {
                            self.gkLocalPlayer?.gamePlayerID != $0.player?.gamePlayerID
                        }
                        
                        for opponent in opponents {
                            if let player = opponent.player {
                                if !self.playerImage.keys.contains(player.gamePlayerID) {
                                    self.loadPlayerImage(player: player)
                                }
                            }
                        }
                        
                        // Restore the current game data from the match object.
                        if let matchData = match.matchData,
                           let data = self.unarchiveMatchData(matchData: matchData) {
                            self.data = data
                        } else {
                            let players = [GKLocalPlayer.local] + opponents.map({ $0.player })
                            self.data = self.createMatchData(players: players)
                        }
                    
                        // Update the interface depending on whether it's the local player's turn.
                        if GKLocalPlayer.local == match.currentParticipant?.player {
                            self.data.setCurrentPlayer(GKLocalPlayer.local.gamePlayerID)
                        } else {
                            if let currentParticipant = match.currentParticipant,
                               let currentPlayer = currentParticipant.player {
                                self.data.setCurrentPlayer(currentPlayer.gamePlayerID)
                            } else {
                                self.data.setCurrentPlayer("")
                            }
                        }
                        
                        // Display the match message.
                        self.matchMessage = match.message
                        
                        // Retain the match ID so action methods can load the current match object later.
                        self.currentMatchID = match.matchID
                        
                        // Display the game view for this match.
                        self.playingGame = true
                    }
                } catch {
                    // Handle the error.
                    print("Error: \(error.localizedDescription).")
                }
            }
        
        case .ended:
            print("Match ended.")

        case .matching:
            print("Still finding players.")

        default:
            print("Status unknown.")
        }
    }
    
    /// Handles when a player forfeits a match when it's their turn using the view controller interface.
    func player(_ player: GKPlayer, wantsToQuitMatch match: GKTurnBasedMatch) {
        // Remove the current participant. If the count drops below the minimum, the next participant ends the match.
        let nextParticipants = match.participants.filter {
            $0 != match.currentParticipant
        }
        
        // Quit while it's the local player's turn.
        match.participantQuitInTurn(
            with: GKTurnBasedMatch.Outcome.quit,
            nextParticipants: nextParticipants,
            turnTimeout: GKTurnTimeoutDefault, match: match.matchData!
        )
    }
    
    /// Handles when a participant ends the match using the view controller interface.
    func player(_ player: GKPlayer, matchEnded match: GKTurnBasedMatch) {
        // Notify the local participant when the match ends.
        GKNotificationBanner.show(
            withTitle: "Match Ended Title",
            message: "This is a GKNotificationBanner message.", completionHandler: nil
        )
        
        // Check whether the local player is playing the match that ends before returning to the content view.
        if self.currentMatchID == match.matchID {
            self.resetGame()
        }
    }
    
    /// Handles when the sender cancels an exchange request.
    func player(_ player: GKPlayer, receivedExchangeCancellation exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
    }
    
    /// Handles when all players either respond or time out responding to this request.
    func player(_ player: GKPlayer, receivedExchangeReplies replies: [GKTurnBasedExchangeReply],
                forCompletedExchange exchange: GKTurnBasedExchange, for match: GKTurnBasedMatch) {
        // GameKit sends this message to both the current participant and the sender of the exchange request.
        saveExchanges(for: match)
    }
    
    /// Exchanges the items and removes completed exchanges from the match object.
    func saveExchanges(for match: GKTurnBasedMatch) {
        // Check whether the local player is the current participant who can save exchanges.
        guard GKLocalPlayer.local.gamePlayerID == self.data.currentPlayer else { return }

        // Save all the completed exchanges.
        if let completedExchanges = match.completedExchanges {
            // Resolve the game data to pass to all participants.
            let gameData = (archiveMatchData() ?? match.matchData)!

            // Save and forward the game data with the latest items.
            Task {
                try await match.saveMergedMatch(gameData, withResolvedExchanges: completedExchanges)
            }
        }
    }
}
