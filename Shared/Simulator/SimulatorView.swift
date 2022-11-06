import SwiftUI
import Algorithms

struct SimulatorView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var simManager: SimulationManager
    @EnvironmentObject var container: EventManagersContainer
    
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var lockSelection: [Int: Int]
    
    @State var simulationData: GeometricPlotData = GeometricPlotData()
    @State var K: PlotKSizes = .small
    @State var simulationResult: SimulationResults = SimulationResults()
    @State var shownAsSheet: Bool = false
    @State var editableHeader: Bool = true
    @State var simulationError: Bool = false
    @State var clearButton: Bool = false
    @State var resetButton: Bool = false
    @State var isSharePresented: Bool = false
    
    func getFileName(exportedSettings: ExportedEventManagerSettings) -> URL? {
        guard let encoded = try? JSONEncoder().encode(exportedSettings) else {
            return nil
        }
        let documents = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first
        guard let path = documents?.appendingPathComponent("\(exportedSettings.name).events") else {
            return nil
        }
        do {
            try encoded.write(to: path, options: .atomicWrite)
        } catch {
            print(error.localizedDescription)
        }
        return path
    }
    
    var fileNames: [URL] {
        get {
            return container.eventManagers.managers.map {
                getFileName(
                    exportedSettings: ExportedEventManagerSettings(
                        settings: $0.settings
                    )
                )!
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                SimulatorHeaderView(
                    totalDice: $totalDice,
                    selectedDice: $selectedDice,
                    K: $K,
                    lockSelection: $lockSelection,
                    simManager: simManager,
                    editableHeader: $editableHeader
                )
                .listRowSeparator(.hidden)
                EventsView(
                    simManager: simManager,
                    managers: container.eventManagers,
                    totalDice: $totalDice,
                    selectedDice: $selectedDice,
                    lockSelection: $lockSelection,
                    closedSave: saveEvents
                )
                .listRowSeparator(.hidden)
                PresetsView(
                    eventManagers: container.eventManagers,
                    simManager: simManager,
                    selectedDice: $selectedDice

                )
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .padding(.bottom, 20)
            .navigationTitle("Simulator")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    if shownAsSheet {
                        BackButtonView(dismiss: dismiss)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if #unavailable(iOS 16.0) {
                        EditButton()
                    }
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    Button {
                        resetButton.toggle()
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                    .confirmationDialog("", isPresented: $resetButton) {
                        Button("Reset \(container.eventManagers.managers.count) Events", role: .destructive) {
                            withAnimation {
                                for manager in container.eventManagers.managers {
                                    for index in manager.events.indices {
                                        if index == 0 {
                                            manager.events[index].reset(dice: selectedDice, conjunction: .first)
                                        } else {
                                            manager.events[index].reset(dice: selectedDice, conjunction: nil)
                                        }
                                    }
                                }
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Reset All Events to Default?")
                    }
                    Button {
                        clearButton.toggle()
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                    .confirmationDialog("", isPresented: $clearButton) {
                        Button("Delete \(container.eventManagers.managers.count) Events", role: .destructive) {
                            withAnimation {
                                container.eventManagers.managers.removeAll()
                            }
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
                            ActivityViewController(activityItems: fileNames)
                        }
                    )
                    Button {
                        DispatchQueue.global(qos: .userInteractive).async {
                            computeAll()
                        }
                    } label: {
                        Image(systemName: "hammer.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            loadSettings(eventManagers: container.eventManagers)
            DispatchQueue.global(qos: .userInteractive).async {
                compute()
            }
        }
        .onChange(of: container.eventManagers.managers) { _ in
            saveEvents()
        }
    }
    func computeAll() -> Void {
        do {
            try simManager.batches = simManager.getSimulationBatches(
                diceType: selectedDice,
                eventSize: totalDice,
                lockSelection: lockSelection
            )
        } catch {
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
            return
        }
        DispatchQueue.main.async {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
        for manager in container.eventManagers.managers {
            do {
                let simulationResult = try simManager.simulate(
                    events: manager.events,
                    eventSize: totalDice,
                    diceType: selectedDice,
                    lockSelection: lockSelection,
                    synchronousSimulation: false
                )
                DispatchQueue.main.async {
                    manager.simulationResult = simulationResult
                    manager.simulationData = simManager.computeSimulationData(
                        p: simulationResult.probability
                    )
                }
            } catch {
                DispatchQueue.main.async {
                    manager.simulationResult.status = .error
                }
            }
        }
    }
    
    func compute() -> Void {
        do {
            try simManager.batches = simManager.getSimulationBatches(
                diceType: selectedDice,
                eventSize: totalDice,
                lockSelection: lockSelection
            )
        } catch {
            DispatchQueue.main.async {
                simulationError = true
            }
        }
    }
    
    func saveEvents() {
        saveSettings(eventManagers: container.eventManagers)
    }
    
    func saveSettings(eventManagers: EventManagers) {
        var events: [EventManagerSettings] = []
        for manager in eventManagers.managers {
            events.append(manager.settings)
        }
        EventManagers.save(url: eventManagers.url, settings: events) { result in
            if case .failure(let error) = result {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func loadSettings(eventManagers: EventManagers) {
        EventManagers.load(url: eventManagers.url) { result in
            switch result {
            case .failure(_):
                saveSettings(eventManagers: eventManagers)
            case .success(let settings):
                eventManagers.managers = []
                for setting in settings {
                    let eventManager = EventManager(name: setting.name)
                    eventManager.settings = setting
                    eventManagers.managers.append(eventManager)
                }
            }
        }
    }
}

struct EventsView: View {
    @StateObject var simManager: SimulationManager
    @StateObject var managers: EventManagers
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var lockSelection: [Int: Int]
    
    let closedSave: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Button {
                    withAnimation(.spring()) {
                        managers.showManager.toggle()
                    }
                } label: {
                    Label("Events", systemImage: "chevron.right.circle.fill")
                        .labelStyle(.iconOnly)
                        .imageScale(.large)
                        .rotationEffect(.degrees(managers.showManager ? 90 : 0))
                        .scaleEffect(managers.showManager ? 1.1 : 1)
                    Text("Events")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                    Image(systemName: "flowchart")
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.borderless)
                Spacer()
                if !managers.showManager {
                    Image(
                        systemName: "\(managers.managers.filter{!$0.pin}.count).circle.fill"
                    )
                    .foregroundColor(.secondary)
                }
            }
            HStack{
                Text("Compute and View")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        ForEach($managers.managers, id: \.self) { $manager in
            if managers.showManager || manager.pin {
                EventView(
                    simManager: simManager,
                    eventManager: manager,
                    totalDice: $totalDice,
                    selectedDice: $selectedDice,
                    lockSelection: $lockSelection,
                    closedSave: closedSave,
                    duplicate: duplicate
                )
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation {
                            deleteEventManager(eventManager: manager)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                    Button {
                        withAnimation {
                            reset(eventManager: manager)
                        }
                    } label: {
                        Label("Reset", systemImage: "arrow.counterclockwise.circle.fill")
                    }
                    .tint(.indigo)
                    Button {
                        withAnimation {
                            duplicate(eventManager: manager)
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
        if managers.showManager {
            ZStack {
                SimulatorCard(minHeight: 40)
                HStack {
                    Text("New Event")
                        .font(.headline)
                        .padding(.leading, 5)
                    Spacer()
                    Button {
                        managers.managers.append(EventManager(name: "Event \(managers.managers.count + 1)"))
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.multicolor)
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(.leading, 5)
                .padding(.trailing, 5)
            }
        }
    }
    
    func reset(eventManager: EventManager) {
        withAnimation {
            for index in eventManager.events.indices {
                if index == 0 {
                    eventManager.events[index].reset(dice: selectedDice, conjunction: .first)
                } else {
                    eventManager.events[index].reset(dice: selectedDice, conjunction: nil)
                }
            }
        }
    }
    
    func duplicate(eventManager: EventManager) {
        guard let index = managers.managers.firstIndex(where: {$0.id == eventManager.id}) else {
            managers.managers.append(eventManager.copy() as! EventManager)
            return
        }
        managers.managers.insert(
            eventManager.copy() as! EventManager,
            at: index
        )
    }
    
    func deleteEventManager(eventManager: EventManager) {
        guard let index = managers.managers.firstIndex(where: {$0.id == eventManager.id}) else {
            return
        }
        managers.managers.remove(at: index)
    }
    
    func delete(at offsets: IndexSet) {
        managers.managers.remove(atOffsets: offsets)
    }
    
    func move(from source: IndexSet, to destination: Int) {
        managers.managers.move(fromOffsets: source, toOffset: destination)
    }
}

struct EventView: View {
    @StateObject var simManager: SimulationManager
    @StateObject var eventManager: EventManager
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var lockSelection: [Int: Int]
    
    @State public var isSharePresented: Bool = false
    @State private var initUpdate = false
    @State public var presentAlert: Bool = false
    
    let closedSave: () -> Void
    let duplicate: (EventManager) -> Void
    
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
        VStack {
            HStack {
                Button {
                    eventManager.showingWhere = true
                } label: {
                    Text(eventManager.name == "" ? "\t" : eventManager.name)
                        .font(.headline.bold())
                        .modifier(ButtonInset(opacity: false))
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            if #available(iOS 16.0, *) {
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
                            EventViewButton(
                                simManager: simManager,
                                eventManager: eventManager,
                                totalDice: $totalDice,
                                selectedDice: $selectedDice,
                                lockSelection: $lockSelection,
                                closedSave: closedSave
                            )
                        )
                    }
                )
                .contextMenu {
                    EventViewContextMenu(
                        eventManager: eventManager,
                        isSharePresented: $isSharePresented,
                        presentAlert: $presentAlert
                    )
                } preview: {
                    WhereView(
                        simManager: simManager,
                        eventManager: eventManager,
                        totalDice: $totalDice,
                        selectedDice: $selectedDice,
                        lockSelection: $lockSelection,
                        closedSave: closedSave
                    )
                }
            } else {
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
                            EventViewButton(
                                simManager: simManager,
                                eventManager: eventManager,
                                totalDice: $totalDice,
                                selectedDice: $selectedDice,
                                lockSelection: $lockSelection,
                                closedSave: closedSave
                            )
                        )
                    }
                )
                .contextMenu {
                    EventViewContextMenu(
                        eventManager: eventManager,
                        isSharePresented: $isSharePresented,
                        presentAlert: $presentAlert
                    )
                }
            }
        }
        .sheet(
            isPresented: $isSharePresented,
            content: {
                if #available(iOS 16.0, *) {
                    ActivityViewController(
                        activityItems: [fileName!]
                    )
                    .presentationDetents([.fraction(0.99)])
                } else {
                    ActivityViewController(
                        activityItems: [fileName!]
                    )
                }
            }
        )
        .alert(
            "Rename Event",
            isPresented: $presentAlert,
            actions: {
                TextField("Name", text: self.$eventManager.name)
                Button("Dismiss", role: .cancel, action: {})
            },
            message: {}
        )
        .onAppear {
            if !initUpdate {
                DispatchQueue.global(qos: .userInteractive).async {
                    compute()
                }
                initUpdate = true
            }
        }
        .onChange(of: selectedDice) { value in
            for index in eventManager.events.indices {
                eventManager.events[index].dice = value
            }
        }
        .onChange(of: eventManager) { _ in
            closedSave()
        }
        .onChange(of: eventManager.events) { _ in
            closedSave()
        }
        .sheet(isPresented: $eventManager.showingWhere) {
            WhereView(
                simManager: simManager,
                eventManager: eventManager,
                totalDice: $totalDice,
                selectedDice: $selectedDice,
                lockSelection: $lockSelection,
                closedSave: closedSave
            )
        }
    }
    
    func compute() -> Void {
        do {
            let simulationResult = try simManager.simulate(
                events: eventManager.events,
                eventSize: totalDice,
                diceType: selectedDice,
                lockSelection: lockSelection,
                synchronousSimulation: false
            )
            DispatchQueue.main.async {
                eventManager.simulationResult = simulationResult
                eventManager.simulationData = simManager.computeSimulationData(
                    p: simulationResult.probability
                )
            }
        } catch {
            DispatchQueue.main.async {
                eventManager.simulationResult.status = .error
            }
        }
    }
}

struct EventViewContextMenu: View {
    @StateObject var eventManager: EventManager
    @Binding var isSharePresented: Bool
    @Binding var presentAlert: Bool
    
    var body: some View {
        Section {
            if #available(iOS 16.0, *) {
                Button {
                    presentAlert = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                }
            }
            Button {
                eventManager.showingWhere = true
            } label: {
                Label("Edit", systemImage: "ellipsis.circle.fill")
            }
            Button {
                self.isSharePresented = true
            } label: {
                Label("Share" , systemImage: "square.and.arrow.up")
            }
        }
    }
}

struct EventViewButton: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var simManager: SimulationManager
    @StateObject var eventManager: EventManager
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @Binding var lockSelection: [Int: Int]
    
    let closedSave: () -> Void
    
    var body: some View {
        ZStack {
            if colorScheme == .light {
                SimulatorCard(minHeight: 60, color: Color("Background"), opacity: 0.8)
                    .shadow(color: Color("LightShadow"), radius: 3, x: -3, y: -3)
                    .shadow(color: Color("DarkShadow"), radius: 2, x: 2, y: 2)
            } else {
                SimulatorCard(minHeight: 60)
            }
            HStack {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        Text("\(eventManager.events.count)")
                            .font(.headline.bold())
                        ZStack {
                            Image(systemName: "circle.fill")
                                .resizable()
                                .frame(width: 11, height: 11)
                                .offset(x: 1, y: 6)
                                .foregroundColor(.primary)
                            if eventManager.validEvents {
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .frame(width: 12, height: 12)
                                    .offset(x: 1, y: 6)
                                    .foregroundColor(.green)
                                    .animation(.default, value: eventManager.validEvents)
                                
                            } else {
                                Image(systemName: "x.circle.fill")
                                    .resizable()
                                    .frame(width: 12, height: 12)
                                    .offset(x: 1, y: 6)
                                    .foregroundColor(.red)
                                    .animation(.default, value: eventManager.validEvents)
                            }
                        }
                    }
                    Text("Events")
                        .font(.subheadline)
                }
                .padding(.leading, 8)
                Spacer()
                switch eventManager.simulationResult.status {
                case .populated, .error:
                    VStack {
                        Text("\(eventManager.simulationResult.probability * 100, specifier: "%.2f")%")
                            .font(.headline.bold())
                        Text("Prob")
                            .font(.subheadline)
                    }
                    VStack {
                        Text(eventManager.simulationResult.safeSum)
                            .font(.headline.bold())
                        Text("Sum")
                            .font(.subheadline)
                    }
                    VStack {
                        Text(eventManager.simulationResult.safeAvg)
                            .font(.headline.bold())
                        Text("Avg")
                            .font(.subheadline)
                    }
                    .padding(.trailing, 5)
                case .empty:
                    ProgressView()
                        .padding(.trailing, 15)
                }
                Divider()
                Button {
                    eventManager.pin.toggle()
                    closedSave()
                } label: {
                    if eventManager.pin {
                        Image(systemName: "pin.fill")
                            .foregroundColor(.accentColor)
                    } else {
                        Image(systemName: "pin")
                            .foregroundColor(.accentColor)
                    }
                }
                .buttonStyle(.borderless)
                .padding(.trailing, 10)
            }
            .foregroundColor(.primary)
            .foregroundStyle(.ultraThickMaterial)
        }
    }
}

struct FlowArrowView: View {
    var color: Color = .blue
    var opacity: Double = SimulatorConstants.buttonClick
    
    var body: some View {
        HStack {
            Spacer()
            Arrow()
                .fill(color)
                .rotationEffect(.degrees(180))
                .opacity(opacity)
                .frame(width: 20, height: 30)
            Spacer()
        }
    }
}

struct SimulatorCard: View {
    @State var minHeight: CGFloat? = SimulatorConstants.cardHeight
    @State var minWidth: CGFloat? = SimulatorConstants.cardHeight
    @State var maxWidth: CGFloat? = nil
    @State var maxHeight: CGFloat? = nil
    @State var color: Color = .secondary
    @State var opacity: Double = 0.2
    
    var body: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(color)
            .opacity(opacity)
            .frame(
                minWidth: minWidth,
                maxWidth: maxWidth,
                minHeight: minHeight,
                maxHeight: maxHeight
            )
    }
}

struct PresetsView: View {
    @StateObject var eventManagers: EventManagers
    @StateObject var simManager: SimulationManager
    @Binding var selectedDice: DiceTypes?
    @State var selectedEventManager: EventManager? = nil
    @State var addAll: Bool = false
    @State var game: Game = .example
    @State var showPresets: [EventManager] = SimulationPresets.presets[.example]!
    @State var showRecommendations = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Button {
                    withAnimation(.spring()) {
                        showRecommendations.toggle()
                    }
                } label: {
                    Label("Events", systemImage: "chevron.right.circle.fill")
                        .labelStyle(.iconOnly)
                        .imageScale(.large)
                        .rotationEffect(.degrees(showRecommendations ? 90 : 0))
                        .scaleEffect(showRecommendations ? 1.1 : 1)
                    Text("Presets")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                }
                .buttonStyle(.borderless)
                Spacer()
                if showRecommendations {
                    Button {
                        addAll.toggle()
                    } label: {
                        Text("Add All")
                    }
                    .buttonStyle(.borderless)
                    .transition(.opacity)
                    .confirmationDialog("", isPresented: $addAll) {
                        Button("Add \((SimulationPresets.presets[game] ?? []).count) Events") {
                            withAnimation {
                                for preset in SimulationPresets.presets[game] ?? [] {
                                    preset.updateSelectedDiceType(newDiceType: selectedDice)
                                    let presetCopy: EventManager = preset.copy() as! EventManager
                                    eventManagers.managers.append(presetCopy)
                                }
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("Add All Events?")
                    }
                }
            }
            HStack {
                Text("Presets for")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Menu {
                    Picker("Game", selection: $game) {
                        ForEach(Game.allCases, id: \.self) {
                            Text("\($0.rawValue)")
                        }
                    }
                    .onChange(of: game) { tag in
                        showPresets = SimulationPresets.presets[tag] ?? []
                    }
                } label: {
                    Text("\(game.rawValue)")
                        .modifier(ButtonInset(opacity: false, color: showRecommendations ? .accentColor : .gray))
                }
                .disabled(!showRecommendations)
                Spacer()
            }
            .padding(.top, 5)
        }
        if showRecommendations {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .center, spacing: 30) {
                    ForEach($showPresets) { $preset in
                        GeometryReader { geometry in
                            PresetCard(
                                preset: $preset,
                                selectedDice: $selectedDice,
                                simManager: simManager,
                                add: add
                            )
                            .rotation3DEffect(
                                Angle(
                                    degrees: computeAngle(geometry.frame(in: .global).minX)
                                ),
                                axis: (x: 0, y: 1.0, z: 0)
                            )
                            .scaleEffect(1.1 * cos(computeAngle(geometry.frame(in: .global).minX)))
                        }
                        .frame(width: 200, height: 80)
                    }
                }
                .padding(.all, 10)
            }
            .frame(width: UIScreen.main.bounds.width * 0.95, height: 120)
        }
    }
    
    func computeAngle(_ minX: CGFloat) -> Double {
        return (Double(minX) - UIScreen.main.bounds.width / 2.0 + 100.0) / -UIScreen.main.bounds.width
    }
    
    func add(newManager: EventManager) {
        newManager.updateSelectedDiceType(newDiceType: selectedDice)
        let newManagerCopy: EventManager = newManager.copy() as! EventManager
        eventManagers.managers.append(newManagerCopy)
    }
}


