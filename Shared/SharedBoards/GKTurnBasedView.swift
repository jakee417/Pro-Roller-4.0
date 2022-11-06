//
//  GKTurnBasedView.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 10/20/22.
//

import SwiftUI
import GameKit
import ConfettiSwiftUI

enum TurnBasedGames: String, CaseIterable, Codable {
    case yahtzee = "Yahtzee"
    case farkle = "Farkle"
}
                        
struct GKTurnBasedView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var gkManager: GKManager
    @State var game: TurnBasedGames = .yahtzee
    @StateObject var yahtzeeManager: DiceManager = DiceManager(
        name: "Yahtzee",
        dice: [
            Dice(sides: .D6, diceColor: .white),
            Dice(sides: .D6, diceColor: .white),
            Dice(sides: .D6, diceColor: .white),
            Dice(sides: .D6, diceColor: .white),
            Dice(sides: .D6, diceColor: .white)
        ],
        sides: .D6,
        selectionMode: .freezable
    )
    @State var counter: Int = 0
    @State var yahtzeeShowing: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                switch game {
                case .yahtzee:
                    TurnBasedBoardView(
                        diceManager: yahtzeeManager,
                        counter: $counter,
                        yahtzeeShowing: $yahtzeeShowing,
                        showYahtzeeBanner: showYahtzeeBanner
                    )
                    .disabled(endRound())
                    .blur(radius: endRound() ? 0.7 : 0.0)
                    .scaleEffect(endRound() ? 0.95 : 1.0)
                    .animation(.default, value: yahtzeeManager.count)
                    .listRowSeparator(.hidden)
                case .farkle:
                    EmptyView()
                        .listRowSeparator(.hidden)
                }
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .foregroundColor(.secondary)
                        .opacity(0.2)
                    switch game {
                    case .yahtzee:
                        YahtzeeScoreBoardView(data: self.$gkManager.data)
                            .environmentObject(yahtzeeManager)
                    case .farkle:
                        EmptyView()
                    }
                }
                .listRowSeparator(.hidden)
            }
            .navigationTitle(game.rawValue)
            .listStyle(.plain)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    EmptyView()
                        .modifier(
                            YahtzeeConfetti(
                                counter: $counter,
                                openingAngle: 270,
                                closingAngle: 360
                            )
                        )
                    if counter > 0 && yahtzeeShowing {
                        Button {
                            counter += 1
                            showYahtzeeBanner()
                        } label: {
                            HStack(spacing: 2) {
                                Text("replay")
                                    .font(.caption2)
                                Image(systemName: "arrow.counterclockwise.circle.fill")
                                    .resizable()
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .buttonStyle(.borderless)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    EmptyView()
                        .modifier(
                            YahtzeeConfetti(
                                counter: $counter,
                                openingAngle: 180,
                                closingAngle: 270
                            )
                        )
                    Button {
                        DispatchQueue.main.async {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }
    
    func endRound() -> Bool {
        return (
            yahtzeeManager.count >= 3 ||
            self.gkManager.data.disableDice ||
            !self.gkManager.data.myTurn
        )
    }
    
    func showYahtzeeBanner() {
        Task {
            let currentPlayer = await gkManager.currentPlayer
            DispatchQueue.main.async {
                if let currentPlayer = currentPlayer {
                    GKNotificationBanner.show(
                        withTitle: "\(currentPlayer.displayName) Rolled A Yahtzee!!!",
                        message: nil, completionHandler: nil
                    )
                } else {
                    GKNotificationBanner.show(
                        withTitle: "A Yahtzee was Rolled!!!",
                        message: nil, completionHandler: nil
                    )
                }
            }
        }
    }
}

struct YahtzeeConfetti: ViewModifier {
    @Binding var counter: Int
    
    var openingAngle: Double = 60
    var closingAngle: Double = 120

    func body(content: Content) -> some View {
        content
            .confettiCannon(
                counter: $counter,
                num: 50,
                confettis: [
                    .text("🎲"),
                    .shape(.circle),
                    .shape(.square),
                    .shape(.slimRectangle)
                ],
                colors: [
                    .blue,
                    .red,
                    .green,
                    .purple,
                    .orange
                ],
                confettiSize: 10.0,
                rainHeight: 600,
                fadesOut: true,
                opacity: 1.0,
                openingAngle: Angle(degrees: openingAngle),
                closingAngle: Angle(degrees: closingAngle),
                radius: 400,
                repetitions: 0,
                repetitionInterval: 0.7
            )
    }
}

struct GKTurnBasedView_Previews: PreviewProvider {
    static var previews: some View {
        GKTurnBasedView()
            .environmentObject(GKManager())
            .environmentObject(SimulationManager())
    }
}
