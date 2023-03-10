import SwiftUI
import LinkPresentation
import UIKit

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

extension Collection where Element: Equatable {
    func contains<C: Collection>(_ collection: C) -> Bool where C.Element == Element  {
        guard !collection.isEmpty else { return false }
        let size = collection.count
        for i in indices.dropLast(size-1) where self[i..<index(i, offsetBy: size)].elementsEqual(collection) {
            return true
        }
        return false
    }
}

func calculateMedian(array: [Int]) -> Int {
    let sorted = array.sorted()
    if sorted.count % 2 == 0 {
        return Int((sorted[(sorted.count / 2)] + sorted[(sorted.count / 2) - 1])) / 2
    } else {
        return Int(sorted[(sorted.count - 1) / 2])
    }
}

struct ActivityViewController: UIViewControllerRepresentable {

    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

extension Array {
    mutating func remove(at set:IndexSet) {
        var arr = Swift.Array(self.enumerated())
        arr.removeAll{set.contains($0.offset)}
        self = arr.map{$0.element}
    }
}

extension Int {
    var double: Double {
        get { Double(self) }
        set { self = Int(floor(newValue)) }
    }
}

extension Array {
    func scan<T>(initial: T, _ f: (T, Element) -> T) -> [T] {
        return self.reduce([initial], { (listSoFar: [T], next: Element) -> [T] in
            // because we seeded it with a non-empty
            // list, it's easy to prove inductively
            // that this unwrapping can't fail
            let lastElement = listSoFar.last!
            return listSoFar + [f(lastElement, next)]
        })
    }
}

enum HandScriptType: String {
    case regular = "Caveat-Regular"
    case medium = "Caveat-Medium"
    case semiBold = "Caveat-SemiBold"
    case bold = "Caveat-Bold"
}

struct HandScriptFont: ViewModifier {
    var type: HandScriptType
    var size: CGFloat
    
    init(_ type: HandScriptType, size: CGFloat = 16) {
        self.type = type
        self.size = size
    }
    
    func body(content: Content) -> some View {
        content
            .font(.custom(type.rawValue, size: size))
    }
}

extension View {
    func handScriptFont(_ type: HandScriptType, size: CGFloat) -> some View {
        modifier(HandScriptFont(type, size: size))
    }
}
