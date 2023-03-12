import SwiftUI
import GameKit
import GameKitUI

struct BoardToolbarView: View {
    @EnvironmentObject var gkManager: GKManager
    @StateObject var diceManagers: DiceManagers = DiceManagers()
    @State var selection: Set<Int> = Set<Int>()
    @State var showDelete: Bool = false
    @State var showReset: Bool = false
    
    let closedSave: () -> Void
    let roll: (DiceManager) -> Void
    let reset: (DiceManager) -> Void
    
    var body: some View {
        Button {
            showReset.toggle()
        } label: {
            Label("", systemImage: "arrow.counterclockwise.circle.fill")
                .symbolRenderingMode(.multicolor)
        }
        .confirmationDialog("", isPresented: $showReset) {
            Button("Reset \(diceManagers.managers.count) Boards", role: .destructive) {
                for manager in diceManagers.managers {
                    reset(manager)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Reset All Boards?")
        }
        .disabled(diceManagers.managers.isEmpty)
        .buttonStyle(.borderless)
        Button {
            showDelete.toggle()
        } label: {
            Label("", systemImage: "trash.circle.fill")
                .symbolRenderingMode(.multicolor)
        }
        .confirmationDialog("", isPresented: $showDelete) {
            Button("Delete \(diceManagers.managers.count) Boards", role: .destructive) {
                selection = Set(diceManagers.managers.indices)
                delete(selection: selection)
                selection = Set<Int>()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Delete All Boards?")
        }
        .disabled(diceManagers.managers.isEmpty)
        .buttonStyle(.borderless)
        .padding(.leading, 15)
        Spacer()
        if self.gkManager.allowMultiplayer {
            MultiplayerButton(closedSave: closedSave)
                .padding(.trailing, 15)
        }
        Button {
            for diceManager in diceManagers.managers {
                roll(diceManager)
                closedSave()
            }
        } label: {
            Text("Roll All")
                .font(.subheadline)
        }
        .buttonStyle(.borderedProminent)
        .disabled(diceManagers.managers.isEmpty)
    }
    
    func delete(selection: Set<Int>) {
        diceManagers.managers.remove(at: IndexSet(selection))
    }
}

struct MultiplayerButton: View {
    @State private var showMatchMaker: Bool = false
    @State var showConfirmation: Bool = false
    @EnvironmentObject var gkManager: GKManager
    
    let closedSave: () -> Void
    
    var body: some View {
        if let match = self.gkManager.gkMatch {
            if !match.players.isEmpty {
                cancelButton
            } else {
                inviteButton
            }
        } else {
            inviteButton
        }
    }
    
    var cancelButton: some View {
        Button {
            GKMatchManager.shared.cancel()
        } label: {
            Label("Remove Friends Boards", systemImage: "person.fill.badge.minus")
                .symbolRenderingMode(.multicolor)
        }
        .buttonStyle(.borderless)
    }
    
    var inviteButton: some View {
        Button {
            showMatchMaker = true
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
    }
}
