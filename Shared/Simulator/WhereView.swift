//
//  WhereView.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 8/7/22.
//

import Foundation
import SwiftUI

struct WhereView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var simManager: SimulationManager
    @StateObject var eventManager: EventManager
    
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var lockSelection: [Int: Int]
    
    @State var K: PlotKSizes = .small
    @State var selection: Set<Int> = Set<Int>()
    
    @State var showDelete: Bool = false
    @State var showReset: Bool = false
    @State var isSharePresented: Bool = false
    
    let closedSave: () -> Void
    
    var exportedSettings: ExportedEventManagerSettings {
        get {
            return ExportedEventManagerSettings(settings: eventManager.settings)
        }
    }
    
    var fileName: URL? {
        get {
            guard let encoded = try? JSONEncoder().encode(exportedSettings) else {
                return nil
            }
            let documents = FileManager.default.urls(
                for: .documentDirectory, in: .userDomainMask
            ).first
            guard let path = documents?.appendingPathComponent("\(eventManager.safeName).events") else {
                return nil
            }
            do {
                try encoded.write(to: path, options: .atomicWrite)
            } catch {
                print(error.localizedDescription)
            }
            return path
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                VStack {
                    HStack {
                        Button {
                            withAnimation(.spring()) {
                                eventManager.showingConjunctions.toggle()
                            }
                        } label: {
                            Label("Where", systemImage: "chevron.right.circle.fill")
                                .labelStyle(.iconOnly)
                                .imageScale(.large)
                                .rotationEffect(.degrees(eventManager.showingConjunctions ? 90 : 0))
                                .scaleEffect(eventManager.showingConjunctions ? 1.1 : 1)
                        }
                        .buttonStyle(.borderless)
                        TextField("Name", text: self.$eventManager.name)
                            .font(.title3.bold())
                            .textFieldStyle(.roundedBorder)
                            .foregroundColor(.accentColor)
                            .onSubmit {
                                closedSave()
                            }
                        Button {
                            eventManager.name = ""
                        } label: {
                            Image(systemName: "x.circle.fill")
                                .foregroundColor(.secondary.opacity(0.2))
                                .imageScale(.small)
                        }
                        .buttonStyle(.borderless)
                        Spacer()
                    }
                    HStack {
                        Text("Customize events to simulate different quantities of interest")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                if eventManager.showingConjunctions {
                    SimulatorViewEvents(
                        events: $eventManager.events,
                        totalDice: $totalDice,
                        selectedDice: $selectedDice,
                        lockSelection: $lockSelection,
                        simManager: simManager
                    )
                    NewEvent(
                        events: $eventManager.events,
                        selectedDice: $selectedDice
                    )
                    .listRowSeparator(.hidden)
                }
                SimulationHistogramView(
                    simulationData: $eventManager.simulationData,
                    K: $K,
                    simulationResult: $eventManager.simulationResult,
                    eventManager: eventManager,
                    totalDice: $totalDice,
                    selectedDice: $selectedDice,
                    lockSelection: $lockSelection,
                    simManager: simManager
                )
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .padding(.bottom, 20)
            .navigationTitle("Event Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    BackButtonView(dismiss: dismiss)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if #unavailable(iOS 16.0) {
                        EditButton()
                    }
                    NavigationLink {
                        WhereInfoView()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Group {
                        Button {
                            showReset.toggle()
                        } label: {
                            Label("", systemImage: "arrow.counterclockwise.circle.fill")
                                .symbolRenderingMode(.multicolor)
                        }
                        .disabled(eventManager.events.isEmpty)
                        .confirmationDialog("", isPresented: $showReset) {
                            Button("Reset \(eventManager.events.count) Events", role: .destructive) {
                                selection = Set(eventManager.events.indices)
                                reset(selection: selection)
                                selection = Set<Int>()
                            }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("Reset All Events?")
                        }
                        Button {
                            showDelete.toggle()
                        } label: {
                            Label("", systemImage: "trash.circle.fill")
                                .symbolRenderingMode(
                                    eventManager.events.isEmpty ? .monochrome : .multicolor
                                )
                        }
                        .disabled(eventManager.events.isEmpty)
                        .confirmationDialog("", isPresented: $showDelete) {
                            Button("Delete \(eventManager.events.count) Events", role: .destructive) {
                                selection = Set(eventManager.events.indices)
                                delete(selection: selection)
                                selection = Set<Int>()
                            }
                            Button("Cancel", role: .cancel) { }
                        } message: {
                            Text("Delete All Events?")
                        }
                        Spacer()
                        Button {
                            self.isSharePresented = true
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                        .padding(.trailing, 10)
                        .sheet(
                            isPresented: $isSharePresented,
                            content: {
                                if #available(iOS 16.0, *) {
                                    ActivityViewController(
                                        activityItems: [fileName!]
                                    )
                                    .presentationDetents([.fraction(0.5), .fraction(0.99)])
                                } else {
                                    ActivityViewController(
                                        activityItems: [fileName!]
                                    )
                                }
                            }
                        )
                        SimulatorResultsView(
                            events: $eventManager.events,
                            totalDice: $totalDice,
                            selectedDice: $selectedDice,
                            simulationData: $eventManager.simulationData,
                            simulationResult: $eventManager.simulationResult,
                            lockSelection: $lockSelection,
                            simManager: simManager,
                            label: nil
                        )
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
    
    func delete(selection: Set<Int>) {
        eventManager.events.remove(at: IndexSet(selection))
    }
    
    func reset(selection: Set<Int>) {
        for index in selection {
            if index == 0 {
                eventManager.events[index].reset(dice: selectedDice, conjunction: .first)
            } else {
                eventManager.events[index].reset(dice: selectedDice, conjunction: nil)
            }
        }
    }
}


struct SimulatorResultsView: View {
    @Binding var events: [Event]
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var simulationData: GeometricPlotData
    @Binding var simulationResult: SimulationResults
    @Binding var lockSelection: [Int: Int]
    @StateObject var simManager: SimulationManager
    @State var simulationErrorMsg: String = "Error, please try again."
    @State var simulationError: Bool = false
    
    let label: (() -> AnyView)?
    
    var body: some View {
        HStack {
            Button {
                DispatchQueue.global(qos: .userInteractive).async {
                    compute()
                }
            } label: {
                if label != nil {
                    label!()
                } else {
                    Image(systemName: "hammer.circle.fill")
                        .imageScale(.large)
                }
            }
            .buttonStyle(.borderless)
        }
        .alert(simulationErrorMsg, isPresented: $simulationError) {
            Button("OK", role: .cancel) { }
        }
    }
    
    func compute() -> Void {
        do {
            let simulationResultTmp = try simManager.simulate(
                events: events,
                eventSize: totalDice,
                diceType: selectedDice,
                lockSelection: lockSelection
            )
            let simulationDataTmp = simManager.computeSimulationData(
                p: simulationResult.probability
            )
            DispatchQueue.main.async {
                self.simulationResult = simulationResultTmp
                self.simulationData = simulationDataTmp
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        } catch SimulationError.nilDiceType {
            DispatchQueue.main.async {
                simulationErrorMsg = "Select a Dice Type"
                simulationData.status = .error
                simulationResult.status = .error
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                simulationError = true
            }
        } catch SimulationError.invalidEvent(let invalidEvent) {
            DispatchQueue.main.async {
                simulationErrorMsg = "Where not complete"
                events[invalidEvent].triggerInvalid()
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                simulationData.status = .error
                simulationResult.status = .error
                simulationError = true
            }
        } catch SimulationError.invalidEvents(let reason) {
            DispatchQueue.main.async {
                simulationErrorMsg = "\(reason)"
                simulationData.status = .error
                simulationResult.status = .error
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                simulationError = true
            }
        } catch SimulationError.nilDiceAmount {
            DispatchQueue.main.async {
                simulationErrorMsg = "Add At Least One Die"
                simulationData.status = .error
                simulationResult.status = .error
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                simulationError = true
            }
        } catch {
            DispatchQueue.main.async {
                simulationData.status = .error
                simulationResult.status = .error
                simulationErrorMsg = "Error, please try again"
                simulationError = true
            }
        }
    }
}

struct SimulationHistogramView: View {
    @Binding var simulationData: GeometricPlotData
    @Binding var K: PlotKSizes
    @Binding var simulationResult: SimulationResults
    @StateObject var eventManager: EventManager
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var lockSelection: [Int: Int]
    @StateObject var simManager: SimulationManager
    @State var PMFAndCDFSwitch: Bool = false
    @State var showInfo: Bool = false
    @State var rotationCount: Int = 1
    
    var body: some View {
        VStack {
            ZStack {
                HStack {
                    Spacer()
                    FlowArrowView(
                        color: eventManager.validEvents ? .green : .blue,
                        opacity: eventManager.validEvents ? SimulatorConstants.buttonClick : SimulatorConstants.buttonUnclick
                    )
                    .animation(Animation.default, value: eventManager.validEvents)
                    Spacer()
                }
                HStack {
                    Text("Result")
                        .font(.title2.bold())
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.accentColor)
                    Spacer()
                }
            }
            HStack {
                Text("Plot the statistics of when you will see the first success")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
            ZStack {
                SimulatorCard()
                VStack {
                    SimulatorResultsView(
                        events: $eventManager.events,
                        totalDice: $totalDice,
                        selectedDice: $selectedDice,
                        simulationData: $eventManager.simulationData,
                        simulationResult: $eventManager.simulationResult,
                        lockSelection: $lockSelection,
                        simManager: simManager,
                        label: {
                            AnyView(
                                HStack(alignment: .center, spacing: 15) {
                                    VStack {
                                        Text("\(simulationResult.probability * 100, specifier: "%.2f")%")
                                            .font(.title2.bold())
                                        Text("Prob")
                                            .font(.subheadline)
                                    }
                                    VStack {
                                        Text(eventManager.simulationResult.safeSum)
                                            .font(.title2.bold())
                                        Text("Sum")
                                            .font(.subheadline)
                                    }
                                    VStack {
                                        Text(eventManager.simulationResult.safeAvg)
                                            .font(.title2.bold())
                                        Text("Avg")
                                            .font(.subheadline)
                                    }
                                }
                                    .modifier(ButtonInset(opacity: false))
                            )
                        }
                    )
                    HStack {
                        Text("With")
                        Button {
                            withAnimation(.easeInOut) {
                                PMFAndCDFSwitch.toggle()
                                rotationCount += 1
                            }
                        } label: {
                            VStack {
                                if PMFAndCDFSwitch {
                                    Text("Individual")
                                        .font(.headline)
                                } else {
                                    Text("Cumulative")
                                        .font(.headline)
                                }
                            }
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                .rotationEffect(
                                    .degrees(360 * Double(rotationCount))
                                )
                        }
                        .buttonStyle(.bordered)
                        Text("plot style")
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            if simulationData.status == .populated {
                VStack {
                    Text("Attempts Until First Success")
                        .font(.caption.bold())
                    HStack {
                        Text("Probability")
                            .font(.caption2.italic())
                            .rotationEffect(.degrees(-90))
                            .fixedSize()
                            .frame(width: 20, height: 90)
                        ScrollView(.horizontal) {
                            HStack {
                                if PMFAndCDFSwitch {
                                    BarChart(
                                        histMode: .percentage,
                                        animate: false,
                                        data: simulationData.pmfDataSizeK(K)
                                    )
                                    .transition(.moveAndFade)
                                } else {
                                    BarChart(
                                        histMode: .percentage,
                                        animate: false,
                                        data: simulationData.cdfDataSizeK(K)
                                    )
                                    .transition(.moveAndFade)
                                }
                            }
                            .scaledToFit()
                            .frame(
                                maxWidth: .infinity,
                                maxHeight: .infinity,
                                alignment: .center
                            )
                        }
                        .frame(minHeight: 130)
                    }
                }
                if PMFAndCDFSwitch {
                    Text("Attempt")
                        .font(.caption2.italic())
                } else {
                    Text("Attempts")
                        .font(.caption2.italic())
                }
                Picker("", selection: $K) {
                    ForEach(PlotKSizes.allCases, id: \.self) {
                        Text("\($0.rawValue)").tag($0)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
}

struct NewEvent: View {
    @Binding var events: [Event]
    @Binding var selectedDice: DiceTypes?
    
    var body: some View {
        ZStack {
            SimulatorCard(minHeight: nil, maxHeight: 40)
            HStack {
                Image(systemName: "\(events.count + 1).circle.fill")
                    .foregroundColor(.accentColor)
                Text("Where")
                    .font(.headline)
                Spacer()
                Button {
                    if events.isEmpty {
                        events.append(Event(dice: selectedDice, conjunction: .first))
                    } else {
                        events.append(Event(dice: selectedDice))
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .imageScale(.large)
                }
                .buttonStyle(.borderless)
                
            }
            .padding(.leading, 10)
            .padding(.trailing, 10)
        }
    }
}

struct PreviewWhereView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var eventManager: EventManager
    @Binding var selectionDice: DiceTypes?
    @ObservedObject var simManager: SimulationManager
    
    @State var dummyTotalDice = 6
    @State var dummyLockSelectionDice: [Int: Int] = [:]
    
    let addFunc: (EventManager) -> Void
    
    var body: some View {
        NavigationView {
            List {
                VStack {
                    HStack {
                        Text(eventManager.name)
                            .font(.title3.bold())
                        Spacer()
                    }
                    HStack {
                        Text("Preview A Preset")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                SimulatorViewEvents(
                    events: $eventManager.events,
                    totalDice: $dummyTotalDice,
                    selectedDice: $selectionDice,
                    lockSelection: $dummyLockSelectionDice,
                    sheetVariable: .standard,
                    buttonMode: false,
                    simManager: simManager
                )
                .disabled(true)
                .moveDisabled(true)
                .deleteDisabled(true)
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    BackButtonView(dismiss: dismiss)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        addFunc(eventManager)
                        dismiss()
                    } label: {
                        Text("Add")
                        Label("Add", systemImage: "flowchart")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .navigationTitle("Event Preview")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.plain)
        }
        .navigationViewStyle(.stack)
    }
}

struct WhereViewPreview: View {
    @State var totalDice: Int = 6
    @State var selectedDice: DiceTypes? = .D6
    @State var lockSelection: [Int: Int] = [:]
    var body: some View {
        WhereView(simManager: SimulationManager(), eventManager: EventManager(name: "Preview"), totalDice: $totalDice, selectedDice: $selectedDice, lockSelection: $lockSelection, closedSave: {})
    }
}

struct WhereView_Previews: PreviewProvider {
    static var previews: some View {
        WhereViewPreview()
    }
}
