//
//  GKManager+GKMatchDelegate.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 10/23/22.
//

import Foundation
import GameKit
import SwiftUI

/// Handles callbacks from various GKMatch objects
extension GKManager: GKMatchDelegate {
    // MARK: Realtime Methods
    func match(_ match: GKMatch, didReceive data: Data, fromRemotePlayer player: GKPlayer) {
        let dataString: String = String(decoding: data, as: UTF8.self)
        if dataString == GKManagerMessage.poll.rawValue {
            return
        }
        if dataString == GKManagerMessage.nudge.rawValue {
            GKNotificationBanner.show(
                withTitle: "\(player.displayName) Nudge Nudge... 👈",
                message: nil,
                duration: TimeInterval(1.0)
            )
            return
        }
        if dataString == GKManagerMessage.huzzah.rawValue {
            GKNotificationBanner.show(
                withTitle: "\(player.displayName) Huzzah! 🥳",
                message: nil,
                duration: TimeInterval(1.0)
            )
            return
        }
        if dataString == GKManagerMessage.oof.rawValue {
            GKNotificationBanner.show(
                withTitle: "\(player.displayName) Oof! 😵‍💫",
                message: nil,
                duration: TimeInterval(1.0)
            )
            return
        }
        DiceManagers.decode(data: data) { result in
            switch result {
            case .failure(let error):
                print("Failure while trying to decode DiceManagerSettings \(error.localizedDescription)")
            case .success(let newDiceManagers):
                DispatchQueue.main.async {
                    guard let oldDiceManagers = self.playerDiceManagers[player.gamePlayerID] else {
                        // No DiceManager existed, so start a new
                        self.playerDiceManagers[player.gamePlayerID] = newDiceManagers
                        return
                    }
                    for (index, diceManager) in newDiceManagers.managers.enumerated() {
                        if oldDiceManagers.managers.indices.contains(index) {
                            // Override Settings
                            oldDiceManagers.managers[index].settings = diceManager.settings
                        } else {
                            // Add completely new DiceManager
                            oldDiceManagers.managers.append(diceManager)
                        }
                    }
                    // Remove DiceManagers no longer used
                    let removeSet = (
                        IndexSet(oldDiceManagers.managers.indices)
                            .symmetricDifference(IndexSet(newDiceManagers.managers.indices))
                    )
                    oldDiceManagers.managers.remove(at: removeSet)
                }
            }
        }
    }
    
    func match(_ match: GKMatch, player: GKPlayer, didChange state: GKPlayerConnectionState) {
        switch state {
        case .connected:
            GKNotificationBanner.show(
                withTitle: "\(player.displayName) has joined",
                message: nil,
                duration: TimeInterval(2.0)
            )
            self.loadPlayerImage(player: player)
        case .disconnected, .unknown:
            GKNotificationBanner.show(
                withTitle: "\(player.displayName) has left",
                message: nil,
                duration: TimeInterval(2.0)
            )
            DispatchQueue.main.async {
                withAnimation {
                    _ = self.playerDiceManagers.removeValue(forKey: player.gamePlayerID)
                }
            }
        @unknown default:
            break
        }
    }
    
    func match(_ match: GKMatch, didFailWithError error: Error?) {
        if let error = error {
            print("Match has error: \(error.localizedDescription)")
        }
        print("Match has error")
    }
    
    func match(_ match: GKMatch, shouldReinviteDisconnectedPlayer player: GKPlayer) -> Bool {
        return true
    }
    
    // MARK: Turn Based Methods
    /// Resets the game interface to the content view.
    func resetGame() {
        DispatchQueue.main.async {
            self.playingGame = false
            self.currentMatchID = nil
            self.data.resetGame()
        }
    }
    
    /// Removes all the matches from Game Center.
    func removeMatches() async {
        do {
            // Load all the matches.
            let existingMatches = try await GKTurnBasedMatch.loadMatches()
            
            // Remove all the matches.
            for match in existingMatches {
                try await match.remove()
            }
        } catch {
            print("Error: \(error.localizedDescription).")
        }
        
    }
    
    enum MatchEndReason {
        case endOfRounds, notEnoughPlayers
    }
    
