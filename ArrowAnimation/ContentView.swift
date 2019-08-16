//
//  ContentView.swift
//  ArrowAnimation
//
//  Created by Chris Eidhof on 01.08.19.
//  Copyright © 2019 Chris Eidhof. All rights reserved.
//

import SwiftUI

struct Eight: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { p in
            let start = CGPoint(x: 0.75, y: 0)
            p.move(to: start)
            p.addQuadCurve(to: CGPoint(x: 1, y: 0.5), control: CGPoint(x: 1, y: 0))
            p.addQuadCurve(to: CGPoint(x: 0.75, y: 1), control: CGPoint(x: 1, y: 1))
            p.addCurve(to: CGPoint(x: 0.25, y: 0), control1: CGPoint(x: 0.5, y: 1), control2: CGPoint(x: 0.5, y: 0))
            p.addQuadCurve(to: CGPoint(x: 0, y: 0.5), control: CGPoint(x: 0, y: 0))
            p.addQuadCurve(to: CGPoint(x: 0.25, y: 1), control: CGPoint(x: 0, y: 1))
            p.addCurve(to: start, control1: CGPoint(x: 0.5, y: 1), control2: CGPoint(x: 0.5, y: 0))
        }.applying(CGAffineTransform(scaleX: rect.width, y: rect.height))
    }
}

extension Path {
    func point(at position: CGFloat) -> CGPoint {
        assert(position >= 0 && position <= 1)
        guard position > 0 else { return cgPath.currentPoint }
        return trimmedPath(from: 0, to: position).cgPath.currentPoint
    }

    func pointAndAngle(at position: CGFloat) -> (CGPoint, Angle) {
        let p1 = point(at: position)
        let p2 = point(at: (position + 0.01).truncatingRemainder(dividingBy: 1))
        let angle = Angle(radians: Double(atan2(p2.y-p1.y, p2.x-p1.x)))
        return (p1, angle)
    }
}

let strokeStyle = StrokeStyle(lineWidth: 3)

struct FollowPath<P: Shape>: GeometryEffect {
    let pathShape: P
    var offset: CGFloat // 0...1
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        let path = pathShape.path(in: CGRect(origin: .zero, size: size))
        let (point, angle) = path.pointAndAngle(at: offset)
        let affineTransform = CGAffineTransform(translationX: point.x, y: point.y).rotated(by: CGFloat(angle.radians) + .pi/2)
        return ProjectionTransform(affineTransform)
    }
}

struct Trail<P: Shape>: Shape {
    let pathShape: P
    var offset: CGFloat // 0...1
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        let path = pathShape.path(in: rect)
        var result = Path()
        let trailLength: CGFloat = 0.2
        let trimFrom = offset - trailLength
        if trimFrom < 0 {
            result.addPath(path.trimmedPath(from: trimFrom + 1, to: 1))
        }
        result.addPath(path.trimmedPath(from: max(0, trimFrom), to: offset))
        result = result.strokedPath(strokeStyle)
        return result
    }
}


struct OnPath<P: Shape, S: Shape>: Shape {
    var shape: S
    let pathShape: P
    var offset: CGFloat // 0...1
    
    var animatableData: AnimatablePair<CGFloat, S.AnimatableData> {
        get {
            AnimatablePair(offset, shape.animatableData)
        }
        set {
            offset = newValue.first
            shape.animatableData = newValue.second
        }
    }
    
    func path(in rect: CGRect) -> Path {
        let path = pathShape.path(in: rect)
        let (point, angle) = path.pointAndAngle(at: offset)
        let shapePath = shape.path(in: rect)
        let size = shapePath.boundingRect.size
        let head = shapePath
            .offsetBy(dx: -size.width/2, dy: -size.height/2)
            .applying(CGAffineTransform(rotationAngle: CGFloat(angle.radians) + .pi/2))
            .offsetBy(dx: point.x, dy: point.y)
        var result = Path()
        let trailLength: CGFloat = 0.2
        let trimFrom = offset - trailLength
        if trimFrom < 0 {
            result.addPath(path.trimmedPath(from: trimFrom + 1, to: 1))
        }
        result.addPath(path.trimmedPath(from: max(0, trimFrom), to: offset))
        result = result.strokedPath(strokeStyle)
        result.addPath(head)
        return result
    }
}

struct ArrowHead: Shape {
    func path(in rect: CGRect) -> Path {
        return Path { p in
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }.strokedPath(strokeStyle)
    }
}

struct ContentView: View {
    let rect = Rectangle()
        .size(width: 30, height: 30)
    @State var position: CGFloat = 0

    var body: some View {
        VStack {
            ZStack {
                Eight()
                    .stroke(Color.gray)
                ArrowHead()
                    .size(width: 30, height: 30)
                    .offset(x: -15, y: -15)
                    .modifier(FollowPath(pathShape: Eight(), offset: position))
                Trail(pathShape: Eight(), offset: position)
            }.onAppear(perform: {
                withAnimation(Animation.linear(duration: 5).repeatForever(autoreverses:          false)) {
                    self.position = 1
                }
            })
            .aspectRatio(16/9, contentMode: .fit)
            .padding(20)
        }
        
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
