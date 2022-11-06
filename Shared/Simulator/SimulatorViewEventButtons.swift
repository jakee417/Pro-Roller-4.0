import SwiftUI

struct BoundButtonView: View {
    @Binding var event: Event
    @State var showingOptions: Bool = false
    @State var buttonMode: Bool = true
    
    var boundLabel: String {
        get {
            guard event.bound != nil else {
                return "Bound"
            }
            return event.bound!.rawValue
        }
    }
    
    var body: some View {
        if buttonMode {
            Button {
                showingOptions.toggle()
            } label: {
                if event.bound == nil {
                    (
                        Text(Image(systemName: "greaterthan.circle.fill")) +
                        Text(boundLabel)
                    )
                    .modifier(ButtonInset(opacity: true))
                } else {
                    Text(boundLabel)
                        .modifier(ButtonInset(opacity: false))
                }
            }
            .buttonStyle(.borderless)
            .confirmationDialog("Comparison", isPresented: $showingOptions) {
                BoundPickerView(event: $event)
            } message: {
                Text("How To Compare Dice Quantities?")
            }
        } else {
            if event.bound == nil {
                (
                    Text(Image(systemName: "greaterthan.circle.fill")) +
                    Text(boundLabel)
                )
                .font(.headline)
                .modifier(ButtonInset(opacity: false, color: .gray))
            } else {
                Text(boundLabel)
                    .font(.headline)
                    .modifier(ButtonInset(opacity: false, color: .gray))
            }
        }
    }
}

struct BoundPickerView: View {
    @Binding var event: Event
    
    var body: some View {
        ForEach(Bound.allCases, id: \.self.rawValue) { value in
            Button {
                event.bound = value
            } label: {
                Text("\(value.rawValue) \(buttonCheckMark(event.bound == value))")
            }
        }
        Button("Clear", role: .destructive) {
            event.bound = nil
        }
    }
}

struct DiceAmountView: View {
    @Binding var event: Event
    @Binding var totalDice: Int
    @Binding var selectedDice: DiceTypes?
    @State var buttonMode: Bool = true
    @Binding var sheetVariable: SheetVariable
    
    var body: some View {
        HStack {
            if !buttonMode && (sheetVariable == .quantity || sheetVariable == .grid) {
                Text("0...\(totalDice)")
            } else {
                Menu {
                    Picker("Dice Quantity", selection: self.$event.quantity) {
                        ForEach(0...totalDice, id: \.self) {
                            Text("\($0)")
                        }
                    }
                } label: {
                    Text("\(self.event.quantity)")
                        .padding(.leading, 5)
                        .padding(.trailing, 5)
                        .modifier(
                            ButtonInset(
                                opacity: false, color: buttonMode ? .accentColor : .secondary
                            )
                        )
                }
            }
            DiceButtonView(event: $event, selectedDice: $selectedDice)
        }
        .font(.headline)
    }
}

struct DiceButtonView: View {
    @Binding var event: Event
    @Binding var selectedDice: DiceTypes?
    
    var diceLabel: String {
        get {
            guard let diceType = selectedDice?.rawValue else {
                return "Dice"
            }
            return "D\(diceType)"
        }
    }
    
    var body: some View {
        Text(Image(systemName: "dice")) + Text(" ") + Text(diceLabel)
    }
}

struct ReductionButtonView: View {
    @Binding var event: Event
    @State var showingOptions: Bool = false
    @State var buttonMode: Bool = true
    
    var label: String {
        get {
            guard event.reduction != nil else {
                return "Reduction"
            }
            return event.reduction!.rawValue
        }
    }
    
    var body: some View {
        if buttonMode {
            Button {
                showingOptions.toggle()
            } label: {
                if event.reduction == nil {
                    (Text(Image(systemName: "x.squareroot")) + Text(" ") + Text(label))
                        .modifier(ButtonInset(opacity: true))
                } else {
                    Text(label)
                        .modifier(ButtonInset(opacity: false))
                }
            }
            .buttonStyle(.borderless)
            .confirmationDialog("Reductions", isPresented: $showingOptions) {
                ReductionPickerView(event: $event)
            } message: {
                Text("How To Combine Dice?")
            }
        } else {
            if event.reduction == nil {
                (Text(Image(systemName: "x.squareroot")) + Text(" ") + Text(label))
                    .font(.headline)
                    .modifier(ButtonInset(opacity: false, color: .gray))
            } else {
                Text(label)
                    .font(.headline)
                    .modifier(ButtonInset(opacity: false, color: .gray))
            }
        }
        
    }
}

struct ReductionPickerView: View {
    @Binding var event: Event
    
    var body: some View {
        ForEach(Reduction.allCases, id: \.self.rawValue) { value in
            Button {
                event.reduction = value
            } label: {
                if value == .each {
                    Text("No Reduction \(buttonCheckMark(event.reduction == value))")
                } else {
                    Text("\(value.rawValue) \(buttonCheckMark(event.reduction == value))")
                }
                
            }
        }
        Button("Clear", role: .destructive) {
            event.reduction = nil
        }
    }
}


struct ComparisonButtonView: View {
    @Binding var event: Event
    @State var showingOptions: Bool = false
    @State var buttonMode: Bool = true
    
    var label: String {
        get {
            guard event.comparison != nil else {
                return "Comparison"
            }
            return event.comparison!.rawValue
        }
    }
    
