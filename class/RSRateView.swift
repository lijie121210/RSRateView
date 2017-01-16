//
//  RSRateView.swift
//  RollingStone
//
//  Created by jie on 2017/1/12.
//  Copyright © 2017年 HTIOT.Inc. All rights reserved.
//

import UIKit

open class RSRateView: UIView {
    
    fileprivate var animator: RSRateAnimator?

    open var progress: Float = RSRateModel.Init.value {
        didSet {
            progressLayer.progress = progress
        }
    }
    
    open var progressLayer: RSRateLayer {
        return self.layer as! RSRateLayer
    }
    
    open func setLayerModel(_ m: RSRateModel) {
        (self.layer as! RSRateLayer).setModel( m )
    }
    
    open override class var layerClass: Swift.AnyClass {
        return RSRateLayer.self
    }
    open override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = UIColor.clear
    }
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.clear
    }
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
    }
    
}

extension RSRateView {
    convenience init(frame: CGRect, model: RSRateModel) {
        self.init(frame: frame)
        self.setLayerModel(model)
    }
    
    ///
    open func animate(withDuration duration: TimeInterval, target progress: Float = 1.0) {
        
        if let animator = self.animator {
            animator.clear()
        }
        
        animator = RSRateAnimator(timeInterval: duration, targetProgress: progress, updateClosure: { (p) in
            self.progress = p
        }) {
            self.animator?.clear()
            self.animator = nil
        }
        animator!.run()
    }
    
    open func cancelAnimator() {
        if let animator = self.animator {
            animator.cancel()
            animator.clear()
        }
        self.animator = nil
    }
}

/// RSRateLayer
/// Provide the context for drawing
open class RSRateLayer: CALayer {
    
    @NSManaged var progress: Float
    
    open var model: RSRateModel = RSRateModel.default
    
    open func setModel(_ m: RSRateModel) {
        model = m
    }
    
    open override class func needsDisplay(forKey key: String) -> Bool {
        if key == RSRateModel.Init.key {
            return true
        }
        return super.needsDisplay(forKey: key)
    }
    
    open override func action(forKey event: String) -> CAAction? {
        if event == RSRateModel.Init.key {
            let animation = CABasicAnimation(keyPath: event)
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
            animation.fromValue = self.presentation()?.progress
            return animation
        }
        return super.action(forKey: event)
    }
    open override func draw(in ctx: CGContext) {
        guard let cprogress = self.presentation()?.progress else {
            return
        }
        self.model().model.draw(in: ctx,
                                base: bounds,
                                of: CGFloat( min( max(0.0, cprogress), 1.0) ))
    }
}

extension RSRateLayer {
    public convenience init(model: RSRateModel) {
        self.init()
        
        self.model = model
    }
}

/// RSDrawable
/// Type defination
protocol RSDrawable {
    func draw(in ctx: CGContext)
}

/// RSShadow
/// Represent a shadow attribute.
public struct RSShadow: Equatable {
    public var offset: CGSize
    public var blurRadius: CGFloat
    public var color: CGColor
}

/// RSLineAttr
/// Stroke options to draw a line
public struct RSStrokeAttr: Equatable {
    
    static let `default` = RSStrokeAttr(width: 2.0, color: UIColor(white: 0.8, alpha: 1).cgColor)
    
    /// set 0.0 to fit the bounds of the context
    public var width: CGFloat
    public var join: CGLineJoin
    public var cap: CGLineCap
    public var color: CGColor
    public var shadow: RSShadow?
    
    
    public init(width: CGFloat, color: CGColor, cap: CGLineCap = .round, join: CGLineJoin = .round, shadow: RSShadow? = nil) {
        self.width = width
        self.color = color
        self.cap = cap
        self.join = join
        self.shadow = shadow
    }
}

/// RSArcAttr
/// Fill options to draw an arc
public struct RSFillAttr: Equatable {
    
    static let `default` = RSFillAttr(color: UIColor(white: 0.8, alpha: 1).cgColor, shadow: nil)
    
    public var color: CGColor
    public var shadow: RSShadow?
    
    init(color: CGColor, shadow: RSShadow? = nil) {
        self.color = color
        self.shadow = shadow
    }
}

