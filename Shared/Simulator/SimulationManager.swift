//
//  SimulatorViewHeader.swift
//  Pro Roller
//
//  Created by Jake Taylor on 7/29/22.
//

import Foundation

enum SimulationError: Error {
    case invalidEvent(_ index: Int)
    case invalidEvents(_ reason: String)
    case nilDiceType
    case nilDiceAmount
}

struct ValidEvent {
    var bound: Bound
    var quantity: Int
    var reduction: Reduction
    var comparison: Comparison
    var value: Int
    var values: Between
    var conjunction: Conjunction
    var diceType: DiceTypes
    
    var lowestValue: Int {
        get {
            if values.lower < values.upper {
                return values.lower
            } else if values.upper < values.lower {
                return values.upper
            } else {
                return values.upper
            }
        }
    }
    
    var highestValue: Int {
        get {
            if values.lower > values.upper {
                return values.lower
            } else if values.upper > values.lower {
                return values.upper
            } else {
                return values.upper
            }
        }
    }
}

enum SimulationSize: Int, CaseIterable {
    case small = 1_000
    case medium = 5_000
    case large = 10_000
}

enum SimulationStatus {
    case populated, empty, error
}

struct SimulationResults: Identifiable {
    var id: UUID = UUID()
    var probability: Double = 0.0
    var sum: Double = 0.0
    var average: Double = 0.0
    var status: SimulationStatus = .empty
    
    var safeSum: String {
        get {
            return sum.isNaN ? "--" : String(format: "%.2f", sum)
        }
    }
    
    var safeAvg: String {
        get {
            return average.isNaN ? "--" : String(format: "%.2f", average)
        }
    }
}

enum PlotKSizes: Int, CaseIterable {
    case small = 10
    case medium = 100
    case large = 1_000
    case extraLarge = 10_000
}

struct GeometricPlotData: Identifiable {
    var id: UUID = UUID()
    var pmfData: [ChartData] = []
    var cdfData: [ChartData] = []
    var status: SimulationStatus = .empty
    
    func _DataSizeK(_ K: PlotKSizes, data: [ChartData]) -> [ChartData] {
        guard status == .populated else {
            return []
        }
        var result: [ChartData] = []
        if K != .small {
            result.append(data[0])
        }
        for k in stride(from: 0, to: K.rawValue + 1, by: K.rawValue / 10) {
            if k == 0 {
                continue
            }
            result.append(data[k - 1])
        }
        return result
    }
    
    func pmfDataSizeK(_ K: PlotKSizes) -> [ChartData] {
        return _DataSizeK(K, data: pmfData)
    }
    
    func cdfDataSizeK(_ K: PlotKSizes) -> [ChartData] {
        return _DataSizeK(K, data: cdfData)
    }
}

struct Simulation1D: Identifiable {
    var id: UUID = UUID()
    var prob1D: [ChartData] = [ChartData]()
    var sum1D: [ChartData] = [ChartData]()
    var avg1D: [ChartData] = [ChartData]()
    var status: SimulationStatus = .empty
}

struct Simulation2D: Identifiable {
    var id: UUID = UUID()
    var probGrid: [Int: [Int: ChartData]] = [Int: [Int: ChartData]]()
    var sumGrid: [Int: [Int: ChartData]] = [Int: [Int: ChartData]]()
    var avgGrid: [Int: [Int: ChartData]] = [Int: [Int: ChartData]]()
    var status: SimulationStatus = .empty
}

class SimulationManager: ObservableObject {
    @Published var _batchSize = SimulationSize.medium.rawValue
    @Published var showSettings: Bool = true
    @Published var simulateFrozen: Bool = true
    
    public var batches: [[Int]] = [[]]

    var batchSize: Int {
        get {
            return _batchSize
        }
        set(newBatchSize) {
            _batchSize = newBatchSize
        }
    }
    
    func getSimulationBatch(diceType: DiceTypes, eventSize: Int, lockSelection: [Int: Int]) throws -> [Int] {
        var batch: [Int] = []
        if eventSize - 1 < 0 {
            throw SimulationError.nilDiceAmount
        }
        for i in 0...eventSize - 1 {
            // Is this frozen or not? Do we simulateFrozen?
            if lockSelection.contains(where: { $0.key == i }) && simulateFrozen {
                guard let value = lockSelection[i] else {
                    continue
                }
                batch.append(value)
            } else {
                batch.append(Int.random(in: 1..<diceType.rawValue + 1))
            }
        }
        assert(eventSize == batch.count)
        return batch
    }
    
