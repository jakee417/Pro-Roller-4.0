//
//  ProRollerAppIcon.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 3/5/23.
//

import SwiftUI

struct ProRollerAppIcon: View {
    static let appIconSize: CGFloat = 512
    @State var dice3: Dice = Dice(sides: .D6, diceColor: .white)
    
    var body: some View {
        if #available(iOS 16.0, *) {
            RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                .fill(RadialGradient(gradient: Gradient(colors: [.red, .orange, .yellow]), center: .center, startRadius: 0, endRadius: 600))
                .overlay(
                    dice3.renderView()
                        .scaleEffect(4.0)
                        .onAppear {
                            dice3.value = 5
                        }
                )
        } else {
            EmptyView()
        }
    }
}



@available(iOS 16.0, *)
struct ProRollerAppIcon_Previews: PreviewProvider {
    static var previews: some View {
        ProRollerAppIcon()
            .shadow(radius: 10)
            .frame(width: ProRollerAppIcon.appIconSize, height: ProRollerAppIcon.appIconSize)
    }
}
