//
//  MainWindowController.swift
//  PanoCapture
//
//  Created by jin junjie on 2024/8/20.
//

import Foundation
import Cocoa

class MainWindowController: NSWindowController {
    var trackingArea: NSTrackingArea?
    var observer: Any?
    
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.isOpaque = false
        window?.backgroundColor = NSColor.black.withAlphaComponent(0.5)
        window?.acceptsMouseMovedEvents = true
        window?.styleMask = [.borderless, .fullSizeContentView]
        window?.titlebarAppearsTransparent = true
        window?.level = .screenSaver
    
        window?.setFrame(NSScreen.main?.frame ?? .zero, display: true)
        trackingArea = NSTrackingArea(rect: window!.contentView!.bounds,
                                          options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved],
                                          owner: self,
                                          userInfo: nil)
        window?.contentView?.addTrackingArea(trackingArea!)
    }
   
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSLog("mouseEntered")
        NSCursor.crosshair.set()
    }
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        print("Mouse exited")
    }
    
    func updateTrackingArea() {
        if let oldTrackingArea = trackingArea {
            window?.contentView?.removeTrackingArea(oldTrackingArea)
        }
        
        let newTrackingArea = NSTrackingArea(rect: window!.contentView!.bounds,
                                             options: [.activeAlways, .mouseEnteredAndExited, .mouseMoved],
                                             owner: self,
                                             userInfo: nil)
        window?.contentView?.addTrackingArea(newTrackingArea)
        trackingArea = newTrackingArea
    }
}
