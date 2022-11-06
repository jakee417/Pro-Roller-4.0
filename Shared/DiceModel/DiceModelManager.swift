import SwiftUI

struct DiceManagerSettings: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var diceAmount: Int
    var diceType: DiceTypes
    var selectionMode: RollType
    var animate: Bool
    var showHistogram: Bool
    var showProfile: Bool
    var incrementAmount: DiceAmountPresets
    var color: Color
    var diceValues: [Int]
    var count: Int
    var lockSelection: [Int: Int]
    var editSelection: Set<Int>
    init(
        id: UUID = UUID(),
        name: String = "",
        diceAmount: Int = 0,
        diceType: DiceTypes = .D6, 
        selectionMode: RollType = .shuffle, 
        animate: Bool = true,
        showHistogram: Bool = true,
        showProfile: Bool = true,
        incrementAmount: DiceAmountPresets = .small,
        color: Color = .white,
        diceValues: [Int] = [],
        count: Int = 0,
        lockSelection: [Int: Int] = [:],
        editSelection: Set<Int> = []
    ) {
        self.id = id
        self.name = name
        self.diceAmount = diceAmount
        self.diceType = diceType
        self.selectionMode = selectionMode
        self.animate = animate
        self.showHistogram = showHistogram
        self.showProfile = showProfile
        self.incrementAmount = incrementAmount
        self.color = color
        self.diceValues = diceValues
        self.count = count
        self.lockSelection = lockSelection
        self.editSelection = editSelection
    }
}

extension DiceManagerSettings {
    struct Data {
        var name: String = ""
        var diceAmount: Int = 0
        var diceType: DiceTypes = .D6
        var selectionMode: RollType = .shuffle
        var animate: Bool = true
        var showHistogram: Bool = true
        var showProfile: Bool = true
        var incrementAmount: DiceAmountPresets = .small
        var color: Color = .white
        var diceValues: [Int] = []
        var count: Int = 0
        var lockSelection: [Int: Int] = [:]
        var editSelection: Set<Int>
    }
    
    var data: Data {
        Data(
            name: name,
            diceAmount: diceAmount,
            diceType: diceType, 
            selectionMode: selectionMode,
            animate: animate,
            showHistogram: showHistogram,
            showProfile: showProfile,
            incrementAmount: incrementAmount,
            color: color,
            diceValues: diceValues,
            count: count,
            lockSelection: lockSelection,
            editSelection: editSelection
        )
    }
    
    mutating func update(from data: Data) {
        name = data.name
        diceAmount = data.diceAmount
        diceType = data.diceType
        selectionMode = data.selectionMode
        animate = data.animate
        showHistogram = data.showHistogram
        showProfile = data.showProfile
        incrementAmount = data.incrementAmount
        color = data.color
        diceValues = data.diceValues
        count = data.count
        lockSelection = data.lockSelection
        editSelection = data.editSelection
    }
    
    init(data: Data) {
        id = UUID()
        name = data.name
        diceAmount = data.diceAmount
        diceType = data.diceType
        selectionMode = data.selectionMode
        animate = data.animate
        showHistogram = data.showHistogram
        showProfile = data.showProfile
        incrementAmount = data.incrementAmount
        color = data.color
        diceValues = data.diceValues
        count = data.count
        lockSelection = data.lockSelection
        editSelection = data.editSelection
    }
}

class DiceManager: ObservableObject, Identifiable, Equatable {
    @Published var name: String
    @Published var dice: [Dice]
    @Published public var count: Int = 0
    @Published private var _sides: DiceTypes
    @Published private var _selectionMode: RollType = .shuffle
    @Published var showHistogram: Bool = false
    @Published var animate: Bool = true
    @Published var incrementAmount: DiceAmountPresets = .small
    @Published private var _color: Color = .white
    @Published public var lockSelection: [Int: Int] = [:]
    @Published public var showSimulator: Bool = false
    @Published public var showProfile: Bool = false
    @Published public var editSelection: Set<Int> = Set<Int>()
    
    init(
        name: String = "",
        dice: [Dice] = [],
        sides: DiceTypes = .D6,
        selectionMode: RollType = .shuffle
    ) {
        self.name = name
        self.dice = dice
        self._sides = sides
        self._selectionMode = selectionMode
        self.sides = sides
        self.selectionMode = selectionMode
    }
    
