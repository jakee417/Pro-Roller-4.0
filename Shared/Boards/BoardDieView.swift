import SwiftUI

struct BoardDieView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var diceManager: DiceManager
    @Binding var visibleIndices: Set<Int>
    @Binding var animationIndices: Set<Int>
    
    let closedSave: () -> Void
    
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
                        Button {
                            switch diceManager.selectionMode {
                            case .shuffle, .sort:
                                diceManager.pushForwardHistory(diceManager.settings)
                                diceManager.count += 1
                                animationIndices = visibleIndices
                                var animationChunks = Array(animationIndices).chunked(into: Constants.maxAnimations)
                                animationChunks.shuffle()
                                diceManager.selectionModeRoll()
                                let lastIndex = animationChunks.count
                                for (index, chunk) in animationChunks.enumerated() {
                                    let seconds = Constants.animationWaitTime * Double(index)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                                        withAnimation {
                                            self.animationIndices = self.animationIndices.symmetricDifference(chunk)
                                        }
                                    }
                                }
                                DispatchQueue.main.asyncAfter(
                                    deadline: .now() + Constants.animationWaitTime * Double(lastIndex)
                                ) {
                                    withAnimation {
                                        self.animationIndices = Set<Int>()
                                    }
                                }
                            case .single:
                                diceManager.pushForwardHistory(diceManager.settings)
                                diceManager.count += 1
                                UIImpactFeedbackGenerator(style: .soft)
                                    .impactOccurred()
                                animationIndices = Set([index])
                                diceManager.rollIndex(index: index)
                                withAnimation {
                                    animationIndices = Set<Int>()
                                }
                            case .freezable:
                                withAnimation(.easeIn.speed(3)) {
                                    if diceManager.lockSelection.contains(where: { $0.key == index }) {
                                        diceManager.lockSelection.removeValue(forKey: index)
                                    } else {
                                        diceManager.lockSelection.updateValue(
                                            diceManager.dice[index].value,
                                            forKey: index
                                        )
                                    }
                                }
                            case .edit:
                                if diceManager.editSelection.contains(index) {
                                    diceManager.editSelection.remove(index)
                                } else {
                                    diceManager.editSelection.insert(index)
                                }
                            }
                            closedSave()
                        } label: {
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
                                .onAppear {
                                    visibleIndices.insert(index)
                                }
                                .onDisappear {
                                    visibleIndices.remove(index)
                                }
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: Constants.diceCornerRadius)
                                        .stroke(style: StrokeStyle(lineWidth: 4, dash: [5]))
                                        .foregroundColor(.red)
                                        .opacity(shouldEdit(index: index) ? 0.5 : 0.0)
                                        .frame(width: Constants.diceSize + 5, height: Constants.diceSize + 5)
                                )
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(minHeight: Constants.boardMinHeight, maxHeight: Constants.boardMaxHeight)
        }
    }
    
    func backgroundRoll() {
        switch diceManager.selectionMode {
        case .single, .shuffle, .sort, .freezable, .edit:
            diceManager.pushForwardHistory(diceManager.settings)
            diceManager.count += 1
            animationIndices = visibleIndices
            var animationChunks = Array(animationIndices).chunked(into: Constants.maxAnimations)
            animationChunks.shuffle()
            diceManager.selectionModeRoll()
            let lastIndex = animationChunks.count
            for (index, chunk) in animationChunks.enumerated() {
                let seconds = Constants.animationWaitTime * Double(index)
                DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
                    withAnimation {
                        self.animationIndices = animationIndices.symmetricDifference(chunk)
                    }
                }
            }
            DispatchQueue.main.asyncAfter(
                deadline: .now() + Constants.animationWaitTime * Double(lastIndex)
            ) {
                withAnimation {
                    self.animationIndices = Set<Int>()
                }
            }
        }
        closedSave()
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
    
    func shouldEdit(index: Int) -> Bool {
        diceManager.selectionMode == .edit &&
        diceManager.editSelection.contains(index)
    }
    
    func shouldFreeze(index: Int) -> Bool {
        diceManager.selectionMode == .freezable && 
        diceManager.lockSelection.contains(where: {$0.key == index})
    }
}
