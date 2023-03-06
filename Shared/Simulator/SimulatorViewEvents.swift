import SwiftUI

enum SheetVariable: String {
    case quantity = "Amounts"
    case value = "Values"
    case value1 = "Value 1's"
    case value2 = "Value 2's"
    case grid = "Amounts and Values"
    case standard = "Standard"
}

func sheetVariableTitle(_ value: SheetVariable) -> String {
    switch value {
    case .quantity:
        return "Amount"
    case .value:
        return "Value"
    case .value1:
        return "Value 1"
    case .value2:
        return "Value 2"
    case .grid, .standard:
        return ""
    }
}

struct SimulatorViewEvents: View {
    @Binding var events: [Event]
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var lockSelection: [Int: Int]
    @State var showingQuantityOptions: Bool = false
    @State var showingDiceOptions: Bool = false
    @State var quantityText: String = ""
    @State var quantityOpacity: Double = 0.8
    @State var sheetVariable: SheetVariable = .grid
    @State var buttonMode: Bool = true
    
    @StateObject var simManager: SimulationManager
    
    var body: some View {
        ForEach($events, id: \.self) { $event in
            if let index = events.firstIndex(where: {$0.id == event.id}) {
                VStack {
                    ZStack {
                        if index != 0 {
                            if buttonMode {
                                Arrow()
                                    .fill(event.validEvent == .valid ? .green : .blue)
                                    .rotationEffect(.degrees(180))
                                    .opacity(event.validEvent == .valid ? 0.8 : 0.2)
                                    .animation(.easeIn, value: event.validEvent)
                                    .frame(width: 20, height: 30)
                            } else {
                                Arrow()
                                    .fill(.secondary)
                                    .rotationEffect(.degrees(180))
                                    .opacity(0.2)
                                    .frame(width: 20, height: 30)
                            }
                        }
                        HStack {
                            Image(systemName: "\(index + 1).circle.fill")
                                .foregroundColor(.accentColor)
                            if events[index] != events.first {
                                ConjunctionButtonView(event: $event, buttonMode: buttonMode)
                            } else {
                                Text("Where")
                                    .font(.headline.bold())
                            }
                            Spacer()
                            if event.validEvent != .valid {
                                Button {
                                    withAnimation {
                                        if event.conjunction == nil {
                                            if index != 0 {
                                                event.conjunction = .and
                                            } else {
                                                event.conjunction = .first
                                            }
                                        }
                                        event.setDefault(dice: selectedDice)
                                    }
                                } label: {
                                    Image(systemName: "wand.and.stars.inverse")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    EventContentView(
                        event: $event,
                        totalDice: $totalDice,
                        selectedDice: $selectedDice,
                        lockSelection: $lockSelection,
                        simManager: simManager,
                        sheetVariable: sheetVariable,
                        buttonMode: buttonMode
                    )
                }
                .listRowSeparator(.hidden)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    if index != 0 || events.count > 1 {
                        Button(role: .destructive) {
                            withAnimation {
                                deleteEvent(event)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                    Button {
                        withAnimation {
                            if index == 0 {
                                event.reset(dice: selectedDice, conjunction: .first)
                            } else {
                                event.reset(dice: selectedDice, conjunction: nil)
                            }
                        }
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise.circle.fill")
                    }
                    .tint(.indigo)
                    Button {
                        var newEvent = event
                        newEvent.id = UUID()
                        if newEvent.conjunction == .first {
                            newEvent.conjunction = nil
                        }
                        withAnimation {
                            events.insert(newEvent, at: index + 1)
                        }
                    } label: {
                        Label("Duplicate", systemImage: "plus.rectangle.on.rectangle")
                    }
                    .tint(.green)
                }
            }
        }
        .onDelete(perform: delete)
        .onMove(perform: move)
    }
    
    private func deleteEvent(_ event: Event) {
        guard let index = events.firstIndex(where: {$0.id == event.id}) else {
            return
        }
        events.remove(at: index)
        if !events.isEmpty {
            events[0].setFirst()
        }
    }
    
    func delete(at offsets: IndexSet) {
        events.remove(atOffsets: offsets)
        if !events.isEmpty {
            events[0].setFirst()
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        // possibly handle a "first" conjunction
        if source.contains(0) || destination == 0 {
            events[0].conjunction = nil
        }
        events.move(fromOffsets: source, toOffset: destination)
        if !events.isEmpty {
            events[0].setFirst()
        }
    }
}

struct EventContentView: View {
    @Binding var event: Event
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var lockSelection: [Int: Int]
    @StateObject var simManager: SimulationManager
    @State var showSheet1D: Bool = false
    @State var showSheet2D: Bool = false
    @State var sheetVariable: SheetVariable = .value
    @State var buttonMode: Bool = true
    @State var simulation1D: Simulation1D = Simulation1D()
    @State var simulation2D: Simulation2D = Simulation2D()
    @State var simulationError: Bool = false
    
    var body: some View {
        ZStack {
            SimulatorCard(minWidth: nil)
            VStack(spacing: 15) {
                VStack(spacing: 15) {
                    HStack(spacing: 15) {
                        ReductionButtonView(event: $event, buttonMode: buttonMode)
                        switch event.reduction {
                        case .minimum, .maximum, .average, .sum, .mode, .median, .sequence:
                            BoundButtonView(event: $event, buttonMode: buttonMode)
                                .modifier(ButtonInset(opacity: false, color: .gray))
                                .disabled(true)
                            HStack {
                                Text("\(totalDice)")
                                DiceButtonView(event: $event, selectedDice: $selectedDice)
                            }
                            .font(.headline)
                        case .consecutive, .each, nil:
                            BoundButtonView(event: $event, buttonMode: buttonMode)
                            DiceAmountView(
                                event: $event,
                                totalDice: $totalDice,
                                selectedDice: $selectedDice,
                                buttonMode: buttonMode,
                                sheetVariable: $sheetVariable
                            )
                        }
                    }
                    HStack(spacing: 15) {
                        if event.reduction == .sequence {
                            ComparisonButtonView(event: $event, buttonMode: buttonMode)
                                .modifier(ButtonInset(opacity: false, color: .gray))
                                .disabled(true)
                        } else {
                            ComparisonButtonView(event: $event, buttonMode: buttonMode)
                        }
                        ValueAmountView(
                            event: $event,
                            selectedDice: $selectedDice,
                            totalDice: $totalDice,
                            buttonMode: buttonMode,
                            sheetVariable: $sheetVariable
                        )
                    }
                }
            }
            .padding(.all, 10)
        }
        .contextMenu {
            if (
                [Reduction.each, Reduction.consecutive].contains(event.reduction) &&
                event.comparison != .between
            ) {
                Button {
                    compute2D()
                    showSheet2D.toggle()
                } label: {
                    Label("Dice Amounts & Values", systemImage: "square.grid.3x2.fill")
                        .symbolRenderingMode(.multicolor)
                }
                .disabled(event.validEvent != .valid)
            }
            if [Reduction.consecutive, Reduction.each].contains(event.reduction) {
                Button {
                    sheetVariable = .quantity
                    compute1D()
                    showSheet1D.toggle()
                } label: {
                    Label("Dice Amounts", systemImage: "chart.bar.fill")
                }
                .disabled(event.validEvent != .valid)
            }
            if event.comparison == .between || event.reduction == .sequence {
                Button {
                    sheetVariable = .value1
                    compute1D()
                    showSheet1D.toggle()
                } label: {
                    Label("First Values", systemImage: "chart.bar.fill")
                }
                .disabled(event.validEvent != .valid)
                Button {
                    sheetVariable = .value2
                    compute1D()
                    showSheet1D.toggle()
                } label: {
                    Label("Second Values", systemImage: "chart.bar.fill")
                }
                .disabled(event.validEvent != .valid)
            } else {
                Button {
                    sheetVariable = .value
                    compute1D()
                    showSheet1D.toggle()
                } label: {
                    Label("Dice Values", systemImage: "chart.bar.fill")
                }
                .disabled(event.validEvent != .valid)
            }
        }
        .sheet(isPresented: $showSheet1D) {
            if #available(iOS 16.0, *) {
                EventSheetView(
                    event: $event,
                    totalDice: $totalDice,
                    selectedDice: $selectedDice,
                    lockSelection: $lockSelection,
                    simManager: simManager,
                    sheetVariable: $sheetVariable,
                    simulationType: .oneDimension,
                    simulation1D: $simulation1D,
                    simulation2D: $simulation2D,
                    simulationError: $simulationError
                )
                .presentationDetents([.medium, .large])
            } else {
                EventSheetView(
                    event: $event,
                    totalDice: $totalDice,
                    selectedDice: $selectedDice,
                    lockSelection: $lockSelection,
                    simManager: simManager,
                    sheetVariable: $sheetVariable,
                    simulationType: .oneDimension,
                    simulation1D: $simulation1D,
                    simulation2D: $simulation2D,
                    simulationError: $simulationError
                )
            }
        }
        .sheet(isPresented: $showSheet2D) {
            if #available(iOS 16.0, *) {
                EventSheetView(
                    event: $event,
                    totalDice: $totalDice,
                    selectedDice: $selectedDice,
                    lockSelection: $lockSelection,
                    simManager: simManager,
                    sheetVariable: $sheetVariable,
                    simulationType: .twoDimensions,
                    simulation1D: $simulation1D,
                    simulation2D: $simulation2D,
                    simulationError: $simulationError
                )
                .presentationDetents([.medium, .large])
            } else {
                EventSheetView(
                    event: $event,
                    totalDice: $totalDice,
                    selectedDice: $selectedDice,
                    lockSelection: $lockSelection,
                    simManager: simManager,
                    sheetVariable: $sheetVariable,
                    simulationType: .twoDimensions,
                    simulation1D: $simulation1D,
                    simulation2D: $simulation2D,
                    simulationError: $simulationError
                )
            }
        }
    }
    
    private func compute1D() -> Void {
        simulation1D = Simulation1D()
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                let simulation1DTmp = try simManager.simulate1D(
                    events: [event],
                    eventSize: totalDice,
                    diceType: selectedDice,
                    lockSelection: lockSelection,
                    sheetVariable: sheetVariable
                )
                DispatchQueue.main.async {
                    simulation1D = simulation1DTmp
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                DispatchQueue.main.async {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    simulation1D.status = .error
                    simulationError = true
                }
            }
        }
    }
    
    private func compute2D() {
        simulation2D = Simulation2D()
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                let simulation2DTmp = try simManager.simulate2D(
                    events: [event],
                    eventSize: totalDice,
                    diceType: selectedDice,
                    lockSelection: lockSelection
                )
                DispatchQueue.main.async {
                    simulation2D = simulation2DTmp
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            } catch {
                DispatchQueue.main.async {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                    simulation2D.status = .error
                    simulationError = true
                }
            }
        }
    }
}

enum SimulationType {
    case oneDimension
    case twoDimensions
}

struct EventSheetView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var event: Event
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var lockSelection: [Int: Int]
    @StateObject var simManager: SimulationManager
    @Binding var sheetVariable: SheetVariable
    @State var simulationType: SimulationType
    @Binding var simulation1D: Simulation1D
    @Binding var simulation2D: Simulation2D
    @Binding var simulationError: Bool
    @State var showCard: Bool = true
    
    var body: some View {
        NavigationView {
            VStack{
                List{
                    HStack {
                        Button {
                            withAnimation(.spring()) {
                                showCard.toggle()
                            }
                        } label: {
                            Label("Where", systemImage: "chevron.right.circle.fill")
                                .labelStyle(.iconOnly)
                                .imageScale(.large)
                                .rotationEffect(.degrees(showCard ? 90 : 0))
                                .scaleEffect(showCard ? 1.1 : 1)
                            Text("Where")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.borderless)
                        Spacer()
                    }
                    if showCard {
                        EventContentView(
                            event: $event,
                            totalDice: $totalDice,
                            selectedDice: $selectedDice,
                            lockSelection: $lockSelection,
                            simManager: simManager,
                            sheetVariable: sheetVariable,
                            buttonMode: false
                        )
                        .disabled(true)
                        .listRowSeparator(.hidden)
                    }
                    switch simulationType {
                    case .oneDimension:
                        EventSheet1DView(
                            event: $event,
                            simulationData: $simulation1D,
                            simManager: simManager,
                            totalDice: $totalDice,
                            selectedDice: $selectedDice,
                            sheetVariable: $sheetVariable
                        )
                        .listRowSeparator(.hidden)
                    case .twoDimensions:
                        EventSheet2DView(
                            event: $event,
                            simulationData: $simulation2D,
                            simManager: simManager,
                            totalDice: $totalDice,
                            selectedDice: $selectedDice
                        )
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
            .alert("Error, please try again", isPresented: $simulationError) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            }
            .navigationViewStyle(.stack)
            .navigationTitle("All Dice \(sheetVariable.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    BackButtonView(dismiss: dismiss)
                }
            }
        }
    }
}

enum GraphDisplay: String, CaseIterable {
    case probability = "Probability"
    case sum = "Summation"
    case average = "Average"
}

struct EventSheet1DView: View {
    @Binding var event: Event
    @Binding var simulationData: Simulation1D
    @StateObject var simManager: SimulationManager
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var sheetVariable: SheetVariable
    @State var arrowColor: Color = .green
    @State var graphDisplay: GraphDisplay = .probability
    
    var body: some View {
        VStack {
            HStack {
                Text("Results for")
                EventSheetGraphDisplay(graphDisplay: $graphDisplay)
                Spacer()
            }
            .font(.title3.bold())
            HStack {
                Text("Plot of all \(sheetVariable.rawValue)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
            switch graphDisplay {
            case .probability:
                EventSheet1D(
                    data: $simulationData.prob1D,
                    yLabel: graphDisplay.rawValue,
                    xLabel: sheetVariableTitle(sheetVariable),
                    histMode: .percentage
                )
                .transition(.moveAndFade)
            case .sum:
                EventSheet1D(
                    data: $simulationData.sum1D,
                    yLabel: graphDisplay.rawValue,
                    xLabel: sheetVariableTitle(sheetVariable),
                    histMode: .raw
                )
                .transition(.moveAndFade)
            case .average:
                EventSheet1D(
                    data: $simulationData.avg1D,
                    yLabel: graphDisplay.rawValue,
                    xLabel: sheetVariableTitle(sheetVariable),
                    histMode: .raw
                )
                .transition(.moveAndFade)
            }
        }
    }
}

struct EventSheet2DView: View {
    @Binding var event: Event
    @Binding var simulationData: Simulation2D
    @StateObject var simManager: SimulationManager
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @State var arrowColor: Color = .green
    @State var graphDisplay: GraphDisplay = .probability
    
    var body: some View {
        VStack {
            HStack {
                Text("Results for")
                EventSheetGraphDisplay(graphDisplay: $graphDisplay)
                Spacer()
            }
            .font(.title3.bold())
            HStack {
                Text("Grid of all Amounts & Values")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Spacer()
            }
            switch graphDisplay {
            case .probability:
                EventSheet2D(data: $simulationData.probGrid)
                    .transition(.moveAndFade)
            case .sum:
                EventSheet2D(data: $simulationData.sumGrid)
                    .transition(.moveAndFade)
            case .average:
                EventSheet2D(data: $simulationData.avgGrid)
                    .transition(.moveAndFade)
            }
        }
    }
}


struct EventSheet1D: View {
    @Binding var data: [ChartData]
    @State var yLabel: String = ""
    @State var xLabel: String = ""
    @State var histMode: HistogramMode = .raw
    
    var body: some View {
        if !data.isEmpty {
            VStack {
                HStack {
                    Text(yLabel)
                        .font(.caption2.italic())
                        .rotationEffect(.degrees(-90))
                        .fixedSize()
                        .frame(width: 20, height: 90)
                    ScrollView(.horizontal) {
                        HStack {
                            BarChart(
                                histMode: histMode,
                                animate: false,
                                data: data
                            )
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
                Text(xLabel)
                    .font(.caption2.italic())
            }
        } else {
            ProgressView()
        }
    }
}


struct EventSheet2D: View {
    @State var yLabel: String = "Quantity\t"
    @State var xLabel: String = "Value\t"
    @Binding var data: [Int: [Int: ChartData]]
    
    @ViewBuilder
    func ColorView(intensity: Double) -> some View {
        (Color.red)
            .grayscale(1.0 - intensity)
            .cornerRadius(10)
            .frame(width: 70, height: 70)
    }
    
    var body: some View {
        if !data.isEmpty {
            HStack {
                Text(yLabel)
                    .font(.caption2.italic())
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .frame(width: 10, height: 50)
                VStack {
                    ScrollView(.vertical, showsIndicators: false) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyVGrid(columns: [GridItem(.flexible())], content: {
                                ForEach(Array(data.keys.sorted()), id: \.self) { quantity in
                                    HStack {
                                        Text("\(quantity)")
                                            .font(.caption2.italic())
                                            .rotationEffect(.degrees(-90))
                                            .fixedSize()
                                            .frame(width: 14, height: 10)
                                        LazyHGrid(rows: [GridItem(.flexible())], alignment: .center, content: {
                                            ForEach(Array(data[quantity]!.keys.sorted()), id: \.self) { value in
                                                VStack {
                                                    ZStack {
                                                        ColorView(intensity: data[quantity]![value]!.normalizedValue)
                                                        Text(data[quantity]![value]!.label)
                                                            .font(.caption.bold())
                                                    }
                                                    if quantity == data.count - 1 {
                                                        Text("\(value)")
                                                            .font(.caption2.italic())
                                                    }
                                                }
                                            }
                                        })
                                    }
                                }
                            })
                        }
                        .padding(.trailing, 20)
                    }
                    Text(xLabel)
                        .font(.caption2.italic())
                }
            }
        } else {
            ProgressView()
        }
    }
}

struct EventSheetGraphDisplay: View {
    @Binding var graphDisplay: GraphDisplay
    @State var showingOptions: Bool = false
    
    var body: some View {
        Button {
            showingOptions.toggle()
        } label: {
            Text(graphDisplay.rawValue)
                .modifier(ButtonInset(opacity: false))
        }
        .buttonStyle(.borderless)
        .confirmationDialog("Display", isPresented: $showingOptions) {
            ForEach(GraphDisplay.allCases, id: \.self.rawValue) { value in
                Button {
                    graphDisplay = value
                } label: {
                    Text("\(value.rawValue) \(buttonCheckMark(graphDisplay == value))")
                }
            }
        } message: {
            Text("Result")
        }
    }
}

