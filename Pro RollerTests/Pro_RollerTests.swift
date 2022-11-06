//
//  Pro_RollerTests.swift
//  Pro RollerTests
//
//  Created by Jake Taylor on 7/29/22.
//

import XCTest
@testable import Pro_Roller

class Pro_RollerTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testScoreEachEvent() throws {
        let event = ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .and, diceType: .D6)
        let batch1 = [4, 4, 6, 1, 3, 4, 2]
        let batch2 = [6, 1, 3, 3, 5, 2]
        let batch3 = [4, 2, 4, 1, 4, 1]
        let simulator = SimulationManager()
        let result1 = simulator.scoreEachEvent(batch: batch1, event: event)
        let result2 = simulator.scoreEachEvent(batch: batch2, event: event)
        let result3 = simulator.scoreEachEvent(batch: batch3, event: event)
        XCTAssertEqual(result1, true)
        XCTAssertEqual(result2, false)
        XCTAssertEqual(result3, true)
    }
    
    func testScoreConsecutiveEvent() throws {
        let event1 = ValidEvent(bound: .exactly, quantity: 3, reduction: .consecutive, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .first, diceType: .D6)
        let event2 = ValidEvent(bound: .exactly, quantity: 3, reduction: .consecutive, comparison: .leq, value: 3, values: Between(lower: 1, upper: 1), conjunction: .first, diceType: .D6)
        let event3 = ValidEvent(bound: .exactly, quantity: 3, reduction: .consecutive, comparison: .geq, value: 3, values: Between(lower: 1, upper: 1), conjunction: .first, diceType: .D6)
        let event4 = ValidEvent(bound: .geq, quantity: 3, reduction: .consecutive, comparison: .geq, value: 3, values: Between(lower: 1, upper: 1), conjunction: .first, diceType: .D6)
        let batch1 = [4, 2, 4, 4, 4, 1, 2]
        let batch2 = [6, 1, 4, 4, 5, 2]
        let batch3 = [4, 2, 4, 1, 4, 1]
        let batch4 = [1, 2, 3, 4, 5, 6]
        let batch5 = [1, 1, 1, 1, 1, 1, 6, 5, 6, 5, 6, 5, 6, 5]
        let simulator = SimulationManager()
        let result1 = simulator.scoreConsecutiveEvent(batch: batch1, event: event1)
        let result2 = simulator.scoreConsecutiveEvent(batch: batch2, event: event1)
        let result3 = simulator.scoreConsecutiveEvent(batch: batch3, event: event1)
        let result4 = simulator.scoreConsecutiveEvent(batch: batch4, event: event2)
        let result5 = simulator.scoreConsecutiveEvent(batch: batch4, event: event3)
        let result6 = simulator.scoreConsecutiveEvent(batch: batch5, event: event4)
        XCTAssertEqual(result1, true)
        XCTAssertEqual(result2, false)
        XCTAssertEqual(result3, false)
        XCTAssertEqual(result4, true)
        XCTAssertEqual(result5, false)
        XCTAssertEqual(result6, true)
    }
    
    func testScoreEvents1() throws {
        // https://www.quora.com/If-you-roll-a-die-10-times-what-is-the-probability-of-rolling-a-1-at-least-once
        let simulator = SimulationManager()
        let event = ValidEvent(bound: .geq, quantity: 1, reduction: .each, comparison: .equals, value: 1, values: Between(lower: 1, upper: 1), conjunction: .first, diceType: .D6)
        let batches = try? simulator.getSimulationBatches(diceType: .D6, eventSize: 10, lockSelection: [:])
        var results: Int = 0
        for batch in batches! {
            let result = simulator.scoreEvents(batch: batch, events: [event])
            results += result.first! ? 1 : 0
        }
        XCTAssertEqual(Double(results) / Double(simulator.batchSize), 0.838, accuracy: 0.02)
    }
    
    func testScoreEvents2() throws {
        let simulator = SimulationManager()
        let event = ValidEvent(bound: .exactly, quantity: 1, reduction: .each, comparison: .equals, value: 1, values: Between(lower: 1, upper: 1), conjunction: .first, diceType: .D6)
        let batches = try? simulator.getSimulationBatches(diceType: .D2, eventSize: 1, lockSelection: [:])
        var results: Int = 0
        for batch in batches! {
            let result = simulator.scoreEvents(batch: batch, events: [event])
            results += result.first! ? 1 : 0
        }
        XCTAssertEqual(Double(results) / Double(simulator.batchSize), 0.5, accuracy: 0.02)
    }
    
    func testScoreConjunctions1() throws {
        // [&& true && false && true || true && true || false && true]
        let events1: [ValidEvent] = [
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .first, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .and, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .and, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .or, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .and, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .or, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .and, diceType: .D6)
        ]
        let scores1 = [true, false, true, true, true, false, true]
        let simulator = SimulationManager()
        let result1 = try! simulator.scoreConjunctions(scores: scores1, events: events1)
        let result2 = simulator.numberOrConjunctions(events: events1)
        XCTAssertEqual(result1, 1)
        XCTAssertEqual(result2, 2)
    }
    
    func testScoreConjunctions2() throws {
        let simulator = SimulationManager()
        // [|| true && false || false || false || true && true && false || true]
        let events2: [ValidEvent] = [
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .first, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .and, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .or, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .or, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .or, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .and, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .and, diceType: .D6),
            ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .or, diceType: .D6)
        ]
        let scores2 = [true, false, false, false, true, true, false, true]
        let result3 = try! simulator.scoreConjunctions(scores: scores2, events: events2)
        let result4 = simulator.numberOrConjunctions(events: events2)
        XCTAssertEqual(result3, 1)
        XCTAssertEqual(result4, 4)
    }
    
    func testScoreConjunctions3() throws {
        let simulator = SimulationManager()
        // [true]
        let events3: [ValidEvent] = [ValidEvent(bound: .exactly, quantity: 3, reduction: .each,  comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .or, diceType: .D6)]
        let scores3: [Bool] = [true]
        let result5 = try! simulator.scoreConjunctions(scores: scores3, events: events3)
        let result6 = simulator.numberOrConjunctions(events: events3)
        XCTAssertEqual(result5, 1)
        XCTAssertEqual(result6, 0)
    }
    
    func testScoreConjunctions4() throws {
        let simulator = SimulationManager()
        // [false]
        let events4: [ValidEvent] = [ValidEvent(bound: .exactly, quantity: 3, reduction: .each, comparison: .equals, value: 4, values: Between(lower: 1, upper: 1), conjunction: .or, diceType: .D6)]
        let scores4: [Bool] = [false]
        let result7 = try! simulator.scoreConjunctions(scores: scores4, events: events4)
        let result8 = simulator.numberOrConjunctions(events: events4)
        XCTAssertEqual(result7, 0)
        XCTAssertEqual(result8, 0)
    }
    
    // https://www.yahtzeemanifesto.com/yahtzee-odds.php
    func testThreeOfAKind() throws {
        let simulator = SimulationManager()
        var result = SimulationResults()
        do {
            result = try simulator.simulate(
                events: (1...6).map({Event(bound: .geq, quantity: 3, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: $0)}),
                eventSize: 5,
                diceType: .D6,
                lockSelection: [:]
            )
        } catch {
            XCTAssert(false)
        }
        XCTAssertEqual(result.probability, 0.1929, accuracy: 0.05)
    }
    
    func testFourOfAKind() throws {
        let simulator = SimulationManager()
        var result = SimulationResults()
        do {
            result = try simulator.simulate(
                events: (1...6).map({Event(bound: .geq, quantity: 4, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: $0)}),
                eventSize: 5,
                diceType: .D6,
                lockSelection: [:]
            )
        } catch {
            XCTAssert(false)
        }
        XCTAssertEqual(result.probability, 0.0193, accuracy: 0.02)
    }
    
    func testFullHouse() throws {
        let simulator = SimulationManager()
        var result = SimulationResults()
        do {
            result = try simulator.simulate(
                events: Array((1...6)).permutations(ofCount: 2).map({[
                    Event(bound: .exactly, quantity: 3, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: $0.first!),
                    Event(bound: .exactly, quantity: 2, dice: .D6, conjunction: .and, reduction: .each, comparison: .equals, value: $0.last!)
                ]}).reduce([], +),
                eventSize: 5,
                diceType: .D6,
                lockSelection: [:]
            )
        } catch {
            XCTAssert(false)
        }
        XCTAssertEqual(result.probability, 0.0386, accuracy: 0.02)
    }
    
    func testSmallStraight() throws {
        let simulator = SimulationManager()
        var result = SimulationResults()
        do {
            result = try simulator.simulate(
                events: Array((1...4)).map({Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .and, reduction: .each, comparison: .equals, value: $0)}) +
                [Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: 2)] +
                Array((3...5)).map({Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .and, reduction: .each, comparison: .equals, value: $0)}) +
                [Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: 3)] +
                Array((4...6)).map({Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .and, reduction: .each, comparison: .equals, value: $0)}),
                eventSize: 5,
                diceType: .D6,
                lockSelection: [:]
            )
        } catch {
            XCTAssert(false)
        }
        XCTAssertEqual(result.probability, 0.1235, accuracy: 0.05)
    }
    
    func testLargeStraight() throws {
        let simulator = SimulationManager()
        var result = SimulationResults()
        do {
            result = try simulator.simulate(
                events: Array((1...5)).map({Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .and, reduction: .each, comparison: .equals, value: $0)}) +
                [Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .or, reduction: .each, comparison: .equals, value: 2)] +
                Array((3...6)).map({Event(bound: .geq, quantity: 1, dice: .D6, conjunction: .and, reduction: .each, comparison: .equals, value: $0)}),
                eventSize: 5,
                diceType: .D6,
                lockSelection: [:]
            )
        } catch {
            XCTAssert(false)
        }
        XCTAssertEqual(result.probability, 0.0309, accuracy: 0.05)
    }
    
    func testRankings() throws {
        let yahtzeeRankings = YahtzeeGameRankings(
            sortedPlayers: [],
            sortedScores: [5, 5, 4, 3, 3, 2, 1]
        )
        XCTAssertEqual(yahtzeeRankings.rankings, [1, 1, 2, 3, 3, 4, 5])
    }
}
