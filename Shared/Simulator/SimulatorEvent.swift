import SwiftUI
import UniformTypeIdentifiers

class SimulatorConstants {
    static let cardHeight: CGFloat = 100
    static let diceColor: Color = .blue
    static let buttonColor: Color = .blue
    static let buttonClick: Double = 1.0
    static let buttonUnclick: Double = 0.2
    static let cardBrightness: Double = 0.8
    static let popUpPadding: Double = 10.0
    static let popUpWidth: Double = 100
    static let popUpHeight: Double = 30
    // Yahtzee setup
    static let defaultTotalDice: Int = 5
}

enum Bound: String, CaseIterable, Codable {
    case exactly = "Exactly"
    case leq = "At most"
    case geq = "At least"
    case le = "Less than"
    case ge = "Greater than"
}

enum Reduction: String, CaseIterable, Codable {
    case each = "\t"
    case consecutive = "Run of"
    case sequence = "Sequence of"
    case sum = "Sum of"
    case average = "Average of"
    case median = "Median of"
    case minimum = "Minimum of"
    case maximum = "Maximum of"
    case mode = "Mode of"
}

enum Comparison: String, CaseIterable, Codable {
    case equals = "Equals"
    case neq = "Not Equal"
    case leq = "Less Than Or Equal"
    case geq = "Greater Than Or Equal"
    case le = "Less Than"
    case ge = "Greater Than"
    case between = "Between"
}

enum Conjunction: String, CaseIterable, Codable {
    case and = "And"
    case or = "Or"
    case first = "First"
}

enum EventStatus {
    case valid, invalid, none
}

struct Between: Hashable, Identifiable, Codable {
    var id: UUID = UUID()
    var lower: Int
    var upper: Int
}

struct Event: Hashable, Identifiable {
    // -----------------------------------------
    // Occurence: At least 3 D3 = 4
    // Reduction: Exactly 3 D3 sum to exactly 10
    // Subset Reduction: At least 3 D3 sum to less than 10
    // -----------------------------------------
    var id: UUID
    // Minimal
    var _bound: Bound?
    var quantity: Int
    var dice: DiceTypes?
    // Reduction Clause
    var reduction: Reduction?
    var _comparison: Comparison?
    // Dice values to compare
    var value: Int
    var values: Between
    // Comparison to previous event
    var conjunction: Conjunction?
    
    var invalid: Bool = false
    var resetFlag: Bool = false
    
    var bound: Bound? {
        get {
            switch reduction {
            case .each, .consecutive, nil:
                return _bound
            default:
                return .exactly
            }
        }
        set (newBound) {
            _bound = newBound
        }
    }
    
    var comparison: Comparison? {
        get {
            switch reduction {
            case .sequence:
                return .between
            default:
                return _comparison
            }
        }
        set (newComparison) {
            _comparison = newComparison
        }
    }
    
    var settings: EventSettings {
        get {
            return EventSettings(
                bound: bound,
                quantity: quantity,
                dice: dice,
                reduction: reduction,
                comparison: comparison,
                value: value,
                values: values,
                conjunction: conjunction
            )
        }
        
        set (settings) {
            bound = settings.bound
            quantity = settings.quantity
            dice = settings.dice
            reduction = settings.reduction
            comparison = settings.comparison
            value = settings.value
            values = settings.values
            conjunction = settings.conjunction
        }
    }
    
    var validEvent: EventStatus {
        get {
            if (
                validEventWithoutConjunction == .valid &&
                conjunction != nil
            ) {
                return .valid
            } else if invalid {
                return .invalid
            } else {
                return .none
            }
        }
        set {
            
        }
    }
    
    var validEventWithoutConjunction: EventStatus {
        get {
            switch reduction {
            case .each, .consecutive, nil:
                if (
                    bound != nil && dice != nil &&
                    reduction != nil && comparison != nil
                ) {
                    return .valid
                } else if invalid {
                    return .invalid
                } else {
                    return .none
                }
            case .sequence:
                if reduction != nil && dice != nil {
                    return .valid
                } else if invalid {
                    return .invalid
                } else {
                    return .none
                }
            case .average, .minimum, .maximum, .mode, .median, .sum:
                if (
                    reduction != nil && dice != nil &&
                    comparison != nil
                ) {
                    return .valid
                } else if invalid {
                    return .invalid
                } else {
                    return .none
                }
            }
        }
        set {
            
        }
    }
    