    func endMatch(
        activeParticipants: [GKTurnBasedParticipant],
        match: GKTurnBasedMatch,
        reason: MatchEndReason
    ) async throws {
        let yahtzeeGameRankings = self.data.playerDataSortedByTotal
        var outcome: String = "Pro Roller Game has Ended"
        
        // Set the match outcomes for active participants.
        for participant in activeParticipants {
            if let player = participant.player {
                if let index = yahtzeeGameRankings.sortedPlayers.firstIndex(
                    where: { $0 == player.gamePlayerID }
                ) {
                    let ranking = yahtzeeGameRankings.rankings[index]
                    if ranking == 1 {
                        participant.matchOutcome = .first
                    } else if ranking == 2 {
                        participant.matchOutcome = .second
                    } else if ranking == 3 {
                        participant.matchOutcome = .third
                    } else if ranking == 4 {
                        participant.matchOutcome = .fourth
                    } else {
                        participant.matchOutcome = .lost
                    }
                } else {
                    // Didn't receive a ranking
                    participant.matchOutcome = .lost
                }
                
                if GKLocalPlayer.local == player {
                    switch participant.matchOutcome {
                    case .won:
                        outcome = "You won in Pro Roller 😎"
                    case .lost:
                        outcome = "You lost in Pro Roller 😵‍💫"
                    case .first:
                        outcome = "You came in first place! 🥇"
                    case .second:
                        outcome = "You came in second place! 🥈"
                    case .third:
                        outcome = "You came in third place! 🥉"
                    case .fourth:
                        outcome = "You came in fourth place!"
                    default:
                        break
                    }
                }
            } else {
                // Never assigned a player
                participant.matchOutcome = .none
            }
        }
        
        // End the match in turn.
        try await match.endMatchInTurn(withMatch: match.matchData ?? Data())
        
        // Notify the local player when the match ends.
        var message: String? = nil
        switch reason {
        case .endOfRounds:
            break
        case .notEnoughPlayers:
            message = "All other players left."
        }
        await GKNotificationBanner.show(withTitle: outcome, message: message)
        
        resetGame()
    }
    
    func reorderParticipantsWithPlayers(
        participants: [GKTurnBasedParticipant],
        ordering: [String]
    ) -> [GKTurnBasedParticipant] {
        // Find an ordering of the participants with players
        var participantsWithPlayersOrder: [Int] = []
        for participant in participants {
            if let player = participant.player,
               let index = ordering.firstIndex(where: { $0 == player.gamePlayerID }) {
                participantsWithPlayersOrder.append(index)
            } else {
                participantsWithPlayersOrder.append(9999)
            }
        }
        // Sort the participantsWithPlayers based off ordering
        var participantsWithPlayersCombined = Array(zip(participants, participantsWithPlayersOrder))
        participantsWithPlayersCombined = participantsWithPlayersCombined.sorted(by: { $0.1 < $1.1})
        return participantsWithPlayersCombined.map({ $0.0})
    }
    
    /// Takes the local player's turn.
    func takeTurn() async {
        // Handle all the cases that can occur when the player takes their turn:
        // 1. Resets the interface if GameKit fails to load the match.
        // 2. Ends the game if there aren't enough players.
        // 3. Otherwise, takes the turn and passes to the next participant.
        
        // Check whether there's an ongoing match.
        guard currentMatchID != nil else {
            return
        }
        
        do {
            // Load the most recent match object from the match ID.
            let match = try await GKTurnBasedMatch.load(withID: currentMatchID!)
            
            // Remove participants who quit or otherwise aren't in the match.
            let activeParticipants = match.participants.filter {
                switch $0.status {
                case .invited, .matching, .active:
                    return true
                case .unknown, .declined, .done:
                    return false
                @unknown default:
                    return true
                }
            }
            
            // End the match if the active participants drop below the minimum. Only the current
            // participant can end a match, so check for this condition in this method when it
            // becomes the local player's turn.
            if activeParticipants.count < GKManager.minPlayers {
                try await endMatch(
                    activeParticipants: activeParticipants,
                    match: match,
                    reason: .notEnoughPlayers
                )
            } else {
                // Check to see if the game has ended.
                if self.data.endOfGame {
                    try await endMatch(
                        activeParticipants: activeParticipants,
                        match: match,
                        reason: .endOfRounds
                    )
                    return
                }
                
                // Otherwise, take the turn and pass to the next participants.
                // Create the game data to store in Game Center.
                let gameData = (archiveMatchData() ?? match.matchData)!
                
                let participantsWithPlayers = activeParticipants.filter {
                    $0 != match.currentParticipant &&
                    $0.player != nil
                }
                print("participantsWithPlayers: \(participantsWithPlayers.count)")
                
                let participantsWithoutPlayers = activeParticipants.filter {
                    $0 != match.currentParticipant &&
                    $0.player == nil
                }
                print("participantsWithoutPlayers: \(participantsWithoutPlayers.count)")
                
                // Order the participants by how many turns they have taken.
                let participantOrder = self.data.playersSortedByCompletedTurns
                let participantsWithPlayersSorted = reorderParticipantsWithPlayers(
                    participants: participantsWithPlayers,
                    ordering: participantOrder
                )

                // Set the match message.
                match.setLocalizableMessageWithKey("Take your turn in Pro Roller.", arguments: nil)
                
                // Pass the turn to the next participant.
                let nextParticipants = participantsWithPlayersSorted + participantsWithoutPlayers
                print(nextParticipants)
                try await match.endTurn(
                    withNextParticipants: nextParticipants,
                    turnTimeout: GKTurnTimeoutDefault,
                    match: gameData
                )
            }
        } catch {
            // Handle the error.
            print("Error: \(error.localizedDescription).")
            resetGame()
        }
    }
    
