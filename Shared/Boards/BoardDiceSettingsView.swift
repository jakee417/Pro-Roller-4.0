import SwiftUI
import GameKitUI

struct BoardDiceSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var diceManager: DiceManager
    @Binding var showSettings: Bool
    @Binding var diceAmount: Float
    
    var diceAmountInt: Int {
        get {
            return Int(diceAmount)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(
                    header: Text("Roll Mode "), footer: Text(Image(systemName: rollTypeImage(diceManager.selectionMode)))
                ) {
                    Picker("Roll Mode", selection: self.$diceManager.selectionMode) {
                        ForEach(RollType.allCases, id: \.self) {
                            Text("\($0.rawValue)")
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section(header: Text("Number of Dice "), footer: Text("\(diceAmountInt)")) {
                    HStack {
                        Slider(
                            value: $diceAmount,
                            in: 0...Float(diceManager.maxDice),
                            step: 1
                        )
                    }
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
                Section("Visuals") {
                    Toggle(isOn: $diceManager.showProfile) {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.secondary)
                        Text("Name")
                    }
                    if diceManager.showProfile {
                        HStack {
                            TextField("Name", text: $diceManager.name)
                                .foregroundColor(.accentColor)
                            Spacer()
                        }
                    }
                    Toggle(isOn: $diceManager.animate) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .foregroundColor(.secondary)
                        Text("Animations")
                    }
                    Toggle(isOn: $diceManager.showHistogram) {
                        Image(systemName: "chart.bar.fill")
                            .foregroundColor(.secondary)
                        Text("Scores")
                    }
                    HStack {
                        if #available(iOS 16.0, *) {
                            VStack {
                                HStack {
                                    ZStack {
                                        Image(systemName: "circle.fill")
                                            .imageScale(.large)
                                            .foregroundColor(.secondary)
                                        Image(systemName: "circle.fill")
                                            .foregroundColor(diceManager.color)
                                    }
                                    Spacer()
                                }
                                
                                HStack {
                                    Text("Color")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        } else {
                            HStack {
                                ZStack {
                                    Image(systemName: "circle.fill")
                                        .imageScale(.large)
                                        .foregroundColor(.secondary)
                                    Image(systemName: "circle.fill")
                                        .foregroundColor(diceManager.color)
                                }
                                Text("Color")
                            }
                        }
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
                }
                Section("Increase/Decrease Amount") {
                    Picker("", selection: $diceManager.incrementAmount) {
                        ForEach(DiceAmountPresets.allCases, id: \.self) {
                            Text("\($0.rawValue)")
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Board Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    BackButtonView(dismiss: dismiss)
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}
