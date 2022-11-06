import SwiftUI

enum DiceTypes: Int, CaseIterable, Codable {
    case D2 = 2
    case D3 = 3
    case D4 = 4
    case D5 = 5
    case D6 = 6
    case D7 = 7
    case D8 = 8
    case D9 = 9
    case D10 = 10
    case D11 = 11
    case D12 = 12
    case D20 = 20
    case D40 = 40
    case D100 = 100
}

enum DiceAmountPresets: Int, CaseIterable, Codable {
    case small = 1
    case medium = 5
    case large = 100
}

enum RollType: String, CaseIterable, Codable {
    case shuffle = "Shuffle"
    case sort = "Sort"
    case single = "Single"
    case freezable = "Frozen"
    case edit = "Edit"
}

func rollTypeImage(_ type: RollType) -> String {
    switch type {
    case .shuffle:
        return "shuffle.circle.fill"
    case .sort:
        return "123.rectangle.fill"
    case .single:
        return "1.square.fill"
    case .freezable:
        return "cube.fill"
    case .edit:
        return "pencil.circle.fill"
    }
}

struct Dice: Hashable, Identifiable {
    let id: UUID
    var value: Int
    var sides: DiceTypes
    var diceColor: Color
    var x: CGFloat
    var y: CGFloat
    var z: CGFloat
    var rotationDirection: Double
    
    var contrastColor: Color {
        get {
            return diceColor == .black ? .white : .black
        }
    }
    
    func randomValue() -> Int {
        return Int.random(in: 1..<sides.rawValue + 1)
    }
    
    mutating func roll() {
        self.value = self.randomValue()
    }
    
    func drawRandomTransition() -> CGFloat {
        return [CGFloat(-1.0), CGFloat(1.0)].randomElement()!
    }
    
    mutating func randomTransition() {
        let transitionSide = [1, 0].randomElement()!
        if transitionSide == 1 {
            self.x = drawRandomTransition()
            self.y = 0
        } else {
            self.x = 0
            self.y = drawRandomTransition()
        }
    }
    
    mutating func randomDirection() {
        self.rotationDirection = drawRandomTransition()
    }
    
    init(sides: DiceTypes = .D6, diceColor: Color = .white) {
        self.id = UUID()
        self.value = 0
        self.sides = sides
        self.diceColor = diceColor
        self.x = CGFloat(0.0)
        self.y = CGFloat(0.0)
        self.z = CGFloat(0.0)
        self.rotationDirection = 0.0
        self.randomDirection()
        self.randomTransition()
        self.roll()
    }
}

extension Dice {
    @ViewBuilder
    func textView() -> some View {
        Text("\((self.value))")
            .foregroundColor(diceColor == .white ? .black : .white)
            .font(.largeTitle.bold())
    }
    
    @ViewBuilder
    func smallTextView() -> some View {
        Text("\((self.value))")
            .foregroundColor(diceColor == .white ? .black : .white)
            .font(.headline.bold())
    }
    
    @ViewBuilder
    func pipView() -> some View {
        Circle()
            .innerShadow(using: Circle(), color: contrastColor, width: 3, blur: 6)
            .foregroundColor(contrastColor)
            .opacity(0.9)
            .frame(width: Constants.dicePipSize, height: Constants.dicePipSize)
            
    }
    
    @ViewBuilder
    func defaultView() -> some View {
        ZStack{
            Capsule(style: .continuous)
                .foregroundColor(diceColor)
                .innerShadow(using: Capsule(style: .continuous), color: contrastColor, width: 3)
                .frame(width: Constants.diceSize * 8 / 10, height: Constants.diceSize)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            textView()
        }
    }
    
    @ViewBuilder
    func D2View() -> some View {
        ZStack{
            Circle()
                .foregroundColor(diceColor)
                .innerShadow(using: Circle(), color: contrastColor, width: 3)
                .frame(width: Constants.diceSize, height: Constants.diceSize)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            switch self.value {
            case 1:
                Text("H")
                    .foregroundColor(diceColor == .white ? .black : .white)
                    .font(.largeTitle.bold())
            case 2:
                Text("T")
                    .foregroundColor(diceColor == .white ? .black : .white)
                    .font(.largeTitle.bold())
            default:
                Text("\((self.value))")
                    .foregroundColor(diceColor == .white ? .black : .white)
                    .font(.largeTitle.bold())
            }
        }
    }
    
