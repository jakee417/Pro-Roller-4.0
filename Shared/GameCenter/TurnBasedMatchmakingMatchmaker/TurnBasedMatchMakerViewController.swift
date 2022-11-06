//
//  TurnBasedMatchMakerViewController.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 10/28/22.
//

#if os(iOS)

import Foundation
import GameKit
import SwiftUI
import GameKitUI

public class TurnBasedMatchmakingMatchmakerViewController: UIViewController, GKTurnBasedMatchmakerViewControllerDelegate, GKMatchDelegate {

    private let matchRequest: GKMatchRequest
    private var matchmakingMode: Any? = nil
    private let canceled: () -> Void
    private let failed: (Error) -> Void
    private let started: (GKTurnBasedMatch) -> Void
    
    public init(matchRequest: GKMatchRequest,
                canceled: @escaping () -> Void,
                failed: @escaping (Error) -> Void,
                started: @escaping (GKTurnBasedMatch) -> Void) {
        self.matchRequest = matchRequest
        self.canceled = canceled
        self.failed = failed
        self.started = started
        super.init(nibName: nil, bundle: nil)
    }
    
    @available(iOS 15.0, *)
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
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let viewController = GKTurnBasedMatchmakerViewController(matchRequest: self.matchRequest)
        if #available(iOS 15, *) {
            viewController.matchmakingMode = self.matchmakingMode as? GKMatchmakingMode ?? .default
        }
        viewController.turnBasedMatchmakerDelegate = self
        self.add(viewController)
    }

    public func turnBasedMatchmakerViewControllerWasCancelled(_ viewController: GKTurnBasedMatchmakerViewController) {
        viewController.dismiss(
            animated: true,
            completion: {
                self.canceled()
                viewController.remove()
        })
    }

    public func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFailWithError error: Error) {
        viewController.dismiss(
            animated: true,
            completion: {
                self.failed(error)
                viewController.remove()
        })
    }

    public func turnBasedMatchmakerViewController(_ viewController: GKTurnBasedMatchmakerViewController, didFind match: GKTurnBasedMatch) {
        viewController.dismiss(
            animated: true,
            completion: {
                self.started(match)
                viewController.remove()
        })
    }
}

#endif
