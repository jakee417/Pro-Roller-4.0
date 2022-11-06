//
//  GKMatchMakerAppModel.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 9/22/22.
//

import os.log
import Combine
import Foundation
import GameKit
import GameKitUI
import SwiftUI

/// GameKit Managing Class
class GKManager: NSObject, GKLocalPlayerListener, ObservableObject {
    static public let minPlayers = 2
    static public let maxPlayers = 8
    
    // GameKit data
    @Published public var showAuthentication = false
    @Published public var showInvite = false
    @Published public var showMatch = false
    @Published public var allowMultiplayer = false
    
    // Stored images of local and remote players.
    @Published var uiImage: UIImage? = nil
    @Published var playerImage: [String: UIImage] = [:]
    
    // Stored data from a realtime match
    @Published var isPolling: Bool = false
    @Published var playerDiceManagers: [String: DiceManagers] = [:]
    var timer: Timer = Timer() {
        didSet {
            withAnimation(.easeIn) {
                if timer.isValid {
                    self.isPolling = true
                } else {
                    self.isPolling = false
                }
            }
        }
    }
    
    // Subscribed data from GKMatchManager
    @Published public var gkLocalPlayer: GKLocalPlayer? {
        didSet {
            if let player = gkLocalPlayer {
                withAnimation {
                    self.allowMultiplayer = (
                        player.isAuthenticated &&
                        !player.isMultiplayerGamingRestricted
                    )
                }
                if cachedPlayers == nil {
                    self.loadRecentPlayers(player)
                }
                player.register(self)
            }
        }
    }
    
    @Published public var invite: Invite = Invite.zero {
        didSet {
            self.showInvite = invite.gkInvite != nil
            self.showAuthentication = invite.needsToAuthenticate ?? false
        }
    }
    
    @Published public var cachedMatchRequest: GKMatchRequest? = nil
    @Published public var cachedPlayers: [GKPlayer]? = nil
    @Published public var gkMatch: GKMatch? {
        didSet {
            guard let match = self.gkMatch else {
                print("match has been set to nil")
                DispatchQueue.main.async {
                    self.showMatch = false
                }
                self.pollStop()
                return
            }
            if match.players.isEmpty {
                print("match set but no players found")
            }
            
            // Set the delegate to receive callbacks
            match.delegate = self
            for player in match.players {
                self.loadPlayerImage(player: player)
            }
            DispatchQueue.main.async {
                self.showInvite = false
                self.showMatch = true
            }
            self.pollStart()
            self.setMatchRequestCache(lastPlayers: match.players)
            DispatchQueue.main.async {
                withAnimation(.easeIn) {
                    self.cachedPlayers = match.players
                }
            }
        }
    }
    
    // MARK: Turn Based Data
    @Published var playingGame = false
    @Published var messages: [GKTurnBasedMessage] = []
    @Published var matchMessage: String? = nil
    @Published var data = YahtzeeData(
        players: [],
        currentPlayer: ""
    )
    @Published var currentMatchID: String? = nil {
        didSet {
            print("currentMatchID: \(currentMatchID ?? "nil")")
        }
    }

    // MARK: currentPlayer
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

    // MARK: Synced Items
    private var cancellableInvite: AnyCancellable?
    private var cancellableMatch: AnyCancellable?
    private var cancellableLocalPlayer: AnyCancellable?

    public override init() {
        super.init()
        self.subscribe()
    }

    deinit {
        self.unsubscribe()
    }

    func subscribe() {
        self.cancellableInvite = GKMatchManager
            .shared
            .invite
            .sink { (invite) in
                self.invite = invite
        }
        self.cancellableMatch = GKMatchManager
            .shared
            .match
            .sink { (match) in
                self.gkMatch = match.gkMatch
        }
        self.cancellableLocalPlayer = GKMatchManager
            .shared
            .localPlayer
            .sink { (localPlayer) in
                self.gkLocalPlayer = localPlayer
        }
    }

    func unsubscribe() {
        self.cancellableInvite?.cancel()
        self.cancellableMatch?.cancel()
        self.cancellableLocalPlayer?.cancel()
    }
}
