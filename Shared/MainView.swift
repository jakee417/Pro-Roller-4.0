import SwiftUI
import GameKitUI
import GameKit

enum importError: Error {
    case invalidFile
    case invalidEvent
}

enum ImportError: Error {
    case invalidEvent(_ index: Int)
    case invalidEvents(_ reason: String)
    case nilDiceType
    case nilDiceAmount
}

struct MainView: View {
    @EnvironmentObject var gkManager: GKManager
    @StateObject var simManager: SimulationManager = SimulationManager()
    @StateObject var container: EventManagersContainer = EventManagersContainer()
    @StateObject var diceManagers: DiceManagers = DiceManagers()
    @State var showImport: Bool = false
    @State var importAlert: String = ""
    @State var showImportAlert: Bool = false
    @State var importedEventManager: EventManager = EventManager(
        name: "Imported", pin: false
    )
    
    var window: UIWindow? {
        guard let scene = UIApplication.shared.connectedScenes.first,
              let windowSceneDelegate = scene.delegate as? UIWindowSceneDelegate,
              let window = windowSceneDelegate.window else {
            return nil
        }
        return window
    }
    
    var body: some View {
        ZStack {
            BoardsView(
                diceManagers: diceManagers,
                saveSettings: saveDiceManagerSettings
            )
            .environmentObject(container)
            .environmentObject(simManager)
            .sheet(isPresented: $showImport) {
                ImportedWhereView(
                    importedEventManager: $importedEventManager,
                    simManager: simManager,
                    addFunc: addFunc
                )
            }
            .alert(importAlert, isPresented: $showImportAlert) {
                Button("OK", role: .cancel) { }
            }
            .onOpenURL { url in
                showImport = false
                guard url.pathExtension == "events" else {
                    return
                }
                Task {
                    try await importData(from: url)
                }
            }
            if self.gkManager.showInvite {
                GKInviteView(
                    invite: self.gkManager.invite.gkInvite!
                ) {
                } failed: { error in
                    GKNotificationBanner.show(
                        withTitle: "Cannot Accept Invite",
                        message: nil,
                        duration: TimeInterval(2.0)
                    )
                } started: { match in
                    
                    self.gkManager.showInvite = false
                    self.gkManager.gkMatch = match
                    saveDiceManagerSettings()
                }
                .ignoresSafeArea()
            }
        }
        .onChange(of: self.gkManager.showInvite) { value in
            if value {
                DispatchQueue.main.async {
                    window?.rootViewController?.dismiss(animated: true, completion: nil)
                }
            }
        }
    }
    
    public func diceManagerSettings() -> [DiceManagerSettings] {
        var settings: [DiceManagerSettings] = []
        for manager in diceManagers.managers {
            settings.append(manager.settings)
        }
        return settings
    }
    
    func saveDiceManagerSettings() {
        let settings = diceManagerSettings()
        self.gkManager.sendDiceManagerSettings(settings: settings)
        DiceManagers.save(settings: settings) { result in
            if case .failure(let error) = result {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func saveEventMangagerSettings(eventManagers: EventManagers) {
        var settings: [EventManagerSettings] = []
        for manager in eventManagers.managers {
            settings.append(manager.settings)
        }
        EventManagers.save(url: eventManagers.url, settings: settings) { result in
            if case .failure(let error) = result {
                fatalError(error.localizedDescription)
            }
        }
    }
    
    func addFunc(eventManager: EventManager) -> Void {
        container.eventManagers.managers.append(eventManager)
        saveEventMangagerSettings(eventManagers: container.eventManagers)
    }
    
    func _importData(url: URL) throws {
        guard let data = try? Data(contentsOf: url) else {
            importAlert = "Error While Reading File"
            showImportAlert = true
            throw importError.invalidEvent
          }
        guard let exportedSettings = try? JSONDecoder().decode(
            ExportedEventManagerSettings.self, from: data) else {
            importAlert = "Imported Event Was Invalid"
            showImportAlert = true
            throw importError.invalidEvent
        }
        var _events: [EventSettings] = []
        for event in exportedSettings.events {
            _events.append(EventSettings(from: event))
        }
        let settings = EventManagerSettings(
            name: exportedSettings.name,
            pin: false,
            events: _events
        )
        self.importedEventManager.settings = settings
        DispatchQueue.main.async {
            window?.rootViewController?.dismiss(animated: true, completion: nil)
            showImport = true
        }
    }
    
    func importData(from url: URL) async throws {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                try _importData(url: url)
                return
            }
            try _importData(url: url)
            url.stopAccessingSecurityScopedResource()
        } catch {
            window?.rootViewController?.dismiss(animated: true, completion: nil)
            importAlert = error.localizedDescription
            showImportAlert = true
        }
        
    }
}

struct ImportedWhereView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var importedEventManager: EventManager
    @ObservedObject var simManager: SimulationManager
    
    @State var dummyTotalDice = 6
    @State var dummySelectionDice: DiceTypes? = nil
    @State var dummyLockSelectionDice: [Int: Int] = [:]
    
    let addFunc: (EventManager) -> Void

    var body: some View {
        NavigationView {
            List {
                VStack {
                    HStack {
                        Text(importedEventManager.name)
                            .font(.title3.bold())
                        Spacer()
                    }
                    HStack {
                        Text("View & Import an Event")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                SimulatorViewEvents(
                    events: $importedEventManager.events,
                    totalDice: $dummyTotalDice,
                    selectedDice: $dummySelectionDice,
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
                        addFunc(importedEventManager.copy() as! EventManager)
                        dismiss()
                    } label: {
                        Text("Import")
                        Label("Import", systemImage: "flowchart")
                    }
                    .buttonStyle(.borderless)
                }
            }
            .navigationTitle("Event Import")
            .navigationBarTitleDisplayMode(.inline)
            .listStyle(.plain)
        }
        .navigationViewStyle(.stack)
    }
}

struct Previews_MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