    func getSimulationBatches(diceType: DiceTypes?, eventSize: Int, lockSelection: [Int: Int]) throws -> [[Int]] {
        var _eventSize: Int = eventSize
        if !simulateFrozen {
            _eventSize -= lockSelection.count
        }
        guard let _diceType = diceType else {
            throw SimulationError.nilDiceType
        }
        var simulationBatches: [[Int]] = []
        for _ in 1...batchSize {
            do {
                try simulationBatches.append(
                    getSimulationBatch(
                        diceType: _diceType,
                        eventSize: _eventSize,
                        lockSelection: lockSelection
                    )
                )
            } catch SimulationError.nilDiceAmount {
                throw SimulationError.nilDiceAmount
            }
        }
        return simulationBatches
    }
    
    func convertEventToValidEvent(event: Event) throws -> ValidEvent {
        guard let reduction = event.reduction else {
            throw SimulationError.invalidEvent(0)
        }
        
        guard let diceType = event.dice else {
            throw SimulationError.invalidEvent(0)
        }
        
        guard let conjunction = event.conjunction else {
            throw SimulationError.invalidEvent(0)
        }
        
        // sequence doesn't need comparison or bound
        if reduction == .sequence {
            return ValidEvent(
                bound: .exactly,
                quantity: event.quantity,
                reduction: reduction,
                comparison: .between,
                value: event.value,
                values: event.values,
                conjunction: conjunction,
                diceType: diceType
            )
        }
        
        guard let comparison = event.comparison else {
            throw SimulationError.invalidEvent(0)
        }
        
        // aggregation doesn't need bound
        if (
            reduction == .sum || reduction == .median ||
            reduction == .maximum || reduction == .minimum ||
            reduction == .mode || reduction == .average
        ) {
            return ValidEvent(
                bound: .exactly,
                quantity: event.quantity,
                reduction: reduction,
                comparison: comparison,
                value: event.value,
                values: event.values,
                conjunction: conjunction,
                diceType: diceType
            )
        }
        
        guard let bound = event.bound else {
            throw SimulationError.invalidEvent(0)
        }
        
        return ValidEvent(
            bound: bound,
            quantity: event.quantity,
            reduction: reduction,
            comparison: comparison,
            value: event.value,
            values: event.values,
            conjunction: conjunction,
            diceType: diceType
        )
    }
    
    func boolToInt(_ condition: Bool) -> Int {
        return condition ? 1 : 0
    }
    
    func scoreEachEvent(batch: [Int], event: ValidEvent) -> Bool {
        /// Exactly 3 D6 each = 4
        /// [4, 2, 4, 1, 4, 1] -> events
        /// [1, 0, 1, 0, 1, 0] -> reduction
        /// 3 -> compare against bound
        var result: Int = 0
        for element in batch {
            switch event.comparison {
            case .equals:
                result += boolToInt(element == event.value)
            case .neq:
                result += boolToInt(element != event.value)
            case .leq:
                result += boolToInt(element <= event.value)
            case .geq:
                result += boolToInt(element >= event.value)
            case .le:
                result += boolToInt(element < event.value)
            case .ge:
                result += boolToInt(element > event.value)
            case .between:
                result += boolToInt(element >= event.lowestValue && element <= event.highestValue)
            }
        }
        switch event.bound {
        case .exactly:
            return result == event.quantity
        case .leq:
            return result <= event.quantity
        case .geq:
            return result >= event.quantity
        case .le:
            return result < event.quantity
        case .ge:
            return result > event.quantity
        }
    }
    
    func scoreAggregationEvent(batch: [Int], event: ValidEvent) -> Bool {
        /// TODO: Implement
        /// [6, 1, 3]
        //
        // Exactly 2 D6 sum to exactly 4
        // [10] -> reduction
        // 1 -> compare against bound
        //
        var result: Int = 0
        switch event.reduction {
        case .sum:
            result = batch.reduce(0, { x, y in x + y })
        case .average:
            result = batch.reduce(0, { x, y in x + y })
            result = result / batch.count
        case .median:
            result = calculateMedian(array: batch)
        case .maximum:
            result = batch.max() ?? 0
        case .minimum:
            result = batch.min() ?? 0
        case .mode:
            let mappedItems = batch.map { ($0, 1) }
            let counts = Dictionary(mappedItems, uniquingKeysWith: +)
            result = counts.max { a, b in a.value < b.value }?.key ?? 0
        case .each, .consecutive, .sequence:
            break
        }
        // For aggregation, we compare the result to the comparison, not bound.
        switch event.comparison {
        case .equals:
            return result == event.value
        case .neq:
            return result != event.value
        case .leq:
            return result <= event.value
        case .geq:
            return result >= event.value
        case .le:
            return result < event.value
        case .ge:
            return result > event.value
        case .between:
            return result >= event.lowestValue && result <= event.highestValue
        }
    }
    
