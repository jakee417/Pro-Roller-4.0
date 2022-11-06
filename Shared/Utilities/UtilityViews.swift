//
//  File.swift
//  Pro Roller
//
//  Created by Jake Taylor on 7/29/22.
//

import Foundation
import SwiftUI


struct BackButtonView: View {
    @State var dismiss: DismissAction
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            HStack {
                Image(systemName: "chevron.left")
                    .resizable()
                    .frame(
                        width: Constants.sheetBackButtonWidth,
                        height: Constants.sheetBackButtonHeight,
                        alignment: .topLeading
                    )
                    .foregroundColor(.accentColor)
            }
        }
    }
}

extension Animation {
    static func sequentialRipple(index: Int) -> Animation {
        Animation.spring(dampingFraction: 0.7)
            .speed(2)
            .delay(0.015 * Double(index))
    }
}

extension Animation {
    static func repeatForever() -> Animation {
        Animation.linear(duration: 0.3)
        .repeatForever()
    }
}

extension Animation {
    static func repeatN(_ n: Int) -> Animation {
        Animation.linear(duration: 0.3)
        .repeatCount(n)
    }
}

extension Shape {
    func radialFill() -> some View {
        self.fill(AngularGradient(
            gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple]),
            center: .center
        ))
        .opacity(0.75)
    }
}

extension Shape {
    func triangleFill() -> some View {
        self.fill(AngularGradient(
            gradient: Gradient(colors: [.red, .yellow, .blue]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(180)
        ))
        .opacity(0.75)
    }
}

extension Shape {
    func linearFill() -> some View {
        self.fill(LinearGradient(
            gradient: Gradient(colors: [.red, .orange, .yellow, .green, .blue, .purple]),
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        ))
        .opacity(0.75)
    }
}

extension AnyTransition {
    static var moveAndFade: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .leading).combined(with: .scale),
            removal: .move(edge: .trailing).combined(with: .scale)
        )
    }
}

extension View {
    func innerShadow<S: Shape>(
        using shape: S,
        angle: Angle = .degrees(0),
        color: Color = .black,
        width: CGFloat = 6,
        blur: CGFloat = 6
    ) -> some View {
        let finalX = CGFloat(cos(angle.radians - .pi / 2))
        let finalY = CGFloat(sin(angle.radians - .pi / 2))
        
        return self
            .overlay(
                shape
                    .stroke(color, lineWidth: width)
                    .offset(x: finalX * width * 0.6, y: finalY * width * 0.6)
                    .blur(radius: blur)
                    .mask(shape)
            )
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
        return path
    }
}

struct softTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        // vertex
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY * 0.98))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY * 0.99))
        path.addLine(to: CGPoint(x: rect.minX * 0.99, y: rect.maxY * 0.99))
        path.addLine(to: CGPoint(x: rect.minX * 0.99, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX * 0.98, y: rect.maxY))
        // vertex
        path.addLine(to: CGPoint(x: rect.maxX * 0.98, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.99, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX * 0.99, y: rect.maxY * 0.99))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.99))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.98))
        // vertex
        path.addLine(to: CGPoint(x: rect.midX * 1.02, y: rect.minY * 0.98))
        path.addLine(to: CGPoint(x: rect.midX * 1.01, y: rect.minY * 0.99))
        path.addLine(to: CGPoint(x: rect.midX * 0.99, y: rect.minY * 0.99))
        path.addLine(to: CGPoint(x: rect.midX * 0.98, y: rect.minY * 0.98))
        return path
    }
}

struct Arrow: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            let width = rect.width
            let height = rect.height
            
            path.addLines( [
                CGPoint(x: width * 0.4, y: height),
                CGPoint(x: width * 0.4, y: height * 0.4),
                CGPoint(x: width * 0.2, y: height * 0.4),
                CGPoint(x: width * 0.5, y: height * 0.1),
                CGPoint(x: width * 0.8, y: height * 0.4),
                CGPoint(x: width * 0.6, y: height * 0.4),
                CGPoint(x: width * 0.6, y: height)
                
            ])
            path.closeSubpath()
        }
    }
}

struct PlayerView: View {
    @State var playerImage: UIImage?
    
    let gradient = Gradient(colors: [.primary, .gray])

    var body: some View {
        if let uiImage = self.playerImage {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
                .clipShape(Circle())
                .shadow(radius: 1)
        } else {
            Image(systemName: "person.fill")
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
                .background(
                    .radialGradient(
                        gradient,
                        center: .center,
                        startRadius: 0.0,
                        endRadius: 20.0
                    )
                )
                .clipShape(Circle())
                .shadow(radius: 1)
                .foregroundColor(.accentColor)
        }
    }
}
