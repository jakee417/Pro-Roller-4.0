//
//  SharedBoardView.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 9/22/22.
//

import SwiftUI
import GameKit
import GameKitUI

struct SharedBoardView: View {
    @EnvironmentObject var gkManager: GKManager
    @ObservedObject var diceManagers: DiceManagers
    @State var player: GKPlayer
    @State var uiImage: UIImage? = nil
    @State var showPlayer: Bool = true
    @State var initPhoto: Bool = true

    var body: some View {
        VStack {
            VStack {
                HStack {
                    Button {
                        withAnimation(.spring()) {
                            showPlayer.toggle()
                        }
                    } label: {
                        Label("Friend", systemImage: "chevron.right.circle.fill")
                            .labelStyle(.iconOnly)
                            .imageScale(.large)
                            .rotationEffect(.degrees(showPlayer ? 90 : 0))
                            .scaleEffect(showPlayer ? 1.1 : 1)
                        HStack {
                            Text("\(player.displayName)")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(.borderless)
                    Spacer()
                    HStack {
                        if !showPlayer {
                            Image(systemName: "\(diceManagers.managers.count).circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                HStack {
                    Text("View a Friend's Dice")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            if showPlayer {
                ForEach(diceManagers.managers) { diceManager in
                    SharedBoardDiceView(diceManager: diceManager, player: $player)
                }
            }
        }
        .contextMenu {
            Button("Nudge 👈") {
                gkManager.nudge(player)
            }
            Button("Huzzah 🥳") {
                gkManager.huzzah(player)
            }
            Button("Oof 😵‍💫") {
                gkManager.oof(player)
            }
        }
    }
}