/// RSLine
/// Represent a line, and it can draw itself in the given context.
public struct RSLine: Equatable, RSDrawable {
    
    public var from: CGPoint
    public var to: CGPoint
    public var attribute: RSStrokeAttr
    
    public func draw(in ctx: CGContext) {
        ctx.beginPath()
        if let s = attribute.shadow {
            ctx.setShadow(offset: s.offset, blur: s.blurRadius, color: s.color)
        }
        ctx.setStrokeColor(attribute.color)
        ctx.setLineWidth(attribute.width)
        ctx.setLineCap(attribute.cap)
        ctx.setLineJoin(attribute.join)
        ctx.move(to: from)
        ctx.addLine(to: to)
        ctx.strokePath()
    }
}

/// RSSolidArc
/// Represent a solid arc, and it can draw itself in the given context.
public struct RSSolidArc: Equatable, RSDrawable {
    
    public var center: CGPoint
    public var radius: CGFloat
    public var start: CGFloat
    public var end: CGFloat
    public var clockwise: Bool
    public var attribute: RSFillAttr
    
    public func draw(in ctx: CGContext) {
        ctx.beginPath()
        if let shadow = attribute.shadow {
            ctx.setShadow(offset: shadow.offset, blur: shadow.blurRadius, color: shadow.color)
        }
        ctx.setFillColor(attribute.color)
        ctx.move(to: center)
        ctx.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: clockwise)
        ctx.closePath()
        ctx.fillPath()
    }
}

/// RSHollowArc
/// Represent a hollow arc, and it can draw itself in the given context.
public struct RSHollowArc: Equatable, RSDrawable {
    
    public var center: CGPoint
    public var radius: CGFloat
    public var start: CGFloat
    public var end: CGFloat
    public var clockwise: Bool
    public var attribute: RSStrokeAttr
    
    public func draw(in ctx: CGContext) {
        ctx.beginPath()
        if let shadow = attribute.shadow {
            ctx.setShadow(offset: shadow.offset, blur: shadow.blurRadius, color: shadow.color)
        }
        ctx.setStrokeColor(attribute.color)
        ctx.setLineCap(attribute.cap)
        ctx.setLineJoin(attribute.join)
        ctx.setLineWidth(attribute.width)
        ctx.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: clockwise)
        ctx.strokePath()
    }
}

/// RSConcentricArc
/// Represent a solid arc with a static border, and it can draw itself in the given context.
public struct RSConcentricArc: Equatable, RSDrawable {
    
    public var center: CGPoint
    public var outlineRadius: CGFloat
    public var inlineRadius: CGFloat
    public var start: CGFloat
    public var end: CGFloat
    public var clockwise: Bool
    public var lineAttr: RSStrokeAttr
    public var arcAttr: RSFillAttr
    
    public func draw(in ctx: CGContext) {
        ctx.beginPath()
        if let shadow = lineAttr.shadow {
            ctx.setShadow(offset: shadow.offset, blur: shadow.blurRadius, color: shadow.color)
        }
        ctx.setStrokeColor(lineAttr.color)
        ctx.setLineCap(lineAttr.cap)
        ctx.setLineJoin(lineAttr.join)
        ctx.setLineWidth(lineAttr.width)
        ctx.addArc(center: center, radius: outlineRadius, startAngle: 0.0, endAngle: CGFloat.pi * 2, clockwise: clockwise)
        ctx.strokePath()
        
        ctx.beginPath()
        if let shadow = arcAttr.shadow {
            ctx.setShadow(offset: shadow.offset, blur: shadow.blurRadius, color: shadow.color)
        }
        ctx.setFillColor(arcAttr.color)
        ctx.move(to: center)
        ctx.addArc(center: center, radius: inlineRadius, startAngle: start, endAngle: end, clockwise: clockwise)
        ctx.closePath()
        ctx.fillPath()
    }
}

/// RSRateModel
/// Model for RSRateLayer
public struct RSRateModel {
    
    public enum Shape: Equatable {
        case line
        case solidArc
        case hollowArc(width: CGFloat)
        case concentricArc(borderWidth: CGFloat, gap: CGFloat)
    }
    