    func boolToRun(_ condition: Bool, result: inout Int, results: inout [Int]) {
        if condition {
            result += 1
        } else {
            // Record run length if present
            if result > 0 {
                results.append(result)
            }
            // Reset current run
            result = 0
        }
    }
    
    func scoreConsecutiveEvent(batch: [Int], event: ValidEvent) -> Bool {
        /// Exactly 3 D6 consecutively equal to 4
        /// [4, 2, 4, 4, 4, 1, 2] -> events
        /// [1, 3] -> reduction
        /// 1 & 3 -> compared against bound
        // Run length
        var result: Int = 0
        // All run lengths
        var results: [Int] = []
        for element in batch {
            switch event.comparison {
            case .equals:
                boolToRun(element == event.value, result: &result, results: &results)
            case .neq:
                boolToRun(element != event.value, result: &result, results: &results)
            case .leq:
                boolToRun(element <= event.value, result: &result, results: &results)
            case .geq:
                boolToRun(element >= event.value, result: &result, results: &results)
            case .le:
                boolToRun(element < event.value, result: &result, results: &results)
            case .ge:
                boolToRun(element > event.value, result: &result, results: &results)
            case .between:
                boolToRun(
                    element >= event.lowestValue && element <= event.highestValue,
                    result: &result,
                    results: &results
                )
            }
        }
        
        // Add the last result if needed
        if result > 0 {
            results.append(result)
        }
        
        switch event.bound {
        case .exactly:
            return results.contains(event.quantity)
        case .leq:
            return results.contains{ $0 <= event.quantity }
        case .geq:
            return results.contains{ $0 >= event.quantity }
        case .le:
            return results.contains{ $0 < event.quantity }
        case .ge:
            return results.contains{ $0 > event.quantity }
        }
    }
    
    func scoreSequenceEvent(batch: [Int], event: ValidEvent) -> Bool {
        /// Sequence in 5 D6
        /// between 1 and 4
        /// [5, 1, 2, 3, 4, 3] -> events
        /// true
        var subSequence = Array(event.lowestValue...event.highestValue)
        if event.values.upper < event.values.lower {
            subSequence = Array(subSequence.reversed())
        }
        return batch.contains(subSequence)
    }
    
    func scoreEvent(batch: [Int], event: ValidEvent) -> Bool {
        switch event.reduction {
        case .each:
            return scoreEachEvent(batch: batch, event: event)
        case .average, .median, .sum, .maximum, .minimum, .mode:
            return scoreAggregationEvent(batch: batch, event: event)
        case .consecutive:
            return scoreConsecutiveEvent(batch: batch, event: event)
        case .sequence:
            return scoreSequenceEvent(batch: batch, event: event)
        }
    }
    
    func scoreEvents(batch: [Int], events: [ValidEvent]) -> [Bool] {
        var scores: [Bool] = []
        for event in events {
            let score = scoreEvent(batch: batch, event: event)
            scores.append(score)
        }
        return scores
    }
    
    func numberOrConjunctions(events: [ValidEvent]) -> Int {
        var orConjunctions: Int = 0
        for (index, event) in events.enumerated() {
            if index == 0 {
                continue
            } else {
                orConjunctions += event.conjunction == .or ? 1 : 0
            }
        }
        return orConjunctions
    }
    
