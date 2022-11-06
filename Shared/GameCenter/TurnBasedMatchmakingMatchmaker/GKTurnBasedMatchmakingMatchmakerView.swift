//
//  GKTurnBasedMatchmakingMatchmakerView.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 10/28/22.
//

#if os(iOS) || os(tvOS)

import Foundation
import GameKit
import SwiftUI

public struct GKTurnBasedMatchmakingMatchmakerView: UIViewControllerRepresentable {
    
    private let matchRequest: GKMatchRequest
    private var matchmakingMode: Any? = nil
    private let canceled: () -> Void
    private let failed: (Error) -> Void
    private let started: (GKTurnBasedMatch) -> Void
    
    public init(matchRequest: GKMatchRequest,
                matchmakingMode: GKMatchmakingMode,
                canceled: @escaping () -> Void,
                failed: @escaping (Error) -> Void,
                started: @escaping (GKTurnBasedMatch) -> Void) {
        self.matchRequest = matchRequest
        self.matchmakingMode = matchmakingMode
        self.canceled = canceled
        self.failed = failed
        self.started = started
    }
    
    @available(iOS 15.0, *)
    public init(minPlayers: Int,
                maxPlayers: Int,
                inviteMessage: String,
                matchmakingMode: GKMatchmakingMode,
                canceled: @escaping () -> Void,
                failed: @escaping (Error) -> Void,
                started: @escaping (GKTurnBasedMatch) -> Void) {
        let matchRequest = GKMatchRequest()
        matchRequest.minPlayers = minPlayers
        matchRequest.maxPlayers = maxPlayers
        matchRequest.inviteMessage = inviteMessage
        self.matchRequest = matchRequest
        self.matchmakingMode = matchmakingMode
        self.canceled = canceled
        self.failed = failed
        self.started = started
    }
    
    public func makeUIViewController(
        context: UIViewControllerRepresentableContext<GKTurnBasedMatchmakingMatchmakerView>) -> TurnBasedMatchmakingMatchmakerViewController {
            if #available(iOS 15.0, *) {
                return self.makeMatchmakerViewControllerForiOS15AndHigher()
            } else {
                return self.makeMatchmakerViewController()
            }
        }
    
    @available(iOS 15.0, *)
    internal func makeMatchmakerViewControllerForiOS15AndHigher() -> TurnBasedMatchmakingMatchmakerViewController {
        guard let matchmakingMode = self.matchmakingMode as? GKMatchmakingMode else {
            return self.makeMatchmakerViewController()
        }
        return TurnBasedMatchmakingMatchmakerViewController(
            matchRequest: self.matchRequest,
            matchmakingMode: matchmakingMode) {
            self.canceled()
        } failed: { (error) in
            self.failed(error)
        } started: { (match) in
            self.started(match)
        }
    }
    
    internal func makeMatchmakerViewController() -> TurnBasedMatchmakingMatchmakerViewController {
        return TurnBasedMatchmakingMatchmakerViewController(
            matchRequest: self.matchRequest) {
                self.canceled()
            } failed: { (error) in
                self.failed(error)
            } started: { (match) in
                self.started(match)
            }
    }
    
    public func updateUIViewController(
        _ uiViewController: TurnBasedMatchmakingMatchmakerViewController,
        context: UIViewControllerRepresentableContext<GKTurnBasedMatchmakingMatchmakerView>) {
        }
}

#endif
