//
//  YahtzeeGame.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 10/21/22.
//

import Foundation
import SwiftUI
import GameKit

enum YahtzeeEventType: String, Codable {
    case ones = "Ones"
    case twos = "Twos"
    case threes = "Threes"
    case fours = "Fours"
    case fives = "Fives"
    case sixes = "Sixes"
    case threeOfAKind = "Three of a Kind"
    case fourOfAKind = "Four of a Kind"
    case fullHouse = "Full House"
    case smallStraight = "Small Straight"
    case largeStraight = "Large Straight"
    case yahtzee = "Yahtzee"
    case chance = "Chance"
}

struct YahtzeeEvent: Identifiable, Codable {
    var id = UUID()
    var eventType: YahtzeeEventType
    var score: Int?
    
    init(id: UUID = UUID(), eventType: YahtzeeEventType, score: Int? = nil) {
        self.id = id
        self.eventType = eventType
        self.score = score
    }
    
    mutating func updateScore(_ newScore: Int) {
        self.score = newScore
    }
}

struct YahtzeeBonusEvent: Identifiable, Codable {
    var id = UUID()
    var scores: [Int] = []
    var yahtzeeBonusEnabled: Bool = false
    var yahtzeeScored: Bool = false
    
    mutating func addScore() {
        self.scores.append(100)
    }
    
    var score: Int {
        get {
            self.scores.reduce(0, +)
        }
    }
}

struct UpperSection: Identifiable, Codable {
    var id = UUID()
    var ones = YahtzeeEvent(eventType: .ones)
    var twos = YahtzeeEvent(eventType: .twos)
    var threes = YahtzeeEvent(eventType: .threes)
    var fours = YahtzeeEvent(eventType: .fours)
    var fives = YahtzeeEvent(eventType: .fives)
    var sixes = YahtzeeEvent(eventType: .sixes)
    
    var subTotal: Int {
        get {
            var res: Int = 0
            res += ones.score ?? 0
            res += twos.score ?? 0
            res += threes.score ?? 0
            res += fours.score ?? 0
            res += fives.score ?? 0
            res += sixes.score ?? 0
            return res
        }
    }
    var bonus: Bool {
        get {
            if subTotal >= 63 {
                return true
            }
            return false
        }
    }
    
    var bonusAmount: Int {
        get {
            if bonus {
                return 35
            }
            return 0
        }
    }
    
    var total: Int {
        get {
            return subTotal + bonusAmount
        }
    }
    
    var completed: Bool {
        get {
            return (
                ones.score != nil &&
                twos.score != nil &&
                threes.score != nil &&
                fours.score != nil &&
                fives.score != nil &&
                sixes.score != nil
            )
        }
    }
    
    var completedTurns: Int {
        get {
            return [
                self.ones,
                self.twos,
                self.threes,
                self.fours,
                self.fives,
                self.sixes
            ].map({$0.score != nil ? 1 : 0}).reduce(0, +)
        }
    }
}

struct LowerSection: Identifiable, Codable {
    var id = UUID()
    var threeOfAKind = YahtzeeEvent(eventType: .threeOfAKind)
    var fourOfAKind = YahtzeeEvent(eventType: .fourOfAKind)
    var fullHouse = YahtzeeEvent(eventType: .fullHouse)
    var smallStraight = YahtzeeEvent(eventType: .smallStraight)
    var largeStraight = YahtzeeEvent(eventType: .largeStraight)
    var yahtzee = YahtzeeEvent(eventType: .yahtzee) {
        didSet {
            if let score = self.yahtzee.score {
                if score == 50 {
                    // If we have a Yahtzee, then give a bonusYaht
                    self.yahtzeeBonus.yahtzeeBonusEnabled = true
                }
                // Enable the Yahtzee Joker Rule Scoring
                self.yahtzeeBonus.yahtzeeScored = true
            }
        }
    }
    var chance = YahtzeeEvent(eventType: .chance)
    var yahtzeeBonus = YahtzeeBonusEvent()
    
