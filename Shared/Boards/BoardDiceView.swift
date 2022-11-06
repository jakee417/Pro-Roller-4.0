import SwiftUI

struct BoardDiceView: View {
    @StateObject var diceManager: DiceManager
    @State var showSettings: Bool = false
    @State var diceAmountOrdered: Float = 0
    @State var visibleIndices: Set<Int> = Set<Int>()
    @State var animationIndices: Set<Int> = Set<Int>()
    
    let closedSave: () -> Void
    let roll: (DiceManager) -> Void
    
    var body: some View {
        VStack {
            UserView(diceManager: diceManager, closedSave: closedSave)
            BoardDiceHeaderView(
                diceManager: diceManager, 
                showSettings: $showSettings,
                incrementAmount: $diceManager.incrementAmount,
                visibleIndices: $visibleIndices,
                animationIndices: $animationIndices,
                closedSave: closedSave,
                roll : roll
            )
            .sheet(isPresented: $showSettings) {
                BoardDiceSettingsView(
                    diceManager: diceManager, 
                    showSettings: $showSettings,
                    diceAmount: $diceAmountOrdered
                )
            }
            .onChange(of: showSettings) { value in
                if value {
                    diceAmountOrdered = Float(diceManager.totalDice)
                } else {
                    if Float(diceManager.totalDice) != diceAmountOrdered {
                        diceManager.dice = []
                        if Int(diceAmountOrdered) != 0 {
                            for _ in 1...Int(diceAmountOrdered) {
                                diceManager.append()
                            }
                        }
                    }
                }
                closedSave()
            }
            BoardDieView(
                diceManager: diceManager,
                visibleIndices: $visibleIndices,
                animationIndices: $animationIndices,
                closedSave: closedSave
            )
            HStack{
                SelectionModePicker(diceManager: diceManager, closedSave: closedSave)
                switch diceManager.selectionMode {
                case .shuffle, .sort, .single:
                    Spacer()
                case .edit:
                    DiceValueView(diceManager: diceManager, closedSave: closedSave)
                case .freezable:
                    DiceFrozenHelperView(diceManager: diceManager, closedSave: closedSave)
                }
                Spacer()
                HStack {
                    Button {
                        diceManager.rewindHistory()
                        closedSave()
                    } label: {
                        Image(systemName: "arrow.uturn.backward.circle")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                    .disabled(diceManager.history.isEmpty)
                    Button {
                        diceManager.recallHistory()
                        closedSave()
                    } label: {
                        Image(systemName: "arrow.uturn.forward.circle")
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                    .disabled(diceManager.futureHistory.isEmpty)
                }
            }
            HistogramView(
                diceManager: diceManager,
                showHistogram: self.$diceManager.showHistogram
            )
            .transition(.moveAndFade)
        }
        .sheet(isPresented: $diceManager.showSimulator) {
            if #available(iOS 16.0, *) {
                SimulatorView(
                    totalDice: $diceManager.totalDice,
                    selectedDice: $diceManager.sidesOptional,
                    lockSelection: $diceManager.lockSelection,
                    shownAsSheet: true
                )
                .presentationDetents([.fraction(0.99)])
            } else {
                SimulatorView(
                    totalDice: $diceManager.totalDice,
                    selectedDice: $diceManager.sidesOptional,
                    lockSelection: $diceManager.lockSelection,
                    shownAsSheet: true
                )
            }
        }
    }
}

struct SelectionModePicker: View {
    @ObservedObject var diceManager: DiceManager
    @State var rollTypes: [RollType] = RollType.allCases
    
    let closedSave: () -> Void
    
    var body: some View {
        Menu(
            content: {
                Picker("", selection: $diceManager.selectionMode) {
                    ForEach(rollTypes, id: \.self) {
                        Text($0.rawValue).foregroundColor(Color(UIColor.systemBlue)).tag($0)
                    }
                }
                .onChange(of: diceManager.selectionMode) { tag in
                    closedSave()
                }
            },
            label: {
                Image(systemName: rollTypeImage(diceManager.selectionMode))
                    .imageScale(.large)
            }
        )
    }
}

struct UserView: View {
    @StateObject var diceManager: DiceManager
    
    let closedSave: () -> Void
    
    var body: some View {
        if diceManager.showProfile {
            HStack {
                TextField("Name", text: $diceManager.name)
                    .foregroundColor(.accentColor)
                    .onSubmit {
                        closedSave()
                    }
                Spacer()
            }
        }
    }
}

struct DiceFrozenHelperView: View {
    @StateObject var diceManager: DiceManager
    
    let closedSave: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            Button {
                if Set(diceManager.lockSelection.keys) != Set(diceManager.dice.indices) {
                    diceManager.lockSelection = Dictionary(
                        uniqueKeysWithValues: zip(
                            diceManager.dice.indices,
                            diceManager.dice.map({ dice in
                                dice.value
                            })
                        )
                    )
                } else {
                    diceManager.lockSelection = [:]
                }
                closedSave()
            } label: {
                if Set(diceManager.lockSelection.keys) == Set(diceManager.dice.indices) {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                } else if Set(diceManager.lockSelection.keys) == Set<Int>() {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.accentColor)
                        .imageScale(.large)
                }
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 3)
        }
    }
}

struct DiceValueView: View {
    @StateObject var diceManager: DiceManager
    @State var changedValue: Int = 1
    
    let closedSave: () -> Void
    
    var intProxy: Binding<Double> {
        return Binding<Double>(
            get: {
                return Double(changedValue)
                
            },
            set: { value in
                changedValue = Int(value)
            }
        )
    }
    var body: some View {
        HStack {
            Text("\(changedValue)")
                .disabled(diceManager.editSelection.isEmpty)
            Slider(value: intProxy, in: 1.0...Double(diceManager.sides.rawValue)) { editing in
                if !editing {
                    for index in diceManager.editSelection {
                        diceManager.dice[index].value = changedValue
                    }
                    UIImpactFeedbackGenerator(style: .soft)
                        .impactOccurred()
                    diceManager.editSelection = Set<Int>()
                }
            }
            .disabled(diceManager.editSelection.isEmpty)
            Spacer()
            Button {
                if diceManager.editSelection != Set(diceManager.dice.indices) {
                    diceManager.editSelection = Set(diceManager.dice.indices)
                } else {
                    diceManager.editSelection = Set<Int>()
                }
                closedSave()
            } label: {
                if diceManager.editSelection == Set(diceManager.dice.indices) {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                } else if diceManager.editSelection == Set<Int>() {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .imageScale(.large)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.accentColor)
                        .imageScale(.large)
                }
            }
            .buttonStyle(.borderless)
            .padding(.trailing, 3)
        }
    }
}