    func scoreConjunctions(scores: [Bool], events: [ValidEvent]) throws -> Int {
        /// Combine a sequence of booleans based upon a sequence of conjunctions.
        /// Example:
        /// [true && false && true || true && true || false && true]
        /// And part:
        /// [true]
        /// [false]
        /// [false]
        /// [false, true]
        /// [false, true]
        /// [false, true, false]
        /// [false || true || false]
        /// Or part:
        ///  false [false, true, false]
        /// [false, true, false]
        /// [true, false]
        /// [true]
        guard events.count != 0 else {
            throw SimulationError.invalidEvents("Specify at least one where clause")
        }
        guard scores.count == events.count else {
            throw SimulationError.invalidEvents("Scores different than clauses")
        }
        var index = 0
        var _scores: [Bool] = []
        // And pass
        while index < events.count {
            switch events[index].conjunction {
            case .or, .first:
                // skip a consolidation, save for Or part.
                _scores.append(scores[index])
            case .and:
                // consolidate the last entry with the current.
                _scores.append(_scores.popLast()! && scores[index])
            }
            index += 1
        }
        let orConjunctions = numberOrConjunctions(events: events)
        guard _scores.count - 1 == orConjunctions else {
            throw SimulationError.invalidEvents("Incorrect Or conjunction clauses")
        }
        var finalScore: Bool = false
        // Or pass
        for score in _scores {
            finalScore = finalScore || score
        }
        return finalScore ? 1 : 0
    }
    
    func eventsToValidEvents(events: [Event]) throws -> [ValidEvent] {
        var _events = events
        var validEvents: [ValidEvent] = []
        for index in events.indices {
            do {
                if index == 0 {
                    // Always change the first conjunction since we have
                    // nothing to compare it against.
                    _events[index].setFirst()
                }
                try validEvents.append(
                    convertEventToValidEvent(event: _events[index])
                )
            } catch SimulationError.invalidEvent {
                throw SimulationError.invalidEvent(index)
            }
        }
        return validEvents
    }
    
    func simulateSingleBatch(
        events: [Event],
        eventSize: Int,
        diceType: DiceTypes?,
        lockSelection: [Int: Int],
        batch: [Int]
    ) throws -> Bool {
        let passedEvents = events
        // Parse events
        var validEvents: [ValidEvent] = []
        do {
            validEvents = try eventsToValidEvents(events: passedEvents)
        } catch SimulationError.invalidEvent(let index) {
            throw SimulationError.invalidEvent(index)
        }
        let scores = scoreEvents(batch: batch, events: validEvents)
        var score: Int
        do {
            // See if the conjunction of events is valid
            score = try scoreConjunctions(scores: scores, events: validEvents)
        } catch SimulationError.invalidEvents(let reason) {
            throw SimulationError.invalidEvents(reason)
        }
        if score == 1 {
            return true
        }
        return false
    }
    
    func simulate(
        events: [Event],
        eventSize: Int,
        diceType: DiceTypes?,
        lockSelection: [Int: Int],
        synchronousSimulation: Bool = true
    ) throws -> SimulationResults {
        // Simulate
        if synchronousSimulation {
            do {
                try batches = getSimulationBatches(
                    diceType: diceType,
                    eventSize: eventSize,
                    lockSelection: lockSelection
                )
            } catch SimulationError.nilDiceType {
                throw SimulationError.nilDiceType
            } catch SimulationError.nilDiceAmount {
                throw SimulationError.nilDiceAmount
            }
        }
        guard let batch = batches.first else {
            throw SimulationError.nilDiceAmount
        }
        if batch.isEmpty {
            throw SimulationError.nilDiceAmount
        }
        let passedEvents = events
        // Parse events
        var validEvents: [ValidEvent] = []
        do {
            validEvents = try eventsToValidEvents(events: passedEvents)
        } catch SimulationError.invalidEvent(let index) {
            throw SimulationError.invalidEvent(index)
        }
        // Analyze events & samples
        var numSuccess: Int = 0
        var totalSum: Int = 0
        var totalAverage: Double = 0.0
        for batch in batches {
            // Score each of the events
            let scores = scoreEvents(batch: batch, events: validEvents)
            do {
                // See if the conjunction of events is valid
                let score = try scoreConjunctions(scores: scores, events: validEvents)
                // Contribute towards E[sum(dice) | conjunctions = true]
                if score == 1 {
                    let sum = batch.reduce(0, +)
                    totalSum += sum
                    totalAverage += Double(sum / batch.count)
                }
                numSuccess += score
            } catch SimulationError.invalidEvents(let reason) {
                throw SimulationError.invalidEvents(reason)
            }
        }
        return SimulationResults(
            probability: Double(numSuccess) / Double(batches.count),
            sum: Double(totalSum) / Double(numSuccess),
            average: Double(totalAverage) / Double(numSuccess),
            status: .populated
        )
    }
    