    var total: Int {
        get {
            var res: Int = 0
            res += threeOfAKind.score ?? 0
            res += fourOfAKind.score ?? 0
            res += fullHouse.score ?? 0
            res += smallStraight.score ?? 0
            res += largeStraight.score ?? 0
            res += yahtzee.score ?? 0
            res += chance.score ?? 0
            res += yahtzeeBonus.score
            return res
        }
    }
    
    var completed: Bool {
        get {
            return (
                threeOfAKind.score != nil &&
                fourOfAKind.score != nil &&
                fullHouse.score != nil &&
                smallStraight.score != nil &&
                largeStraight.score != nil &&
                yahtzee.score != nil &&
                chance.score != nil
            )
        }
    }
    
    var completedTurns: Int {
        get {
            return [
                self.threeOfAKind,
                self.fourOfAKind,
                self.fullHouse,
                self.smallStraight,
                self.largeStraight,
                self.yahtzee,
                self.chance
            ].map({$0.score != nil ? 1 : 0}).reduce(0, +)
        }
    }
}

struct YahtzeeRound: Identifiable, Equatable, Codable {
    static func == (lhs: YahtzeeRound, rhs: YahtzeeRound) -> Bool {
        lhs.id == rhs.id
    }
    var id = UUID()
    var lowerSection: LowerSection = LowerSection()
    var upperSection: UpperSection = UpperSection()
    
    var total: Int {
        return lowerSection.total + upperSection.total
    }
    
    var completed: Bool {
        get {
            return lowerSection.completed && upperSection.completed
        }
    }
    
    var completedTurns: Int {
        return lowerSection.completedTurns + upperSection.completedTurns
    }
}

struct YahtzeePlayerData: Identifiable, Codable, Hashable {
    var id = UUID()
    var turnCount: Int = 0
    var numRounds: Int
    var rounds: [YahtzeeRound]
    var displayName: String?
    var gamePlayerID: String
    var scores: [Int] {
        get {
            return rounds.map { $0.total }
        }
    }
    
    init(
        id: UUID = UUID(),
        displayName: String?,
        gamePlayerID: String,
        numRounds: Int
    ) {
        self.id = id
        self.numRounds = max(numRounds, 1)
        self.displayName = displayName
        self.gamePlayerID = gamePlayerID
        self.rounds = []
        for _ in 1...self.numRounds {
            self.rounds.append(YahtzeeRound())
        }
    }
    
    var cusum: [Int] {
        var cusum: [Int] = []
        var current: Int = 0
        for score in scores {
            cusum.append(current + score)
            current += score
        }
        return cusum
    }
    
    /// [True, True, True]
    /// 0, 1, 2, 3
    var currentRoundIndex: Int {
        get {
            var currentRound: Int = 0
            for round in self.rounds {
                if round.completed {
                    currentRound += 1
                } else {
                    return currentRound
                }
            }
            return currentRound
        }
    }
    
    var currentRound: YahtzeeRound {
        get {
            return self.rounds[self.currentRoundIndex]
        }
    }
    
