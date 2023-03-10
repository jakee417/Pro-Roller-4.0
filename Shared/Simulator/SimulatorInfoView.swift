//
//  SimulatorInfoView.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 3/8/23.
//

import SwiftUI

struct SimulatorInfoView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Text("Answer **What-If** type questions about your boards! ")
                        .handScriptFont(.regular, size: 18)
                    Text("Select the **number of dice to roll per simulation**. Each board has its own simulator, and as you add & remove dice, the changes will be reflected on the original board. ")
                        .handScriptFont(.regular, size: 18)
                        .padding(.top, 5)
                }
                VStack(alignment: .leading) {
                    (Text("D\(DiceTypes.D6.rawValue) ") + Text(Image(systemName: "dice.fill")) + Text(" Dice"))
                        .modifier(ButtonInset(opacity: false))
                    Text("Select the number of sides (6) that the dice (D) will have in the simulation.\n\n**Note** - changing this will also change the dice type on the original board! ")
                        .handScriptFont(.regular, size: 18)
                }
                VStack(alignment: .leading) {
                    Text("\(5000) times")
                        .modifier(ButtonInset(opacity: false))
                    Text("Select the total number of simulations (5000). For example, if you roll 6, D6 dice 5,000 times, this would be a total of 6 * 5,000 = 30,000 total dice rolls. The results of each simulated roll is aggregated to compute the statistics in the **Events** section.\n\n**Note** - Increasing this value will improve estimates at the cost of higher computation times. ")
                        .handScriptFont(.regular, size: 18)
                }
                VStack(alignment: .leading) {
                    HStack {
                        Text("About simulating with frozen")
                            .handScriptFont(.regular, size: 18)
                        Text(Image(systemName: "cube.fill"))
                            .foregroundColor(.accentColor)
                        Text("dice ")
                            .handScriptFont(.regular, size: 18)
                    }
                    (
                        Text("\(2) ") +
                        Text(Image(systemName: "cube.fill")) +
                        Text(" Frozen")
                    )
                    .font(.headline)
                    .modifier(ButtonInset(opacity: false))
                    .padding(.top, 5)
                    Text("This indicates that some of the dice (2 in the example) may be frozen. In each simulation, these values will be held fixed to the values displayed on the original board. ")
                        .handScriptFont(.regular, size: 18)
                    Text("No Frozen")
                        .font(.headline)
                        .modifier(ButtonInset(opacity: false))
                        .padding(.top, 5)
                    Text("This has the opposite behavior. If we have frozen dice, simulate random values anyways and ignore the fixed values on the original board. ")
                        .handScriptFont(.regular, size: 18)
                }
            } header: {
                Text("Generate ")
                    .handScriptFont(.semiBold, size: 32)
                
            }
            Section {
                VStack(alignment: .leading) {
                    (
                        Text("In this section, we compute the statistics of our simulated dice rolls according to an **Event**  ")
                        + Text(Image(systemName: "flowchart.fill")).foregroundColor(.accentColor)
                        + Text(". You can add **Preset Events** or create your own **Custom Events**.")
                     )
                        .handScriptFont(.regular, size: 18)
                    Text("Tapping a specific event card will run a simulation and compute statistics for that **individual** event. ")
                        .padding(.top, 5)
                        .handScriptFont(.regular, size: 18)
                    Image(systemName: "hammer.circle.fill")
                        .foregroundColor(.accentColor)
                        .padding(.top, 5)
                    Text("Run a simulation and compute statistics for **all** events currently displayed. ")
                        .handScriptFont(.regular, size: 18)
                }
                VStack(alignment: .leading) {
                    HStack {
                        Text("Ex. ")
                            .handScriptFont(.regular, size: 18)
                        Text("Exactly Two, Ones")
                            .modifier(ButtonInset(opacity: false))
                        Spacer()
                    }
                    Text("Count the proportion (**Prob**) of time that **exactly** two dice roll a value of one. When this occurs, the card will also display the summation (**Sum**) and average (**Avg**) of all the dice when the event occurs. ")
                        .handScriptFont(.regular, size: 18)
                    Text("**Note** - Tapping on the event's title will show you more details!")
                        .handScriptFont(.regular, size: 18)
                        .padding(.top, 5)
                }
            } header: {
                Text("Events ")
                    .handScriptFont(.semiBold, size: 32)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Info")
        .listStyle(.grouped)
    }
}

struct SimulatorInfoView_Previews: PreviewProvider {
    static var previews: some View {
        SimulatorInfoView()
    }
}