    init(
        bound: Bound? = nil,
        quantity: Int = 1, 
        dice: DiceTypes? = nil,
        conjunction: Conjunction? = nil,
        reduction: Reduction? = nil,
        comparison: Comparison? = nil,
        value: Int = 1,
        values: Between = Between(lower: 1, upper: 1)
    ) {
        self.id = UUID()
        self._bound = bound
        self.quantity = quantity
        self.dice = dice
        self.conjunction = conjunction
        self.reduction = reduction
        self._comparison = comparison
        self.value = value
        self.values = values
    }
}

extension Event {
    mutating func setDefault(dice: DiceTypes?) {
        self.dice = dice
        if self.bound == nil {
            self.bound = .exactly
        }
        if self.reduction == nil {
            self.reduction = .each
        }
        if self.comparison == nil {
            self.comparison = .equals
        }
    }
    
    mutating func setFirst() {
        self.conjunction = .first
    }
    
    mutating func triggerInvalid() {
        self.invalid = true
    }
    
    mutating func reset(dice: DiceTypes?, conjunction: Conjunction?) {
        self.bound = nil
        self.quantity = 1
        self.dice = dice
        self.conjunction = conjunction
        self.reduction = nil
        self.comparison = nil
        self.value = 1
        self.values = Between(lower: 1, upper: 1)
        self.resetFlag.toggle()
    }
}

class EventManager: NSObject, ObservableObject, Identifiable, NSCopying {
    @Published var name: String
    @Published var events: [Event] = []
    @Published var pin: Bool = false
    @Published var simulationResult: SimulationResults = SimulationResults()
    @Published var simulationData: GeometricPlotData = GeometricPlotData()
    @Published var showingWhere: Bool = false
    @Published var showingConjunctions: Bool = true
    
    init(name: String, pin: Bool = false, events: [Event] = []) {
        self.name = name
        self.pin = pin
        self.events = events
    }
    
    var safeName: String {
        if self.name == "" {
            return "Event"
        } else {
            return self.name
        }
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = EventManager(name: name, pin: pin, events: events)
        return copy
    }
    
    var settings: EventManagerSettings {
        get {
            var _events: [EventSettings] = []
            for event in events {
                _events.append(event.settings)
            }
            return EventManagerSettings(
                name: self.safeName,
                pin: pin,
                events: _events
            )
        }
        set (settings) {
            name = settings.name
            pin = settings.pin
            events = []
            for setting in settings.events {
                var event = Event()
                event.settings = setting
                events.append(event)
            }
        }
    }
    
    func updateSelectedDiceType(newDiceType: DiceTypes?) {
        for index in events.indices {
            events[index].dice = newDiceType
        }
    }
    
    static func == (lhs: EventManager, rhs: EventManager) -> Bool {
        return lhs.settings == rhs.settings
    }
    
    static func != (lhs: EventManager, rhs: EventManager) -> Bool {
        return !(lhs == rhs)
    }
    
    var validEvents: Bool {
        get {
            if events.isEmpty {
                return false
            }
            return events.allSatisfy({$0.validEvent == .valid})
        }
    }
}

enum EventURL: String {
    case events = "events.data"
    case favorites = "favorites.data"
}

class EventManagers: ObservableObject {
    @Published var managers: [EventManager]
    @Published var showManager: Bool = true
    var url: EventURL
    
    init(url: EventURL, managers: [EventManager] = []) {
        self.url = url
        self.managers = managers
    }
    
    private static func fileURL(_ url: EventURL) throws -> URL {
        try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent(url.rawValue)
    }
    