    func simulate1D(
        events: [Event],
        eventSize: Int,
        diceType: DiceTypes?,
        lockSelection: [Int: Int],
        sheetVariable: SheetVariable
    ) throws -> Simulation1D {
        do {
            try batches = getSimulationBatches(
                diceType: diceType,
                eventSize: eventSize,
                lockSelection: lockSelection
            )
        } catch SimulationError.nilDiceType {
            throw SimulationError.nilDiceType
        } catch SimulationError.nilDiceAmount {
            throw SimulationError.nilDiceAmount
        }
        guard let batch = batches.first else {
            throw SimulationError.nilDiceAmount
        }
        if batch.isEmpty {
            throw SimulationError.nilDiceAmount
        }
        guard var passedEvent: Event = events.first else {
            return Simulation1D()
        }
        passedEvent.setFirst()
        var validEvents: [ValidEvent]
        // Parse events
        do {
            try validEvents = [
                convertEventToValidEvent(event: passedEvent)
            ]
        } catch SimulationError.invalidEvent {
            throw SimulationError.invalidEvent(0)
        }
        // Analyze events & samples
        guard let validEvent = validEvents.first else {
            return Simulation1D()
        }
        // Initialize variables
        var probData: [ChartData] = [ChartData]()
        var sumData: [ChartData] = [ChartData]()
        var avgData: [ChartData] = [ChartData]()
        var maxValueSum: Int = 1
        var maxValueAvg: Double = 1.0
        var startIter: Int = 0
        var maxIter: Int = 0
        switch sheetVariable {
        case .value, .value1, .value2:
            startIter = 1
            maxIter = validEvent.diceType.rawValue
        case .quantity:
            startIter = 0
            maxIter = batches.first?.count ?? eventSize
        case .grid, .standard:
            break
        }
        if validEvent.reduction == .sum {
            maxIter *= batches.first?.count ?? eventSize
        }
        for value in startIter...maxIter {
            var numSuccess: Int = 0
            var totalSum: Int = 0
            var totalAverage: Double = 0.0
            var validEventCopy = validEvent
            switch sheetVariable {
            case .value:
                validEventCopy.value = value
            case .value1:
                validEventCopy.values.lower = value
            case .value2:
                validEventCopy.values.upper = value
            case .quantity:
                validEventCopy.quantity = value
            case .grid, .standard:
                break
            }
            for batch in batches {
                let scores = scoreEvents(batch: batch, events: [validEventCopy])
                do {
                    let score = try scoreConjunctions(scores: scores, events: [validEventCopy])
                    if score == 1 {
                        let sum = batch.reduce(0, +)
                        totalSum += sum
                        totalAverage += Double(sum / batch.count)
                    }
                    numSuccess += score
                } catch SimulationError.invalidEvents(let reason) {
                    throw SimulationError.invalidEvents(reason)
                }
            }
            let probability = Double(numSuccess) / Double(batches.count)
            probData.append(
                ChartData(
                    label: String(value),
                    numericLabel: value,
                    normalizedValue: probability,
                    value: numSuccess,
                    percentage: probability
                )
            )
            let sumDataValue = numSuccess == 0 ? 0 : Int(Double(totalSum) / Double(numSuccess))
            maxValueSum = max(maxValueSum, sumDataValue)
            sumData.append(
                ChartData(
                    label: String(value),
                    numericLabel: value,
                    normalizedValue: 0,
                    value: sumDataValue,
                    percentage: 0
                )
            )
            let avgDataValue = numSuccess == 0 ? 0.0 : Double(totalAverage) / Double(numSuccess)
            maxValueAvg = max(maxValueAvg, avgDataValue)
            avgData.append(
                ChartData(
                    label: String(value),
                    numericLabel: value,
                    normalizedValue: 0,
                    value: Int(avgDataValue),
                    percentage: 0
                )
            )
        }
        // Normalize grid
        for value in sumData.indices {
            sumData[value].normalizedValue = Double(sumData[value].value) / Double(maxValueSum)
            avgData[value].normalizedValue = Double(avgData[value].value) / Double(maxValueAvg)
        }
        return Simulation1D(
            prob1D: probData,
            sum1D: sumData,
            avg1D: avgData,
            status: .populated
        )
    }
    