    public var history: [DiceManagerSettings] = []
    public var futureHistory: [DiceManagerSettings] = []
    
    var selectionMode: RollType {
        get {
            return self._selectionMode
        }
        set (value) {
            switch self._selectionMode {
            case .shuffle, .single, .sort:
                break
            case .freezable:
                withAnimation(nil) {
                    self.lockSelection = [:]
                }
            case .edit:
                self.editSelection = []
            }
            self._selectionMode = value
        }
    }
    
    func rewindHistory() {
        // Check for a past. If there is none, do nothing.
        // Otherwise, record the future and reset to the past.
        guard let last = history.popLast() else {
            return
        }
        // Current snapshot goes to futureHistory.
        futureHistory.append(settings)
        settings = last
    }
    
    func recallHistory() {
        // Check for a future. If there was no future history, do nothing.
        // Otherwise, recall the future and add to history stack.
        guard let first: DiceManagerSettings = futureHistory.popLast() else {
            return
        }
        // Put the current settings, back into history.
        history.append(settings)
        settings = first
    }
    
    func pushForwardHistory(_ artifact: DiceManagerSettings) {
        // If we had a futureHistory, it is now invalidated.
        futureHistory = []
        // Add to history stack
        history.append(artifact)
        // Control history size
        if history.count > 100 {
            history.removeFirst()
        }
    }
    
    var settings: DiceManagerSettings {
        get {
            let _diceValues = dice.map({ $0.value })
            return DiceManagerSettings(
                name: name,
                diceAmount: totalDice, 
                diceType: sides, 
                selectionMode: selectionMode,
                animate: animate, 
                showHistogram: showHistogram,
                showProfile: showProfile,
                incrementAmount: incrementAmount,
                color: color,
                diceValues: _diceValues,
                count: count,
                lockSelection: lockSelection,
                editSelection: editSelection
            )
        }
        set(setting) {
            self.sides = setting.diceType
            self.dice = []
            if setting.diceAmount > 0 {
                for _ in 1...setting.diceAmount {
                    self.append()
                }
            }
            self.setDice(setting.diceValues)
            self.selectionMode = setting.selectionMode
            self.showHistogram = setting.showHistogram
            self.animate = setting.animate
            self.incrementAmount = setting.incrementAmount
            self.color = setting.color
            self.name = setting.name
            self.showProfile = setting.showProfile
            self.count = setting.count
            self.lockSelection = setting.lockSelection
            self.editSelection = setting.editSelection
        }
    }
    
    func setDice(_ values: [Int]) {
        guard values.count == dice.count else {
            return
        }
        for index in values.indices {
            dice[index].value = values[index]
        }
    }
    
    static func == (lhs: DiceManager, rhs: DiceManager) -> Bool {
        return lhs.settings == rhs.settings
    }
    
    static func != (lhs: DiceManager, rhs: DiceManager) -> Bool {
        return !(lhs == rhs)
    }
    
    public var maxDice: Int {
        get {
            return 100
        }
    }
    
    public var color: Color {
        get {
            return self._color
        }
        set(color) {
            self._color = color
            for index in self.dice.indices {
                self.dice[index].diceColor = self._color
            }
        }
    }
    
    public var sides: DiceTypes {
        get {
            return _sides
        }
        set(newSides) {
            _sides = newSides
            self.editSelection = Set<Int>()
            for index in self.dice.indices {
                self.dice[index] = Dice(sides: _sides, diceColor: color)
            }
        }
    }
    
    public var sidesOptional: DiceTypes? {
        get {
            return _sides
        }
        set(newSides) {
            guard let newSide = newSides else {
                return
            }
            _sides = newSide
            for index in self.dice.indices {
                self.dice[index] = Dice(sides: _sides, diceColor: color)
            }
        }
    }
    
    public var chartData: [ChartData] {
        get {
            var totals: [Int: Double] = [:]
            for side in Array(1...sides.rawValue) {
                totals[side] = 0
            }
            for die in dice {
                totals[die.value] = (totals[die.value] ?? 0) + 1
            }
            var result: [ChartData] = []
            var maxCount = totals.values.max() ?? 1
            if maxCount == 0 {
                maxCount += 1
            }
            for (key, value) in totals.sorted(by: <){
                result.append(
                    ChartData(
                        label: "\(key)", 
                        numericLabel: key,
                        normalizedValue: value / maxCount,
                        value: Int(value),
                        percentage: value / Double(safeTotalDice)
                    )
                )
            }
            return result
        }
    }
    
