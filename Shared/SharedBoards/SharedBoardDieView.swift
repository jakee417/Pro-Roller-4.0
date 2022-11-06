//
//  SharedBoardDieView.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 9/27/22.
//

import Foundation
import SwiftUI

struct SharedBoardDieView: View {
    @ObservedObject var diceManager: DiceManager
    @State var animationIndices: Set<Int> = []
    @State var oldDice: [Dice] = []
    @State var visibleIndices: Set<Int> = Set<Int>()
    
    let rows = [
        GridItem(.adaptive(minimum: 80)),
        GridItem(.adaptive(minimum: 80))
    ]
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.secondary)
                .opacity(0.2)
            ScrollView(.horizontal) {
                LazyHGrid(rows: rows, alignment: .center, spacing: 20) {
                    ForEach(diceManager.dice.indices, id: \.self) { index in
                        diceManager.dice[index].renderView()
                            .opacity(animationGuard(index: index) ? 0.0 : 1.0)
                            .rotation3DEffect(
                                .degrees(animationGuard(index: index) ? 0 : 360),
                                axis: (
                                    x: diceManager.dice[index].x,
                                    y: diceManager.dice[index].y,
                                    z: diceManager.dice[index].z
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.diceCornerRadius)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .white]),
                                            startPoint: .bottomLeading,
                                            endPoint: .topTrailing
                                        )
                                    )
                                    .opacity(shouldFreeze(index: index) ? 0.5 : 0.0)
                                    .frame(width: Constants.diceSize + 5, height: Constants.diceSize + 5)
                            )
                            .onAppear {
                                visibleIndices.insert(index)
                            }
                            .onDisappear {
                                visibleIndices.remove(index)
                            }
                    }
                    .onChange(of: diceManager.dice) { newDice in
                        for index in newDice.indices {
                            if index < self.oldDice.count {
                                let oldDie = self.oldDice[index]
                                let newDie = newDice[index]
                                if oldDie.value != newDie.value && visibleIndices.contains(index) {
                                    _ = self.animationIndices.insert(index)
                                }
                            }
                        }
                        self.oldDice = newDice
                        withAnimation {
                            self.animationIndices = Set<Int>()
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(minHeight: Constants.boardMinHeight, maxHeight: Constants.boardMaxHeight)
        }
    }
    
    func animationGuard(index: Int) -> Bool {
        if diceManager.selectionMode == .freezable {
            return (
                diceManager.animate &&
                // Only apply the lockIndices if we are in freezable
                !diceManager.lockSelection.contains(where: {$0.key == index}) &&
                animationIndices.contains(index)
            )
        } else {
            return (
                diceManager.animate &&
                animationIndices.contains(index)
            )
        }
    }
    
    func shouldFreeze(index: Int) -> Bool {
        diceManager.selectionMode == .freezable &&
        diceManager.lockSelection.contains(where: {$0.key == index})
    }
}