    func simulate2D(
        events: [Event],
        eventSize: Int,
        diceType: DiceTypes?,
        lockSelection: [Int: Int]
    ) throws -> Simulation2D {
        do {
            try batches = getSimulationBatches(
                diceType: diceType,
                eventSize: eventSize,
                lockSelection: lockSelection
            )
        } catch SimulationError.nilDiceType {
            throw SimulationError.nilDiceType
        } catch SimulationError.nilDiceAmount {
            throw SimulationError.nilDiceAmount
        }
        guard let batch = batches.first else {
            throw SimulationError.nilDiceAmount
        }
        if batch.isEmpty {
            throw SimulationError.nilDiceAmount
        }
        guard var passedEvent: Event = events.first else {
            return Simulation2D()
        }
        passedEvent.setFirst()
        var validEvents: [ValidEvent]
        // Parse events
        do {
            try validEvents = [
                convertEventToValidEvent(event: passedEvent)
            ]
        } catch SimulationError.invalidEvent {
            throw SimulationError.invalidEvent(0)
        }
        // Analyze events & samples
        guard let validEvent = validEvents.first else {
            return Simulation2D()
        }
        // Initialize variables
        var probData: [Int: [Int: ChartData]] = [Int: [Int: ChartData]]()
        var sumData: [Int: [Int: ChartData]] = [Int: [Int: ChartData]]()
        var avgData: [Int: [Int: ChartData]] = [Int: [Int: ChartData]]()
        for quantity in 0...(batches.first?.count ?? eventSize) {
            probData.updateValue([:], forKey: quantity)
            sumData.updateValue([:], forKey: quantity)
            avgData.updateValue([:], forKey: quantity)
        }
        var maxValueSum: Int = 1
        var maxValueAvg: Double = 1.0
        // 2D Grid
        for quantity in 0...(batches.first?.count ?? eventSize) {
            for value in 1...validEvent.diceType.rawValue {
                var numSuccess: Int = 0
                var totalSum: Int = 0
                var totalAverage: Double = 0.0
                var validEventCopy = validEvent
                validEventCopy.quantity = quantity
                validEventCopy.value = value
                for batch in batches {
                    let scores = scoreEvents(batch: batch, events: [validEventCopy])
                    do {
                        let score = try scoreConjunctions(scores: scores, events: [validEventCopy])
                        if score == 1 {
                            let sum = batch.reduce(0, +)
                            totalSum += sum
                            totalAverage += Double(sum / batch.count)
                        }
                        numSuccess += score
                    } catch SimulationError.invalidEvents(let reason) {
                        throw SimulationError.invalidEvents(reason)
                    }
                }
                let probability = Double(numSuccess) / Double(batches.count)
                probData[quantity]!.updateValue(
                    ChartData(
                        label: String(format: "%.1f", probability * 100) + "%",
                        numericLabel: 0,
                        normalizedValue: probability,
                        value: numSuccess,
                        percentage: probability
                    ),
                    forKey: value
                )
                let sumDataValue = numSuccess == 0 ? 0 : Int(Double(totalSum) / Double(numSuccess))
                maxValueSum = max(maxValueSum, sumDataValue)
                sumData[quantity]!.updateValue(
                    ChartData(
                        label: "\(sumDataValue)",
                        numericLabel: 0,
                        normalizedValue: 0,
                        value: sumDataValue,
                        percentage: 0
                    ),
                    forKey: value
                )
                let avgDataValue = numSuccess == 0 ? 0.0 : Double(totalAverage) / Double(numSuccess)
                maxValueAvg = max(maxValueAvg, avgDataValue)
                avgData[quantity]!.updateValue(
                    ChartData(
                        label: String(format: "%.1f", avgDataValue),
                        numericLabel: 0,
                        normalizedValue: 0,
                        value: Int(avgDataValue),
                        percentage: 0
                    ),
                    forKey: value
                )
            }
        }
        // Normalize grid
        for _quantity in 0...(batches.first?.count ?? eventSize) {
            for _value in 1...validEvent.diceType.rawValue {
                sumData[_quantity]![_value]!.normalizedValue = Double(sumData[_quantity]![_value]!.value) / Double(maxValueSum)
                avgData[_quantity]![_value]!.normalizedValue = Double(avgData[_quantity]![_value]!.value) / Double(maxValueAvg)
            }
        }
        return Simulation2D(
            probGrid: probData,
            sumGrid: sumData,
            avgGrid: avgData,
            status: .populated
        )
    }
    
