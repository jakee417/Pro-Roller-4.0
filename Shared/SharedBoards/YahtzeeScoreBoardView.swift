//
//  YahtzeeScoreBoardView.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 10/21/22.
//

import SwiftUI
import GameKit

enum YahtzeeScoreBoardType: String {
    case players = "players"
    case rounds = "rounds"
}

struct YahtzeeScoreBoardView: View {
    @EnvironmentObject var gkManager: GKManager
    @EnvironmentObject var yahtzeeManager: DiceManager
    @Binding var data: YahtzeeData
    @State var roundSelection: Int = 0
    @State var showScoreCard: Bool = true
    
    
    let rows: [GridItem] = [GridItem](
        repeating: GridItem(.flexible(), spacing: 20),
        count: 26
    )
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    withAnimation(.spring()) {
                        showScoreCard.toggle()
                    }
                } label: {
                    Label("Boards", systemImage: "chevron.right.circle.fill")
                        .labelStyle(.iconOnly)
                        .imageScale(.large)
                        .rotationEffect(.degrees(showScoreCard ? 90 : 0))
                        .scaleEffect(showScoreCard ? 1.1 : 1)
                }
                .buttonStyle(.borderless)
                .padding(.leading, 5)
                RoundMenu(data: $data, roundSelection: $roundSelection)
                Spacer()
                if self.data.disableScoreboard {
                    Button(role: .destructive) {
                        self.yahtzeeManager.count = 0
                        self.data.resetTurn()
                        Task {
                            await self.gkManager.takeTurn()
                        }
                    } label: {
                        Text("End Turn")
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                }
            }
            if showScoreCard {
                HStack {
                    YahtzeeLeadColumn(rows: rows)
                        .padding(.all, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.secondary)
                                .opacity(0.1)
                        )
                    YahtzeePlayerView(
                        data: self.$data,
                        roundSelection: $roundSelection,
                        rows: rows
                    )
                }
            }
        }
    }
}

struct RoundMenu: View {
    @Binding var data: YahtzeeData
    @Binding var roundSelection: Int
    
    var body: some View {
        Menu(
            content: {
                Picker("", selection: $roundSelection) {
                    ForEach(0...data.numRounds - 1, id: \.self) {
                        Text(
                            "Round \($0 + 1)"
                        )
                    }
                }
            },
            label: {
                HStack {
                    (
                        Text("Round ") +
                        Text(Image(systemName: "\(roundSelection + 1).circle.fill"))
                    )
                }
                .padding(.all, 2)
                .modifier(ButtonInset(opacity: false))
            }
        )
    }
}

struct YahtzeeLeadColumn: View {
    let rows: [GridItem]
    
    let lowerLeading = [
        "Lower",
        "3 of a Kind",
        "4 of a Kind",
        "Full House",
        "Sm. Straight",
        "Lg. Straight",
        "Yahtzee",
        "Chance",
        "Yahtzee Bonus",
        "Lower Total"
    ]
    
    var body: some View {
        LazyHGrid(rows: rows, alignment: .center, spacing: 10) {
            Text("")
            Group {
                Text("Upper")
                    .font(.title3.bold())
                Text("Ones")
                Text("Twos")
                Text("Threes")
                Text("Fours")
                Text("Fives")
                Text("Sixes")
                Text("Subtotal")
                    .font(.subheadline.italic())
                Text("Bonus")
                Text("Upper Total")
                    .font(.headline.italic())
            }
            Text("")
            Group {
                Text("Lower")
                    .font(.title3.bold())
                Text("3 of a Kind")
                Text("4 of a Kind")
                Text("Full House")
                Text("Sm. Straight")
                Text("Lg. Straight")
                Text("Yahtzee")
                Text("Chance")
                Text("Yahtzee Bonus")
                Text("Lower Total")
                    .font(.headline.italic())
            }
            Group {
                Text("")
                Text("Round Total")
                    .font(.headline.italic())
                Text("Grand Total")
                    .font(.headline.italic())
                Text("")
            }
        }
    }
}

