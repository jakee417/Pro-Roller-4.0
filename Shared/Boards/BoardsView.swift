import SwiftUI
import GameKit
import GameKitUI

struct BoardsView_Previews: PreviewProvider {
    static var previews: some View {
        BoardsView(diceManagers: DiceManagers(), saveSettings: {})
            .environmentObject(GKManager())
    }
}

struct BoardsView: View {
    @Environment(\.editMode) private var editMode
    @EnvironmentObject var gkManager: GKManager
    @ObservedObject var diceManagers: DiceManagers
    
    @State var showLocalBoards: Bool = true
    @State var showBottomOptions: Bool = true
    
    let saveSettings: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                LazyVStack(spacing: 3) {
                    HStack {
                        Button {
                            withAnimation(.spring()) {
                                showLocalBoards.toggle()
                            }
                        } label: {
                            Label("Boards", systemImage: "chevron.right.circle.fill")
                                .labelStyle(.iconOnly)
                                .imageScale(.large)
                                .rotationEffect(.degrees(showLocalBoards ? 90 : 0))
                                .scaleEffect(showLocalBoards ? 1.1 : 1)
                            Text("My Boards")
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.borderless)
                        Spacer()
                        if !showLocalBoards {
                            Image(systemName: "\(diceManagers.managers.count).circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Text("View and Roll Your Dice")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .listRowSeparator(.hidden)
                if showLocalBoards {
                    ForEach($diceManagers.managers) { $diceManager in
                        BoardDiceView(
                            diceManager: diceManager,
                            closedSave: saveSettings,
                            roll: roll
                        )
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteDiceManager(diceManager)
                                saveSettings()
                            } label: {
                                Label("Delete", systemImage: "trash.fill")
                            }
                            Button(role: .cancel) {
                                reset(diceManager)
                                saveSettings()
                            } label: {
                                Label("Reset", systemImage: "arrow.counterclockwise.circle.fill")
                            }
                            .tint(.indigo)
                            Button {
                                duplicate(diceManager)
                                saveSettings()
                            } label: {
                                Label("Duplicate", systemImage: "plus.rectangle.on.rectangle")
                            }
                            .tint(.green)
                        }
                    }
                    .onDelete(perform: delete)
                    .onMove(perform: move)
                    .listRowSeparator(.hidden)
                    NewDiceBoardView(diceManagers: diceManagers)
                        .listRowSeparator(.hidden)
                }
                if self.gkManager.showMatch,
                   let match = self.gkManager.gkMatch {
                    ForEach(match.players, id: \.self) { player in
                        if let diceManagers = self.gkManager.playerDiceManagers[player.gamePlayerID] {
                            SharedBoardView(
                                diceManagers: diceManagers,
                                player: player
                            )
                        }
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle(Constants.title)
            .listStyle(.plain)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if #unavailable(iOS 16.0) {
                        EditButton()
                    }
                    
                    GameCenterButton(closedSave: saveSettings)
                }
                ToolbarItemGroup(placement: .bottomBar) {
                    BoardToolbarView(
                        diceManagers: diceManagers,
                        closedSave: saveSettings,
                        roll: roll,
                        reset: reset
                    )
                }
            }
        }
        .onAppear {
            loadSettings()
        }
        .onChange(of: diceManagers.managers) { _ in
            saveSettings()
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationViewStyle(.stack)
    }
    
    func loadSettings() {
        DiceManagers.load() { result in
            switch result {
            case .failure(_):
                saveSettings()
            case .success(let settings):
                diceManagers.managers = []
                for setting in settings {
                    let newDiceManager = DiceManager()
                    newDiceManager.settings = setting
                    diceManagers.managers.append(newDiceManager)
                }
            }
        }
    }
    
    public func roll(_ diceManager: DiceManager) {
        switch diceManager.selectionMode {
        case .single, .shuffle, .sort, .freezable, .edit:
            diceManager.pushForwardHistory(diceManager.settings)
            diceManager.count += 1
            diceManager.selectionModeRoll()
        }
    }
    
    private func reset(_ diceManager: DiceManager) {
        withAnimation {
            diceManager.count = 0
            diceManager.lockSelection = [:]
            diceManager.editSelection = []
        }
    }
    
    private func duplicate(_ diceManager: DiceManager) {
        guard let index = diceManagers.managers.firstIndex(where: {$0.id == diceManager.id}) else {
            return
        }
        let newDiceManager = DiceManager()
        newDiceManager.settings = diceManager.settings
        withAnimation {
            diceManagers.managers.insert(newDiceManager, at: index + 1)
        }
    }
    
    private func deleteDiceManager(_ diceManager: DiceManager) {
        guard let index = diceManagers.managers.firstIndex(where: {$0.id == diceManager.id}) else {
            return
        }
        diceManagers.managers.remove(at: index)
    }
    
    func delete(at offsets: IndexSet) {
        for offset in offsets.reversed() {
            diceManagers.managers.remove(at: offset)
        }
    }
    