    func computeSimulationDataHelper(pmfData: inout [ChartData], cdfData: inout [ChartData], k: Int, probability: Double, cumulativeProbability: Double) {
        pmfData.append(
            ChartData(
                label: "\(k)",
                numericLabel: k,
                normalizedValue: probability,
                value: Int(probability * 100),
                percentage: probability
            )
        )
        cdfData.append(
            ChartData(
                label: "\(k)",
                numericLabel: k,
                normalizedValue: cumulativeProbability,
                value: Int(cumulativeProbability * 100),
                percentage: cumulativeProbability
            )
        )
    }
    
    func computeSimulationData(p: Double) -> GeometricPlotData {
        /// Args p = probability, k = trials. Returns data from Geometric Distribution
        var pmfData: [ChartData] = []
        var cdfData: [ChartData] = []
        var cumulativeProbability: Double = 0.0
        for k in 1...PlotKSizes.extraLarge.rawValue {
            let probability: Double = pow((1.0 - p), (Double(k) - 1.0)) * p
            cumulativeProbability += probability
            computeSimulationDataHelper(pmfData: &pmfData, cdfData: &cdfData, k: k, probability: probability, cumulativeProbability: cumulativeProbability)
        }
        return GeometricPlotData(pmfData: pmfData, cdfData: cdfData, status: .populated)
    }
}

enum Game: String, CaseIterable {
    case example = "Examples"
    case yahtzee = "Yahtzee"
    case backgammon = "Backgammon"
    case farkle = "Farkle"
    case monopoly = "Monopoly"
    
    var description: String {
        switch self {
        case .example:
            return "Basic examples to get you started"
        case .yahtzee:
            return "Try to see if you can roll a Yahtzee"
        case .backgammon:
            return "Sixes or Doubles to move pips"
        case .farkle:
            return "Get as many points without rolling a Farkle"
        case .monopoly:
            return "Double or Sum of Two Dice to get Boardwalk"
        }
    }
}