struct PresetCard: View {
    @Binding var preset: EventManager
    @Binding var selectedDice: DiceTypes?
    @StateObject var simManager: SimulationManager
    
    @State var showPreview = false
    @State var previewEventManager: EventManager = EventManager(name: "")
    @State var dummyTotalDice = 6
    @State var dummyLockSelectionDice: [Int: Int] = [:]
    
    let add: (EventManager) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    previewEventManager = preset
                    showPreview = true
                } label: {
                    Text(preset.name)
                        .font(.headline)
                        .modifier(ButtonInset(opacity: false))
                        .scaledToFit()
                }
                .buttonStyle(.borderless)
                .sheet(isPresented: $showPreview) {
                    PreviewWhereView(
                        eventManager: $previewEventManager,
                        selectionDice: $selectedDice,
                        simManager: simManager,
                        addFunc: add
                    )
                }
                .padding(.leading, 5)
                Spacer()
            }
            ZStack {
                SimulatorCard(minHeight: 40, minWidth: 200)
                    .shadow(color: .primary, radius: 3, x: 5, y: 5)
                HStack {
                    VStack {
                        Text("\(preset.events.count)")
                            .font(.headline.bold())
                        Text("Events")
                            .font(.subheadline)
                    }
                    .padding(.leading, 10)
                    Spacer()
                    Button {
                        add(preset)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .symbolRenderingMode(.multicolor)
                            .imageScale(.large)
                    }
                    .buttonStyle(.borderless)
                    .padding(.trailing, 10)
                }
            }
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
