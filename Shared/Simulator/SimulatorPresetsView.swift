//
//  SimulatorPresetsView.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 3/5/23.
//

import SwiftUI

struct SimulatorPresetsView: View {
    @StateObject var eventManagers: EventManagers
    @StateObject var simManager: SimulationManager
    @Binding var selectedDice: DiceTypes?
    
    var body: some View {
        List {
            ForEach(Game.allCases, id: \.self) { game in
                PresetView(eventManagers: eventManagers, simManager: simManager, selectedDice: $selectedDice, game: game)
                    .padding(.vertical, 10)
            }
        }
        .navigationTitle("Recommended")
        .listStyle(.plain)
    }
}

struct PresetView: View {
    @StateObject var eventManagers: EventManagers
    @StateObject var simManager: SimulationManager
    @Binding var selectedDice: DiceTypes?
    @State var game: Game
    
    @State var selectedEventManager: EventManager? = nil
    @State var addAll: Bool = false
    @State var showPresets: [EventManager] = SimulationPresets.presets[.example]!
    @State var showRecommendations = true
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button {
                    withAnimation(.spring()) {
                        showRecommendations.toggle()
                    }
                } label: {
                    Label(game.rawValue, systemImage: "chevron.right.circle.fill")
                        .labelStyle(.iconOnly)
                        .imageScale(.large)
                        .rotationEffect(.degrees(showRecommendations ? 90 : 0))
                        .scaleEffect(showRecommendations ? 1.1 : 1)
                    Text(game.rawValue)
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
            HStack{
                Text(game.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
            if showRecommendations {
                scrollWheel
            }
        }
    }
    
    func add(newManager: EventManager) {
        newManager.updateSelectedDiceType(newDiceType: selectedDice)
        let newManagerCopy: EventManager = newManager.copy() as! EventManager
        eventManagers.managers.append(newManagerCopy)
    }
}

private extension PresetView {
    private func computeAngle(_ minX: CGFloat) -> Double {
        return (Double(minX) - UIScreen.main.bounds.width / 2.0 + 100.0) / -UIScreen.main.bounds.width
    }
    
    var scrollWheel: some View {
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
        .frame(width: UIScreen.main.bounds.width * 0.95, height: 90)
        .onAppear {
            if let presets = SimulationPresets.presets[game] {
                showPresets = presets
            }
        }
    }
}
//
//struct PresetsView: View {
//    @StateObject var eventManagers: EventManagers
//    @StateObject var simManager: SimulationManager
//    @Binding var selectedDice: DiceTypes?
//    @State var selectedEventManager: EventManager? = nil
//    @State var addAll: Bool = false
//    @State var game: Game = .example
//    @State var showPresets: [EventManager] = SimulationPresets.presets[.example]!
//    @State var showRecommendations = true
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 2) {
//            HStack {
//                Button {
//                    withAnimation(.spring()) {
//                        showRecommendations.toggle()
//                    }
//                } label: {
//                    Label("Events", systemImage: "chevron.right.circle.fill")
//                        .labelStyle(.iconOnly)
//                        .imageScale(.large)
//                        .rotationEffect(.degrees(showRecommendations ? 90 : 0))
//                        .scaleEffect(showRecommendations ? 1.1 : 1)
//                    Text("Presets")
//                        .font(.title.bold())
//                        .foregroundColor(.primary)
//                }
//                .buttonStyle(.borderless)
//                Spacer()
//                if showRecommendations {
//                    Button {
//                        addAll.toggle()
//                    } label: {
//                        Text("Add All")
//                    }
//                    .buttonStyle(.borderless)
//                    .transition(.opacity)
//                    .confirmationDialog("", isPresented: $addAll) {
//                        Button("Add \((SimulationPresets.presets[game] ?? []).count) Events") {
//                            withAnimation {
//                                for preset in SimulationPresets.presets[game] ?? [] {
//                                    preset.updateSelectedDiceType(newDiceType: selectedDice)
//                                    let presetCopy: EventManager = preset.copy() as! EventManager
//                                    eventManagers.managers.append(presetCopy)
//                                }
//                            }
//                        }
//                        Button("Cancel", role: .cancel) { }
//                    } message: {
//                        Text("Add All Events?")
//                    }
//                }
//            }
//            HStack {
//                Text("Preset Events for")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                Menu {
//                    Picker("Game", selection: $game) {
//                        ForEach(Game.allCases, id: \.self) {
//                            Text("\($0.rawValue)")
//                        }
//                    }
//                    .onChange(of: game) { tag in
//                        showPresets = SimulationPresets.presets[tag] ?? []
//                    }
//                } label: {
//                    Text("\(game.rawValue)")
//                        .modifier(ButtonInset(opacity: false, color: showRecommendations ? .accentColor : .gray))
//                }
//                .disabled(!showRecommendations)
//                Spacer()
//            }
//            .padding(.top, 5)
//        }
//        if showRecommendations {
//            ScrollView(.horizontal, showsIndicators: false) {
//                LazyHStack(alignment: .center, spacing: 30) {
//                    ForEach($showPresets) { $preset in
//                        GeometryReader { geometry in
//                            PresetCard(
//                                preset: $preset,
//                                selectedDice: $selectedDice,
//                                simManager: simManager,
//                                add: add
//                            )
//                            .rotation3DEffect(
//                                Angle(
//                                    degrees: computeAngle(geometry.frame(in: .global).minX)
//                                ),
//                                axis: (x: 0, y: 1.0, z: 0)
//                            )
//                            .scaleEffect(1.1 * cos(computeAngle(geometry.frame(in: .global).minX)))
//                        }
//                        .frame(width: 200, height: 80)
//                    }
//                }
//                .padding(.all, 10)
//            }
//            .frame(width: UIScreen.main.bounds.width * 0.95, height: 120)
//        }
//    }
//
//    func computeAngle(_ minX: CGFloat) -> Double {
//        return (Double(minX) - UIScreen.main.bounds.width / 2.0 + 100.0) / -UIScreen.main.bounds.width
//    }
//
//    func add(newManager: EventManager) {
//        newManager.updateSelectedDiceType(newDiceType: selectedDice)
//        let newManagerCopy: EventManager = newManager.copy() as! EventManager
//        eventManagers.managers.append(newManagerCopy)
//    }
//}


struct PresetCard: View {
    @Binding var preset: EventManager
    @Binding var selectedDice: DiceTypes?
    @StateObject var simManager: SimulationManager
    
    @State var showPreview = false
    @State var previewEventManager: EventManager = EventManager(name: "")
    @State var dummyTotalDice = 6
    @State var dummyLockSelectionDice: [Int: Int] = [:]
    @State var buttonClicked = false
    
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
                        buttonClicked = true
                        add(preset)
                        withAnimation(.easeIn(duration: 1.0)) {
                            buttonClicked = false
                        }
                    } label: {
                        if buttonClicked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .imageScale(.large)
                        } else {
                            Image(systemName: "plus.circle.fill")
                                .symbolRenderingMode(.multicolor)
                                .imageScale(.large)
                        }
                    }
                    .buttonStyle(.borderless)
                    .padding(.trailing, 10)
                }
            }
        }
    }
}

struct SimulatorPresetsViewPreview: View {
    @State var selectedDice: DiceTypes? = .D6
    
    var body: some View {
        SimulatorPresetsView(eventManagers: EventManagers(url: .events), simManager: SimulationManager(), selectedDice: $selectedDice)
    }
}

struct SimulatorPresetsView_Previews: PreviewProvider {
    static var previews: some View {
        SimulatorPresetsViewPreview()
    }
}