struct YahtzeePlayerView: View {
    @EnvironmentObject var gkManager: GKManager
    @Binding var data: YahtzeeData
    @Binding var roundSelection: Int
    @State var playerSelection: String = ""
    @State var showRounds: Bool = false
    
    let rows: [GridItem]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: rows, alignment: .center, spacing: 20) {
                ForEach(self.$data.playerData) { $playerData in
                    Text("")
                    Button {
                        playerSelection = playerData.gamePlayerID
                        showRounds = true
                    } label: {
                        HStack {
                            if let displayName = playerData.displayName {
                                Text("\(displayName)")
                                    .font(.subheadline.bold())
                            }
                            if let image = self.gkManager.playerImage[playerData.gamePlayerID] {
                                PlayerView(playerImage: image)
                            } else {
                                PlayerView(playerImage: nil)
                            }
                        }
                    }
                    .buttonStyle(.bordered)
                    .sheet(isPresented: $showRounds) {
                        YahtzeeRoundSheet(
                            data: $data,
                            currentPlayer: $playerSelection,
                            rows: rows
                        )
                    }
                    if (
                        playerData.gamePlayerID != data.currentPlayer ||
                        playerData.currentRoundIndex != roundSelection ||
                        !data.myTurn ||
                        data.disableScoreboard
                    ) {
                        UpperView(
                            round: $playerData.rounds[roundSelection],
                            disabled: true
                        )
                        LowerView(
                            round: $playerData.rounds[roundSelection],
                            disabled: true
                        )
                    } else {
                        UpperView(
                            round: $playerData.rounds[roundSelection],
                            disabled: false
                        )
                        LowerView(
                            round: $playerData.rounds[roundSelection],
                            disabled: false
                        )
                    }
                    Text("")
                    Text("\(playerData.rounds[roundSelection].total)")
                        .font(.headline.bold())
                    Text("\(playerData.cusum[roundSelection])")
                        .font(.headline.bold())
                    Text("")
                }
            }
        }
    }
}

struct YahtzeeRoundSheet: View {
    @EnvironmentObject var gkManager: GKManager
    @Environment(\.dismiss) var dismiss
    @Binding var data: YahtzeeData
    @Binding var currentPlayer: String
    
    let rows: [GridItem]
    
    var body: some View {
        NavigationView {
            List {
                HStack {
                    YahtzeeLeadColumn(rows: rows)
                        .padding(.all, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.secondary)
                                .opacity(0.1)
                        )
                    if let playerData = self.data.playerData.first(where: { $0.gamePlayerID == currentPlayer }) {
                        YahtzeeRoundView(
                            playerData: playerData,
                            currentPlayer: $currentPlayer,
                            rows: rows
                        )
                    }
                }
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if let playerData = self.data.playerData.first(where: { $0.gamePlayerID == currentPlayer }) {
                        if let image = self.gkManager.playerImage[playerData.gamePlayerID] {
                            PlayerView(playerImage: image)
                        } else {
                            PlayerView(playerImage: nil)
                        }
                        if let displayName = playerData.displayName {
                            Text(displayName)
                                .font(.headline.bold())
                        } else {
                            Text("Automatching")
                                .font(.headline.bold())
                        }
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}

struct YahtzeeRoundView: View {
    @State var playerData: YahtzeePlayerData
    @Binding var currentPlayer: String
    
    let rows: [GridItem]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: rows, alignment: .center, spacing: 20) {
                ForEach(self.$playerData.rounds) { $round in
                    if let index = playerData.rounds.firstIndex(of: round) {
                        Text("")
                        HStack {
                            (
                                Text("Round ") +
                                Text(Image(systemName: "\(index + 1).circle.fill"))
                            )
                                .font(.subheadline.bold())
                        }
                        .modifier(ButtonInset(opacity: false, color: .secondary))
                        UpperView(round: $round, disabled: true)
                        LowerView(round: $round, disabled: true)
                        Text("")
                        Text("\(round.total)")
                            .font(.headline.bold())
                        Text("\(playerData.cusum[index])")
                            .font(.headline.bold())
                        Text("")
                    }
                }
            }
        }
    }
}