    public enum Orientation: Int, Equatable {
        /// If you want the orientation changes follow the frame, use auto.
        /// For line: width >= height -> .horizontal;
        /// For arc: counterClockwise
        case auto
        case horizontal
        case vertical
        case clockwise
        case counterClockwise
        
        static let lines: [Orientation] = [.auto, .horizontal, .vertical]
        static let arcs: [Orientation] = [.auto, .clockwise, .counterClockwise]
    }
    
    public struct Init {
        static var value: Float = 0.0001
        static var key = "progress"
    }
    
    static let `default` = RSRateModel(shape: .line, orientation: .auto)
    
    public var shape: Shape
    public var orientation: Orientation
    public var strokeAttr: RSStrokeAttr?
    public var fillAttr: RSFillAttr?
    var backgroundColor: UIColor?
    
    init(shape: Shape, orientation: Orientation, strokeAttr: RSStrokeAttr? = nil, fillAttr: RSFillAttr? = nil, backgroundColor: UIColor? = nil) {
        self.shape = shape
        self.orientation = orientation
        self.strokeAttr = strokeAttr
        self.fillAttr = fillAttr
        self.backgroundColor = backgroundColor
    }
    
    func draw(in ctx: CGContext, base rect: CGRect, of progress: CGFloat) {
        
        drawBackground(in: ctx, base: rect)
        
        switch (shape, Orientation.lines.contains(orientation), Orientation.arcs.contains(orientation)) {
        case (.line, true, _): drawLine(base: rect, of: progress).draw(in: ctx)
        case (.solidArc, _, true): drawSolidArc(base: rect, of: progress).draw(in: ctx)
        case (.hollowArc(width: let w), _, true): drawHollowArc(base: rect, and: w, of: progress).draw(in: ctx)
        case (.concentricArc(borderWidth: let w, gap: let g), _, true): drawConcentricArc(base: rect, with: w, and: g, of: progress).draw(in: ctx)
        default: break
        }
    }
    
    func drawBackground(in ctx: CGContext, base rect: CGRect) {
        guard let background = backgroundColor else {
            return
        }
        switch shape {
        case .line:
            let bezier = UIBezierPath(roundedRect: rect, cornerRadius: (rect.width >= rect.height ? rect.height : rect.width) * 0.5)
            ctx.beginPath()
            ctx.addPath(bezier.cgPath)
            ctx.setFillColor(background.cgColor)
            ctx.fillPath()
        case .concentricArc(borderWidth: _, gap: _), .hollowArc(width: _), .solidArc:
            ctx.beginPath()
            ctx.addArc(center: CGPoint(x: rect.width * 0.5, y: rect.height * 0.5),
                       radius: (rect.width >= rect.height ? rect.height : rect.width) * 0.5,
                       startAngle: 0,
                       endAngle: CGFloat.pi * 2.0,
                       clockwise: false)
            ctx.setFillColor(background.cgColor)
            ctx.fillPath()
        }
    }
    
    func drawLine(base rect: CGRect, of progress: CGFloat) -> RSLine {
        var orientation = self.orientation
        if orientation == .auto {
            orientation = rect.width >= rect.height ? .horizontal : .vertical
        }
        
        var lineWidth: CGFloat
        var startPoint: CGPoint
        var endPoint: CGPoint
        
        if orientation == .horizontal {
            startPoint = CGPoint(x: 0.0, y: rect.midY)
            endPoint = CGPoint(x: progress * rect.width, y: rect.midY)
            
            if let w = strokeAttr?.width, w > 0.0 {
                lineWidth = w
            } else if let h = strokeAttr?.shadow?.offset.height, let r = strokeAttr?.shadow?.blurRadius {
                lineWidth = max(1.0, rect.height - max(h, r))
            } else {
                lineWidth = rect.height
            }
            
        } else {
            startPoint = CGPoint(x: rect.midX, y: 0)
            endPoint = CGPoint(x: rect.midX, y: progress * rect.height)
            
            if let w = strokeAttr?.width, w > 0.0 {
                lineWidth = w
            } else if let h = strokeAttr?.shadow?.offset.width, let r = strokeAttr?.shadow?.blurRadius {
                lineWidth = max(1.0, rect.width - max(h, r))
            } else {
                lineWidth = rect.width
            }
        }
        
        let attr = RSStrokeAttr(width:  lineWidth,
                                color:  strokeAttr?.color   ?? RSStrokeAttr.default.color,
                                cap:    strokeAttr?.cap     ?? RSStrokeAttr.default.cap,
                                join:   strokeAttr?.join    ?? RSStrokeAttr.default.join,
                                shadow: strokeAttr?.shadow  ?? RSStrokeAttr.default.shadow)
        
        return RSLine(from: startPoint, to: endPoint, attribute: attr)
    }
    