    var totalDice: Int {
        get {
            return dice.count
        }
        set(value) {
            let difference = value - dice.count
            if difference > 0 {
                for _ in 1...(difference) {
                    append()
                }
            } else if difference < 0 {
                for _ in 1...abs(difference) {
                    popLastUnfrozen()
                }
            }
        }
    }
    
    var safeTotalDice: Int {
        get {
            if dice.isEmpty {
                return 1
            } else {
                return self.totalDice
            }
        }
    }
    
    var totalRoll: Int {
        get {
            return dice.map({$0.value}).reduce(0, +)
        }
    }
    
    var Average: Double {
        get {
            return Double(totalRoll) / Double(safeTotalDice)
        }
    }
    
    var indexValueMap: [Int: Int] {
        get {
            var map: [Int: Int] = [:]
            for index in dice.indices {
                map.updateValue(dice[index].value, forKey: index)
            }
            return map
        }
    }
    
    func append() {
        dice.append(Dice(sides: sides, diceColor: color))
    }
    
    func popLast() {
        lockSelection.removeValue(forKey: dice.count - 1)
        _ = dice.popLast()
    }
    
    func popLastUnfrozen() {
        let unfrozen = Set(dice.indices).subtracting(lockSelection.keys)
        guard let lastUnfrozenIndex = unfrozen.max() else {
            return
        }
        _ = dice.remove(at: lastUnfrozenIndex)
        // update the accounting of lockSelection
        let needToDecrement = Set(lockSelection.keys).subtracting(0...lastUnfrozenIndex).sorted()
        for index in needToDecrement {
            print(index)
            guard let value = lockSelection.removeValue(forKey: index) else {
                continue
            }
            lockSelection.updateValue(value, forKey: index - 1)
        }
    }
    
    func sort() {
        self.dice.sort{ 
            $0.value < $1.value 
        }
    }
    
    func rollIndex(index: Int) {
        self.dice[index].roll()
        self.dice[index].randomTransition()
    }
    
    func roll() {
        for index in self.dice.indices {
            self.rollIndex(index: index)
        }
    }
    
    func freezeRoll() {
        for index in self.dice.indices {
            if !self.lockSelection.contains(where: { $0.key == index }) {
                self.rollIndex(index: index)
            }
        }
    }
    
    func selectionModeRoll() {
        UIImpactFeedbackGenerator(style: .soft)
            .impactOccurred()
        switch self.selectionMode {
        case .single, .shuffle, .edit:
            self.roll()
        case .sort:
            self.roll()
            self.sort()
        case .freezable:
            freezeRoll()
        }
    }
}

class DiceManagers: ObservableObject {
    @Published var managers: [DiceManager] = []
    
    init(_ managers: [DiceManager] = []) {
        self.managers = managers
    }
    
    func append(_ element: DiceManager = DiceManager()) {
        managers.append(element)
    }
    
    func popLast() {
        _ = managers.popLast()
    }
    
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("settings.data")
    }
    
    static func load(completion: @escaping (Result<[DiceManagerSettings], Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let fileURL = try fileURL()
                guard let file = try? FileHandle(forReadingFrom: fileURL) else {
                    DispatchQueue.main.async {
                        completion(.success([]))
                    }
                    return
                }
                let settings = try JSONDecoder().decode([DiceManagerSettings].self, from: file.availableData)
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
    
    static func save(settings: [DiceManagerSettings], completion: @escaping (Result<Int, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try JSONEncoder().encode(settings)
                let outfile = try fileURL()
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
    
    static func encode(settings: [DiceManagerSettings], completion: @escaping (Result<Data, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let encoded = try JSONEncoder().encode(settings)
                DispatchQueue.main.async {
                    completion(.success(encoded))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    static func decode(data: Data, completion: @escaping (Result<DiceManagers, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let decoded = try JSONDecoder().decode([DiceManagerSettings].self, from: data)
                let newDiceManagers: DiceManagers = DiceManagers()
                for setting in decoded {
                    let newDiceManager = DiceManager()
                    newDiceManager.settings = setting
                    newDiceManagers.managers.append(newDiceManager)
                }
                DispatchQueue.main.async {
                    completion(.success(newDiceManagers))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