struct SimulationPresets {
    static let presets: [Game: [EventManager]] = [
        .example: [
            EventManager(
                name: "Exactly Two, Ones",
                events: [
                    Event(bound: .exactly, quantity: 2, dice: nil, conjunction: .first, reduction: .each, comparison: .equals, value: 1)
                ]
            ),
            EventManager(
                name: "Avg Between 3 & 5",
                events: [
                    Event(bound: .exactly, quantity: 1, dice: nil, conjunction: .first, reduction: .average, comparison: .between, values: Between(lower: 3, upper: 5))
                ]
            ),
            EventManager(
                name: "Snake Eyes",
                events: [
                    Event(bound: .geq, quantity: 2, dice: nil, conjunction: .first, reduction: .consecutive, comparison: .equals, value: 1)
                ]
            )
        ],
        .monopoly: [
            EventManager(
                name: "Doubles",
                events: (1...6).map({Event(bound: .exactly, quantity: 2, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
            ),
            EventManager(
                name: "Sum of 2 Dice",
                events: [Event(bound: .exactly, quantity: 2, dice: nil, conjunction: .first, reduction: .sum, comparison: .equals, value: 15)]
            ),
        ],
        .yahtzee: [
            EventManager(
                name: "Two of a Kind",
                events: (1...6).map({Event(bound: .geq, quantity: 2, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
            ),
            EventManager(
                name: "Three of a Kind",
                events: (1...6).map({Event(bound: .geq, quantity: 3, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
            ),
            EventManager(
                name: "Four of a Kind",
                events: (1...6).map({Event(bound: .geq, quantity: 4, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
            ),
            EventManager(
                name: "Full House",
                events: Array((1...6)).permutations(ofCount: 2).map({[
                    Event(bound: .exactly, quantity: 3, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0.first!),
                    Event(bound: .exactly, quantity: 2, dice: nil, conjunction: .and, reduction: .each, comparison: .equals, value: $0.last!)
                ]}).reduce([], +)
            ),
            EventManager(
                name: "Small Straight",
                events: Array((1...4)).map({Event(bound: .geq, quantity: 1, dice: nil, conjunction: .and, reduction: .each, comparison: .equals, value: $0)}) +
                [Event(bound: .geq, quantity: 1, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: 2)] +
                Array((3...5)).map({Event(bound: .geq, quantity: 1, dice: nil, conjunction: .and, reduction: .each, comparison: .equals, value: $0)}) +
                [Event(bound: .geq, quantity: 1, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: 3)] +
                Array((4...6)).map({Event(bound: .geq, quantity: 1, dice: nil, conjunction: .and, reduction: .each, comparison: .equals, value: $0)})
            ),
            EventManager(
                name: "Large Straight",
                events: Array((1...5)).map({Event(bound: .geq, quantity: 1, dice: nil, conjunction: .and, reduction: .each, comparison: .equals, value: $0)}) +
                [Event(bound: .geq, quantity: 1, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: 2)] +
                Array((3...6)).map({Event(bound: .geq, quantity: 1, dice: nil, conjunction: .and, reduction: .each, comparison: .equals, value: $0)})
            ),
            EventManager(
                name: "Yahtzee",
                events: (1...6).map({ Event(bound: .exactly, quantity: 5, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
            ),
            EventManager(
                name: "Chance",
                events: [
                    Event(bound: .exactly, quantity: 5, dice: nil, conjunction: .first, reduction: .sum, comparison: .equals, value: 15)
                ]
            )
        ],
        .backgammon: [
            EventManager(
                name: "Double Sixes",
                events: [
                    Event(bound: .exactly, quantity: 2, dice: nil, conjunction: .first, reduction: .each, comparison: .equals, value: 6)
                ]
            ),
            EventManager(
                name: "Any Double",
                events: (1...6).map({Event(bound: .exactly, quantity: 2, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
            )
        ],
        .farkle: [
            EventManager(
                name: "At Least One, 1",
                events: [
                    Event(bound: .geq, quantity: 1, dice: nil, conjunction: .first, reduction: .each, comparison: .equals, value: 1)
                ]
            ),
            EventManager(
                name: "At Least One, 5",
                events: [
                    Event(bound: .geq, quantity: 1, dice: nil, conjunction: .first, reduction: .each, comparison: .equals, value: 5)
                ]
            ),
            EventManager(
                name: "At Least One, 1 or 5",
                events: [
                    Event(bound: .geq, quantity: 1, dice: nil, conjunction: .first, reduction: .each, comparison: .equals, value: 1),
                    Event(bound: .geq, quantity: 1, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: 5),
                ]
            ),
            EventManager(
                name: "Any Three of a Kind",
                events: (1...6).map({Event(bound: .geq, quantity: 3, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
            ),
            EventManager(
                name: "Any Four of a Kind",
                events: (1...6).map({Event(bound: .geq, quantity: 4, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
            ),
            EventManager(
                name: "Any Five of a Kind",
                events: (1...6).map({Event(bound: .geq, quantity: 5, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
            ),
            EventManager(
                name: "Any Six of a Kind",
                events: (1...6).map({Event(bound: .geq, quantity: 6, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0)})
            ),
            EventManager(
                name: "1-6 Straight",
                events: Array((1...6)).map({Event(bound: .geq, quantity: 1, dice: nil, conjunction: .and, reduction: .each, comparison: .equals, value: $0)})
            ),
            EventManager(
                name: "Three Pairs",
                events: Array((1...6)).combinations(ofCount: 3).map({[
                    Event(bound: .exactly, quantity: 2, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0[0]),
                    Event(bound: .exactly, quantity: 2, dice: nil, conjunction: .and, reduction: .each, comparison: .equals, value: $0[1]),
                    Event(bound: .exactly, quantity: 2, dice: nil, conjunction: .and, reduction: .each, comparison: .equals, value: $0[2])
                ]}).reduce([], +)
            ),
            EventManager(
                name: "Four of Any Number w/ a Pair",
                events: Array((1...6)).permutations(ofCount: 2).map({[
                    Event(bound: .exactly, quantity: 4, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0.first!),
                    Event(bound: .exactly, quantity: 2, dice: nil, conjunction: .and, reduction: .each, comparison: .equals, value: $0.last!)
                ]}).reduce([], +)
            ),
            EventManager(
                name: "Two Triplets",
                events: Array((1...6)).combinations(ofCount: 2).map({[
                    Event(bound: .exactly, quantity: 3, dice: nil, conjunction: .or, reduction: .each, comparison: .equals, value: $0.first!),
                    Event(bound: .exactly, quantity: 3, dice: nil, conjunction: .and, reduction: .each, comparison: .equals, value: $0.last!)
                ]}).reduce([], +)
            )
        ]
    ]
}
