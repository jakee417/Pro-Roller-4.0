import SwiftUI

struct Constants {
    static let title: String = "Boards"
    static let boardMinHeight: CGFloat = 180
    static let boardMaxHeight: CGFloat = 300
    static let sheetBackButtonWidth: CGFloat = 10
    static let sheetBackButtonHeight: CGFloat = 20
    static let smallButtonSize: CGFloat = 30
    static let smallButtonPadding: CGFloat = 15
    static let backgroundImageSize: CGFloat = 120
    static let maxAnimations: Int = 6
    static let animationWaitTime: Double = 0.1
    static let diceSize: CGFloat = 70
    static let diceCornerRadius: CGFloat = 7
    static let dicePipSize: CGFloat = 15
    static let diceColors: [Color] = [
        .black,
        .blue,
        .brown,
        .cyan,
        .gray,
        .green,
        .indigo,
        .mint,
        .orange,
        .pink,
        .purple,
        .red,
        .teal,
        .white,
        .yellow,
    ].sorted {
        $0.description < $1.description
    }
    static let colors: [Color] = [
        .blue,
        .orange,
        .red,
        .green,
        .pink,
        .brown,
        .teal,
        .yellow,
        .cyan
    ]
}