    func drawSolidArc(base rect: CGRect, of progress: CGFloat) -> RSSolidArc {
        
        var orientation = self.orientation
        if orientation == .auto {
            orientation = .counterClockwise
        }
        
        let centerPoint = CGPoint(x: rect.width * 0.5, y: rect.height * 0.5)
        var radius = (rect.width >= rect.height ? rect.height : rect.width) * 0.5
        var startAngle: CGFloat
        var endAngle: CGFloat
        var clockwise: Bool
        
        if orientation == .counterClockwise {
            startAngle = 0.0001
            endAngle = progress * CGFloat(M_PI * 2)
            clockwise = false
        } else {
            startAngle = progress * CGFloat(M_PI * 2)
            endAngle = 0.0001
            clockwise = true
        }
        if let shadow = fillAttr?.shadow {
            radius = max(radius - max(shadow.blurRadius, shadow.offset.width, shadow.offset.height), 1.0)
        }
        
        let attr = RSFillAttr(color:    fillAttr?.color     ?? RSFillAttr.default.color,
                              shadow:   fillAttr?.shadow    ?? RSFillAttr.default.shadow)
        
        return RSSolidArc(center: centerPoint,
                          radius: radius,
                          start: startAngle,
                          end: endAngle,
                          clockwise: clockwise,
                          attribute: attr)
    }
    
    func drawHollowArc(base rect: CGRect, and width: CGFloat, of progress: CGFloat) -> RSHollowArc {
        
        var orientation = self.orientation
        if orientation == .auto {
            orientation = .counterClockwise
        }
        
        let centerPoint = CGPoint(x: rect.width * 0.5, y: rect.height * 0.5)
        var radius = (rect.width >= rect.height ? rect.height : rect.width) * 0.5 - width * 0.5
        var startAngle: CGFloat
        var endAngle: CGFloat
        var clockwise: Bool
        
        if orientation == .counterClockwise {
            startAngle = 0.0001
            endAngle = progress * CGFloat(M_PI * 2)
            clockwise = false
        } else {
            startAngle = progress * CGFloat(M_PI * 2)
            endAngle = 0.0001
            clockwise = true
        }
        if let shadow = strokeAttr?.shadow {
            radius = max(radius - max(shadow.blurRadius, shadow.offset.width, shadow.offset.height), 1.0)
        }
        
        let attr = RSStrokeAttr(width:  width,
                                color:  strokeAttr?.color   ?? RSStrokeAttr.default.color,
                                cap:    strokeAttr?.cap     ?? RSStrokeAttr.default.cap,
                                join:   strokeAttr?.join    ?? RSStrokeAttr.default.join,
                                shadow: strokeAttr?.shadow  ?? RSStrokeAttr.default.shadow)
        
        return RSHollowArc(center: centerPoint,
                           radius: radius,
                           start: startAngle,
                           end: endAngle,
                           clockwise: clockwise,
                           attribute: attr)
        
    }
    
