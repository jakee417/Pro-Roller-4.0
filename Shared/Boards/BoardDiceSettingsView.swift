import SwiftUI
import GameKitUI

struct BoardDiceSettingsView: View {
    @StateObject var diceManager: DiceManager
    @Binding var diceAmount: Float
    
    var diceAmountInt: Int {
        get {
            return Int(diceAmount)
        }
    }
    
    var body: some View {
        Form {
            Section {
                Picker("Roll Mode", selection: self.$diceManager.selectionMode) {
                    ForEach(RollType.allCases, id: \.self) {
                        Text("\($0.rawValue)")
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Roll Mode")
            } footer: {
                HStack {
                    Image(systemName: rollTypeImage(diceManager.selectionMode))
                    switch diceManager.selectionMode {
                    case .shuffle:
                        Text("Shuffle all dice")
                    case .sort:
                        Text("Shuffle all dice, then sort in increasing order")
                    case .single:
                        Text("Shuffle one dice at a time")
                    case .freezable:
                        Text("Freeze the value of selected dice")
                    case .edit:
                        Text("Change the value of selected dice")
                    }
                }

            }
            Section {
                VStack {
                    Slider(
                        value: $diceAmount,
                        in: 0...Float(diceManager.maxDice),
                        step: 1
                    )
                    HStack {
                        Spacer()
                        Stepper {
                            EmptyView()
                        } onIncrement: {
                            for _ in 1...diceManager.incrementAmount.rawValue {
                                diceAmount += 1
                            }
                        } onDecrement: {
                            for _ in 1...diceManager.incrementAmount.rawValue {
                                diceAmount = max(0, diceAmount - 1)
                            }
                        }
                        .frame(maxWidth: 0)
                        Spacer()
                    }
                }
            } header: {
                Text("Number of Dice")
            } footer: {
                Text("\(diceAmountInt) dice")
            }
            Section {
                HStack {
                    Image(systemName: "person")
                    if diceManager.showProfile {
                        TextField("Name", text: $diceManager.name)
                            .foregroundColor(.accentColor)
                    } else {
                        Text("Name")
                    }
                    Spacer()
                    Toggle("", isOn: $diceManager.showProfile)
                }
            }
            Section {
                HStack {
                    Text("Animations")
                    Spacer()
                    Toggle("", isOn: $diceManager.animate)
                }
                HStack {
                    color
                    Spacer()
                    Menu(
                        content: {
                            Picker("Color", selection: $diceManager.color) {
                                ForEach(Constants.diceColors, id: \.self) {
                                    Text($0.description)
                                }
                            }
                        },
                        label: {
                            Text(diceManager.color.description)
                        }
                    )
                }
            } header: {
                Text("Visuals")
            }
            Section {
                Picker("", selection: $diceManager.incrementAmount) {
                    ForEach(DiceAmountPresets.allCases, id: \.self) {
                        Text("\($0.rawValue)")
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Increase/Decrease Amount")
            } footer: {
                Text("How many dice to add or remove at a time")
            }
        }
        .navigationTitle("Board Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension BoardDiceSettingsView {
    var color: some View {
        HStack {
            Image(systemName: "circle.fill")
                .foregroundColor(diceManager.color)
                .background {
                    Image(systemName: "circle.fill")
                        .imageScale(.large)
                        .foregroundColor(.primary)
                        .scaleEffect(1.02)
                }
            Text("Color")
        }
    }
}

struct BoardDiceSettingsViewPreview: View {
    @State var diceAmount: Float = 5.0
    var body: some View {
        BoardDiceSettingsView(diceManager: DiceManager(), diceAmount: $diceAmount)
    }
}

struct BoardDiceSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        BoardDiceSettingsViewPreview()
    }
}
