//
//  GKManagerExtensions.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 10/23/22.
//

import Foundation
import GameKit
import SwiftUI

/// Extension that provides helper functions to GKManager
extension GKManager {
    /// Load the localPlayers image into the Manager
    public func loadImage(player: GKPlayer) {
        DispatchQueue.global().async { [self] in
            player.loadPhoto(for: GKPlayer.PhotoSize.small, withCompletionHandler: { (image, error) in
                guard let image = image else {
                    return
                }
                DispatchQueue.main.async {
                    withAnimation(.easeIn) {
                        self.uiImage = image
                        self.playerImage[player.gamePlayerID] = image
                    }
                }
            })
        }
    }
    
    /// Load images for remote players into the Manager
    public func loadPlayerImage(player: GKPlayer) {
        DispatchQueue.global(qos: .userInteractive).async { [self] in
            player.loadPhoto(for: GKPlayer.PhotoSize.small, withCompletionHandler: { (image, error) in
                guard let image = image else {
                    return
                }
                DispatchQueue.main.async {
                    withAnimation(.easeIn) {
                        self.playerImage[player.gamePlayerID] = image
                    }
                }
            })
        }
    }
    
    public func loadRecentPlayers(_ player: GKLocalPlayer) {
        player.loadRecentPlayers { players, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let players = players {
                let recentPlayers = Array(players.uniqued(on: { $0.gamePlayerID }).prefix(7))
                for player in recentPlayers {
                    self.loadPlayerImage(player: player)
                }
                self.setMatchRequestCache(lastPlayers: recentPlayers)
                DispatchQueue.main.async {
                    withAnimation(.easeIn) {
                        self.cachedPlayers = recentPlayers
                    }
                }
            }
        }
    }
    
    
    /// Set a cache
    public func setMatchRequestCache(lastPlayers: [GKPlayer]) {
        let newMatchRequest = GKMatchRequest()
        newMatchRequest.recipients = lastPlayers
        newMatchRequest.minPlayers = 2
        newMatchRequest.maxPlayers = lastPlayers.count + 1
        newMatchRequest.inviteMessage = "Let's Share Pro Roller Boards!"
        self.cachedMatchRequest = newMatchRequest
    }
    
    /// Send a DiceManagerSettings to all players in the current match
    public func sendDiceManagerSettings(settings: [DiceManagerSettings]) {
        if let match = self.gkMatch {
            DiceManagers.encode(settings: settings) { result in
                switch result {
                case .failure(let error):
                    print("Failure while trying to encode DiceManagerSettings \(error.localizedDescription)")
                case .success(let data):
                    do {
                        try match.sendData(toAllPlayers: data, with: .reliable)
                    } catch {
                        print("Failure while trying to send DiceManagerSettings \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: Realtime messaging buttons
    public func nudge(_ remotePlayer: GKPlayer) {
        if let match = self.gkMatch {
            DispatchQueue.global(qos: .background).async {
                do {
                    try match.send(
                        Data(GKManagerMessage.nudge.rawValue.utf8),
                        to: [remotePlayer],
                        dataMode: .reliable
                    )
                } catch {
                    print("Nudge Error:\n\(error.localizedDescription)")
                }
            }
        }
    }
    
    public func huzzah(_ remotePlayer: GKPlayer) {
        if let match = self.gkMatch {
            DispatchQueue.global(qos: .background).async {
                do {
                    try match.send(
                        Data(GKManagerMessage.huzzah.rawValue.utf8),
                        to: [remotePlayer],
                        dataMode: .reliable
                    )
                } catch {
                    print("Congrats Error:\n\(error.localizedDescription)")
                }
            }
        }
    }
    
    public func oof(_ remotePlayer: GKPlayer) {
        if let match = self.gkMatch {
            DispatchQueue.global(qos: .background).async {
                do {
                    try match.send(
                        Data(GKManagerMessage.oof.rawValue.utf8),
                        to: [remotePlayer],
                        dataMode: .reliable
                    )
                } catch {
                    print("Oof Error:\n\(error.localizedDescription)")
                }
            }
        }
    }
}

/// Extension that handles Realtime Polling
extension GKManager {
    public func pollMatch() {
        if let match = self.gkMatch {
            DispatchQueue.global(qos: .background).async {
                do {
                    try match.sendData(
                        toAllPlayers: Data(GKManagerMessage.poll.rawValue.utf8),
                        with: .unreliable
                    )
                } catch {
                    print("Ping Error:\n\(error.localizedDescription)")
                }
            }
        }
    }
    
    func pollStart() {
        timer.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            self.pollMatch()
        }
    }
    
    func pollStop() {
        timer.invalidate()
        timer = Timer()
    }
}

/// Extension responsible for archiving and unarchiving game data.
extension GKManager {
    
    /// Returns a data representation of the game data that you pass between players.
    ///
    /// - Returns: An archive of a property list with key-value pairs that represent the match state.
    func archiveMatchData() -> Data? {
        let encoder = PropertyListEncoder()
        let matchData: Data
        do {
            matchData = try encoder.encode(self.data)
            return matchData
        } catch {
            print("Error: \(error.localizedDescription).")
            return nil
        }
    }
    
    /// Sets the match state to the provided game data.
    ///
    /// Unarchives a property list representation of the game data with key-value pairs that represent the match state.
    /// - Parameter matchData: A data representation of the match state that another game instance creates using the `archiveMatchData()` method.
    func unarchiveMatchData(matchData: Data) -> YahtzeeData? {
        let decoder = PropertyListDecoder()
        do {
            let data = try decoder.decode(YahtzeeData.self, from: matchData)
            return data
        } catch {
            print("Error: \(error.localizedDescription).")
            return nil
        }
    }
    
    func createMatchData(players: [GKPlayer?]) -> YahtzeeData {
        return YahtzeeData(
            players: players,
            currentPlayer: GKLocalPlayer.local.gamePlayerID
        )
    }
}
