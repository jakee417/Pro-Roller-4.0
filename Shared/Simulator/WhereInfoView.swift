//
//  WhereInfoView.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 3/9/23.
//

import SwiftUI

struct WhereInfoView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Text("This is where you can view or customize an event. Each event is composed of several **Where** clauses that control what we look for in each round of simulations. These **Where** clauses are then joined together using **Conjunctions**. ")
                        .handScriptFont(.regular, size: 18)
                }
                VStack(alignment: .leading) {
                    (Text(Image(systemName: "x.squareroot")) + Text(" Reduction"))
                        .modifier(ButtonInset(opacity: false))
                    Text("Controls how dice are combined together.\n\n**Sum**, **Average**, **Mode**, **Median** are measures of central tendency.\n\n **Maximum** and **Minimum** focus on the highest & lowest values in the dice.\n\n**Run** will measure when things happen consecutively (i.e. a 4, 4, & 4 occuring). \n\n**Sequence** looks for an increasing or decreasing sequence between start and end values.\n\n**No Reduction** skips a reduction, and checks each die individually. ")
                        .handScriptFont(.regular, size: 18)
                }
                VStack(alignment: .leading) {
                    (Text(Image(systemName: "greaterthan.circle.fill")) + Text(" Bound"))
                        .modifier(ButtonInset(opacity: false))
                    Text("States how many dice we need to consider the simulation a 'success' or 'failure'.\n\n **Note** - For certain reductions, only **Exactly** is allowed. ")
                        .handScriptFont(.regular, size: 18)
                }
                VStack(alignment: .leading) {
                    (Text(Image(systemName: "equal.circle.fill")) + Text(" Comparison"))
                        .modifier(ButtonInset(opacity: false))
                    Text("Is what we are looking for on each individual die (for **No Reduction**) or across all dice (for all other reductions). ")
                        .handScriptFont(.regular, size: 18)
                }
                VStack(alignment: .leading) {
                    HStack {
                        Text("Conjunction")
                            .font(.headline)
                            .modifier(ButtonInset(opacity: false))
                        Text("(")
                        Text("And")
                            .font(.headline)
                            .modifier(ButtonInset(opacity: false))
                        Text("&")
                            .handScriptFont(.regular, size: 18)
                        Text("Or")
                            .font(.headline)
                            .modifier(ButtonInset(opacity: false))
                        Text(")")
                        Spacer()
                    }
                    Text("The two ways to combine **Where** clauses is using **And** and **Or**. An **And** conjuction stipulates that both clauses need to occur to be considered a success. **Or** on the other hand requires only one, or both to occur. With these two building blocks, we are able to chain together many **Where** clauses into complex events! ")
                        .handScriptFont(.regular, size: 18)
                }
            } header: {
                Text("Where Clauses ")
                    .handScriptFont(.semiBold, size: 32)
                
            }
            Section {
                VStack(alignment: .leading) {
                    Text("Pressing down & holding on an individual **Where** clause will show a preview of the results specific to that individual clause. ")
                        .handScriptFont(.regular, size: 16)
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.accentColor)
                        .padding(.top, 5)
                    Text("Shows a cross section of values **or** dice amounts across all potential values. ")
                        .handScriptFont(.regular, size: 18)
                    Image(systemName: "square.grid.3x2.fill")
                        .foregroundColor(.accentColor)
                        .padding(.top, 5)
                    Text("Shows a **grid** of all possible potential values across values **and** dice amounts. ")
                        .handScriptFont(.regular, size: 18)
                    Text("**Note** - the **grid** preview is not available for certain where clauses. ")
                        .handScriptFont(.regular, size: 18)
                        .padding(.top, 5)
                }
                
            } header: {
                Text("Where Preview ")
                    .handScriptFont(.semiBold, size: 32)
                
            }
            Section {
                VStack(alignment: .leading) {
                    Text("Now that our simulation and event is specified, we can analyze the results! ")
                        .handScriptFont(.regular, size: 18)
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.accentColor)
                        .padding(.top, 5)
                    Text("Shows a plot of how many rolls we should expect to conduct until the **first** time the event will occur. Probabilities are either shown **Individually** or **Cumulatively** across the number of attempts. ")
                        .padding(.top, 5)
                        .handScriptFont(.regular, size: 18)
                    Image(systemName: "hammer.circle.fill")
                        .foregroundColor(.accentColor)
                        .padding(.top, 5)
                    Text("Run a simulation and compute statistics for this specific event across all of its **Where** clauses. ")
                        .handScriptFont(.regular, size: 18)
                }
            } header: {
                Text("Result ")
                    .handScriptFont(.semiBold, size: 32)
                
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Info")
        .listStyle(.grouped)
    }
}

struct WhereInfoView_Previews: PreviewProvider {
    static var previews: some View {
        WhereInfoView()
    }
}
