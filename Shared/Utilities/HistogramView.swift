import SwiftUI

struct HistogramView: View {
    @StateObject var diceManager: DiceManager
    @Binding var showHistogram: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.secondary)
                .opacity(0.2)
            HStack(alignment: .bottom) {
                VStack {
                    HStack {
                        Button {
                            withAnimation(.spring()) {
                                showHistogram.toggle()
                            }
                        } label: {
                            Label("Scores", systemImage: "chevron.right.circle.fill")
                                .labelStyle(.iconOnly)
                                .imageScale(.medium)
                                .rotationEffect(.degrees(showHistogram ? 90 : 0))
                                .scaleEffect(showHistogram ? 1.1 : 1)
                            Spacer()
                            HStack(alignment: .bottom) {
                                Text("\(diceManager.totalDice)")
                                    .font(.caption.bold())
                                Text("Dice")
                                    .font(.caption2)
                                Text("\(diceManager.count)")
                                    .font(.caption.bold())
                                Text("Roll")
                                    .font(.caption2)
                                Text("\(diceManager.totalRoll)")
                                    .font(.caption.bold())
                                Text("Sum")
                                    .font(.caption2)
                                Text("\(diceManager.Average, specifier: "%.1f")")
                                    .font(.caption.bold())
                                Text("Avg")
                                    .font(.caption2)
                            }
                            .scaledToFit()
                            .foregroundColor(.primary)
                        }
                        .buttonStyle(.borderless)
                        .padding(.leading, 3)
                        .padding(.top, 3)
                        Spacer()
                    }
                    if showHistogram {
                        HStack {
                            Text("Frequency")
                                .font(.caption2.italic())
                                .rotationEffect(.degrees(-90))
                                .fixedSize()
                                .frame(width: 20, height: 90)
                            ScrollView(.horizontal) {
                                HStack{
                                    BarChart(data: diceManager.chartData)
                                }
                                .scaledToFit()
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: .infinity,
                                    alignment: .center
                                )
                            }
                            
                        }
                        .frame(minHeight: 130)
                    }
                }
            }
        }
    }
}

struct ChartData: Identifiable {
    var id: UUID = UUID()
    var label: String
    var numericLabel: Int
    var normalizedValue: Double
    var value: Int
    var percentage: Double
}

enum HistogramMode {
    case raw, percentage, both
}

struct BarChart: View {
    @State var showPercentage: Bool = false
    @State var histMode: HistogramMode = .both
    @State var animate: Bool = true
    var data: [ChartData]
    
    var body: some View {
        ForEach(data.indices, id: \.self) { index in
            if animate {
                BarChartCell(
                    showPercentage: $showPercentage,
                    histMode: $histMode,
                    label: data[index].label,
                    normalizedValue: data[index].normalizedValue,
                    value: data[index].value,
                    index: index,
                    percentage: data[index].percentage
                )
                .animation(.sequentialRipple(index: index))
                .padding(.top)
            } else {
                BarChartCell(
                    showPercentage: $showPercentage,
                    histMode: $histMode,
                    label: data[index].label,
                    normalizedValue: data[index].normalizedValue,
                    value: data[index].value,
                    index: index,
                    percentage: data[index].percentage
                )
                .padding(.top)
            }
        }
    }
}

struct BarChartCell: View {
    @Binding var showPercentage: Bool
    @Binding var histMode: HistogramMode
    var label: String
    var normalizedValue: Double
    var value: Int
    var index: Int
    var percentage: Double
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Constants.colors[index % Constants.colors.count])
                    .foregroundColor(.white)
                    .scaleEffect(
                        CGSize(
                            width: 0.6,
                            height: normalizedValue
                        ),
                        anchor: .bottom
                    )
                    .opacity(0.5)
                switch histMode {
                case .raw:
                    Text("\(value)")
                        .font(.caption2.bold())
                        .padding(.bottom, 3)
                case .percentage:
                    (
                        Text("\(percentage * 100, specifier: "%.f")") +
                        Text(" %").font(.system(size: 7, weight: .light))
                    )
                    .font(.system(size: 12).bold())
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .frame(width: 12, height: 15)
                    .padding(.bottom, 9)
                case .both:
                    if showPercentage {
                        (
                            Text("\(percentage * 100, specifier: "%.f")") +
                            Text(" %").font(.system(size: 7, weight: .light))
                        )
                        .font(.system(size: 12).bold())
                        .rotationEffect(.degrees(-90))
                        .fixedSize()
                        .frame(width: 12, height: 15)
                        .padding(.bottom, 9)
                    } else {
                        Text("\(value)")
                            .font(.caption2.bold())
                            .padding(.bottom, 3)
                    }
                }
            }
            Divider()
                .overlay(.primary)
            Text(label)
                .font(.caption)
        }
        .onTapGesture {
            showPercentage.toggle()
        }
    }
}
