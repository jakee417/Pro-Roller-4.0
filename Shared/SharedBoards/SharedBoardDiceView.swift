//
//  SharedBoardDiceView.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 9/26/22.
//

import Foundation
import SwiftUI
import GameKit

struct SharedBoardDiceView: View {
    @ObservedObject var diceManager: DiceManager
    @Binding var player: GKPlayer
    @State var showHistogram: Bool = false
    
    var body: some View {
        VStack {
            SharedBoardDiceHeaderView(diceManager: diceManager, player: $player)
            SharedBoardDieView(diceManager: diceManager)
            HistogramView(
                diceManager: diceManager,
                showHistogram: $showHistogram
            )
            .transition(.moveAndFade)
        }
    }
}

struct SharedBoardDiceHeaderView: View {
    @EnvironmentObject var gkManager: GKManager
    @StateObject var diceManager: DiceManager
    @Binding var player: GKPlayer
    @State var showSimulator: Bool? = false
    @State var diceChange: Bool = false
    @State var sidesChange: Bool = false
    @State var modeChange: Bool = false
    
    let changeDelay: Double = 0.1
    
    var body: some View {
        ZStack {
            NavigationLink(destination:  SimulatorView(totalDice: $diceManager.totalDice, selectedDice: $diceManager.sidesOptional, lockSelection: $diceManager.lockSelection, shownAsSheet: true), tag: true, selection: $showSimulator) {
                EmptyView()
            }
            .opacity(0.0)
            .disabled(true)
            VStack {
                HStack {
                    if diceManager.showProfile {
                        Text(diceManager.name)
                            .foregroundColor(.accentColor)
                    }
                    Spacer()
                }
                HStack {
                    if let uiImage = self.gkManager.playerImage[player.gamePlayerID] {
                        PlayerView(playerImage: uiImage)
                            .modifier(SignalScale(signalChange: $diceChange))
                            .onChange(of: diceManager.dice) { _ in
                                withAnimation {
                                    diceChange = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + changeDelay) {
                                    withAnimation {
                                        self.diceChange = false
                                    }
                                }
                            }
                    } else {
                        PlayerView(playerImage: nil)
                            .modifier(SignalScale(signalChange: $diceChange))
                            .onChange(of: diceManager.dice) { _ in
                                withAnimation {
                                    diceChange = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + changeDelay) {
                                    withAnimation {
                                        self.diceChange = false
                                    }
                                }
                            }
                    }
                    Text("D\(diceManager.sides.rawValue)")
                        .padding(.all, 2)
                        .modifier(ButtonInset(opacity: false, color: .secondary))
                        .modifier(SignalScale(signalChange: $sidesChange))
                        .onChange(of: diceManager.sides) { _ in
                            withAnimation {
                                sidesChange = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + changeDelay) {
                                withAnimation {
                                    self.sidesChange = false
                                }
                            }
                        }
                    Spacer()
                    Button {
                        showSimulator = true
                    } label: {
                        Image(systemName: "flowchart.fill")
                    }
                    .buttonStyle(.borderless)
                    .disabled(diceManager.dice.isEmpty)
                    Image(systemName: rollTypeImage(diceManager.selectionMode))
                        .imageScale(.large)
                        .foregroundColor(.secondary)
                        .modifier(SignalScale(signalChange: $modeChange))
                        .onChange(of: diceManager.selectionMode) { _ in
                            withAnimation {
                                modeChange = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation {
                                    self.modeChange = false
                                }
                            }
                        }
                }
            }
        }
    }
}

struct SignalScale: ViewModifier {
    @Binding var signalChange: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(signalChange ? 1.1 : 1.0)
    }
}