    static func load(url: EventURL, completion: @escaping (Result<[EventManagerSettings], Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let fileURL = try fileURL(url)
                guard let file = try? FileHandle(forReadingFrom: fileURL) else {
                    DispatchQueue.main.async {
                        completion(.success([]))
                    }
                    return
                }
                let settings = try JSONDecoder().decode([EventManagerSettings].self, from: file.availableData)
                DispatchQueue.main.async {
                    completion(.success(settings))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    static func save(
        url: EventURL,
        settings: [EventManagerSettings],
        completion: @escaping (Result<Int, Error>) -> Void
    ) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(settings)
                let outfile = try fileURL(url)
                try data.write(to:outfile)
                DispatchQueue.main.async {
                    completion(.success(settings.count))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

class EventManagersContainer: ObservableObject {
    @Published var eventManagers: EventManagers = EventManagers(url: .events)
}


struct ExportedEventSettings: Codable {
    
    struct exportedBetween: Codable {
        var lower: Int
        var upper: Int
    }
    
    var bound: Bound?
    var quantity: Int
    var dice: DiceTypes?
    var reduction: Reduction?
    var comparison: Comparison?
    var value: Int
    var values: exportedBetween
    var conjunction: Conjunction?
    
    init(settings: EventSettings) {
        self.bound = settings.bound
        self.quantity = settings.quantity
        self.dice = settings.dice
        self.reduction = settings.reduction
        self.comparison = settings.comparison
        self.value = settings.value
        self.values = exportedBetween(
            lower: settings.values.lower, upper: settings.values.upper
        )
        self.conjunction = settings.conjunction
    }
}

struct EventSettings: Identifiable, Codable, Equatable {
    let id: UUID
    var bound: Bound?
    var quantity: Int
    var dice: DiceTypes?
    var reduction: Reduction?
    var comparison: Comparison?
    var value: Int
    var values: Between
    var conjunction: Conjunction?
    init(
        id: UUID = UUID(),
        bound: Bound? = nil,
        quantity: Int = 1,
        dice: DiceTypes? = nil,
        reduction: Reduction? = nil,
        comparison: Comparison? = nil,
        value: Int = 1,
        values: Between = Between(lower: 1, upper: 1),
        conjunction: Conjunction? = nil
    ) {
        self.id = id
        self.bound = bound
        self.quantity = quantity
        self.dice = dice
        self.reduction = reduction
        self.comparison = comparison
        self.value = value
        self.values = values
        self.conjunction = conjunction
    }
    
    init(from export: ExportedEventSettings) {
        self.id = UUID()
        self.bound = export.bound
        self.quantity = export.quantity
        self.dice = export.dice
        self.reduction = export.reduction
        self.comparison = export.comparison
        self.value = export.value
        self.values = Between(lower: export.values.lower, upper: export.values.upper)
        self.conjunction = export.conjunction
    }
}

extension EventSettings {
    struct Data {
        var bound: Bound? = nil
        var quantity: Int = 1
        var dice: DiceTypes? = nil
        var reduction: Reduction? = nil
        var comparison: Comparison? = nil
        var value: Int = 1
        var values: Between = Between(lower: 1, upper: 1)
        var conjunction: Conjunction? = nil
    }
    
    var data: Data {
        Data(
            bound: bound,
            quantity: quantity,
            dice: dice,
            reduction: reduction,
            comparison: comparison,
            value: value,
            values: values,
            conjunction: conjunction
        )
    }
    
    mutating func update(from data: Data) {
        bound = data.bound
        quantity = data.quantity
        dice = data.dice
        reduction = data.reduction
        comparison = data.comparison
        value = data.value
        values = data.values
        conjunction = data.conjunction
    }
    
    init(data: Data) {
        id = UUID()
        bound = data.bound
        quantity = data.quantity
        dice = data.dice
        reduction = data.reduction
        comparison = data.comparison
        value = data.value
        values = data.values
        conjunction = data.conjunction
    }
}

struct ExportedEventManagerSettings: Codable {
    var name: String
    var events: [ExportedEventSettings]
    
    init(settings: EventManagerSettings) {
        self.name = settings.name
        self.events = []
        for event in settings.events {
            self.events.append(
                ExportedEventSettings(settings: event)
            )
        }
    }
}

struct EventManagerSettings: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var pin: Bool
    var events: [EventSettings]
    var showManager: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        pin: Bool,
        events: [EventSettings],
        showManager: Bool = true
    ) {
        self.id = id
        self.name = name
        self.pin = pin
        self.events = events
        self.showManager = showManager
    }
}

extension EventManagerSettings {
    struct Data {
        var name: String = ""
        var pin: Bool = false
        var events: [EventSettings] = []
        var showManager: Bool = true
    }
    
    var data: Data {
        Data(
            name: name,
            pin: pin,
            events: events,
            showManager: showManager
        )
    }
    
    mutating func update(from data: Data) {
        name = data.name
        pin = data.pin
        events = data.events
        showManager = data.showManager
    }
    
    init(data: Data) {
        id = UUID()
        name = data.name
        pin = data.pin
        events = data.events
        showManager = data.showManager
    }
}

extension UTType {
    static var settings: UTType { UTType(exportedAs: "com.company.Pro-Roller") }
}

@available(iOS 16.0, *)
extension ExportedEventManagerSettings: Transferable {
   static var transferRepresentation: some TransferRepresentation {
       CodableRepresentation(contentType: .settings)
   }
}
