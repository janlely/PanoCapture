//
//  MainView.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/20.
//

import Foundation
import Cocoa

class MainView: NSView {
    
    var startPoint: NSPoint?
    var currentPoint: NSPoint?
    
    override func mouseDown(with event: NSEvent) {
        NSLog("mouseDown")
        startPoint = event.locationInWindow
    }
    
    override func mouseDragged(with event: NSEvent) {
        NSLog("mouseDragged")
        currentPoint = event.locationInWindow
        needsDisplay = true
    }
    
    override func mouseUp(with event: NSEvent) {
        needsDisplay = true
        guard let sp = startPoint, let cp = currentPoint else {
            return
        }
        if abs(sp.x - cp.x) < 5 || abs(sp.y - cp.y) < 5 {
            return
        }
        window?.ignoresMouseEvents = true
        //开启5秒结束截图倒计时
    }
    
    override func viewDidMoveToWindow() {
        window?.acceptsMouseMovedEvents = true
        window?.contentView?.postsFrameChangedNotifications = true
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if let startPoint = startPoint, let endPoint = currentPoint {
            NSColor.blue.setStroke()
            let selectionRect = NSRect(x: min(startPoint.x, endPoint.x),
                                       y: min(startPoint.y, endPoint.y),
                                       width: abs(endPoint.x - startPoint.x),
                                       height: abs(endPoint.y - startPoint.y))
            NSBezierPath(rect: selectionRect).stroke()
        }
    }
    
}