    var body: some View {
        if buttonMode {
            Button {
                showingOptions.toggle()
            } label: {
                if event.comparison == nil {
                    (Text(Image(systemName: "equal.circle.fill")) + Text(label))
                        .modifier(ButtonInset(opacity: true))
                } else {
                    Text(label)
                        .modifier(ButtonInset(opacity: false))
                }
            }
            .buttonStyle(.borderless)
            .confirmationDialog("Comparison", isPresented: $showingOptions) {
                ComparisonPickerView(event: $event)
            } message: {
                Text("How To Compare Dice Values?")
            }
        } else {
            if event.comparison == nil {
                (Text(Image(systemName: "equal.circle.fill")) + Text(label))
                    .font(.headline)
                    .modifier(ButtonInset(opacity: false, color: .gray))
            } else {
                Text(label)
                    .font(.headline)
                    .modifier(ButtonInset(opacity: false, color: .gray))
            }
        }
    }
}

struct ComparisonPickerView: View {
    @Binding var event: Event
    
    var body: some View {
        ForEach(Comparison.allCases, id: \.self.rawValue) { value in
            Button("\(value.rawValue) \(buttonCheckMark(event.comparison == value))") {
                event.comparison = value
            }
        }
        Button("Clear", role: .destructive) {
            event.comparison = nil
        }
    }
}


struct ConjunctionButtonView: View {
    @Binding var event: Event
    @State var showingOptions: Bool = false
    @State var buttonMode: Bool = true
    
    var label: String {
        get {
            guard event.conjunction != nil else {
                return "Conjunction"
            }
            return event.conjunction!.rawValue
        }
    }
    
    var body: some View {
        Button {
            showingOptions.toggle()
        } label: {
            if event.conjunction == nil {
                Text(label)
                    .modifier(
                        ButtonInset(
                            opacity: true, color: buttonMode ? .accentColor : .secondary
                        )
                    )
            } else {
                Text(label)
                    .modifier(
                        ButtonInset(
                            opacity: false, color: buttonMode ? .accentColor : .secondary
                        )
                    )
            }
        }
        .buttonStyle(.borderless)
        .confirmationDialog("Conjunction", isPresented: $showingOptions) {
            ConjunctionPickerView(event: $event)
        } message: {
            Text("How To Combine Events?")
        }
    }
}

struct ConjunctionPickerView: View {
    @Binding var event: Event
    
    var body: some View {
        ForEach(Conjunction.allCases, id: \.self.rawValue) { value in
            switch value {
            case .first:
                EmptyView()
            case .and, .or:
                Button("\(value.rawValue) \(buttonCheckMark(event.conjunction == value))") {
                    event.conjunction = value
                }
            }
        }
        Button("Clear", role: .destructive) {
            event.conjunction = nil
        }
    }
}

struct ValueAmountView: View {
    @Binding var event: Event
    @Binding var selectedDice: DiceTypes?
    @Binding var totalDice: Int
    @State var buttonMode: Bool = true
    @Binding var sheetVariable: SheetVariable
    
    var safeMax: Int {
        get {
            guard let dice = event.dice else {
                return 2
            }
            switch event.reduction {
            case .sum:
                return dice.rawValue * totalDice
            case .maximum, .minimum, .consecutive, .sequence, .each, .mode, .average, .median, nil:
                return dice.rawValue
            }
        }
    }
    
    var body: some View {
        if event.comparison == .between || event.reduction == .sequence {
            HStack(spacing: 5) {
                if !buttonMode && sheetVariable == .value1 {
                    Text("1...\(safeMax)")
                } else {
                    Menu {
                        Picker("Dice Value 1", selection: self.$event.values.lower) {
                            ForEach(0...safeMax, id: \.self) {
                                Text("\($0)")
                            }
                        }
                    } label: {
                        Text("\(self.event.values.lower)")
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                            .modifier(ButtonInset(opacity: false, color: buttonMode ? .accentColor : .secondary))
                    }
                }
                Text("and")
                    .scaledToFit()
                if !buttonMode && sheetVariable == .value2 {
                    Text("1...\(safeMax)")
                } else {
                    Menu {
                        Picker("Dice Value 2", selection: self.$event.values.upper) {
                            ForEach(0...safeMax, id: \.self) {
                                Text("\($0)")
                            }
                        }
                    } label: {
                        Text("\(self.event.values.upper)")
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                            .modifier(ButtonInset(opacity: false, color: buttonMode ? .accentColor : .secondary))
                    }
                }
                Text("in value")
                    .scaledToFit()
            }
            .font(.headline)
        } else {
            HStack(spacing: 5) {
                if !buttonMode && (sheetVariable == .value || sheetVariable == .grid) {
                    Text("1...\(safeMax) in value")
                } else {
                    Menu {
                        Picker("Dice Value", selection: self.$event.value) {
                            ForEach(0...safeMax, id: \.self) {
                                Text("\($0)")
                            }
                        }
                    } label: {
                        Text("\(self.event.value)")
                            .padding(.leading, 5)
                            .padding(.trailing, 5)
                            .modifier(ButtonInset(opacity: false, color: buttonMode ? .accentColor : .secondary))
                    }
                    Text("in value")
                        .scaledToFit()
                }
            }
            .font(.headline)
        }
    }
}

struct ButtonInset: ViewModifier {
    @State var opacity: Bool
    @State var color: Color = SimulatorConstants.buttonColor
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(color)
            .opacity(opacity ? SimulatorConstants.buttonUnclick : SimulatorConstants.buttonClick)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .opacity(SimulatorConstants.buttonUnclick)
                    .foregroundColor(color)
                    .scaleEffect(1.05)
                    .frame(minWidth: 5)
            )
    }
}

func buttonCheckMark(_ condition: Bool) -> String {
    return condition ? "✔️" : ""
}