    var completedTurns: Int {
        get {
            return self.currentRound.completedTurns
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// Lightweight Data representation of a DiceModelManager
struct YahtzeeDiceManager: Identifiable, Codable {
    var id = UUID()
    var dice: [Int] = []
    var lockSelection: [Int: Int] = [:]
}

struct YahtzeeData: Identifiable, Codable {
    var id = UUID()
    var currentPlayer: String  // gamePlayerID
    var numRounds: Int
    var disableScoreboard: Bool = false
    var disableDice: Bool = false
    var jokerRule: Bool = false
    
    var playerData: [YahtzeePlayerData]
    var autoMatching: Set<String> = []
    var yahtzeeDiceManager: YahtzeeDiceManager = YahtzeeDiceManager()
    
    init(
        id: UUID = UUID(),
        players: [GKPlayer?],
        numRounds: Int = 3,
        currentPlayer: String
    ) {
        self.id = id
        self.playerData = []
        self.numRounds = numRounds
        self.currentPlayer = currentPlayer
        for player in players {
            if let player = player {
                self.playerData.append(
                    YahtzeePlayerData(
                        displayName: player.displayName,
                        gamePlayerID: player.gamePlayerID,
                        numRounds: self.numRounds
                    )
                )
            } else {
                let uuid = UUID().uuidString
                self.playerData.append(
                    YahtzeePlayerData(
                        displayName: nil,
                        gamePlayerID: uuid,
                        numRounds: self.numRounds
                    )
                )
                autoMatching.insert(uuid)
            }
        }
    }
    
    var endOfGame: Bool {
        return self.playerData.allSatisfy({ $0.currentRoundIndex == self.numRounds })
    }
    
    var myTurn: Bool {
        return self.currentPlayer == GKLocalPlayer.local.gamePlayerID
    }
    
    var currentPlayerDataRound: YahtzeeRound {
        get {
            return self.currentPlayerData.currentRound
        }
    }
    
    var currentPlayerData: YahtzeePlayerData {
        get {
            return self.playerData[self.currentPlayerDataIndex]
        }
    }
    
    var currentPlayerDataIndex: Int {
        get {
            if let index = self.playerData.firstIndex(
                where: {
                    $0.gamePlayerID == self.currentPlayer
                }
            ) {
                return index
            }
            return 0
        }
    }
    
    var playerDataSortedByTotal: YahtzeeGameRankings {
        get {
            let sorted = self.playerData.sorted(by: {
                $0.cusum.last ?? 0 > $1.cusum.last ?? 0
            })
            return YahtzeeGameRankings(
                sortedPlayers: sorted.map({ $0.gamePlayerID }),
                sortedScores: sorted.map({ $0.cusum.last ?? 0 })
            )
        }
    }
    
    var playersSortedByCompletedTurns: [String] {
        get {
            return self.playerData.sorted(by: {
                $0.completedTurns > $1.completedTurns
            }).map({ $0.gamePlayerID })
        }
    }
    
    func playerExists(player: GKPlayer) -> Bool {
        return playerData.contains(where: { $0.gamePlayerID == player.gamePlayerID })
    }
    
    mutating func addPlayer(player: GKPlayer) {
        // See if player already exists and if there is an open spot.
        if !playerExists(player: player),
           let index = playerData.firstIndex(where: { self.autoMatching.contains($0.gamePlayerID) }) {
            // Update automatching spots
            self.autoMatching.remove(self.playerData[index].gamePlayerID)
            // Add new player in open spot
            self.playerData[index] = YahtzeePlayerData(
                displayName: player.displayName,
                gamePlayerID: player.gamePlayerID,
                numRounds: self.numRounds
            )
        }
    }
    
    mutating func setCurrentPlayer(_ newPlayer: String) {
        self.currentPlayer = newPlayer
    }
    
    mutating func resetTurn() {
        self.jokerRule = false
        self.disableDice = false
        self.disableScoreboard = false
    }
    
    mutating func resetGame() {
        self.playerData = []
        self.resetTurn()
    }
    
    
    mutating func enableDisableDice() {
        self.disableDice = true
    }
    
    mutating func enableDisableScoreboard() {
        self.disableScoreboard = true
    }
    
    mutating func enableJoker() {
        self.jokerRule = true
    }
}


struct YahtzeeGameRankings {
    var sortedPlayers: [String]
    var sortedScores: [Int]
    
    var rankings: [Int] {
        // 1, 1, 2, 3, 3, 4, 5
        /// sortedScores: [5, 5, 4, 3, 3, 2, 1]
        /// returns: [1, 1, 2, 3, 3, 4, 5]
        get {
            var index: Int = 0
            var currentRanking: Int = 1
            var rankings: [Int] = []
            while index < sortedScores.count {
                rankings.append(currentRanking)
                if index + 1 < sortedScores.count {
                    if sortedScores[index] > sortedScores[index + 1] {
                        // We have no more of the current ranking.
                        currentRanking += 1
                    }
                }
                index += 1
            }
            return rankings
        }
    }
}