    @ViewBuilder
    func D4View() -> some View {
        ZStack(alignment: .center) {
            softTriangle()
                .foregroundColor(diceColor)
                .innerShadow(
                    using: softTriangle(),
                    color: contrastColor,
                    width: 2,
                    blur: 4
                )
                .frame(width: Constants.diceSize, height: Constants.diceSize)
                .shadow(color: .black, radius: 1, x: 1, y: 1)
            Triangle()
                .frame(width: Constants.diceSize * 9 / 10, height: Constants.diceSize / 4)
                .offset(x: 0, y: 24)
                .opacity(0.2)
                .blur(radius: 3)
                .foregroundColor(contrastColor)
            Triangle()
                .rotation(.degrees(244))
                .frame(width: Constants.diceSize, height: Constants.diceSize / 5)
                .offset(x: 10, y: 6)
                .opacity(0.2)
                .blur(radius: 3)
                .foregroundColor(contrastColor)
            smallTextView()
                .rotation3DEffect(.degrees(-40), axis: (x: 1, y: 0, z: 0))
                .offset(x: 0, y: 25)
            smallTextView()
                .rotation3DEffect(.degrees(-40), axis: (x: 1, y: 0, z: 0))
                .rotationEffect(.degrees(244))
                .offset(x: 10, y: 5)
            smallTextView()
                .rotation3DEffect(.degrees(-40), axis: (x: 1, y: 0, z: 0))
                .rotationEffect(.degrees(117))
                .offset(x: -10, y: 5)
        }
    }
    
    @ViewBuilder
    func D6View() -> some View {
        let offset: CGFloat = -18
        
        ZStack{
            RoundedRectangle(cornerRadius: Constants.diceCornerRadius)
                .foregroundColor(diceColor)
                .innerShadow(
                    using: RoundedRectangle(cornerRadius: Constants.diceCornerRadius),
                    color: contrastColor,
                    width: 3
                )
                .shadow(color: .black, radius: 1, x: 1, y: 1)
                .frame(width: Constants.diceSize, height: Constants.diceSize)
            switch value {
            case 1:
                pipView()
            case 2:
                pipView()
                    .offset(x: -offset, y: -offset)
                pipView()
                    .offset(x: offset, y: offset)
            case 3:
                pipView()
                    .offset(x: -offset, y: -offset)
                pipView()
                pipView()
                    .offset(x: offset, y: offset)
            case 4:
                pipView()
                    .offset(x: -offset, y: -offset)
                pipView()
                    .offset(x: -offset, y: offset)
                pipView()
                    .offset(x: offset, y: -offset)
                pipView()
                    .offset(x: offset, y: offset)
            case 5:
                pipView()
                    .offset(x: -offset, y: -offset)
                pipView()
                    .offset(x: -offset, y: offset)
                pipView()
                pipView()
                    .offset(x: offset, y: -offset)
                pipView()
                    .offset(x: offset, y: offset)
            case 6:
                pipView()
                    .offset(x: -offset, y: -offset)
                pipView()
                    .offset(x: -offset, y: offset)
                pipView()
                    .offset(x: -offset, y: 0)
                pipView()
                    .offset(x: offset, y: 0)
                pipView()
                    .offset(x: offset, y: -offset)
                pipView()
                    .offset(x: offset, y: offset)
            default: 
                textView()
            }
            
        }
    }
    
    @ViewBuilder
    func renderView() -> some View {
        switch self.sides {
        case .D2:
            D2View()
        case .D3:
            defaultView()
        case .D4:
            D4View()
        case .D5:
            defaultView()
        case .D6:
            D6View()
        case .D7:
            defaultView()
        case .D8:
            defaultView()
        case .D9:
            defaultView()
        case .D10:
            defaultView()
        case .D11:
            defaultView()
        case .D12:
            defaultView()
        case .D20:
            defaultView()
        case .D40:
            defaultView()
        case .D100:
            defaultView()
        }
    }
}
