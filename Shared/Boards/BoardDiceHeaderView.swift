import SwiftUI

struct BoardDiceHeaderView: View {
    @StateObject var diceManager: DiceManager
    @Binding var showSettings: Bool
    @Binding var incrementAmount: DiceAmountPresets
    @Binding var visibleIndices: Set<Int>
    @Binding var animationIndices: Set<Int>
    
    let closedSave: () -> Void
    let roll: (DiceManager) -> Void
    
    var body: some View {
        HStack {
            RollButton(
                diceManager: diceManager,
                visibleIndices: $visibleIndices,
                animationIndices: $animationIndices,
                closedSave: closedSave,
                roll: roll
            )
            Menu {
                Picker("Dice Type", selection: $diceManager.sides) {
                    ForEach(DiceTypes.allCases, id: \.self) {
                        Text("D\($0.rawValue)")
                            .onTapGesture {
                                closedSave()
                            }
                    }
                }
                .onChange(of: diceManager.sides) { _ in
                    closedSave()
                }
            } label: {
                Text("D\(diceManager.sides.rawValue)")
                    .padding(.all, 5)
                    .modifier(ButtonInset(opacity: false))
            }
            Spacer()
            Stepper {
                EmptyView()
            } onIncrement: {
                for _ in 1...incrementAmount.rawValue {
                    diceManager.append()
                }
                closedSave()
            } onDecrement: {
                for _ in 1...incrementAmount.rawValue {
                    diceManager.popLast()
                }
                closedSave()
            }
            .frame(maxWidth: 0)
            Spacer()
            Button {
                diceManager.showSimulator = true
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

struct RollButton: View {
    @StateObject var diceManager: DiceManager
    @Binding var visibleIndices: Set<Int>
    @Binding var animationIndices: Set<Int>
    
    let closedSave: () -> Void
    let roll: (DiceManager) -> Void
    
    var body: some View {
        Button {
            switch diceManager.selectionMode {
            case .single, .shuffle, .sort, .freezable, .edit:
                roll(diceManager)
                animationIndices = visibleIndices
                var animationChunks = Array(animationIndices).chunked(into: Constants.maxAnimations)
                animationChunks.shuffle()
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
            }
            closedSave()
        } label: {
            Text("Roll")
                .font(.subheadline)
        }
        .buttonStyle(.borderedProminent)
    }
}