    func drawConcentricArc(base rect: CGRect, with width: CGFloat, and gap: CGFloat, of progress: CGFloat) -> RSConcentricArc {
        
        var orientation = self.orientation
        if orientation == .auto {
            orientation = .counterClockwise
        }
        
        let centerPoint = CGPoint(x: rect.width * 0.5, y: rect.height * 0.5)
        let R = (rect.width >= rect.height ? rect.height : rect.width) * 0.5
        var oradius = R - width * 0.5
        var iradius = R - width - gap
        var startAngle: CGFloat
        var endAngle: CGFloat
        var clockwise: Bool
        
        if orientation == .counterClockwise {
            startAngle = 0.0001
            endAngle = progress * CGFloat(M_PI * 2)
            clockwise = false
        } else {
            startAngle = progress * CGFloat(M_PI * 2)
            endAngle = 0.0001
            clockwise = true
        }
        
        if let shadow = strokeAttr?.shadow {
            oradius = max(oradius - max(shadow.blurRadius, shadow.offset.width, shadow.offset.height), 1.0)
        }
        
        if let shadow = fillAttr?.shadow {
            iradius = max(iradius - max(shadow.blurRadius, shadow.offset.width, shadow.offset.height), 1.0)
        }
        
        let stroke = RSStrokeAttr(width:    width,
                                  color:    strokeAttr?.color   ?? RSStrokeAttr.default.color,
                                  cap:      strokeAttr?.cap     ?? RSStrokeAttr.default.cap,
                                  join:     strokeAttr?.join    ?? RSStrokeAttr.default.join,
                                  shadow:   strokeAttr?.shadow  ?? RSStrokeAttr.default.shadow)
        
        let fill = RSFillAttr(color:    fillAttr?.color     ?? RSFillAttr.default.color,
                              shadow:   fillAttr?.shadow    ?? RSFillAttr.default.shadow)
        
        return RSConcentricArc(center: centerPoint,
                               outlineRadius: oradius,
                               inlineRadius: iradius,
                               start: startAngle,
                               end: endAngle,
                               clockwise: clockwise,
                               lineAttr: stroke,
                               arcAttr: fill)
    }
}






public func ==(lhs: RSShadow, rhs: RSShadow) -> Bool {
    let condition = lhs.offset == rhs.offset
        && lhs.blurRadius == rhs.blurRadius
        && lhs.color == rhs.color
    
    return condition
}

public func ==(lhs: RSStrokeAttr, rhs: RSStrokeAttr) -> Bool {
    return lhs.width == rhs.width && lhs.color == rhs.color && lhs.cap == rhs.cap && lhs.join == rhs.join
}

public func ==(lhs: RSLine, rhs: RSLine) -> Bool {
    return lhs.from == rhs.from && lhs.to == rhs.to && lhs.attribute == rhs.attribute
}

public func ==(lhs: RSFillAttr, rhs: RSFillAttr) -> Bool {
    return lhs.color == rhs.color && lhs.shadow == rhs.shadow
}

public func ==(lhs: RSSolidArc, rhs: RSSolidArc) -> Bool {
    return lhs.center == rhs.center
        && lhs.radius == rhs.radius
        && lhs.start == rhs.start
        && lhs.end == rhs.end
        && lhs.clockwise == rhs.clockwise
        && lhs.attribute == rhs.attribute
}

public func ==(lhs: RSHollowArc, rhs: RSHollowArc) -> Bool {
    return lhs.attribute == rhs.attribute
        && lhs.center == rhs.center
        && lhs.radius == rhs.radius
        && lhs.start == rhs.start
        && lhs.end == rhs.end
        && lhs.clockwise == rhs.clockwise
}

public func ==(lhs: RSConcentricArc, rhs: RSConcentricArc) -> Bool {
    return lhs.arcAttr == rhs.arcAttr
        && lhs.lineAttr == rhs.lineAttr
        && lhs.center == rhs.center
        && lhs.outlineRadius == rhs.outlineRadius
        && lhs.inlineRadius == rhs.inlineRadius
        && lhs.start == rhs.start
        && lhs.end == rhs.end
        && lhs.clockwise == rhs.clockwise
}

public func ==(lhs: RSRateModel.Shape, rhs:RSRateModel.Shape) -> Bool {
    switch (lhs, rhs) {
    case (.line, .line): return true
    case (.solidArc, .solidArc): return true
    case (.hollowArc(let a), .hollowArc(let b)): return a == b
    case (.concentricArc(let a, let b), .concentricArc(let c, let d)): return a == c && b == d
    default: return false
    }
}

public func ==(lhs: RSRateModel, rhs: RSRateModel) -> Bool {
    return lhs.strokeAttr == rhs.strokeAttr
        && lhs.fillAttr == rhs.fillAttr
        && lhs.shape == rhs.shape
        && lhs.orientation == rhs.orientation
}
