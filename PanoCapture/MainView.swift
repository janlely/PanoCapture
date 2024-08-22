//
//  MainView.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/20.
//

import Foundation
import Cocoa

class MainView: NSView, CAAnimationDelegate {
    
    var startPoint: NSPoint?
    var currentPoint: NSPoint?
    var selectionRect: NSRect!
    var selectionLayer: CAShapeLayer?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        NSLog("wantsLayer")
        self.wantsLayer = true // 告诉NSView使用layer
        self.layer = CALayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        NSLog("wantsLayer")
        self.wantsLayer = true // 告诉NSView使用layer
        self.layer = CALayer()
    }
    
    override func mouseDown(with event: NSEvent) {
        NSLog("mouseDown")
        startPoint = self.convert(event.locationInWindow, from: nil)
    }
    
    override func mouseDragged(with event: NSEvent) {
        currentPoint = self.convert(event.locationInWindow, from: nil)
        updateSelectionLayer()
    }
    
    override func mouseUp(with event: NSEvent) {
        NSLog("mouseUp")
        needsDisplay = true
        guard let sp = startPoint, let cp = currentPoint else {
            return
        }
        if abs(sp.x - cp.x) < 5 || abs(sp.y - cp.y) < 5 {
            return
        }
        window?.ignoresMouseEvents = true
        NSCursor.arrow.set()
        // 在这里调用闪光动画
        if let selectionRect = selectionRect {
            flashSelectionArea(selectionRect)
        }
    }
    
    override func viewDidMoveToWindow() {
        window?.acceptsMouseMovedEvents = true
        window?.contentView?.postsFrameChangedNotifications = true
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    func flashSelectionArea(_ rect: NSRect) {
        NSLog("flashSelectionArea")
        let flashLayer = CALayer()
        flashLayer.frame = rect
        flashLayer.backgroundColor = NSColor.white.withAlphaComponent(0.5).cgColor
        flashLayer.zPosition = 1000 // 确保闪光层在顶部
        self.layer?.addSublayer(flashLayer)

        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.0
        animation.duration = 0.25 // 闪光持续时间
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.delegate = self
        flashLayer.add(animation, forKey: "flashAnimation")

        // 动画完成后移除layer
        CATransaction.setCompletionBlock {
            flashLayer.removeFromSuperlayer()
        }
    }
    
    func updateSelectionLayer() {
        if selectionLayer == nil {
            selectionLayer = CAShapeLayer()
            selectionLayer?.strokeColor = NSColor.blue.cgColor
            selectionLayer?.fillColor = nil // 无填充
            selectionLayer?.lineWidth = 1.0
            self.layer?.addSublayer(selectionLayer!)
        }

        if let startPoint = startPoint, let currentPoint = currentPoint {
            selectionRect = NSRect(x: min(startPoint.x, currentPoint.x),
                              y: min(startPoint.y, currentPoint.y),
                              width: abs(currentPoint.x - startPoint.x),
                              height: abs(currentPoint.y - startPoint.y))
            selectionLayer?.path = CGPath(rect: selectionRect, transform: nil)
        }
    }
}