struct UpperView: View {
    @Binding var round: YahtzeeRound
    @State var disabled: Bool
    
    var body: some View {
        if disabled {
            InsertText(event: $round.upperSection.ones)
            InsertText(event: $round.upperSection.twos)
            InsertText(event: $round.upperSection.threes)
            InsertText(event: $round.upperSection.fours)
            InsertText(event: $round.upperSection.fives)
            InsertText(event: $round.upperSection.sixes)
        } else {
            Group {
                InsertButton(event: $round.upperSection.ones)
                InsertButton(event: $round.upperSection.twos)
                InsertButton(event: $round.upperSection.threes)
                InsertButton(event: $round.upperSection.fours)
                InsertButton(event: $round.upperSection.fives)
                InsertButton(event: $round.upperSection.sixes)
            }
        }
        Text("\(round.upperSection.subTotal)")
        Text("\(round.upperSection.bonusAmount)")
        Text("\(round.upperSection.total)")
            .font(.headline.bold())
        Text("")
    }
}

struct LowerView: View {
    @Binding var round: YahtzeeRound
    @State var disabled: Bool
    
    var body: some View {
        Text("")
        if disabled {
            InsertText(event: $round.lowerSection.threeOfAKind)
            InsertText(event: $round.lowerSection.fourOfAKind)
            InsertText(event: $round.lowerSection.fullHouse)
            InsertText(event: $round.lowerSection.smallStraight)
            InsertText(event: $round.lowerSection.largeStraight)
            InsertText(event: $round.lowerSection.yahtzee)
            InsertText(event: $round.lowerSection.chance)
            YahtzeeBonusText(event: $round.lowerSection.yahtzeeBonus)
        } else {
            InsertButton(event: $round.lowerSection.threeOfAKind)
            InsertButton(event: $round.lowerSection.fourOfAKind)
            InsertButton(event: $round.lowerSection.fullHouse)
            InsertButton(event: $round.lowerSection.smallStraight)
            InsertButton(event: $round.lowerSection.largeStraight)
            InsertButton(event: $round.lowerSection.yahtzee)
            InsertButton(event: $round.lowerSection.chance)
            YahtzeeBonusButton(
                event: $round.lowerSection.yahtzeeBonus,
                round: $round
            )
        }
        Text("\(round.lowerSection.total)")
            .font(.headline.bold())
    }
}

struct YahtzeeBonusText: View {
    @Binding var event: YahtzeeBonusEvent
    
    var body: some View {
        Image(systemName: "\(event.scores.count).circle.fill")
            .imageScale(.small)
    }
}

struct YahtzeeBonusButton: View {
    @EnvironmentObject var gkManager: GKManager
    @EnvironmentObject var yahtzeeManager: DiceManager
    @StateObject var simManager: SimulationManager = SimulationManager()
    @Binding var event: YahtzeeBonusEvent
    @Binding var round: YahtzeeRound
    @State var automaticBonus: Bool = false
    @State var showAlert: Bool = false
    @State var score: Int = 0
    @State var type: YahtzeeEventType = .yahtzee
    
