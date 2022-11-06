//
//  TurnBasedBoardView.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 10/20/22.
//

import SwiftUI
import GameKit

struct TurnBasedBoardView: View {
    @EnvironmentObject var gkManager: GKManager
    @EnvironmentObject var simManager: SimulationManager
    @ObservedObject var diceManager: DiceManager
    @Binding var counter: Int
    @Binding var yahtzeeShowing: Bool
    @State var player: GKPlayer = GKPlayer()
    @State var showSimulator: Bool = false
    @State var showSettings: Bool = false
    @State var visibleIndices: Set<Int> = Set<Int>()
    @State var animationIndices: Set<Int> = Set<Int>()
    
    let showYahtzeeBanner: () -> Void
    
    var body: some View {
        VStack {
            TurnBasedBoardHeaderView(
                diceManager: diceManager,
                showSimulator: $showSimulator,
                showSettings: $showSettings,
                visibleIndices: $visibleIndices,
                animationIndices: $animationIndices,
                closedSave: closedSave,
                roll: roll
            )
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundColor(.secondary)
                    .opacity(diceManager.count == 0 ? 0.2 : 0.0)
                    .animation(.easeOut, value: diceManager.count)
                BoardDieView(
                    diceManager: diceManager,
                    visibleIndices: $visibleIndices,
                    animationIndices: $animationIndices,
                    closedSave: closedSave
                )
                .opacity(diceManager.count == 0 ? 0.0 : 1.0)
                .animation(nil, value: diceManager.count)
            }
            .onChange(of: diceManager.count) { value in
                if value == 0 {
                    self.diceManager.lockSelection = [:]
                }
                let values = self.diceManager.dice.map { $0.value }
                if isYahtzee(batch: values) &&
                    diceManager.count > 0 {
                    counter += 1
                    yahtzeeShowing = true
                    showYahtzeeBanner()
                } else {
                    yahtzeeShowing = false
                }
                self.gkManager.data.yahtzeeDiceManager.dice = values
                self.gkManager.data.yahtzeeDiceManager.lockSelection = self.diceManager.lockSelection
                Task {
                    await self.gkManager.saveCurrentTurn()
                }
            }
            HStack {
                Button {
                    let diceValue = [1, 2, 3, 4, 5, 6].randomElement() ?? 1
                    diceManager.setDice([Int](repeating: diceValue, count: 5))
                    diceManager.count += 1
                } label: {
                    Text("Y")
                }
                .buttonStyle(.borderless)
                Spacer()
                DiceFrozenHelperView(
                    diceManager: diceManager,
                    closedSave: closedSave
                )
                .disabled(diceManager.count == 0)
                .opacity(diceManager.count == 0 ? 0.0 : 1.0)
            }
        }
        .sheet(isPresented: $showSimulator) {
            if #available(iOS 16.0, *) {
                SimulatorView(
                    totalDice: $diceManager.totalDice,
                    selectedDice: $diceManager.sidesOptional,
                    lockSelection: $diceManager.lockSelection,
                    shownAsSheet: true,
                    editableHeader: false
                )
                .presentationDetents([.fraction(0.99)])
            } else {
                SimulatorView(
                    totalDice: $diceManager.totalDice,
                    selectedDice: $diceManager.sidesOptional,
                    lockSelection: $diceManager.lockSelection,
                    shownAsSheet: true,
                    editableHeader: false
                )
            }
        }
    }
    
    func closedSave() -> Void {
        
    }
    
    public func roll(_ diceManager: DiceManager) {
        switch diceManager.selectionMode {
        case .single, .shuffle, .sort, .freezable, .edit:
            diceManager.count += 1
            diceManager.selectionModeRoll()
        }
    }
    
    func isYahtzee(batch: [Int]) -> Bool {
        let eventManager = getEventManager(.yahtzee)
        do {
            let occured = try simManager.simulateSingleBatch(
                events: eventManager.events,
                eventSize: 5,
                diceType: .D6,
                lockSelection: [:],
                batch: batch
            )
            return occured
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}

struct TurnBasedBoardHeaderView: View {
    @EnvironmentObject var gkManager: GKManager
    @StateObject var diceManager: DiceManager
    @Binding var showSimulator: Bool
    @Binding var showSettings: Bool
    @Binding var visibleIndices: Set<Int>
    @Binding var animationIndices: Set<Int>
    
    let closedSave: () -> Void
    let roll: (DiceManager) -> Void
    let changeDelay: Double = 0.1
    
    var body: some View {
        VStack {
            HStack {
                if diceManager.showProfile {
                    Text(diceManager.name)
                        .foregroundColor(.accentColor)
                }
                Spacer()
            }
            HStack {
                RollButton(
                    diceManager: diceManager,
                    visibleIndices: $visibleIndices,
                    animationIndices: $animationIndices,
                    closedSave: closedSave,
                    roll: roll
                )
                if let image = self.gkManager.playerImage[self.gkManager.data.currentPlayer] {
                    PlayerView(playerImage: image)
                } else {
                    PlayerView(playerImage: nil)
                }
                Spacer()
                HStack {
                    Text("\(diceManager.count)")
                        .font(.headline.bold())
                    Text("Roll")
                        .font(.subheadline)
                }
                Spacer()
                Button {
                    showSimulator = true
                } label: {
                    Image(systemName: "flowchart.fill")
                }
                .buttonStyle(.borderless)
                .disabled(diceManager.dice.isEmpty)
                Button {
                    showSettings.toggle()
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .imageScale(.large)
                }
                .buttonStyle(.borderless)
                .padding(.leading, 0)
            }
        }
    }
}
