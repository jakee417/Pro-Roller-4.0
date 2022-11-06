//
//  SimulationViewHeader.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 7/30/22.
//

import SwiftUI

struct SimulatorHeaderView: View {
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var K: PlotKSizes
    @Binding var lockSelection: [Int: Int]
    @StateObject var simManager: SimulationManager
    @State var incrementAmount: Int = 1
    @State var quantityOpacity = 0.8
    @State var showSettings: Bool = false
    @Binding var editableHeader: Bool
    
    var validSettings: Bool {
        get {
            if selectedDice != nil {
                return true
            } else {
                return false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 3) {
            HStack {
                Button {
                    withAnimation(.spring()) {
                        simManager.showSettings.toggle()
                    }
                } label: {
                    Label("Events", systemImage: "chevron.right.circle.fill")
                        .labelStyle(.iconOnly)
                        .imageScale(.large)
                        .rotationEffect(.degrees(simManager.showSettings ? 90 : 0))
                        .scaleEffect(simManager.showSettings ? 1.1 : 1)
                    Text("Generate")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    Image(systemName: "dice")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
                Spacer()
                if editableHeader && simManager.showSettings {
                    Stepper {
                        EmptyView()
                    } onIncrement: {
                        totalDice += 1
                    } onDecrement: {
                        totalDice = max(0, totalDice - 1)
                    }
                    .frame(width: 0)
                    .transition(.opacity)
                }
                Spacer()
            }
            HStack {
                Text("Setup the Simulation")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .listRowSeparator(.hidden)
                Spacer()
            }
        }
        if simManager.showSettings {
            SimulationContentView(
                simManager: simManager,
                totalDice: $totalDice,
                selectedDice: $selectedDice,
                editableHeader: $editableHeader,
                lockSelection: $lockSelection
            )
            .listRowSeparator(.hidden)
        }
    }
}

struct SimulationContentView: View {
    @StateObject var simManager: SimulationManager
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var editableHeader: Bool
    @Binding var lockSelection: [Int: Int]
    
    var body: some View {
        ZStack {
            SimulatorCard()
            VStack(spacing: 15) {
                HStack(spacing: 15) {
                    SimulationDiceAmountView(
                        totalDice: $totalDice,
                        lockSelection: $lockSelection,
                        simulateFrozen: $simManager.simulateFrozen
                    )
                    OverallDiceButtonView(
                        selectedDice: $selectedDice,
                        editableHeader: $editableHeader
                    )
                        .disabled(!editableHeader)
                }
                .padding(.top, 10)
                HStack {
                    Text("generated")
                        .font(.headline)
                    SimulationAmountButton(simManager: simManager)
                }
            }
            
        }
    }
}

struct SimulationDiceAmountView: View {
    @Binding var totalDice: Int
    @Binding var lockSelection: [Int: Int]
    @Binding var simulateFrozen: Bool
    @State var showOption: Bool = false
    
    var body: some View {
        if !lockSelection.isEmpty {
            HStack {
                Text("\(totalDice - lockSelection.count) with")
                    .font(.headline)
                Button {
                    showOption = true
                } label: {
                    if simulateFrozen {
                        (
                            Text("\(lockSelection.count) ") +
                            Text(Image(systemName: "cube.fill")) +
                            Text(" Frozen")
                        )
                        .font(.headline)
                        .modifier(ButtonInset(opacity: false))
                    } else {
                        Text("No Frozen")
                            .font(.headline)
                            .modifier(ButtonInset(opacity: false))
                    }
                }
                .buttonStyle(.borderless)
                .confirmationDialog("", isPresented: $showOption) {
                    Button("Include \(lockSelection.count) Frozen") {
                        simulateFrozen = true
                    }
                    Button("Exclude All Frozen", role: .destructive) {
                        simulateFrozen = false
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Simulate with Frozen Dice Included?")
                }
            }
            
        } else {
            Text("\(totalDice - lockSelection.count) total")
                .font(.headline)
        }
    }
}

struct OverallDiceButtonView: View {
    @Binding var selectedDice: DiceTypes?
    @Binding var editableHeader: Bool
    @State var showingOptions: Bool = false
    
    var body: some View {
        HStack {
            Button {
                showingOptions.toggle()
            } label: {
                if selectedDice == nil {
                    (Text(Image(systemName: "dice")) + Text(" ") + Text("Dice"))
                        .modifier(ButtonInset(opacity: true, color: editableHeader ? SimulatorConstants.diceColor : .gray))
                } else {
                    HStack {
                        (Text("D\(selectedDice!.rawValue) ") + Text(Image(systemName: "dice.fill")) + Text(" Dice"))
                            .modifier(ButtonInset(opacity: false, color: editableHeader ? SimulatorConstants.diceColor : .gray))
                    }
                }
                
            }
            .buttonStyle(.borderless)
        }
        .confirmationDialog("Dice", isPresented: $showingOptions) {
            DicePickerView(selectedDice: $selectedDice)
        } message: {
            Text("Select a Dice Type")
        }
    }
}

struct DicePickerView: View {
    @Binding var selectedDice: DiceTypes?
    
    var body: some View {
        ForEach(DiceTypes.allCases, id: \.self.rawValue) { value in
            Button("D\(value.rawValue) \(buttonCheckMark(selectedDice == value))") {
                selectedDice = value
            }
        }
        Button("Cancel", role: .cancel) { }
    }
}

struct SimulationAmountButton: View {
    @StateObject var simManager: SimulationManager
    @State var showingOptions: Bool = false
    
    var body: some View {
        Button {
            showingOptions.toggle()
        } label: {
            Text("\(simManager.batchSize) times")
                .modifier(ButtonInset(opacity: false))
        }
        .buttonStyle(.borderless)
        .confirmationDialog("", isPresented: $showingOptions) {
            SimulationAmountView(simManager: simManager)
        } message: {
            Text("How many Simulation Repetitions?")
        }
    }
}

struct SimulationAmountView: View {
    @StateObject var simManager: SimulationManager
    
    var body: some View {
        ForEach(SimulationSize.allCases, id: \.self.rawValue) { value in
            Button("\(value.rawValue) times \(buttonCheckMark(simManager.batchSize == value.rawValue))") {
                simManager.batchSize = value.rawValue
            }
        }
    }
}
