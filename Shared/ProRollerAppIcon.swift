//
//  ProRollerAppIcon.swift
//  Pro Roller (iOS)
//
//  Created by Jake Taylor on 3/5/23.
//

import SwiftUI

struct ProRollerAppIcon: View {
    static let appIconSize: CGFloat = 512
    @State var dice1: Dice = Dice(sides: .D6, diceColor: .red)
    @State var dice2: Dice = Dice(sides: .D6, diceColor: .green)
    @State var dice3: Dice = Dice(sides: .D6, diceColor: .orange)
    
    var body: some View {
        if #available(iOS 16.0, *) {
            RoundedRectangle(cornerRadius: 10.0, style: .continuous)
                .fill(Color.accentColor.gradient)
                .overlay(
                    VStack {
                        dice1.renderView()
                            .scaleEffect(2.0)
                            .onAppear {
                                dice1.value = 1
                            }
                            .offset(y: -64)
                        HStack {
                            dice2.renderView()
                                .scaleEffect(2.0)
                                .onAppear {
                                    dice2.value = 2
                                }
                                .offset(x: -35)
                            dice3.renderView()
                                .scaleEffect(2.0)
                                .onAppear {
                                    dice3.value = 3
                                }
                                .offset(x: 35)
                        }
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
