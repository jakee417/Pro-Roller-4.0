//
//  GKTurnBasedManager.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 10/19/22.
//

import Foundation
import GameKit
import SwiftUI

/// GameKit Manager for Turn Based Games
class GKTurnBasedManager: NSObject, GKMatchDelegate, GKLocalPlayerListener, ObservableObject {
    @Published var matchAvailable = false
    @Published var playingGame = false
    @Published var myTurn = false
    
    @Published var currentMatchID: String? = nil {
        didSet {
            print("currentMatchID: \(currentMatchID ?? "nil")")
        }
    }
    public let minPlayers = GKManager.minPlayers
    public let maxPlayers = GKManager.maxPlayers

    // The persistent game data.
    @Published var localParticipant: Participant? = nil
    @Published var opponents: [String: Participant] = [:]
    @Published var count = 0
    
    // The messages between players.
    @Published var messages: [GKTurnBasedMessage] = []
    @Published var matchMessage: String? = nil
    
    var currentPlayer: GKPlayer? {
        get async {
            guard let currentMatchID = self.currentMatchID else {
                return nil
            }
            do {
                let match = try await GKTurnBasedMatch.load(withID: currentMatchID)
                guard let currentParticipant = match.currentParticipant else {
                    return nil
                }
                return currentParticipant.player
            } catch {
                return nil
            }
        }
    }
    
    /// Resets the game interface to the content view.
    func resetGame() {
        DispatchQueue.main.async {
            self.playingGame = false
            self.myTurn = false
            self.currentMatchID = nil
            self.opponents = [:]
            self.count = 0
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
                $0.status != .done
            }
            
            // End the match if the active participants drop below the minimum. Only the current
            // participant can end a match, so check for this condition in this method when it
            // becomes the local player's turn.
            if activeParticipants.count < minPlayers {
                // Set the match outcomes for active participants.
                for participant in activeParticipants {
                    participant.matchOutcome = .won
                }
                
                // End the match in turn.
                try await match.endMatchInTurn(withMatch: match.matchData!)
                
                // Notify the local player when the match ends.
                await GKNotificationBanner.show(
                    withTitle: "Match Ended Title",
                    message: "This is a GKNotificationBanner message."
                )
                
                resetGame()
            } else {
                // Otherwise, take the turn and pass to the next participants.
                
                // Update the game data.
                count += 1
                
                // Create the game data to store in Game Center.
                let gameData = (archiveMatchData() ?? match.matchData)!

                // Remove the current participant from the match participants.
                let nextParticipants = activeParticipants.filter {
                    $0 != match.currentParticipant
                }

                // Set the match message.
                match.setLocalizableMessageWithKey("This is a match message.", arguments: nil)

                // Pass the turn to the next participant.
                try await match.endTurn(
                    withNextParticipants: nextParticipants,
                    turnTimeout: GKTurnTimeoutDefault,
                    match: gameData
                )
                
                myTurn = false
            }
        } catch {
            // Handle the error.
            print("Error: \(error.localizedDescription).")
            resetGame()
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
            if myTurn {
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
                
                // Notify the local player that they forfeit the match.
                await GKNotificationBanner.show(
                    withTitle: "Forfeit Match Title",
                    message: "This is a GKNotificationBanner message.")
                
                resetGame()
            } else {
                // Forfeit the match while it's not the local player's turn.
                try await match.participantQuitOutOfTurn(with: GKTurnBasedMatch.Outcome.quit)
                
                // Notify the local player that they forfeit the match.
                await GKNotificationBanner.show(
                    withTitle: "Forfeit Match Title",
                    message: "This is a GKNotificationBanner message."
                )

                resetGame()
            }
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
                    localParticipant?.player.displayName != $0.player?.displayName
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
                self.localParticipant?.player.displayName != $0.player?.displayName
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


/// Extension responsible for archiving and unarchiving game data.
extension GKTurnBasedManager {
    
    /// Returns a data representation of the game data that you pass between players.
    ///
    /// - Returns: An archive of a property list with key-value pairs that represent the match state.
    func archiveMatchData() -> Data? {
        // The property list keys are [
        //    "score": count,
        //    [local player's identifier]: myItems,
        //    [opponent's identifier]: opponentItems ]
        var gamePropertyList: [String: Any] = [:]
        
        // Add the score.
        gamePropertyList["score"] = String(describing: count)

        // Archive the property list and return the Data object.
        do {
            let gameData = try PropertyListSerialization.data(
                fromPropertyList: gamePropertyList,
                format: PropertyListSerialization.PropertyListFormat.binary,
                options: 0
            )
            return gameData
        } catch {
            print("Error: \(error.localizedDescription).")
            return nil
        }
    }
    
    /// Sets the match state to the provided game data.
    ///
    /// Unarchives a property list representation of the game data with key-value pairs that represent the match state.
    /// - Parameter matchData: A data representation of the match state that another game instance creates using the `archiveMatchData()` method.
    func unarchiveMatchData(matchData: Data) {
        do {
            // Convert the Data object to a property list.
            if let gamePropertyList: [String: Any] =
                try PropertyListSerialization.propertyList(from: matchData, format: nil) as? [String: Any] {
                
                // Update User Interface with unarchived match data
                DispatchQueue.main.async {
                    // Restore the score from the property list.
                    if let countString: String = gamePropertyList["score"] as? String {
                        self.count = Int(countString)!
                    }
                }
            }
        } catch {
            print("Error: \(error.localizedDescription).")
        }
    }
}