    func move(from source: IndexSet, to destination: Int) {
        diceManagers.managers.move(fromOffsets: source, toOffset: destination)
    }
}

struct NewDiceBoardView: View {
    @StateObject var diceManagers: DiceManagers
    @State var diceManager: DiceManager = DiceManager()
    
    var body: some View {
        ZStack {
            SimulatorCard(minHeight: 40)
            HStack {
                Text("Add")
                    .foregroundColor(.accentColor)
                    .padding(.leading, 10)
                Menu(
                    content: {
                        Picker("", selection: $diceManager.sides) {
                            ForEach(DiceTypes.allCases, id: \.self) {
                                Text("D\($0.rawValue) Board")
                                    .font(.headline)
                            }
                        }
                    },
                    label: {
                        Text("D\(diceManager.sides.rawValue) Board")
                            .padding(.all, 3)
                            .modifier(ButtonInset(opacity: false))
                    }
                )
                Spacer()
                Button {
                    diceManagers.append(diceManager)
                    diceManager = DiceManager()
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

struct MultiplayerButton: View {
    @State private var showMatchMaker: Bool = false
    @State private var showTurnBasedMatchMaker: Bool = false
    @State private var existingMatch: Bool = false
    @State private var nonExistingMatch: Bool = false
    @EnvironmentObject var gkManager: GKManager
    
    let closedSave: () -> Void
    
    var body: some View {
        Button {
            guard let match = self.gkManager.gkMatch else {
                showMatchMaker = true
                return
            }
            if !match.players.isEmpty {
                existingMatch = true
            } else {
                showMatchMaker = true
            }
        } label: {
            Image(systemName: "person.fill.badge.plus")
                .symbolRenderingMode(.multicolor)
        }
        .buttonStyle(.borderless)
        .sheet(isPresented: $showMatchMaker) {
            GKMatchmakerView(
                minPlayers: GKManager.minPlayers,
                maxPlayers: GKManager.maxPlayers,
                inviteMessage: "Let's Share Pro Roller Boards!",
                matchmakingMode: .inviteOnly
            ) {
                self.showMatchMaker = false
            } failed: { (error) in
                self.showMatchMaker = false
            } started: { (match) in
                closedSave()
            }
            .ignoresSafeArea()
        }
        .confirmationDialog("", isPresented: $existingMatch) {
            if let match = self.gkManager.gkMatch {
                Button("Remove \(match.players.count) Existing", role: .destructive) {
                    showMatchMaker.toggle()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Play with Friends & Remove Existing?")
        }
    }
}

struct GameCenterButton: View {
    @Environment(\.openURL) var openURL
    @Environment(\.scenePhase) var scenePhase
    @EnvironmentObject var gkManager: GKManager
    @State var showGameCenter: Bool = false
    @State var enableGameCenter: Bool = false
    @State var autoLogin: Bool = true
    
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = "Login to Game Center"
    @State private var alertMessage: String = "Settings > Game Center"
    
    let closedSave: () -> Void
    
    var body: some View {
        if let localPlayer = self.gkManager.gkLocalPlayer,
           localPlayer.isAuthenticated {
            Button {
                showGameCenter.toggle()
            } label: {
                HStack(spacing: 0) {
                    if let uiImage = self.gkManager.uiImage {
                        PlayerView(playerImage: uiImage)
                    } else {
                        Image("game-center")
                            .resizable()
                            .frame(width: 20, height: 20)
                    }
                    if gkManager.isPolling {
                        Image(systemName: "circle.fill")
                            .resizable()
                            .frame(width: 5, height: 5)
                            .offset(x: 0, y: 7)
                            .foregroundColor(.green)
                    }
                }
            }
            .buttonStyle(.borderless)
            .fullScreenCover(isPresented: $showGameCenter) {
                GameCenterView(closedSave: closedSave)
            }
        } else {
            Button {
                showAlert.toggle()
            } label: {
                Image("game-center")
                    .resizable()
                    .frame(width: 20, height: 20)
            }
            .onChange(of: scenePhase) { newPhase in
                switch newPhase {
                case .active:
                    print("Active")
                    GKLocalPlayer.local.authenticateHandler = { viewController, error in
                        if let _ = viewController {
                            return
                        }
                        if let error = error {
                            print(error.localizedDescription)
                            return
                        }
                        withAnimation {
                            if let player = self.gkManager.gkLocalPlayer {
                                // Register both realtime and turn based players
                                self.gkManager.loadImage(player: player)
                            }
                        }
                    }
                case .inactive, .background:
                    break
                @unknown default:
                    print("Unknown ScenePhase")
                }
            }
            .alert(isPresented: self.$showAlert) {
                Alert(
                    title: Text(self.alertTitle),
                    message: Text(self.alertMessage),
                    primaryButton: .default(
                        Text("Go to Settings"),
                        action: {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                        }
                    ),
                    secondaryButton: .destructive(Text("Dismiss"))
                )
            }
        }
    }
}

struct GameCenterView: View {
    @State var showOptions: Bool = false
    
    let closedSave: () -> Void
    
    var body: some View {
        ZStack {
            Color("DarkShadow")
                .ignoresSafeArea()
            VStack {
                GKGameCenterView()
                    .ignoresSafeArea()
            }
        }
    }
}

struct LastMatchButton: View {
    @EnvironmentObject var gkManager: GKManager
    @State var showMatchMaker: Bool = false
    @State private var showTurnBasedMatchMaker: Bool = false
    @State private var existingMatch: Bool = false
    @State private var nonExistingMatch: Bool = false
    
    let maxSize: Int = 3
    let closedSave: () -> Void
    let gradient = Gradient(colors: [.accentColor, .secondary])
    
    var body: some View {
        if let matchRequest = self.gkManager.cachedMatchRequest {
            Button {
                guard let match = self.gkManager.gkMatch else {
                    nonExistingMatch = true
                    return
                }
                if !match.players.isEmpty {
                    existingMatch = true
                } else {
                    nonExistingMatch = true
                }
            } label: {
                Label {
                    Text("Invite Recent Friends")
                } icon: {
                    if let cachedPlayers = self.gkManager.cachedPlayers {
                        HStack(alignment: .center, spacing: -10) {
                            ForEach(Array(zip(cachedPlayers, cachedPlayers.indices)), id: \.0) { player, index in
                                if index <= maxSize - 1 {
                                    if let uiImage = self.gkManager.playerImage[player.gamePlayerID] {
                                        PlayerView(playerImage: uiImage)
                                    } else {
                                        PlayerView(playerImage: nil)
                                    }
                                } else if index == maxSize {
                                    ZStack {
                                        Circle()
                                            .fill(
                                                .radialGradient(
                                                    gradient,
                                                    center: .center,
                                                    startRadius: 0.0,
                                                    endRadius: 25.0
                                                )
                                            )
                                            .frame(width: 25, height: 25)
                                            .shadow(radius: 1.0)
                                        Text("+\(cachedPlayers.count - maxSize)")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.primary)
                                            .colorInvert()
                                            .offset(x: -1)
                                    }
                                }
                            }
                        }
                    } else {
                        Image(systemName: "person.3.fill")
                    }
                }
            }
            .sheet(isPresented: $showMatchMaker) {
                GKMatchmakerView(matchRequest: matchRequest) {
                    self.showMatchMaker = false
                } failed: { (error) in
                    self.showMatchMaker = false
                } started: { (match) in
                    closedSave()
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $showMatchMaker) {
                TurnBasedInviteView(
                    showTurnBasedMatchMaker: $showTurnBasedMatchMaker,
                    closedSave: closedSave
                )
            }
            .confirmationDialog("", isPresented: $existingMatch) {
                if let match = self.gkManager.gkMatch {
                    Button("Remove \(match.players.count) Existing", role: .destructive) {
                        showMatchMaker.toggle()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Play with \(matchRequest.maxPlayers - 1) Recent Friends & Remove Existing?")
            }
            .confirmationDialog("", isPresented: $nonExistingMatch) {
                Button("Live Sharing") {
                    showMatchMaker.toggle()
                }
                Button("Turn Based Yahtzee") {
                    showTurnBasedMatchMaker.toggle()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Play with \(matchRequest.maxPlayers - 1) Recent Friends?")
            }
        }
    }
}

struct LeaveMatchButton: View {
    @EnvironmentObject var gkManager: GKManager
    @State var showConfirmation: Bool = false
    
    var body: some View {
        if let match = self.gkManager.gkMatch {
            Button {
                showConfirmation = true
            } label: {
                Label("Remove Friends Boards", systemImage: "person.fill.badge.minus")
                    .symbolRenderingMode(.multicolor)
            }
            .confirmationDialog("", isPresented: $showConfirmation) {
                Button("Remove Friends Boards", role: .destructive) {
                    match.disconnect()
                    GKMatchManager.shared.cancel()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Remove Existing Friends?")
            }
        }
    }
}

struct TurnBasedInviteView: View {
    @EnvironmentObject var gkManager: GKManager
    @Binding var showTurnBasedMatchMaker: Bool
    @State var showOptions: Bool = false
    
    let closedSave: () -> Void
    
    var body: some View {
        ZStack {
            Color("DarkShadow")
            GKTurnBasedMatchmakingMatchmakerView(
                minPlayers: GKManager.minPlayers,
                maxPlayers: GKManager.maxPlayers,
                inviteMessage: "Let's Share Pro Roller Boards!",
                matchmakingMode: .inviteOnly
            ) {
                self.showTurnBasedMatchMaker = false
            } failed: { error in
                self.showTurnBasedMatchMaker = false
            } started: { match in
                closedSave()
            }
        }
        .ignoresSafeArea()
    }
}