    var body: some View {
        YahtzeeBonusText(event: $event)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Yahtzee Bonus!"),
                    message: Text(
                        automaticBonus ?
                        "\(self.event.yahtzeeBonusEnabled ? "You scored 100 extra points and" : "You scored") \(score) points for \(type.rawValue)" :
                            "\(self.event.yahtzeeBonusEnabled ? "You scored 100 extra points, but" : "But") \(type.rawValue) are already scored."
                    ),
                    dismissButton: (
                        automaticBonus ?
                            .destructive(Text("End Turn")) {
                                withAnimation(.easeIn) {
                                    self.gkManager.data.enableDisableDice()
                                    self.gkManager.data.enableDisableScoreboard()
                                }
                            }
                        : .cancel(Text("Score Yahtzee Joker")) {
                            self.gkManager.data.enableDisableDice()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeIn) {
                                    self.gkManager.data.enableJoker()
                                }
                            }
                        }
                    )
                )
            }
            .onChange(of: yahtzeeManager.count) { _ in
                if isYahtzee() && event.yahtzeeScored {
                    if event.yahtzeeBonusEnabled {
                        self.event.addScore()
                    }
                    // Conduct a default Upper section action if possible
                    if let dice = self.yahtzeeManager.dice.first {
                        let value = dice.value
                        score = 5 * value
                        if value == 1 {
                            type = .ones
                            if round.upperSection.ones.score == nil {
                                round.upperSection.ones.updateScore(score)
                                self.automaticBonus = true
                            } else {
                                self.automaticBonus = false
                            }
                        } else if value == 2 {
                            type = .twos
                            if round.upperSection.twos.score == nil {
                                round.upperSection.twos.updateScore(score)
                                self.automaticBonus = true
                            } else {
                                self.automaticBonus = false
                            }
                        } else if value == 3 {
                            type = .threes
                            if round.upperSection.threes.score == nil {
                                round.upperSection.threes.updateScore(score)
                                self.automaticBonus = true
                            } else {
                                self.automaticBonus = false
                            }
                        } else if value == 4 {
                            type = .fours
                            if round.upperSection.fours.score == nil {
                                round.upperSection.fours.updateScore(score)
                                self.automaticBonus = true
                            } else {
                                self.automaticBonus = false
                            }
                        } else if value == 5 {
                            type = .fives
                            if round.upperSection.fives.score == nil {
                                round.upperSection.fives.updateScore(score)
                                self.automaticBonus = true
                            } else {
                                self.automaticBonus = false
                            }
                        } else if value == 6 {
                            type = .sixes
                            if round.upperSection.sixes.score == nil {
                                round.upperSection.sixes.updateScore(score)
                                self.automaticBonus = true
                            } else {
                                self.automaticBonus = false
                            }
                        }
                        self.showAlert = true
                    }
                }
            }
    }
    
    func isYahtzee() -> Bool {
        let eventManager = getEventManager(.yahtzee)
        do {
            let occured = try simManager.simulateSingleBatch(
                events: eventManager.events,
                eventSize: 5,
                diceType: .D6,
                lockSelection: [:],
                batch: yahtzeeManager.dice.map({ $0.value })
            )
            return occured
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

struct InsertText: View {
    @Binding var event: YahtzeeEvent
    
    var body: some View {
        if let score = event.score {
            Text(convertScoreToString(score))
                .font(.caption2)
        } else {
            Text("")
        }
    }
}

struct InsertButton: View {
    @EnvironmentObject var gkManager: GKManager
    @EnvironmentObject var yahtzeeManager: DiceManager
    @StateObject var simManager: SimulationManager = SimulationManager()
    @Binding var event: YahtzeeEvent
    @State var showConfirmation: Bool = false
    
    var score: Int {
        get {
            switch event.eventType {
            case .ones:
                return sumUpper(value: 1)
            case .twos:
                return sumUpper(value: 2)
            case .threes:
                return sumUpper(value: 3)
            case .fours:
                return sumUpper(value: 4)
            case .fives:
                return sumUpper(value: 5)
            case .sixes:
                return sumUpper(value: 6)
            case .threeOfAKind:
                if checkLower(.threeOfAKind) {
                    return yahtzeeManager.totalRoll
                }
                return 0
            case .fourOfAKind:
                if checkLower(.fourOfAKind) {
                    return yahtzeeManager.totalRoll
                }
                return 0
            case .fullHouse:
                if checkLower(.fullHouse) || self.gkManager.data.jokerRule {
                    return 25
                }
                return 0
            case .smallStraight:
                if checkLower(.smallStraight) || self.gkManager.data.jokerRule {
                    return 30
                }
                return 0
            case .largeStraight:
                if checkLower(.largeStraight) || self.gkManager.data.jokerRule {
                    return 40
                }
                return 0
            case .yahtzee:
                if checkLower(.yahtzee) {
                    return 50
                }
                return 0
            case .chance:
                return yahtzeeManager.totalRoll
            }
        }
    }
    
    var body: some View {
        if let eventScore = event.score {
            Text(convertScoreToString(eventScore))
                .font(.caption2)
        } else {
            if yahtzeeManager.count == 0 {
                Text("")
            } else {
                Button {
                    showConfirmation = true
                } label: {
                    Text("\(score)")
                        .font(.caption2)
                        .foregroundColor(score > 0 ? .green : .red)
                }
                .buttonStyle(.borderless)
                .confirmationDialog("", isPresented: $showConfirmation) {
                    Button(
                        "Accept \(score) for \(event.eventType.rawValue)",
                        role: score > 0 ? .none : .destructive
                    ) {
                        withAnimation(.easeIn) {
                            self.event.updateScore(score)
                            self.gkManager.data.enableDisableDice()
                            self.gkManager.data.enableDisableScoreboard()
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("End Turn & Pass To Next Player?")
                }
            }
        }
    }
    
    func sumUpper(value: Int) -> Int {
        return yahtzeeManager.dice
            .map({ $0.value })
            .filter({ $0 == value })
            .reduce(0, +)
    }
    
    func checkLower(_ event: YahtzeeEventType) -> Bool {
        let eventManager = getEventManager(event)
        do {
            let occured = try simManager.simulateSingleBatch(
                events: eventManager.events,
                eventSize: 5,
                diceType: .D6,
                lockSelection: [:],
                batch: yahtzeeManager.dice.map({ $0.value })
            )
            return occured
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

func convertScoreToString(_ score: Int?) -> String {
    guard let score = score else {
        return ""
    }
    return "\(score)"
}

func getEventManager(_ event: YahtzeeEventType) -> EventManager {
    switch event {
    case .ones:
        return EventManager(
            name: "Ones",
            events: [Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .first, reduction: .each, comparison: .equals, value: 1)]
        )
    case .twos:
        return EventManager(
            name: "Twos",
            events: [Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .first, reduction: .each, comparison: .equals, value: 2)]
        )
    case .threes:
        return EventManager(
            name: "Threes",
            events: [Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .first, reduction: .each, comparison: .equals, value: 3)]
        )
    case .fours:
        return EventManager(
            name: "Fours",
            events: [Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .first, reduction: .each, comparison: .equals, value: 4)]
        )
    case .fives:
        return EventManager(
            name: "Fives",
            events: [Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .first, reduction: .each, comparison: .equals, value: 5)]
        )
    case .sixes:
        return EventManager(
            name: "Sixes",
            events: [Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .first, reduction: .each, comparison: .equals, value: 6)]
        )
    case .threeOfAKind:
        return EventManager(
            name: "Three of a Kind",
            events: (1...6).map({Event(bound: .geq, quantity: 3, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
        )
    case .fourOfAKind:
        return EventManager(
            name: "Four of a Kind",
            events: (1...6).map({Event(bound: .geq, quantity: 4, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
        )
    case .fullHouse:
        return EventManager(
            name: "Full House",
            events: Array((1...6)).permutations(ofCount: 2).map({[
                Event(bound: .exactly, quantity: 3, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: $0.first!),
                Event(bound: .exactly, quantity: 2, dice: .D6, conjunction: .and, reduction: .each, comparison: .equals, value: $0.last!)
            ]}).reduce([], +)
        )
    case .smallStraight:
        return EventManager(
            name: "Small Straight",
            events: Array((1...4)).map({Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .and, reduction: .each, comparison: .equals, value: $0)}) +
            [Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: 2)] +
            Array((3...5)).map({Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .and, reduction: .each, comparison: .equals, value: $0)}) +
            [Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: 3)] +
            Array((4...6)).map({Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .and, reduction: .each, comparison: .equals, value: $0)})
        )
    case .largeStraight:
        return EventManager(
            name: "Large Straight",
            events: Array((1...5)).map({Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .and, reduction: .each, comparison: .equals, value: $0)}) +
            [Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: 2)] +
            Array((3...6)).map({Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .and, reduction: .each, comparison: .equals, value: $0)})
        )
    case .yahtzee:
        return EventManager(
            name: "Yahtzee",
            events: (1...6).map({ Event(bound: .exactly, quantity: 5, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
        )
    case .chance:
        return EventManager(name: "")
    }
}