    /// Save match data in Game Center without ending the turn.
    func saveCurrentTurn() async {
        // Check whether there's an ongoing match.
        guard currentMatchID != nil else { return }
        
        do {
            if self.data.myTurn {
                // Load the most recent match object from the match ID.
                let match = try await GKTurnBasedMatch.load(withID: currentMatchID!)
                // Create the game data to store in Game Center.
                let gameData = (archiveMatchData() ?? match.matchData)!
                try await match.saveCurrentTurn(withMatch: gameData)
            }
        } catch {
            print("Error: \(error.localizedDescription).")
        }
        
    }
    
    /// Quits the game by forfeiting the match.
    func forfeitMatch() async {
        // Check whether there's an ongoing match.
        guard currentMatchID != nil else { return }

        do {
            // Load the most recent match object from the match ID.
            let match = try await GKTurnBasedMatch.load(withID: currentMatchID!)
            
            // Forfeit the match while it's the local player's turn.
            if self.data.myTurn {
                // The game updates the data when turn-based events occur, so this game instance should
                // have the current data.
                
                // Create the game data to store in Game Center.
                let gameData = (archiveMatchData() ?? match.matchData)!

                // Remove the participants who quit and the current participant.
                let nextParticipants = match.participants.filter {
                  ($0.status != .done) && ($0 != match.currentParticipant)
                }

                // Forfeit the match.
                try await match.participantQuitInTurn(
                    with: GKTurnBasedMatch.Outcome.quit,
                    nextParticipants: nextParticipants,
                    turnTimeout: GKTurnTimeoutDefault,
                    match: gameData
                )
            } else {
                // Forfeit the match while it's not the local player's turn.
                try await match.participantQuitOutOfTurn(with: GKTurnBasedMatch.Outcome.quit)
            }
            
            // Notify the local player that they forfeit the match.
            await GKNotificationBanner.show(
                withTitle: "You left the Pro Roller Game!",
                message: nil
            )

            resetGame()
        } catch {
            print("Error: \(error.localizedDescription).")
        }
    }
    
    /// Sends a reminder to the opponent to take their turn.
    func sendReminder() async {
        // Check whether there's an ongoing match.
        guard currentMatchID != nil else { return }
        
        do {
            // Load the most recent match object from the match ID.
            let match = try await GKTurnBasedMatch.load(withID: currentMatchID!)
            
            // Create an array containing the current participant.
            let participants = match.participants.filter {
                $0 == match.currentParticipant
            }
            
            // Send a reminder to the current participant.
            try await match.sendReminder(
                to: participants,
                localizableMessageKey: "This is a sendReminder message.",
                arguments: []
            )
        } catch {
            print("Error: \(error.localizedDescription).")
        }
    }
    
    /// Ends the match without forfeiting the game.
    func quitGame() {
        resetGame()
    }
    
    /// Sends a message from one player to another.
    ///
    /// - Parameter content: The message to send to the other player.
    /// - Tag:sendMessage
    func sendMessage(content: String) async {
        // Check whether there's an ongoing match.
        guard currentMatchID != nil else { return }
        
        do {
            // Create a message object to display in the message view.
            let message: GKTurnBasedMessage = GKTurnBasedMessage(
                content: content,
                playerName: GKLocalPlayer.local.displayName,
                isLocalPlayer: true
            )
            messages.append(message)
            
            // Create the exchange data.
            let data: Data? = content.data(using: .utf8)

            if data != nil {
                // Load the most recent match object from the match ID.
                let match = try await GKTurnBasedMatch.load(withID: currentMatchID!)

                // Remove the local player (the sender) from the recipients; otherwise, GameKit doesn't send
                // the exchange request.
                let participants = match.participants.filter {
                    GKLocalPlayer.local.displayName != $0.player?.displayName
                }

                // Send the exchange request with the message.
                try await match.sendExchange(
                    to: participants, data: data!,
                    localizableMessageKey: "This is my text message.",
                    arguments: [], timeout: GKTurnTimeoutDefault
                )
            }
        } catch {
            print("Error: \(error.localizedDescription).")
            return
        }
    }
    
    /// Exchange an item.
    func exchangeItem() async {
        // Check whether there's an ongoing match.
        guard currentMatchID != nil else { return }
        
        do {
            // Load the most recent match object from the match ID.
            let match = try await GKTurnBasedMatch.load(withID: currentMatchID!)

            // Remove the local player (the sender) from the recipients; otherwise, GameKit doesn't send
            // the exchange request.
            let participants = match.participants.filter {
                GKLocalPlayer.local.displayName != $0.player?.displayName
            }

            // Send the exchange request with the message.
            try await match.sendExchange(to: participants, data: Data(),
                localizableMessageKey: "This is my exchange item request.",
                arguments: [], timeout: GKTurnTimeoutDefault)
        } catch {
            print("Error: \(error.localizedDescription).")
            return
        }
    }
}
